#!/usr/bin/env node
// Deterministic profile sync: compiles a selected profile's skills from the
// canonical skills/<name>/SKILL.md source of truth into each adapter's local
// target directory (.agents/skills for Codex, .claude/skills for Claude Code),
// and writes a receipt/lockfile recording what was exported and why.
//
// Apply is transactional: each adapter's export is built and verified in a
// sibling staging directory (see lib/fsutil.mjs) and only then atomically
// swapped into place, so a crash or disk failure at any point leaves the
// prior valid export intact. If the process dies mid-swap, the next apply
// (or a manual `sync --mode apply` re-run) recovers automatically.
//
// Profile contract (shared with schemas/project-profile.schema.json):
// "profile" is the required, canonical identifier field. The skill export
// list is "skills": an array of skill ids, each resolved under
// --skills-dir. Duplicate skill ids are rejected.
//
// Usage:
//   node scripts/sync.mjs --profile <name-or-path> --mode dry-run|apply [options]
//
// Options:
//   --profile        Profile name (resolved under --profiles-dir) or a path to a profile JSON file. Required.
//   --mode           "dry-run" (default) prints the plan only; "apply" writes files + receipts.
//   --skills-dir     Canonical skills root. Default: <repo>/skills
//   --profiles-dir   Profiles root. Default: <repo>/profiles
//   --adapters-dir   Adapters root. Default: <repo>/adapters
//   --out-root       Root that adapter targetDir paths are resolved against. Default: repo root.
//   --release        Source release/version placeholder recorded in the receipt. Default: "unreleased".
//   --timestamp      ISO-8601 timestamp to record in the receipt. Default: current time.
//                     Pass a fixed value to get byte-identical receipts across runs (used by the
//                     determinism fixture).
//   --adapters       Comma-separated adapter ids to sync. Default: all adapters found.

import { writeFileSync, mkdirSync } from 'node:fs';
import { join, resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import {
  copyTreeDeterministic,
  assertNotSymlink,
  stagingDirFor,
  recoverInterruptedSwap,
  atomicReplaceDirectory,
} from './lib/fsutil.mjs';
import {
  loadAdapters,
  resolveProfilePath,
  loadProfile,
  resolveSkills,
  computeReceiptChecksum,
  verifyStagedExport,
} from './lib/sync-core.mjs';

const __dirname = dirname(fileURLToPath(import.meta.url));
const REPO_ROOT = resolve(__dirname, '..');

function parseArgs(argv) {
  const args = { mode: 'dry-run' };
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    const flags = {
      '--profile': 'profile',
      '--mode': 'mode',
      '--skills-dir': 'skillsDir',
      '--profiles-dir': 'profilesDir',
      '--adapters-dir': 'adaptersDir',
      '--out-root': 'outRoot',
      '--release': 'release',
      '--timestamp': 'timestamp',
      '--adapters': 'adapters',
    };
    if (a === '--help' || a === '-h') {
      args.help = true;
      continue;
    }
    if (!(a in flags)) {
      throw new Error(`Unknown argument: ${a}`);
    }
    const value = argv[++i];
    if (value === undefined) {
      throw new Error(`Missing value for ${a}`);
    }
    args[flags[a]] = value;
  }
  return args;
}

function printHelp() {
  console.log(
    'Usage: node scripts/sync.mjs --profile <name-or-path> --mode dry-run|apply [options]\n' +
      'Run with no --mode to preview (dry-run). Pass --mode apply to write files.',
  );
}

function main() {
  const args = parseArgs(process.argv.slice(2));
  if (args.help) {
    printHelp();
    return;
  }
  if (!args.profile) {
    throw new Error('--profile is required');
  }
  if (args.mode !== 'dry-run' && args.mode !== 'apply') {
    throw new Error('--mode must be "dry-run" or "apply"');
  }

  const skillsDir = resolve(args.skillsDir ?? join(REPO_ROOT, 'skills'));
  const profilesDir = resolve(args.profilesDir ?? join(REPO_ROOT, 'profiles'));
  const adaptersDir = resolve(args.adaptersDir ?? join(REPO_ROOT, 'adapters'));
  const outRoot = resolve(args.outRoot ?? REPO_ROOT);
  const release = args.release ?? 'unreleased';
  const timestamp = args.timestamp ?? new Date().toISOString();

  let adapters = loadAdapters(adaptersDir);
  if (args.adapters) {
    const wanted = new Set(args.adapters.split(',').map((s) => s.trim()));
    adapters = adapters.filter((a) => wanted.has(a.id));
    const missing = [...wanted].filter((id) => !adapters.some((a) => a.id === id));
    if (missing.length > 0) {
      throw new Error(`Unknown adapter id(s): ${missing.join(', ')}`);
    }
  }
  if (adapters.length === 0) {
    throw new Error('No adapters selected');
  }

  const profilePath = resolveProfilePath(args.profile, profilesDir);
  const profile = loadProfile(profilePath);
  const skillEntryFiles = new Set(adapters.map((a) => a.skillEntryFile));
  if (skillEntryFiles.size !== 1) {
    throw new Error('All adapters must agree on skillEntryFile for a single sync run');
  }
  const [skillEntryFile] = skillEntryFiles;

  const skills = resolveSkills(profile.skills, skillsDir, skillEntryFile);

  const receipts = adapters.map((adapter) => {
    const receiptChecksum = computeReceiptChecksum({
      profile: profile.profile,
      sourceRelease: release,
      adapterId: adapter.id,
      skills,
    });
    return {
      receiptVersion: '1',
      profile: profile.profile,
      sourceRelease: release,
      adapter: { id: adapter.id, targetDir: adapter.targetDir },
      generatedAt: timestamp,
      skills: skills.map((s) => ({
        id: s.id,
        files: s.files,
        skillChecksum: s.skillChecksum,
      })),
      receiptChecksum,
    };
  });

  const plan = {
    mode: args.mode,
    profile: profile.profile,
    profilePath,
    sourceRelease: release,
    skills: skills.map((s) => ({ id: s.id, fileCount: s.files.length, skillChecksum: s.skillChecksum })),
    targets: adapters.map((a, i) => ({
      adapter: a.id,
      targetDir: join(outRoot, a.targetDir),
      receiptChecksum: receipts[i].receiptChecksum,
    })),
  };

  if (args.mode === 'dry-run') {
    console.log(JSON.stringify(plan, null, 2));
    return;
  }

  adapters.forEach((adapter, i) => {
    const targetDir = join(outRoot, adapter.targetDir);
    const receipt = receipts[i];

    // Reject a symlinked target before touching anything, and clean up any
    // staging/backup leftovers from an apply that was interrupted before
    // it finished swapping in its result.
    assertNotSymlink(targetDir);
    recoverInterruptedSwap(targetDir);

    // Build the full export in a sibling staging directory on the same
    // filesystem, so targetDir itself is never observed in a partial
    // state. Replacing the whole managed target (not just per-skill
    // subdirectories) also means skills exported by a prior profile that
    // are absent from the newly selected profile do not survive the run.
    const stagingDir = stagingDirFor(targetDir);
    mkdirSync(stagingDir, { recursive: true });
    for (const skill of skills) {
      copyTreeDeterministic(skill.sourceDir, join(stagingDir, skill.id));
      // Test-only hook (tests/determinism.sh): simulate a crash/disk
      // failure partway through staging by throwing before the receipt is
      // written or the swap happens, so the test can assert the prior
      // export was left untouched.
      if (process.env.AGENT_STACK_SYNC_TEST_FAIL_AFTER_SKILL === `${adapter.id}:${skill.id}`) {
        throw new Error(
          `Injected test failure after staging skill "${skill.id}" for adapter "${adapter.id}" ` +
            '(AGENT_STACK_SYNC_TEST_FAIL_AFTER_SKILL)',
        );
      }
    }
    writeFileSync(join(stagingDir, 'sync-receipt.json'), JSON.stringify(receipt, null, 2) + '\n');

    // Verify the staged tree and receipt match what was intended before it
    // ever becomes the live export.
    verifyStagedExport(stagingDir, skills, receipt);

    // Atomically swap the verified staged export into place.
    atomicReplaceDirectory(targetDir, stagingDir);
  });

  console.log(JSON.stringify(plan, null, 2));
}

main();
