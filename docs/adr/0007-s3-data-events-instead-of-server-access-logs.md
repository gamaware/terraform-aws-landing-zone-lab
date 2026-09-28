# 0007. S3 data events instead of S3 server access logs

## Status

Accepted

## Context

The log archive and the Terraform state bucket must record who reads and writes their objects. S3 server access logs
did that, but AWS delivers them only to a target bucket with SSE-S3 default encryption; SSE-KMS targets are not
supported. The module therefore kept a second bucket pattern, an SSE-S3 access-log bucket next to every KMS bucket.
Those buckets are encrypted with a key the client does not control, and Trivy (AWS-0132) flags them. Every other
bucket in the landing zone uses a customer managed key.

## Decision

`modules/secure-bucket` creates SSE-KMS buckets only, with a customer managed key and a bucket key; the SSE-S3 branch,
the `sse_algorithm` input and S3 server access logging are removed, and so are the two access-log buckets.

Object access is recorded by the organization trail as CloudTrail S3 data events, delivered to the KMS-encrypted log
archive with log file validation:

- Reads of the log archive bucket. Writes are excluded: CloudTrail and AWS Config write there continuously, and
  recording those writes would feed the trail its own delivery.
- Every read and write of the buckets in `data_event_bucket_arns`; the management stack passes the Terraform state
  bucket.

Checkov CKV_AWS_18 accepts only S3 server access logging as evidence of access logging, so the bucket resource in
`modules/secure-bucket` carries one inline skip for it that points to this record.

## Consequences

- Every bucket, including the audit trail of bucket access, is encrypted with a customer managed key.
- Data events are billed per event (USD 0.10 per 100,000 in the home region at the time of writing). Reads of the log
  archive and state access are low volume; a busy workload bucket added to `data_event_bucket_arns` is not.
- Data events arrive within minutes and are integrity-checked through log file validation; server access logs are best
  effort and unsigned.
- Server access logs carried fields that data events do not, such as the HTTP status and bytes sent. Access
  investigations use CloudTrail Lake or Athena over the trail instead.
- Accounts outside the organization trail, such as a stand-alone sandbox, record no bucket access unless they add a
  trail of their own.

## Compliance

- `modules/secure-bucket/tests/secure_bucket.tftest.hcl`: SSE-KMS with the given key and a bucket key; any value that
  is not a KMS key ARN is rejected.
- `modules/org-trail/tests/org_trail.tftest.hcl`: `data_events_replace_server_access_logs` checks the log-archive read
  selector and the watched-bucket selector; wildcard bucket ARNs are rejected.
- `modules/log-archive/tests/log_archive.tftest.hcl`: the log bucket uses the log-archive key.
- Trivy (HIGH and CRITICAL) and Checkov run in `make verify` and CI.

## Notes

Alternatives considered:

- Keep SSE-S3 access-log buckets: rejected, because they are the only buckets without a customer managed key.
- Point server access logging at an SSE-KMS bucket: both scanners pass, but S3 never delivers the logs.
- CloudTrail Lake or a separate data-event trail: more cost and another resource to govern, for the same records the
  organization trail can carry.
