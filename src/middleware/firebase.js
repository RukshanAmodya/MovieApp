// =============================================================
// Firebase Middleware
// Verifies Firebase ID tokens using Google's public keys
// Works natively in Cloudflare Workers (no Node.js SDK needed)
// =============================================================

const FIREBASE_VERIFY_URL =
  'https://identitytoolkit.googleapis.com/v1/accounts:lookup';

/**
 * Verifies a Firebase ID token by calling the Identity Toolkit API.
 * Returns { valid: true, uid, email } or { valid: false }
 *
 * @param {string} idToken
 * @param {object} env  - Cloudflare env bindings (needs FIREBASE_WEB_API_KEY)
 */
export async function verifyIdToken(idToken, env) {
  try {
    const res = await fetch(
      `${FIREBASE_VERIFY_URL}?key=${env.FIREBASE_WEB_API_KEY}`,
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ idToken }),
      }
    );

    if (!res.ok) return { valid: false };

    const data = await res.json();
    const user = data?.users?.[0];

    if (!user) return { valid: false };

    return {
      valid: true,
      uid:   user.localId,
      email: user.email,
    };
  } catch (err) {
    console.error('Token verification error:', err);
    return { valid: false };
  }
}
