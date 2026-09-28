#!/usr/bin/env bash
# Live test against a real sandbox account. Never part of `make verify`.
#
# Scope: only resources that can be created and deleted in one run (log
# archive bucket and key, VPC without NAT, pipeline role, one budget). AWS
# Organizations, member accounts, SCPs, Identity Center and the organization
# trail are out of scope on purpose: closing an account takes 90 days, and
# org-level changes affect every account. Those are covered offline only.
#
# Live tests run private-only: the plan is saved first, and scripts/check_private_plan.py refuses
# it if anything would be internet-facing. Only the checked plan is applied.
#
# Usage: CONFIRM_LIVE=yes LIVE_ACCOUNT_ID=<sandbox account id> make test-live
set -euo pipefail

PROFILE="${AWS_PROFILE_LIVE:-dev}"
REGION="${AWS_REGION_LIVE:-us-east-1}"
TAG_KEY="purpose"
TAG_VALUE="portfolio-test"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LIVE_DIR="$ROOT_DIR/tests/live"

if [[ "${CONFIRM_LIVE:-}" != "yes" ]]; then
  echo "Refusing to run: this creates real AWS resources in profile '$PROFILE'." >&2
  echo "Re-run with CONFIRM_LIVE=yes LIVE_ACCOUNT_ID=<id> make test-live after reading scripts/test-live.sh." >&2
  exit 2
fi

echo "==> Caller identity (confirm this is the sandbox account)"
aws sts get-caller-identity --profile "$PROFILE" --output table
ACCOUNT_ID="$(aws sts get-caller-identity --profile "$PROFILE" --query Account --output text)"
if [[ -z "${LIVE_ACCOUNT_ID:-}" || "$ACCOUNT_ID" != "$LIVE_ACCOUNT_ID" ]]; then
  echo "Refusing to run: profile '$PROFILE' resolves to $ACCOUNT_ID, LIVE_ACCOUNT_ID is '${LIVE_ACCOUNT_ID:-unset}'." >&2
  exit 2
fi

WORK_DIR="$(mktemp -d)"
SUFFIX="$(od -An -N4 -tx1 /dev/urandom | tr -d ' \n')"
NAME="lz-live-$SUFFIX"
TF_ARGS=(
  -var "profile=$PROFILE"
  -var "region=$REGION"
  -var "account_id=$ACCOUNT_ID"
  -var "suffix=$SUFFIX"
)

# Reuse an existing GitHub OIDC provider by ARN so the test never manages, and
# therefore never deletes, a provider other workloads depend on.
OIDC_ARN="arn:aws:iam::$ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
if aws iam get-open-id-connect-provider --profile "$PROFILE" --open-id-connect-provider-arn "$OIDC_ARN" >/dev/null 2>&1; then
  TF_ARGS+=(-var "oidc_provider_arn=$OIDC_ARN")
fi

export TF_DATA_DIR="$WORK_DIR/.terraform"

leftovers() {
  # Regional resources from this run, found by the run tag. KMS keys cannot be
  # deleted at once; a key in PendingDeletion counts as cleaned up. The tagging
  # API keeps listing deleted security groups and flow logs for a long time,
  # so those are confirmed against EC2 before they count as leftovers.
  local arn state
  aws resourcegroupstaggingapi get-resources --profile "$PROFILE" --region "$REGION" \
    --tag-filters "Key=$TAG_KEY,Values=$TAG_VALUE" "Key=run,Values=$SUFFIX" \
    --query 'ResourceTagMappingList[].ResourceARN' --output text | tr '\t' '\n' | while read -r arn; do
    [[ -z "$arn" ]] && continue
    if [[ "$arn" == arn:aws:kms:* ]]; then
      state="$(aws kms describe-key --profile "$PROFILE" --region "$REGION" --key-id "$arn" \
        --query 'KeyMetadata.KeyState' --output text 2>/dev/null || echo Unknown)"
      [[ "$state" == "PendingDeletion" ]] && continue
    fi
    if [[ "$arn" == arn:aws:ec2:*:security-group/* ]]; then
      aws ec2 describe-security-groups --profile "$PROFILE" --region "$REGION" \
        --group-ids "${arn##*/}" >/dev/null 2>&1 || continue
    fi
    if [[ "$arn" == arn:aws:ec2:*:vpc-flow-log/* ]]; then
      state="$(aws ec2 describe-flow-logs --profile "$PROFILE" --region "$REGION" \
        --flow-log-ids "${arn##*/}" --query 'length(FlowLogs)' --output text)"
      [[ "$state" == "0" ]] && continue
    fi
    echo "$arn"
  done

  # Global resources are looked up by name.
  if aws iam get-role --profile "$PROFILE" --role-name "$NAME" >/dev/null 2>&1; then
    echo "iam role $NAME"
  fi
  if aws iam get-policy --profile "$PROFILE" --policy-arn "arn:aws:iam::$ACCOUNT_ID:policy/$NAME-boundary" >/dev/null 2>&1; then
    echo "iam policy $NAME-boundary"
  fi
  if aws budgets describe-budget --profile "$PROFILE" --account-id "$ACCOUNT_ID" --budget-name "$NAME" >/dev/null 2>&1; then
    echo "budget $NAME"
  fi
}

cleanup() {
  local status=$?
  set +e
  echo "==> Destroying test resources"
  if ! terraform -chdir="$LIVE_DIR" destroy -auto-approve -input=false "${TF_ARGS[@]}"; then
    status=1
  fi
  echo "==> Checking for leftovers from run $SUFFIX"
  local left
  if ! left="$(leftovers)"; then
    echo "Leftover check failed; verify by hand with tag run=$SUFFIX." >&2
    status=1
  elif [[ -n "$left" ]]; then
    echo "Leftover resources (delete them by hand):" >&2
    echo "$left" >&2
    status=1
  fi
  if [[ "$status" -eq 0 ]]; then
    rm -rf "$WORK_DIR"
  else
    echo "State kept for recovery in $WORK_DIR (outside the repository)." >&2
  fi
  exit "$status"
}
trap cleanup EXIT

echo "==> Applying (run $SUFFIX)"
terraform -chdir="$LIVE_DIR" init -input=false -backend-config="path=$WORK_DIR/terraform.tfstate" >/dev/null
terraform -chdir="$LIVE_DIR" plan -input=false -out="$WORK_DIR/live.tfplan" "${TF_ARGS[@]}" >/dev/null
terraform -chdir="$LIVE_DIR" show -json "$WORK_DIR/live.tfplan" >"$WORK_DIR/live-plan.json"
"$ROOT_DIR/scripts/check_private_plan.py" "$WORK_DIR/live-plan.json"
terraform -chdir="$LIVE_DIR" apply -input=false "$WORK_DIR/live.tfplan"

BUCKET="$(terraform -chdir="$LIVE_DIR" output -raw log_bucket_name)"
ACCESS_BUCKET="$BUCKET-access"
VPC_ID="$(terraform -chdir="$LIVE_DIR" output -raw vpc_id)"

fail() {
  echo "FAIL: $1" >&2
  exit 1
}

echo "==> Asserting outcomes"
SSE="$(aws s3api get-bucket-encryption --profile "$PROFILE" --bucket "$BUCKET" \
  --query 'ServerSideEncryptionConfiguration.Rules[0].ApplyServerSideEncryptionByDefault.SSEAlgorithm' --output text)"
[[ "$SSE" == "aws:kms" ]] || fail "log bucket encryption is $SSE, expected aws:kms"

PAB="$(aws s3api get-public-access-block --profile "$PROFILE" --bucket "$BUCKET" \
  --query 'PublicAccessBlockConfiguration.[BlockPublicAcls,BlockPublicPolicy,IgnorePublicAcls,RestrictPublicBuckets]' --output text)"
[[ "$PAB" == $'True\tTrue\tTrue\tTrue' ]] || fail "public access block is '$PAB'"

# AWS CLI v2 rejects /dev/null as a blob body; it needs a regular file.
PROBE_FILE="$WORK_DIR/probe.txt"
: >"$PROBE_FILE"

# Control: a write over HTTPS works. Probe: the same write over plain HTTP is
# refused by the bucket policy with AccessDenied, not by some other error. The
# probe targets the SSE-S3 access-log bucket, which gets the same TLS-only
# statement from secure-bucket: S3 rejects any plain-HTTP write to a bucket
# with KMS default encryption before the bucket policy is evaluated.
aws s3api put-object --profile "$PROFILE" --bucket "$ACCESS_BUCKET" --key probe-https.txt --body "$PROBE_FILE" >/dev/null \
  || fail "HTTPS write to the access-log bucket failed; the probe below would prove nothing"
if HTTP_ERR="$(aws s3api put-object --profile "$PROFILE" --bucket "$ACCESS_BUCKET" --key probe-http.txt --body "$PROBE_FILE" \
  --endpoint-url "http://s3.$REGION.amazonaws.com" 2>&1 >/dev/null)"; then
  fail "plain HTTP write to the access-log bucket succeeded; the TLS-only policy is not enforced"
fi
[[ "$HTTP_ERR" == *AccessDenied* ]] || fail "plain HTTP write failed for another reason: $HTTP_ERR"

RULES="$(aws ec2 describe-security-groups --profile "$PROFILE" --region "$REGION" \
  --filters "Name=vpc-id,Values=$VPC_ID" "Name=group-name,Values=default" \
  --query '[length(SecurityGroups[0].IpPermissions), length(SecurityGroups[0].IpPermissionsEgress)]' --output text)"
[[ "$RULES" == $'0\t0' ]] || fail "default security group has ingress/egress rule counts '$RULES', expected none"

SUB="$(aws iam get-role --profile "$PROFILE" --role-name "$NAME" \
  --query 'Role.AssumeRolePolicyDocument.Statement[0].Condition.StringEquals."token.actions.githubusercontent.com:sub"' --output text)"
[[ "$SUB" == "repo:harbor-goods/storefront:environment:production" ]] || fail "trust subject is '$SUB'"

BOUNDARY="$(aws iam get-role --profile "$PROFILE" --role-name "$NAME" \
  --query 'Role.PermissionsBoundary.PermissionsBoundaryArn' --output text)"
[[ "$BOUNDARY" == *":policy/$NAME-boundary" ]] || fail "permissions boundary is '$BOUNDARY'"

echo "==> All live assertions passed"
