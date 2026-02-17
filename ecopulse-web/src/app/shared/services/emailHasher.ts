import { environment } from "../../../environments/environment";
import { signWithHmac } from "./signWithHmac";

/**
 * Generates a deterministic hash for an email using HMAC-SHA256.
 *
 * Purpose:
 * - Allows you to store a non-plain email identifier in the database.
 * - Enables fast lookups and uniqueness checks (same email -> same hash) as long as the same secret is used.
 *
 * Notes:
 * - This is NOT encryption. It is one-way and cannot be reversed to recover the email.
 * - Always normalize the email before hashing (trim + lowercase) so duplicates match correctly.
 * - The secret key must be the same across environments where you need to verify/look up the same users.
 *
 * @param email With this Property we need to pass the email we want to transform into a deterministic lookup hash.
 * @returns With this method we can get the hashed email (Base64URL), safe to store and query in the DB.
 */
export async function emailHasher(email: string): Promise<string> {
    const e = (email ?? "").trim().toLowerCase();
    if (!e) throw new Error("Email required for hashing");

    const key = environment.hash;
    if (!key) throw new Error("Error on encrypt method: we can't find the hash");

    const emailHashed = await signWithHmac(e, key); 
    return emailHashed;
}
