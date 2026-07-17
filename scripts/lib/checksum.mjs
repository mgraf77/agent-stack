import { createHash } from 'node:crypto';
import { readFileSync } from 'node:fs';

export function sha256Hex(buffer) {
  return createHash('sha256').update(buffer).digest('hex');
}

export function sha256OfFile(path) {
  return sha256Hex(readFileSync(path));
}

export function sha256OfString(str) {
  return sha256Hex(Buffer.from(str, 'utf8'));
}

// Deterministic checksum over an ordered list of [label, hex] pairs, independent
// of object key ordering or JSON.stringify quirks.
export function sha256OfPairs(pairs) {
  const canonical = pairs.map(([label, hex]) => `${label}:${hex}`).join('\n');
  return sha256OfString(canonical);
}
