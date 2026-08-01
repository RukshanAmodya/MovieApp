// =============================================================
// Movies Handler
// Fetches movies from Firebase Realtime Database via REST API
// Verifies the caller's Firebase ID token before serving data
// =============================================================

import { verifyIdToken } from '../middleware/firebase.js';

/**
 * GET /movies
 * Header: Authorization: Bearer <idToken>
 * Returns: [ { id, title, coverUrl, streamUrl }, ... ]
 */
export async function handleMovies(request, env) {
  if (request.method !== 'GET') {
    return jsonResponse({ error: 'Method not allowed' }, 405);
  }

  // ---- Auth verification ----
  const authHeader = request.headers.get('Authorization') ?? '';
  const idToken = authHeader.replace('Bearer ', '').trim();

  if (!idToken) {
    return jsonResponse({ error: 'Unauthorized — no token provided' }, 401);
  }

  const verifyResult = await verifyIdToken(idToken, env);
  if (!verifyResult.valid) {
    return jsonResponse({ error: 'Unauthorized — invalid token' }, 401);
  }

  // ---- Fetch from Firebase RTDB ----
  const dbUrl = `${env.FIREBASE_DB_URL}/movies.json`;

  const res = await fetch(dbUrl, {
    headers: { 'Content-Type': 'application/json' },
  });

  if (!res.ok) {
    return jsonResponse({ error: 'Failed to fetch movies from database' }, 502);
  }

  const raw = await res.json();

  if (!raw) {
    return jsonResponse([], 200);
  }

  // Convert object keys to array and reverse (newest first)
  const movies = Object.entries(raw)
    .reverse()
    .map(([id, val]) => ({
      id,
      title:     val?.title     ?? 'Unknown Title',
      coverUrl:  val?.cover_url ?? val?.coverUrl  ?? '',
      streamUrl: val?.stream_url ?? val?.streamUrl ?? '',
    }));

  return jsonResponse(movies, 200);
}

// ---- helpers ----

function jsonResponse(data, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { 'Content-Type': 'application/json' },
  });
}
