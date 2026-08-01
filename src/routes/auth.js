// =============================================================
// Firebase Auth Handler
// Uses Firebase Auth REST API (Identity Toolkit)
// Handles: /auth/signup, /auth/signin
// =============================================================

const FIREBASE_AUTH_BASE = 'https://identitytoolkit.googleapis.com/v1/accounts';

/**
 * Get Firebase Web API key from env
 */
function getApiKey(env) {
  return env.FIREBASE_WEB_API_KEY;
}

/**
 * POST /auth/signup
 * Body: { email, password }
 * Returns: { idToken, email, uid, expiresIn }
 */
async function signup(request, env) {
  const body = await request.json();
  const { email, password } = body;

  if (!email || !password) {
    return jsonResponse({ error: 'Email and password are required' }, 400);
  }

  const res = await fetch(
    `${FIREBASE_AUTH_BASE}:signUp?key=${getApiKey(env)}`,
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email, password, returnSecureToken: true }),
    }
  );

  const data = await res.json();

  if (!res.ok) {
    const message = firebaseAuthError(data?.error?.message);
    return jsonResponse({ error: message }, 400);
  }

  return jsonResponse({
    idToken: data.idToken,
    email: data.email,
    uid: data.localId,
    expiresIn: data.expiresIn,
  }, 200);
}

/**
 * POST /auth/signin
 * Body: { email, password }
 * Returns: { idToken, email, uid, expiresIn }
 */
async function signin(request, env) {
  const body = await request.json();
  const { email, password } = body;

  if (!email || !password) {
    return jsonResponse({ error: 'Email and password are required' }, 400);
  }

  const res = await fetch(
    `${FIREBASE_AUTH_BASE}:signInWithPassword?key=${getApiKey(env)}`,
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email, password, returnSecureToken: true }),
    }
  );

  const data = await res.json();

  if (!res.ok) {
    const message = firebaseAuthError(data?.error?.message);
    return jsonResponse({ error: message }, 401);
  }

  return jsonResponse({
    idToken: data.idToken,
    email: data.email,
    uid: data.localId,
    expiresIn: data.expiresIn,
  }, 200);
}

/**
 * POST /auth/signout
 * (Client-side token deletion — no server action needed for Firebase)
 */
async function signout() {
  return jsonResponse({ message: 'Signed out successfully' }, 200);
}

/**
 * Route handler for /auth/* paths
 */
export async function handleAuth(request, env, path) {
  if (request.method !== 'POST') {
    return jsonResponse({ error: 'Method not allowed' }, 405);
  }

  if (path === '/auth/signup')  return await signup(request, env);
  if (path === '/auth/signin')  return await signin(request, env);
  if (path === '/auth/signout') return await signout();

  return jsonResponse({ error: 'Auth route not found' }, 404);
}

// ---- helpers ----

function jsonResponse(data, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { 'Content-Type': 'application/json' },
  });
}

function firebaseAuthError(code) {
  switch (code) {
    case 'EMAIL_EXISTS':           return 'This email is already registered.';
    case 'INVALID_PASSWORD':       return 'Incorrect password.';
    case 'EMAIL_NOT_FOUND':        return 'No account found with this email.';
    case 'USER_DISABLED':          return 'This account has been disabled.';
    case 'TOO_MANY_ATTEMPTS_TRY_LATER': return 'Too many attempts. Please try again later.';
    case 'WEAK_PASSWORD : Password should be at least 6 characters':
                                   return 'Password must be at least 6 characters.';
    default:                       return code ?? 'Authentication failed.';
  }
}
