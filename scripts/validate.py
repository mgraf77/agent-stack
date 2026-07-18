#!/usr/bin/env python3
"""Free, local, dependency-free validator for the Agent Stack foundation.

Checks:
  - catalog/repositories.csv matches the expected header and enum.
  - catalog/capabilities/*.json match schemas/capability-record.schema.json
    and stay consistent with catalog/repositories.csv.
  - profiles/*.json match schemas/project-profile.schema.json: 'skills'
    (the exact array scripts/sync.mjs exports) has no duplicates and only
    kebab-case ids, resolving against skills/ on disk when that directory
    exists; 'capabilities' only reference known capability records that
    list this profile back.
  - catalog/receipts/*.json match schemas/sync-release-receipt.schema.json,
    reference a profile that exists, and have their skillChecksum /
    receiptChecksum values recomputed and compared byte-for-byte against
    the same algorithm scripts/lib/checksum.mjs uses (sha256 over an
    ordered list of "label:hex" pairs), to catch drift or hand-edits
    without needing Node.
  - skills/*/promotion.json (a real skill's promotion manifest, see
    schemas/skill-promotion-manifest.schema.json) has the required fields,
    an 'id' matching its containing skills/<id>/ directory, and — unless
    instruction_only is true — a declared entrypoint that is a plain
    relative path inside that same skill directory (no absolute path, no
    '..' traversal, no symlink escape) pointing at a file that exists.

No network access, no third-party packages, no API keys.
"""

import csv
import hashlib
import json
import os
import re
import sys
from pathlib import Path

ROOT = Path(os.environ.get("AGENT_STACK_VALIDATE_ROOT", Path(__file__).resolve().parent.parent))

DATE_RE = re.compile(r"^\d{4}-\d{2}-\d{2}$")
ID_RE = re.compile(r"^[a-z0-9]+(-[a-z0-9]+)*$")
SHA256_RE = re.compile(r"^[0-9a-f]{64}$")
TIMESTAMP_RE = re.compile(r"^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d+)?Z$")

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


def sha256_hex(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def sha256_of_pairs(pairs):
    # Mirrors scripts/lib/checksum.mjs's sha256OfPairs exactly: sha256 of
    # "label:hex" lines joined with "\n", independent of object key order.
    canonical = "\n".join(f"{label}:{hexval}" for label, hexval in pairs)
    return sha256_hex(canonical.encode("utf-8"))


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
    skills_dir = ROOT / "skills"
    skills_dir_present = skills_dir.is_dir()
    profiles = {}
    if not profiles_dir.exists():
        return profiles

    required = ["profile", "display_name", "description", "target_projects", "skills"]
    for path in sorted(profiles_dir.glob("*.json")):
        record = load_json(path)
        if record is None:
            continue
        check_required(path, record, required)

        profile_id = record.get("profile")
        if profile_id and path.stem != profile_id:
            error(f"{path}: filename does not match profile '{profile_id}'")
        if profile_id and not ID_RE.match(profile_id):
            error(f"{path}: profile '{profile_id}' is not kebab-case")

        target_projects = record.get("target_projects")
        if target_projects is not None and not (isinstance(target_projects, list) and target_projects):
            error(f"{path}: target_projects must be a non-empty array")

        skill_ids = record.get("skills")
        if skill_ids is not None:
            if not (isinstance(skill_ids, list) and skill_ids):
                error(f"{path}: skills must be a non-empty array")
            else:
                seen = set()
                for skill_id in skill_ids:
                    if not isinstance(skill_id, str) or not ID_RE.match(skill_id):
                        error(f"{path}: invalid skill id '{skill_id}' (must be kebab-case)")
                        continue
                    if skill_id in seen:
                        error(f"{path}: duplicate skill id '{skill_id}'")
                        continue
                    seen.add(skill_id)
                    if skills_dir_present and not (skills_dir / skill_id / "SKILL.md").is_file():
                        error(f"{path}: skill '{skill_id}' has no skills/{skill_id}/SKILL.md")
                if not skills_dir_present:
                    warn(f"{path}: skills/ not present in this checkout; skill ids checked for format/duplicates only")

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


def _validate_skill_entrypoint(path, skill_dir, entrypoint):
    """Returns an error string, or None if entrypoint is a safe relative
    path inside skill_dir that exists and doesn't escape via a symlink."""
    if entrypoint.startswith("/") or Path(entrypoint).is_absolute():
        return f"{path}: entrypoint '{entrypoint}' must be a relative path, not absolute"
    if ".." in Path(entrypoint).parts:
        return f"{path}: entrypoint '{entrypoint}' must not traverse outside the skill directory"

    candidate = skill_dir / entrypoint
    if not candidate.is_file():
        return f"{path}: entrypoint '{entrypoint}' does not exist in skills/{skill_dir.name}/"

    try:
        resolved_skill_dir = skill_dir.resolve(strict=True)
        resolved_entry = candidate.resolve(strict=True)
    except OSError as exc:
        return f"{path}: entrypoint '{entrypoint}' could not be resolved ({exc})"

    try:
        resolved_entry.relative_to(resolved_skill_dir)
    except ValueError:
        return f"{path}: entrypoint '{entrypoint}' resolves outside skills/{skill_dir.name}/ (symlink escape?)"
    return None


def validate_skill_promotions():
    skills_dir = ROOT / "skills"
    manifests = {}
    if not skills_dir.is_dir():
        return manifests

    required = [
        "id",
        "provenance",
        "declared_tools",
        "untrusted_content_handling",
        "trigger_keywords",
        "positive_examples",
        "negative_examples",
        "rollback",
    ]
    for skill_dir in sorted(p for p in skills_dir.iterdir() if p.is_dir()):
        path = skill_dir / "promotion.json"
        if not path.is_file():
            continue
        record = load_json(path)
        if record is None:
            continue
        check_required(path, record, required)

        skill_id = record.get("id")
        if skill_id is not None and not isinstance(skill_id, str):
            error(f"{path}: id must be a string")
            skill_id = None
        elif isinstance(skill_id, str) and not skill_id:
            error(f"{path}: id must not be empty")
            skill_id = None
        if isinstance(skill_id, str) and skill_id:
            if skill_id != skill_dir.name:
                error(f"{path}: id '{skill_id}' does not match containing directory 'skills/{skill_dir.name}'")
            if not ID_RE.match(skill_id):
                error(f"{path}: id '{skill_id}' is not kebab-case")

        provenance = record.get("provenance")
        if isinstance(provenance, dict):
            for field in ("origin", "license"):
                value = provenance.get(field)
                if not (isinstance(value, str) and value):
                    error(f"{path}: provenance.{field} must be a non-empty string")
        elif provenance is not None:
            error(f"{path}: provenance must be an object")

        for field in ("declared_tools", "trigger_keywords", "positive_examples", "negative_examples"):
            value = record.get(field)
            if value is not None and not (
                isinstance(value, list) and value and all(isinstance(v, str) and v for v in value)
            ):
                error(f"{path}: {field} must be a non-empty array of non-empty strings")

        untrusted = record.get("untrusted_content_handling")
        if untrusted is not None and not isinstance(untrusted, bool):
            error(f"{path}: untrusted_content_handling must be a boolean")

        instruction_only = record.get("instruction_only", False)
        if not isinstance(instruction_only, bool):
            error(f"{path}: instruction_only must be a boolean")
            instruction_only = False

        entrypoint = record.get("entrypoint")
        if instruction_only:
            if entrypoint is not None:
                error(
                    f"{path}: instruction_only is true but entrypoint is also set "
                    "(a skill is either instruction-only or has one entrypoint, not both)"
                )
        elif not entrypoint or not isinstance(entrypoint, str):
            error(f"{path}: entrypoint is required unless instruction_only is true")
        else:
            entry_error = _validate_skill_entrypoint(path, skill_dir, entrypoint)
            if entry_error:
                error(entry_error)

        rollback = record.get("rollback")
        if isinstance(rollback, dict):
            for field in ("method", "date_recorded"):
                value = rollback.get(field)
                if not (isinstance(value, str) and value):
                    error(f"{path}: rollback.{field} must be a non-empty string")
            date_recorded = rollback.get("date_recorded")
            if isinstance(date_recorded, str) and date_recorded and not DATE_RE.match(date_recorded):
                error(f"{path}: rollback.date_recorded '{date_recorded}' is not YYYY-MM-DD")
        elif rollback is not None:
            error(f"{path}: rollback must be an object")

        if skill_id:
            manifests[skill_id] = record
    return manifests


def validate_receipts(profiles):
    receipts_dir = ROOT / "catalog" / "receipts"
    if not receipts_dir.exists():
        return

    required = ["receiptVersion", "profile", "sourceRelease", "adapter", "generatedAt", "skills", "receiptChecksum"]
    for path in sorted(receipts_dir.glob("*.json")):
        record = load_json(path)
        if record is None:
            continue
        check_required(path, record, required)

        profile = record.get("profile")
        if profile is not None and profile not in profiles:
            error(f"{path}: references unknown profile '{profile}'")

        generated_at = record.get("generatedAt")
        if generated_at is not None and not TIMESTAMP_RE.match(generated_at):
            error(f"{path}: generatedAt '{generated_at}' is not an ISO-8601 UTC timestamp")

        adapter = record.get("adapter")
        adapter_id = None
        if isinstance(adapter, dict):
            for field in ("id", "targetDir"):
                if not adapter.get(field):
                    error(f"{path}: adapter.{field} is required")
            adapter_id = adapter.get("id")
        elif adapter is not None:
            error(f"{path}: adapter must be an object")

        skills = record.get("skills")
        skill_checksum_pairs = []
        if isinstance(skills, list):
            for skill in skills:
                if not isinstance(skill, dict):
                    error(f"{path}: each skills[] entry must be an object")
                    continue
                skill_id = skill.get("id")
                files = skill.get("files")
                claimed_skill_checksum = skill.get("skillChecksum")
                if not skill_id or not isinstance(files, list) or not claimed_skill_checksum:
                    error(f"{path}: skill entry missing id/files/skillChecksum")
                    continue
                file_pairs = []
                for f in files:
                    if not isinstance(f, dict) or not f.get("path") or not f.get("sha256"):
                        error(f"{path}: skill '{skill_id}' has a malformed files[] entry")
                        continue
                    if not SHA256_RE.match(f["sha256"]):
                        error(f"{path}: skill '{skill_id}' file '{f.get('path')}' sha256 is not 64 lowercase hex chars")
                        continue
                    file_pairs.append((f["path"], f["sha256"]))
                if not SHA256_RE.match(claimed_skill_checksum):
                    error(f"{path}: skill '{skill_id}' skillChecksum is not 64 lowercase hex chars")
                    continue
                expected_skill_checksum = sha256_of_pairs(file_pairs)
                if expected_skill_checksum != claimed_skill_checksum:
                    error(
                        f"{path}: skill '{skill_id}' skillChecksum mismatch "
                        f"(recorded {claimed_skill_checksum}, recomputed {expected_skill_checksum})"
                    )
                skill_checksum_pairs.append((f"skill:{skill_id}", claimed_skill_checksum))
        elif skills is not None:
            error(f"{path}: skills must be an array")

        claimed_receipt_checksum = record.get("receiptChecksum")
        if profile is not None and adapter_id is not None and skill_checksum_pairs and claimed_receipt_checksum:
            expected_receipt_checksum = sha256_of_pairs(
                [
                    ("profile", profile),
                    ("sourceRelease", record.get("sourceRelease", "")),
                    ("adapter", adapter_id),
                    *skill_checksum_pairs,
                ]
            )
            if not SHA256_RE.match(claimed_receipt_checksum):
                error(f"{path}: receiptChecksum is not 64 lowercase hex chars")
            elif expected_receipt_checksum != claimed_receipt_checksum:
                error(
                    f"{path}: receiptChecksum mismatch "
                    f"(recorded {claimed_receipt_checksum}, recomputed {expected_receipt_checksum}) "
                    "— receipt may be corrupted or hand-edited"
                )


def main():
    catalogue_by_name = validate_catalogue()
    capabilities = validate_capabilities(catalogue_by_name)
    profiles = validate_profiles(capabilities)
    validate_receipts(profiles)
    skill_manifests = validate_skill_promotions()

    print(
        f"Checked: 1 catalogue, {len(capabilities)} capabilities, {len(profiles)} profiles, "
        f"{len(skill_manifests)} skill promotion manifest(s)."
    )
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
