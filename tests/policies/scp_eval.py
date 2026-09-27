"""Minimal evaluator for the Deny-only SCPs in policies/scp/.

It supports exactly the policy grammar those files use (Deny statements with
Action or NotAction, Resource "*" or ARN patterns, and the StringLike,
StringNotEquals and ArnNotLike condition operators) and raises on anything
else, so a new construct in a policy fails the tests instead of being
silently ignored. It answers one question: would any statement deny this
request? It is not a general IAM policy simulator.
"""

from __future__ import annotations

import fnmatch
import json
from dataclasses import dataclass, field
from pathlib import Path

SUPPORTED_OPERATORS = {"StringLike", "StringNotEquals", "ArnLike", "ArnNotLike"}
SUPPORTED_KEYS = {"Sid", "Effect", "Action", "NotAction", "Resource", "Condition"}


class UnsupportedPolicy(ValueError):
    """The policy uses grammar this evaluator does not model."""


@dataclass
class Request:
    action: str
    principal_arn: str
    region: str = "us-east-1"
    resource: str = "*"
    context: dict[str, str] = field(default_factory=dict)

    def value(self, key: str) -> str | None:
        builtin = {
            "aws:PrincipalArn": self.principal_arn,
            "aws:RequestedRegion": self.region,
        }
        return builtin.get(key, self.context.get(key))


def _as_list(value: str | list[str]) -> list[str]:
    return [value] if isinstance(value, str) else list(value)


def _match(pattern: str, value: str, case_sensitive: bool) -> bool:
    if case_sensitive:
        return fnmatch.fnmatchcase(value, pattern)
    return fnmatch.fnmatchcase(value.lower(), pattern.lower())


def _condition_holds(condition: dict, request: Request) -> bool:
    for operator, clauses in condition.items():
        if operator not in SUPPORTED_OPERATORS:
            raise UnsupportedPolicy(f"condition operator {operator}")
        for key, expected in clauses.items():
            actual = request.value(key)
            patterns = _as_list(expected)
            if actual is None:
                # Negated operators match when the key is absent; others fail.
                if operator in {"StringNotEquals", "ArnNotLike"}:
                    continue
                return False
            if operator == "StringNotEquals":
                ok = actual not in patterns
            elif operator == "StringLike":
                ok = any(_match(p, actual, True) for p in patterns)
            elif operator == "ArnLike":
                ok = any(_match(p, actual, True) for p in patterns)
            else:  # ArnNotLike
                ok = not any(_match(p, actual, True) for p in patterns)
            if not ok:
                return False
    return True


def _action_in_scope(statement: dict, action: str) -> bool:
    # IAM action names are case-insensitive.
    if "Action" in statement:
        return any(_match(p, action, False) for p in _as_list(statement["Action"]))
    if "NotAction" in statement:
        return not any(_match(p, action, False) for p in _as_list(statement["NotAction"]))
    raise UnsupportedPolicy("statement without Action or NotAction")


def denied_by(policy: dict, request: Request) -> list[str]:
    """Return the Sids of statements that deny the request."""
    sids = []
    for statement in policy["Statement"]:
        unknown = set(statement) - SUPPORTED_KEYS
        if unknown:
            raise UnsupportedPolicy(f"statement keys {sorted(unknown)}")
        if statement["Effect"] != "Deny":
            raise UnsupportedPolicy("only Deny statements are modeled")
        if not _action_in_scope(statement, request.action):
            continue
        resources = _as_list(statement.get("Resource", "*"))
        if not any(_match(r, request.resource, True) or r == "*" for r in resources):
            continue
        if _condition_holds(statement.get("Condition", {}), request):
            sids.append(statement["Sid"])
    return sids


def load(path: Path) -> dict:
    with path.open(encoding="utf-8") as handle:
        return json.load(handle)
