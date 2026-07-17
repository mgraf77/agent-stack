#!/usr/bin/env node
// Verifies that each adapter's exported target directory matches its
// sync-receipt.json: same skills, same per-file checksums, receipt checksum
// intact, and no symlinks present. Exits non-zero on any drift.
//
// Usage:
//   node scripts/doctor.mjs [--out-root DIR] [--adapters-dir DIR] [--adapters codex,claude-code]

import { existsSync, readFileSync, lstatSync } from 'node:fs';
import { join, resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { sha256OfFile } from './lib/checksum.mjs';
import { listFilesSortedPosix } from './lib/fsutil.mjs';
import { loadAdapters, computeReceiptChecksum } from './lib/sync-core.mjs';

const __dirname = dirname(fileURLToPath(import.meta.url));
const REPO_ROOT = resolve(__dirname, '..');

function parseArgs(argv) {
  const args = {};
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    const flags = { '--out-root': 'outRoot', '--adapters-dir': 'adaptersDir', '--adapters': 'adapters' };
    if (a === '--help' || a === '-h') {
      args.help = true;
      continue;
    }
    if (!(a in flags)) throw new Error(`Unknown argument: ${a}`);
    args[flags[a]] = argv[++i];
  }
  return args;
}

function checkSymlinks(dir, problems) {
  // listFilesSortedPosix already throws on symlinked entries during walk;
  // wrap it so doctor reports a problem instead of crashing.
  try {
    listFilesSortedPosix(dir);
  } catch (err) {
    problems.push(err.message);
  }
}

function doctorAdapter(adapter, outRoot) {
  const targetDir = join(outRoot, adapter.targetDir);
  const problems = [];

  if (!existsSync(targetDir)) {
    return { adapter: adapter.id, ok: false, problems: [`Target directory missing: ${targetDir}`] };
  }

  const receiptPath = join(targetDir, 'sync-receipt.json');
  if (!existsSync(receiptPath)) {
    return { adapter: adapter.id, ok: false, problems: [`Receipt missing: ${receiptPath}`] };
  }

  checkSymlinks(targetDir, problems);
  if (problems.length > 0) {
    return { adapter: adapter.id, ok: false, problems };
  }

  const receipt = JSON.parse(readFileSync(receiptPath, 'utf8'));

  const expectedChecksum = computeReceiptChecksum({
    profile: receipt.profile,
    sourceRelease: receipt.sourceRelease,
    adapterId: receipt.adapter.id,
    skills: receipt.skills,
  });
  if (expectedChecksum !== receipt.receiptChecksum) {
    problems.push(
      `Receipt checksum mismatch (recorded ${receipt.receiptChecksum}, recomputed ${expectedChecksum}) — receipt may be corrupted or hand-edited`,
    );
  }

  for (const skill of receipt.skills) {
    const skillDir = join(targetDir, skill.id);
    if (!existsSync(skillDir)) {
      problems.push(`Skill "${skill.id}" listed in receipt but missing from ${targetDir}`);
      continue;
    }
    const actualFiles = listFilesSortedPosix(skillDir).filter((f) => f !== 'sync-receipt.json');
    const expectedFiles = skill.files.map((f) => f.path).sort();
    if (JSON.stringify(actualFiles) !== JSON.stringify(expectedFiles)) {
      problems.push(
        `Skill "${skill.id}" file set drift. Expected [${expectedFiles.join(', ')}], found [${actualFiles.join(', ')}]`,
      );
      continue;
    }
    for (const file of skill.files) {
      const actualHash = sha256OfFile(join(skillDir, ...file.path.split('/')));
      if (actualHash !== file.sha256) {
        problems.push(`Skill "${skill.id}" file "${file.path}" checksum mismatch`);
      }
    }
  }

  // Flag skill directories present on disk but not recorded in the receipt.
  const receiptSkillIds = new Set(receipt.skills.map((s) => s.id));
  const onDiskEntries = listFilesSortedPosix(targetDir).filter((f) => f !== 'sync-receipt.json');
  const onDiskTopLevelDirs = new Set(onDiskEntries.map((f) => f.split('/')[0]));
  for (const dirName of onDiskTopLevelDirs) {
    if (!receiptSkillIds.has(dirName)) {
      problems.push(`Unmanaged/stale entry in ${targetDir}: "${dirName}" not present in receipt`);
    }
  }

  return { adapter: adapter.id, ok: problems.length === 0, problems };
}

function main() {
  const args = parseArgs(process.argv.slice(2));
  if (args.help) {
    console.log('Usage: node scripts/doctor.mjs [--out-root DIR] [--adapters-dir DIR] [--adapters codex,claude-code]');
    return;
  }

  const outRoot = resolve(args.outRoot ?? REPO_ROOT);
  const adaptersDir = resolve(args.adaptersDir ?? join(REPO_ROOT, 'adapters'));

  let adapters = loadAdapters(adaptersDir);
  if (args.adapters) {
    const wanted = new Set(args.adapters.split(',').map((s) => s.trim()));
    adapters = adapters.filter((a) => wanted.has(a.id));
  }

  const results = adapters.map((a) => doctorAdapter(a, outRoot));
  console.log(JSON.stringify(results, null, 2));

  const allOk = results.every((r) => r.ok);
  if (!allOk) {
    process.exitCode = 1;
  }
}

main();
