#!/usr/bin/env python3
"""Free, local, dependency-free regressions for scripts/validate.py's
skill-promotion checks (validate_skill_promotions / _validate_skill_entrypoint).

Each case builds an isolated temp directory containing a single
skills/<id>/promotion.json (plus whatever entrypoint file it declares),
points scripts/validate.py's module-level ROOT at it, and asserts on the
resulting validate.errors list. No network access, no third-party packages.

Run directly: python3 tests/skill-promotion-validate.py
"""

import importlib.util
import json
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

spec = importlib.util.spec_from_file_location("validate", ROOT / "scripts" / "validate.py")
validate = importlib.util.module_from_spec(spec)
spec.loader.exec_module(validate)

failures = []


def run_case(name, skill_id="sample-skill", entrypoint="check.sh", write_entrypoint=True,
             instruction_only=None, declared_tools=None, expect_error_substr=None):
    with tempfile.TemporaryDirectory() as tmp:
        case_root = Path(tmp)
        skill_dir = case_root / "skills" / "sample-skill"
        skill_dir.mkdir(parents=True)
        (skill_dir / "SKILL.md").write_text(
            "---\nname: sample-skill\ndescription: test fixture\n---\n\n# Sample\n"
        )

        manifest = {
            "id": skill_id,
            "provenance": {"origin": "agent-stack-local", "license": "MIT"},
            "declared_tools": declared_tools if declared_tools is not None else ["Bash"],
            "untrusted_content_handling": True,
            "trigger_keywords": ["x"],
            "positive_examples": ["x"],
            "negative_examples": ["y"],
            "rollback": {"method": "remove the skill", "date_recorded": "2026-07-18"},
        }
        if instruction_only is not None:
            manifest["instruction_only"] = instruction_only
        if entrypoint is not None:
            manifest["entrypoint"] = entrypoint
        (skill_dir / "promotion.json").write_text(json.dumps(manifest))

        if write_entrypoint and entrypoint and not entrypoint.startswith("/") and ".." not in entrypoint:
            (skill_dir / entrypoint).write_text("#!/usr/bin/env bash\necho ok\n")

        validate.ROOT = case_root
        validate.errors = []
        validate.warnings = []
        try:
            validate.validate_skill_promotions()
        except Exception as exc:  # a malformed manifest must produce an error, never a crash
            failures.append(f"{name}: raised {type(exc).__name__}: {exc} instead of a validation error")
            return
        errs = list(validate.errors)

    if expect_error_substr is None:
        if errs:
            failures.append(f"{name}: expected no errors, got {errs}")
            return
        print(f"PASS: {name} (no errors, as expected)")
        return

    if not any(expect_error_substr in e for e in errs):
        failures.append(f"{name}: expected an error containing '{expect_error_substr}', got {errs}")
        return
    print(f"PASS: {name} (rejected: {expect_error_substr!r} found)")


run_case("compliant manifest passes cleanly")
run_case(
    "id mismatch with containing directory is rejected",
    skill_id="not-sample-skill",
    expect_error_substr="does not match containing directory",
)
run_case(
    "scalar (non-string) id is rejected without a traceback",
    skill_id=1,
    expect_error_substr="id must be a string",
)
run_case(
    "non-array declared_tools is rejected without a traceback",
    declared_tools="Bash",
    expect_error_substr="declared_tools must be a non-empty array of strings",
)
run_case(
    "absolute entrypoint path is rejected",
    entrypoint="/etc/passwd",
    write_entrypoint=False,
    expect_error_substr="must be a relative path, not absolute",
)
run_case(
    "'..' traversal in entrypoint path is rejected",
    entrypoint="../../etc/passwd",
    write_entrypoint=False,
    expect_error_substr="must not traverse outside the skill directory",
)
run_case(
    "instruction_only:true with an entrypoint set is rejected",
    entrypoint="check.sh",
    instruction_only=True,
    expect_error_substr="a skill is either instruction-only or has one entrypoint, not both",
)
run_case(
    "instruction_only:true with no entrypoint passes cleanly",
    entrypoint=None,
    instruction_only=True,
)
run_case(
    "missing entrypoint when not instruction-only is rejected",
    entrypoint=None,
    expect_error_substr="entrypoint is required unless instruction_only is true",
)
run_case(
    "entrypoint declared but not present on disk is rejected",
    entrypoint="check.sh",
    write_entrypoint=False,
    expect_error_substr="does not exist in skills/",
)


def run_symlink_escape_case():
    name = "entrypoint symlinked outside the skill directory is rejected"
    with tempfile.TemporaryDirectory() as tmp:
        case_root = Path(tmp)
        skill_dir = case_root / "skills" / "sample-skill"
        skill_dir.mkdir(parents=True)
        (skill_dir / "SKILL.md").write_text(
            "---\nname: sample-skill\ndescription: test fixture\n---\n\n# Sample\n"
        )
        outside = case_root / "outside.sh"
        outside.write_text("#!/usr/bin/env bash\necho outside\n")
        (skill_dir / "escape.sh").symlink_to(outside)

        manifest = {
            "id": "sample-skill",
            "provenance": {"origin": "agent-stack-local", "license": "MIT"},
            "declared_tools": ["Bash"],
            "untrusted_content_handling": True,
            "trigger_keywords": ["x"],
            "positive_examples": ["x"],
            "negative_examples": ["y"],
            "entrypoint": "escape.sh",
            "rollback": {"method": "remove the skill", "date_recorded": "2026-07-18"},
        }
        (skill_dir / "promotion.json").write_text(json.dumps(manifest))

        validate.ROOT = case_root
        validate.errors = []
        validate.warnings = []
        validate.validate_skill_promotions()
        errs = list(validate.errors)

    if not any("symlink escape" in e for e in errs):
        failures.append(f"{name}: expected a symlink-escape error, got {errs}")
        return
    print(f"PASS: {name}")


run_symlink_escape_case()

print()
if failures:
    print(f"RESULT: {len(failures)} skill-promotion validation regression(s) FAILED:")
    for f in failures:
        print(f"  - {f}")
    sys.exit(1)
print("RESULT: all skill-promotion validation regressions passed.")
