import {
  readdirSync,
  mkdirSync,
  copyFileSync,
  chmodSync,
  rmSync,
  lstatSync,
  existsSync,
  renameSync,
} from 'node:fs';
import { join, relative, dirname, sep } from 'node:path';

// Throws if path exists and is itself a symlink. Used to reject a symlinked
// adapter target directory before any write or traversal touches it — a
// symlinked target could otherwise cause sync/doctor to silently read or
// write through it to an arbitrary location.
export function assertNotSymlink(path) {
  let stat;
  try {
    stat = lstatSync(path);
  } catch (err) {
    if (err.code === 'ENOENT') return;
    throw err;
  }
  if (stat.isSymbolicLink()) {
    throw new Error(`Refusing to use symlinked directory: ${path}`);
  }
}

// Sibling paths used to stage a new export and, transiently, to hold the
// previous export while it is swapped out. Fixed (not randomized) names
// keep runs deterministic and let a later run recognize and clean up
// leftovers from an apply that was interrupted before completing.
export function stagingDirFor(targetDir) {
  return `${targetDir}.sync-staging`;
}

export function backupDirFor(targetDir) {
  return `${targetDir}.sync-backup`;
}

// Cleans up any staging/backup directories left behind by an apply that
// was interrupted before it finished. Safe to call unconditionally at the
// start of every apply: a clean prior run leaves neither directory behind,
// so this is then a no-op.
//
// - backup present, targetDir missing: the process died after moving the
//   live export aside but before swapping the new one in. Restore the
//   prior valid export.
// - backup present, targetDir present: the process died after the swap
//   completed but before the now-stale backup was removed. Discard it.
// - staging present: an aborted build that never reached (or survived)
//   the swap. Discard it; the next apply rebuilds it from scratch.
export function recoverInterruptedSwap(targetDir) {
  const staging = stagingDirFor(targetDir);
  const backup = backupDirFor(targetDir);
  assertNotSymlink(targetDir);
  assertNotSymlink(staging);
  assertNotSymlink(backup);

  if (existsSync(backup)) {
    if (!existsSync(targetDir)) {
      renameSync(backup, targetDir);
    } else {
      rmSync(backup, { recursive: true, force: true });
    }
  }
  if (existsSync(staging)) {
    rmSync(staging, { recursive: true, force: true });
  }
}

// Atomically swaps a verified staging directory into targetDir's place.
// Uses two renames (target -> backup, staging -> target) rather than one
// direct rename because POSIX rename(2) refuses to replace a non-empty
// directory and Windows refuses to rename onto any existing directory;
// renaming onto a path that does not yet exist works on both. Each
// individual rename is atomic, so at any instant targetDir is either the
// complete old export or the complete new one, never a partial mix. If the
// process dies between the two renames, recoverInterruptedSwap finishes
// the job (in either direction) on the next apply.
export function atomicReplaceDirectory(targetDir, stagingDir) {
  assertNotSymlink(targetDir);
  assertNotSymlink(stagingDir);
  const backup = backupDirFor(targetDir);
  if (existsSync(backup)) {
    throw new Error(
      `Refusing to swap into ${targetDir}: stale backup directory present at ${backup}. Run sync again to recover it first.`,
    );
  }

  const hadExisting = existsSync(targetDir);
  if (hadExisting) {
    renameSync(targetDir, backup);
  }
  try {
    renameSync(stagingDir, targetDir);
  } catch (err) {
    if (hadExisting) {
      renameSync(backup, targetDir);
    }
    throw err;
  }
  if (hadExisting) {
    rmSync(backup, { recursive: true, force: true });
  }
}

// Recursively lists files under rootDir as sorted, POSIX-style relative paths
// so output is stable across platforms. Throws if a symlink is found —
// distribution must use deterministic copies, never symlinks.
export function listFilesSortedPosix(rootDir) {
  const results = [];

  function walk(dir) {
    const entries = readdirSync(dir, { withFileTypes: true }).sort((a, b) =>
      a.name.localeCompare(b.name),
    );
    for (const entry of entries) {
      const full = join(dir, entry.name);
      if (entry.isSymbolicLink()) {
        throw new Error(`Refusing to process symlink in source tree: ${full}`);
      }
      if (entry.isDirectory()) {
        walk(full);
      } else if (entry.isFile()) {
        results.push(relative(rootDir, full).split(sep).join('/'));
      }
    }
  }

  walk(rootDir);
  return results.sort();
}

// Copies every file from srcDir into destDir, replacing destDir's current
// contents entirely so re-running sync never leaves stale files behind.
// Returns the sorted list of POSIX-relative file paths that were copied.
export function copyTreeDeterministic(srcDir, destDir) {
  assertNotSymlink(destDir);
  rmSync(destDir, { recursive: true, force: true });
  mkdirSync(destDir, { recursive: true });

  const files = listFilesSortedPosix(srcDir);
  for (const relPath of files) {
    const parts = relPath.split('/');
    const srcPath = join(srcDir, ...parts);
    const destPath = join(destDir, ...parts);
    mkdirSync(dirname(destPath), { recursive: true });
    copyFileSync(srcPath, destPath);
    chmodSync(destPath, 0o644);
  }
  return files;
}
