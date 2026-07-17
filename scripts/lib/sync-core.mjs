import { readFileSync, readdirSync, existsSync } from 'node:fs';
import { join } from 'node:path';
import { sha256OfFile, sha256OfPairs } from './checksum.mjs';
import { listFilesSortedPosix } from './fsutil.mjs';

export function loadAdapters(adaptersDir) {
  const ids = readdirSync(adaptersDir, { withFileTypes: true })
    .filter((e) => e.isDirectory())
    .map((e) => e.name)
    .sort();

  return ids.map((id) => {
    const manifestPath = join(adaptersDir, id, 'adapter.json');
    if (!existsSync(manifestPath)) {
      throw new Error(`Adapter "${id}" is missing adapter.json at ${manifestPath}`);
    }
    const manifest = JSON.parse(readFileSync(manifestPath, 'utf8'));
    if (manifest.id !== id) {
      throw new Error(
        `Adapter directory "${id}" declares mismatched id "${manifest.id}" in adapter.json`,
      );
    }
    return manifest;
  });
}

export function resolveProfilePath(profileArg, profilesDir) {
  if (profileArg.endsWith('.json') && existsSync(profileArg)) {
    return profileArg;
  }
  const candidate = join(profilesDir, `${profileArg}.json`);
  if (existsSync(candidate)) {
    return candidate;
  }
  throw new Error(
    `Could not resolve profile "${profileArg}" as a file path or under ${profilesDir}`,
  );
}

// Loads a profile using the shared Agent Stack profile contract
// (schemas/project-profile.schema.json): "profile" is the required,
// canonical identifier field. The skill export list is this adapter's
// domain-specific field, "skills" (a project-profile's broader
// "capabilities" list is out of scope here — this sync only ever exports
// skills/<name>/SKILL.md packages).
export function loadProfile(profilePath) {
  const profile = JSON.parse(readFileSync(profilePath, 'utf8'));

  if (!profile.profile) {
    throw new Error(`Profile at ${profilePath} must declare "profile"`);
  }

  if (!Array.isArray(profile.skills) || profile.skills.length === 0) {
    throw new Error(`Profile at ${profilePath} must declare a non-empty "skills" array`);
  }
  const seen = new Set();
  const duplicates = new Set();
  for (const id of profile.skills) {
    if (seen.has(id)) {
      duplicates.add(id);
    }
    seen.add(id);
  }
  if (duplicates.size > 0) {
    throw new Error(
      `Profile at ${profilePath} lists duplicate skill id(s): ${[...duplicates].sort().join(', ')}`,
    );
  }
  return profile;
}

// Resolves each selected skill id to its canonical source directory under
// skillsDir, verifies SKILL.md exists, and computes a deterministic
// checksum manifest (per file + aggregate) for every skill.
export function resolveSkills(skillIds, skillsDir, skillEntryFile) {
  const sortedIds = [...skillIds].sort();
  return sortedIds.map((id) => {
    const skillDir = join(skillsDir, id);
    if (!existsSync(skillDir)) {
      throw new Error(`Skill "${id}" not found at ${skillDir}`);
    }
    const entryPath = join(skillDir, skillEntryFile);
    if (!existsSync(entryPath)) {
      throw new Error(`Skill "${id}" is missing required entry file ${skillEntryFile}`);
    }

    const files = listFilesSortedPosix(skillDir).map((relPath) => ({
      path: relPath,
      sha256: sha256OfFile(join(skillDir, ...relPath.split('/'))),
    }));

    const skillChecksum = sha256OfPairs(files.map((f) => [f.path, f.sha256]));

    return { id, sourceDir: skillDir, files, skillChecksum };
  });
}

export function computeReceiptChecksum({ profile, sourceRelease, adapterId, skills }) {
  const pairs = [
    ['profile', profile],
    ['sourceRelease', sourceRelease],
    ['adapter', adapterId],
    ...skills.map((s) => [`skill:${s.id}`, s.skillChecksum]),
  ];
  return sha256OfPairs(pairs);
}
