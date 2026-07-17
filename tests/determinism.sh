#!/usr/bin/env bash
# Proves that syncing the same synthetic fixture profile twice, into two
# independent output roots, produces byte-identical exports and receipts.
# Exercises dry-run, apply, and doctor for both adapters.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

WORK_DIR="$(mktemp -d)"
trap 'rm -rf "${WORK_DIR}"' EXIT

FIXTURE_SKILLS="${SCRIPT_DIR}/fixtures/skills"
FIXTURE_PROFILES="${SCRIPT_DIR}/fixtures/profiles"
FIXED_TIMESTAMP="2026-01-01T00:00:00.000Z"

OUT_A="${WORK_DIR}/run-a"
OUT_B="${WORK_DIR}/run-b"

run_sync() {
  local out_root="$1"
  node "${REPO_ROOT}/scripts/sync.mjs" \
    --profile demo \
    --mode apply \
    --skills-dir "${FIXTURE_SKILLS}" \
    --profiles-dir "${FIXTURE_PROFILES}" \
    --out-root "${out_root}" \
    --release "fixture-0.0.0" \
    --timestamp "${FIXED_TIMESTAMP}" \
    > "${out_root}.sync.log"
}

echo "== dry-run (must not write any files) =="
DRY_OUT="${WORK_DIR}/dry-run-untouched"
node "${REPO_ROOT}/scripts/sync.mjs" \
  --profile demo \
  --mode dry-run \
  --skills-dir "${FIXTURE_SKILLS}" \
  --profiles-dir "${FIXTURE_PROFILES}" \
  --out-root "${DRY_OUT}" \
  --release "fixture-0.0.0" \
  --timestamp "${FIXED_TIMESTAMP}"
if [ -e "${DRY_OUT}" ]; then
  echo "FAIL: dry-run wrote to ${DRY_OUT}"
  exit 1
fi
echo "OK: dry-run made no filesystem changes"
echo

echo "== apply run A =="
mkdir -p "${OUT_A}"
run_sync "${OUT_A}"

echo "== apply run B (independent output root, same input) =="
mkdir -p "${OUT_B}"
run_sync "${OUT_B}"

echo
echo "== comparing exported trees =="
if diff -r "${OUT_A}/.agents/skills" "${OUT_B}/.agents/skills" > /dev/null; then
  echo "OK: .agents/skills identical across runs"
else
  echo "FAIL: .agents/skills differs across runs"
  diff -r "${OUT_A}/.agents/skills" "${OUT_B}/.agents/skills" || true
  exit 1
fi

if diff -r "${OUT_A}/.claude/skills" "${OUT_B}/.claude/skills" > /dev/null; then
  echo "OK: .claude/skills identical across runs"
else
  echo "FAIL: .claude/skills differs across runs"
  diff -r "${OUT_A}/.claude/skills" "${OUT_B}/.claude/skills" || true
  exit 1
fi

echo
echo "== comparing receipts byte-for-byte =="
if diff "${OUT_A}/.agents/skills/sync-receipt.json" "${OUT_B}/.agents/skills/sync-receipt.json" > /dev/null; then
  echo "OK: codex receipt identical across runs"
else
  echo "FAIL: codex receipt differs across runs"
  exit 1
fi

if diff "${OUT_A}/.claude/skills/sync-receipt.json" "${OUT_B}/.claude/skills/sync-receipt.json" > /dev/null; then
  echo "OK: claude-code receipt identical across runs"
else
  echo "FAIL: claude-code receipt differs across runs"
  exit 1
fi

echo
echo "== receipt contains required fields =="
node -e '
  const r = JSON.parse(require("fs").readFileSync(process.argv[1], "utf8"));
  const required = ["profile", "sourceRelease", "generatedAt", "skills", "receiptChecksum", "adapter"];
  const missing = required.filter((k) => !(k in r));
  if (missing.length) {
    console.error("FAIL: receipt missing fields: " + missing.join(", "));
    process.exit(1);
  }
  if (!r.skills.every((s) => s.id && s.skillChecksum && Array.isArray(s.files))) {
    console.error("FAIL: receipt skills entries incomplete");
    process.exit(1);
  }
  console.log("OK: receipt has profile, sourceRelease, generatedAt, skills[], receiptChecksum");
' "${OUT_A}/.agents/skills/sync-receipt.json"

echo
echo "== doctor verification (should pass) =="
node "${REPO_ROOT}/scripts/doctor.mjs" --out-root "${OUT_A}"

echo
echo "== doctor detects tampering (should fail) =="
echo "tampered" >> "${OUT_A}/.agents/skills/hello-world/SKILL.md"
if node "${REPO_ROOT}/scripts/doctor.mjs" --out-root "${OUT_A}" --adapters codex > "${WORK_DIR}/doctor-tamper.log"; then
  echo "FAIL: doctor did not detect tampering"
  cat "${WORK_DIR}/doctor-tamper.log"
  exit 1
else
  echo "OK: doctor detected tampering (non-zero exit)"
fi

echo
echo "== doctor detects stale/unmanaged entries (should fail) =="
mkdir -p "${OUT_A}/.claude/skills/rogue-skill"
echo "not managed" > "${OUT_A}/.claude/skills/rogue-skill/SKILL.md"
if node "${REPO_ROOT}/scripts/doctor.mjs" --out-root "${OUT_A}" --adapters claude-code > "${WORK_DIR}/doctor-stale.log"; then
  echo "FAIL: doctor did not detect the unmanaged skill directory"
  cat "${WORK_DIR}/doctor-stale.log"
  exit 1
else
  echo "OK: doctor detected the unmanaged skill directory (non-zero exit)"
fi

echo
echo "== profile change removes stale exports (regression) =="
OUT_C="${WORK_DIR}/run-c"
mkdir -p "${OUT_C}"

# Apply a profile with an extra skill first...
node "${REPO_ROOT}/scripts/sync.mjs" \
  --profile with-extra \
  --mode apply \
  --skills-dir "${FIXTURE_SKILLS}" \
  --profiles-dir "${FIXTURE_PROFILES}" \
  --out-root "${OUT_C}" \
  --release "fixture-0.0.0" \
  --timestamp "${FIXED_TIMESTAMP}" \
  > "${OUT_C}.with-extra.sync.log"

if [ ! -d "${OUT_C}/.agents/skills/legacy-only" ] || [ ! -d "${OUT_C}/.claude/skills/legacy-only" ]; then
  echo "FAIL: setup for regression test did not export legacy-only as expected"
  exit 1
fi

# ...then apply the normal profile that no longer selects that skill.
node "${REPO_ROOT}/scripts/sync.mjs" \
  --profile demo \
  --mode apply \
  --skills-dir "${FIXTURE_SKILLS}" \
  --profiles-dir "${FIXTURE_PROFILES}" \
  --out-root "${OUT_C}" \
  --release "fixture-0.0.0" \
  --timestamp "${FIXED_TIMESTAMP}" \
  > "${OUT_C}.demo.sync.log"

if [ -e "${OUT_C}/.agents/skills/legacy-only" ] || [ -e "${OUT_C}/.claude/skills/legacy-only" ]; then
  echo "FAIL: legacy-only skill from prior profile survived the profile change"
  exit 1
fi
echo "OK: prior-profile-only skill (legacy-only) removed after switching to demo"

if diff -r "${OUT_C}/.agents/skills" "${OUT_B}/.agents/skills" > /dev/null; then
  echo "OK: .agents/skills after profile change matches a clean demo-only export"
else
  echo "FAIL: .agents/skills after profile change does not match a clean demo-only export"
  diff -r "${OUT_C}/.agents/skills" "${OUT_B}/.agents/skills" || true
  exit 1
fi

node "${REPO_ROOT}/scripts/doctor.mjs" --out-root "${OUT_C}"
echo "OK: doctor passes after profile change"

echo
echo "ALL CHECKS PASSED"
