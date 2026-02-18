/**
 * Generates a bcrypt hash for the given input.
 *
 * Purpose:
 * - Stores sensitive values securely (e.g., passwords) as a one-way hash.
 * - Prevents recovering the original value from the stored hash.
 *
 * Notes:
 * - This is NOT encryption. It is one-way and cannot be reversed.
 * - bcrypt is salted by design, so hashing the same value multiple times produces different hashes.
 * - Because of the random salt, bcrypt hashes are NOT suitable for deterministic lookups (e.g., checking if an email already exists).
 * - `process.env.HASH` must be a valid bcrypt salt OR a valid number of rounds depending on your usage.
 *
 * @param toEncrypt With this Property we need to pass the data we want to hash (commonly a password).
 * @returns With this method we can get the bcrypt hash string.
 */
export async function encrypt(input: string): Promise<string> {
  const data = new TextEncoder().encode(input);
  const hash = await crypto.subtle.digest('SHA-256', data);
  return [...new Uint8Array(hash)].map(b => b.toString(16).padStart(2, '0')).join('');
}

