import { readdirSync, mkdirSync, copyFileSync, chmodSync, rmSync } from 'node:fs';
import { join, relative, dirname, sep } from 'node:path';

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
