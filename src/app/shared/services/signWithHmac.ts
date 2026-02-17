/**
 * Generates an HMAC-SHA256 signature for the given data using a secret key.
 *
 * Purpose:
 * - Ensures integrity: detects if `data` was modified.
 * - Ensures authenticity: only someone with `key` can produce the same signature.
 *
 * Notes:
 * - This is NOT encryption. It is one-way and cannot be reversed to recover `data`.
 * - Output is Base64URL encoded, safe to use in URLs and tokens.
 *
 * @param data With this Property we need to pass the data we want to check if it was modified or not
 * @param key With this property we need to pass the key to produce the same signature.
 * @returns With this method we can get the hmac sign (Base64URL).
 */
export async function signWithHmac(data: string, key: string): Promise<string> {
    const enc = new TextEncoder();

    // Import the key for HMAC SHA-256
    const cryptoKey = await crypto.subtle.importKey(
        'raw',
        enc.encode(key),
        { name: 'HMAC', hash: 'SHA-256' },
        false,
        ['sign']
    );

    // Sign the data
    const signature = await crypto.subtle.sign('HMAC', cryptoKey, enc.encode(data));

    // Convert ArrayBuffer -> Base64URL
    return toBase64Url(signature);
}

/** Converts an ArrayBuffer to Base64URL (RFC 4648 §5) */
function toBase64Url(buf: ArrayBuffer): string {
    const bytes = new Uint8Array(buf);

    // Convert bytes to a binary string (safe chunking to avoid call stack limits)
    let binary = '';
    const chunkSize = 0x8000;
    for (let i = 0; i < bytes.length; i += chunkSize) {
        binary += String.fromCharCode(...bytes.subarray(i, i + chunkSize));
    }

    // Base64
    const base64 = btoa(binary);

    // Base64URL: + -> -, / -> _, remove =
    return base64.replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/g, '');
}
