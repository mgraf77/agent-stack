#!/usr/bin/env bash
# Proves that syncing the same synthetic fixture profile twice, into two
# independent output roots, produces byte-identical exports and receipts.
# Exercises dry-run, apply, and doctor for both adapters; the shared
# profile/skills profile contract (required "profile" identifier field
# and duplicate-skill-id rejection); the no-symlink rule; and that
# switching profiles removes skills the new profile no longer selects.
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

echo "== \"profile\" is the canonical, required identifier field =="
node "${REPO_ROOT}/scripts/sync.mjs" \
  --profile demo \
  --mode dry-run \
  --skills-dir "${FIXTURE_SKILLS}" \
  --profiles-dir "${FIXTURE_PROFILES}" \
  --out-root "${WORK_DIR}/profile-field-check" \
  --release "fixture-0.0.0" \
  --timestamp "${FIXED_TIMESTAMP}" \
  | node -e '
    const plan = JSON.parse(require("fs").readFileSync(0, "utf8"));
    if (plan.profile !== "demo") {
      console.error(`FAIL: expected plan.profile "demo", got "${plan.profile}"`);
      process.exit(1);
    }
    console.log("OK: \"profile\" (\"demo\") read as the plan/receipt profile identifier");
  '

echo
echo "== profile missing the required \"profile\" field is rejected =="
if node "${REPO_ROOT}/scripts/sync.mjs" \
  --profile missing-identifier \
  --mode dry-run \
  --skills-dir "${FIXTURE_SKILLS}" \
  --profiles-dir "${FIXTURE_PROFILES}" \
  --out-root "${WORK_DIR}/missing-identifier-check" \
  > "${WORK_DIR}/missing-identifier.log" 2>&1; then
  echo "FAIL: sync.mjs accepted a profile with no \"profile\" field"
  cat "${WORK_DIR}/missing-identifier.log"
  exit 1
fi
if ! grep -q 'must declare "profile"' "${WORK_DIR}/missing-identifier.log"; then
  echo "FAIL: error message did not clearly explain the missing identifier"
  cat "${WORK_DIR}/missing-identifier.log"
  exit 1
fi
echo "OK: profile with no \"profile\" field rejected with a clear error"

echo
echo "== duplicate skill ids are rejected =="
if node "${REPO_ROOT}/scripts/sync.mjs" \
  --profile duplicate-skill \
  --mode dry-run \
  --skills-dir "${FIXTURE_SKILLS}" \
  --profiles-dir "${FIXTURE_PROFILES}" \
  --out-root "${WORK_DIR}/duplicate-skill-check" \
  > "${WORK_DIR}/duplicate-skill.log" 2>&1; then
  echo "FAIL: sync.mjs accepted a profile with duplicate skill ids"
  cat "${WORK_DIR}/duplicate-skill.log"
  exit 1
fi
if ! grep -q 'duplicate skill id' "${WORK_DIR}/duplicate-skill.log"; then
  echo "FAIL: error message did not clearly explain the duplicate skill id"
  cat "${WORK_DIR}/duplicate-skill.log"
  exit 1
fi
echo "OK: profile with duplicate skill ids rejected with a clear error"

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
echo "== apply refuses a symlinked adapter target directory =="
SYMLINK_OUT="${WORK_DIR}/symlink-target"
SYMLINK_REAL_ELSEWHERE="${WORK_DIR}/symlink-real-elsewhere"
mkdir -p "${SYMLINK_OUT}/.agents" "${SYMLINK_REAL_ELSEWHERE}"
ln -s "${SYMLINK_REAL_ELSEWHERE}" "${SYMLINK_OUT}/.agents/skills"
if node "${REPO_ROOT}/scripts/sync.mjs" \
  --profile demo \
  --mode apply \
  --skills-dir "${FIXTURE_SKILLS}" \
  --profiles-dir "${FIXTURE_PROFILES}" \
  --out-root "${SYMLINK_OUT}" \
  --release "fixture-0.0.0" \
  --timestamp "${FIXED_TIMESTAMP}" \
  --adapters codex \
  > "${WORK_DIR}/symlink-apply.log" 2>&1; then
  echo "FAIL: apply wrote through a symlinked target directory"
  cat "${WORK_DIR}/symlink-apply.log"
  exit 1
fi
if ! grep -q "Refusing to use symlinked directory" "${WORK_DIR}/symlink-apply.log"; then
  echo "FAIL: error message did not clearly explain the symlinked target directory"
  cat "${WORK_DIR}/symlink-apply.log"
  exit 1
fi
if [ -n "$(ls -A "${SYMLINK_REAL_ELSEWHERE}")" ]; then
  echo "FAIL: apply wrote into the symlink's real target"
  exit 1
fi
echo "OK: apply refused the symlinked target directory and left its real target untouched"

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
echo "== injected mid-export failure leaves the prior valid export intact and doctor-clean =="
OUT_D="${WORK_DIR}/run-d"
mkdir -p "${OUT_D}"

# Establish a known-good baseline export.
run_sync "${OUT_D}"
node "${REPO_ROOT}/scripts/doctor.mjs" --out-root "${OUT_D}" > /dev/null
BASELINE_RECEIPT_CODEX="$(cat "${OUT_D}/.agents/skills/sync-receipt.json")"
BASELINE_RECEIPT_CLAUDE="$(cat "${OUT_D}/.claude/skills/sync-receipt.json")"

# Re-apply the same profile but inject a failure partway through staging
# the codex export (after "demo-tool" is staged, before the receipt is
# written or the swap happens). This simulates the crash/disk failure the
# old replace-then-copy sequence was vulnerable to.
if AGENT_STACK_SYNC_TEST_FAIL_AFTER_SKILL="codex:demo-tool" node "${REPO_ROOT}/scripts/sync.mjs" \
  --profile demo \
  --mode apply \
  --skills-dir "${FIXTURE_SKILLS}" \
  --profiles-dir "${FIXTURE_PROFILES}" \
  --out-root "${OUT_D}" \
  --release "fixture-0.0.0" \
  --timestamp "${FIXED_TIMESTAMP}" \
  > "${WORK_DIR}/mid-export-failure.log" 2>&1; then
  echo "FAIL: sync.mjs did not fail despite the injected mid-export failure"
  cat "${WORK_DIR}/mid-export-failure.log"
  exit 1
fi
if ! grep -q "Injected test failure after staging skill" "${WORK_DIR}/mid-export-failure.log"; then
  echo "FAIL: injected failure did not fire as expected"
  cat "${WORK_DIR}/mid-export-failure.log"
  exit 1
fi
echo "OK: injected failure fired partway through staging the codex export"

if [ ! -d "${OUT_D}/.agents/skills.sync-staging" ]; then
  echo "FAIL: expected the aborted build's staging directory to be left behind for inspection"
  exit 1
fi
echo "OK: aborted build's staging directory was left behind (targetDir itself was never touched)"

if [ "$(cat "${OUT_D}/.agents/skills/sync-receipt.json")" != "${BASELINE_RECEIPT_CODEX}" ] || \
   [ "$(cat "${OUT_D}/.claude/skills/sync-receipt.json")" != "${BASELINE_RECEIPT_CLAUDE}" ]; then
  echo "FAIL: prior valid export's receipts changed after the injected mid-export failure"
  exit 1
fi
echo "OK: prior valid export's receipts are unchanged"

node "${REPO_ROOT}/scripts/doctor.mjs" --out-root "${OUT_D}"
echo "OK: doctor is clean immediately after the injected mid-export failure"

echo
echo "== a swap interrupted between its two renames is recovered on the next apply =="
OUT_E="${WORK_DIR}/run-e"
mkdir -p "${OUT_E}"
run_sync "${OUT_E}"
node "${REPO_ROOT}/scripts/doctor.mjs" --out-root "${OUT_E}" > /dev/null

# Fabricate the on-disk state a crash between atomicReplaceDirectory's two
# renames would leave: the live export already moved aside to its backup
# path, and a staging directory (here, an incomplete stand-in) left behind
# from the build that was in flight.
mv "${OUT_E}/.agents/skills" "${OUT_E}/.agents/skills.sync-backup"
mkdir -p "${OUT_E}/.agents/skills.sync-staging"

if node "${REPO_ROOT}/scripts/doctor.mjs" --out-root "${OUT_E}" --adapters codex > "${WORK_DIR}/interrupted-doctor.log"; then
  echo "FAIL: doctor did not notice the interrupted swap (target directory missing)"
  cat "${WORK_DIR}/interrupted-doctor.log"
  exit 1
fi
echo "OK: doctor detects the interrupted-swap state (target directory missing)"

run_sync "${OUT_E}"

if [ -e "${OUT_E}/.agents/skills.sync-backup" ] || [ -e "${OUT_E}/.agents/skills.sync-staging" ]; then
  echo "FAIL: leftover staging/backup directory survived recovery"
  exit 1
fi
echo "OK: leftover staging/backup directories were cleaned up by the next apply"

node "${REPO_ROOT}/scripts/doctor.mjs" --out-root "${OUT_E}"

if diff -r "${OUT_E}/.agents/skills" "${OUT_B}/.agents/skills" > /dev/null; then
  echo "OK: recovered export matches a clean demo export byte-for-byte"
else
  echo "FAIL: recovered export does not match a clean demo export"
  diff -r "${OUT_E}/.agents/skills" "${OUT_B}/.agents/skills" || true
  exit 1
fi
echo "OK: interrupted swap recovered automatically on the next apply, doctor-clean"

echo
echo "ALL CHECKS PASSED"
