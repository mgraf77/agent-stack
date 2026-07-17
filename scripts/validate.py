#!/usr/bin/env python3
"""Free, local, dependency-free validator for the Agent Stack foundation.

Checks:
  - catalog/repositories.csv matches the expected header and enum.
  - catalog/capabilities/*.json match schemas/capability-record.schema.json
    and stay consistent with catalog/repositories.csv.
  - profiles/*.json match schemas/project-profile.schema.json and only
    reference capabilities that exist and list this profile back.
  - catalog/receipts/*.json match schemas/sync-release-receipt.schema.json
    and reference a profile that exists.

No network access, no third-party packages, no API keys.
"""

import csv
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

DATE_RE = re.compile(r"^\d{4}-\d{2}-\d{2}$")
ID_RE = re.compile(r"^[a-z0-9]+(-[a-z0-9]+)*$")

CATALOGUE_DECISIONS = {"ADOPT NOW", "PILOT", "HARVEST", "WATCH", "DO NOT USE", "UNRESOLVED"}
CAPABILITY_STATUSES = {"adopt_now", "pilot", "harvest", "watch"}
DECISION_TO_STATUS = {
    "ADOPT NOW": "adopt_now",
    "PILOT": "pilot",
    "HARVEST": "harvest",
    "WATCH": "watch",
}
CATALOGUE_HEADER = [
    "display_name",
    "canonical_repo_or_product",
    "url",
    "category",
    "provenance",
    "decision",
    "rationale",
    "license_or_terms",
    "lifecycle_note",
]

errors = []
warnings = []


def error(msg):
    errors.append(msg)


def warn(msg):
    warnings.append(msg)


def load_json(path):
    try:
        return json.loads(path.read_text())
    except json.JSONDecodeError as exc:
        error(f"{path}: invalid JSON ({exc})")
        return None


def check_required(path, record, required_fields):
    for field in required_fields:
        if field not in record:
            error(f"{path}: missing required field '{field}'")


def validate_catalogue():
    csv_path = ROOT / "catalog" / "repositories.csv"
    if not csv_path.exists():
        error(f"{csv_path}: missing")
        return {}

    rows_by_name = {}
    with csv_path.open(newline="") as f:
        reader = csv.DictReader(f)
        if reader.fieldnames != CATALOGUE_HEADER:
            error(f"{csv_path}: header {reader.fieldnames} does not match expected {CATALOGUE_HEADER}")
            return {}
        for i, row in enumerate(reader, start=2):
            required = [c for c in CATALOGUE_HEADER if c != "url"]
            for field in required:
                if not row.get(field, "").strip():
                    error(f"{csv_path}:{i}: empty required field '{field}'")
            decision = row.get("decision", "").strip()
            if decision not in CATALOGUE_DECISIONS:
                error(f"{csv_path}:{i}: decision '{decision}' not in {sorted(CATALOGUE_DECISIONS)}")
            for key in ("display_name", "canonical_repo_or_product"):
                name = row.get(key, "").strip()
                if name:
                    rows_by_name[name] = row
    return rows_by_name


def validate_capabilities(catalogue_by_name):
    caps_dir = ROOT / "catalog" / "capabilities"
    capabilities = {}
    if not caps_dir.exists():
        return capabilities

    required = ["id", "name", "summary", "category", "status", "source", "compatible_profiles", "added_date"]
    for path in sorted(caps_dir.glob("*.json")):
        record = load_json(path)
        if record is None:
            continue
        check_required(path, record, required)

        cap_id = record.get("id")
        if cap_id and path.stem != cap_id:
            error(f"{path}: filename does not match id '{cap_id}'")
        if cap_id and not ID_RE.match(cap_id):
            error(f"{path}: id '{cap_id}' is not kebab-case")

        status = record.get("status")
        if status is not None and status not in CAPABILITY_STATUSES:
            error(f"{path}: status '{status}' not in {sorted(CAPABILITY_STATUSES)}")

        added_date = record.get("added_date")
        if added_date is not None and not DATE_RE.match(added_date):
            error(f"{path}: added_date '{added_date}' is not YYYY-MM-DD")

        source = record.get("source")
        if isinstance(source, dict):
            for field in ("canonical_repo_or_product", "license_or_terms"):
                if not source.get(field):
                    error(f"{path}: source.{field} is required")
            source_name = source.get("canonical_repo_or_product")
            catalogue_row = catalogue_by_name.get(source_name)
            if source_name and catalogue_row is None:
                error(f"{path}: source '{source_name}' not found in catalog/repositories.csv")
            elif catalogue_row is not None and status is not None:
                expected_status = DECISION_TO_STATUS.get(catalogue_row["decision"])
                if expected_status is None:
                    error(
                        f"{path}: catalogue decision '{catalogue_row['decision']}' for "
                        f"'{source_name}' does not permit a capability record"
                    )
                elif expected_status != status:
                    error(
                        f"{path}: status '{status}' does not match catalogue decision "
                        f"'{catalogue_row['decision']}' (expected '{expected_status}')"
                    )
        elif source is not None:
            error(f"{path}: source must be an object")

        compatible = record.get("compatible_profiles")
        if compatible is not None and not (isinstance(compatible, list) and compatible):
            error(f"{path}: compatible_profiles must be a non-empty array")

        if cap_id:
            capabilities[cap_id] = record
    return capabilities


def validate_profiles(capabilities):
    profiles_dir = ROOT / "profiles"
    profiles = {}
    if not profiles_dir.exists():
        return profiles

    required = ["profile_id", "display_name", "description", "target_projects", "capabilities"]
    for path in sorted(profiles_dir.glob("*.json")):
        record = load_json(path)
        if record is None:
            continue
        check_required(path, record, required)

        profile_id = record.get("profile_id")
        if profile_id and path.stem != profile_id:
            error(f"{path}: filename does not match profile_id '{profile_id}'")
        if profile_id and not ID_RE.match(profile_id):
            error(f"{path}: profile_id '{profile_id}' is not kebab-case")

        target_projects = record.get("target_projects")
        if target_projects is not None and not (isinstance(target_projects, list) and target_projects):
            error(f"{path}: target_projects must be a non-empty array")

        cap_ids = record.get("capabilities")
        if cap_ids is not None:
            if not isinstance(cap_ids, list):
                error(f"{path}: capabilities must be an array")
            else:
                for cap_id in cap_ids:
                    cap = capabilities.get(cap_id)
                    if cap is None:
                        error(f"{path}: references unknown capability '{cap_id}'")
                    elif profile_id and profile_id not in cap.get("compatible_profiles", []):
                        error(
                            f"{path}: capability '{cap_id}' does not list profile "
                            f"'{profile_id}' in its compatible_profiles"
                        )

        if profile_id:
            profiles[profile_id] = record
    return profiles


def validate_receipts(profiles):
    receipts_dir = ROOT / "catalog" / "receipts"
    if not receipts_dir.exists():
        return

    required = ["receipt_id", "type", "date", "profile", "target_project", "validated"]
    for path in sorted(receipts_dir.glob("*.json")):
        record = load_json(path)
        if record is None:
            continue
        check_required(path, record, required)

        receipt_id = record.get("receipt_id")
        if receipt_id and path.stem != receipt_id:
            error(f"{path}: filename does not match receipt_id '{receipt_id}'")

        rtype = record.get("type")
        if rtype is not None and rtype not in {"sync", "release"}:
            error(f"{path}: type '{rtype}' not in ('sync', 'release')")

        date = record.get("date")
        if date is not None and not DATE_RE.match(date):
            error(f"{path}: date '{date}' is not YYYY-MM-DD")

        profile = record.get("profile")
        if profile is not None and profile not in profiles:
            error(f"{path}: references unknown profile '{profile}'")

        validated = record.get("validated")
        if validated is not None and not isinstance(validated, bool):
            error(f"{path}: validated must be a boolean")


def main():
    catalogue_by_name = validate_catalogue()
    capabilities = validate_capabilities(catalogue_by_name)
    profiles = validate_profiles(capabilities)
    validate_receipts(profiles)

    print(f"Checked: 1 catalogue, {len(capabilities)} capabilities, {len(profiles)} profiles.")
    for w in warnings:
        print(f"WARNING: {w}")
    if errors:
        print(f"\n{len(errors)} error(s):")
        for e in errors:
            print(f"  - {e}")
        return 1
    print("OK: all records valid.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
