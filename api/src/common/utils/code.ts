import { createHash, randomBytes } from 'crypto';

export function sha256(input: string): string {
  return createHash('sha256').update(input).digest('hex');
}

const ALPHABET = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

export function makeHumanCode(len = 8): string {
  const buf = randomBytes(len);
  let out = '';
  for (let i = 0; i < len; i++) {
    out += ALPHABET[buf[i] % ALPHABET.length];
  }
  // formateado tipo XXXX-XXXX
  return `${out.slice(0, 4)}-${out.slice(4)}`;
}
