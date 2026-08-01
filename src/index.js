// =============================================================
// Rooflix Cloudflare Worker — Main Entry Point
// Handles all routing with CORS support
// =============================================================

import { handleAuth } from './routes/auth.js';
import { handleMovies } from './routes/movies.js';

const CORS_HEADERS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization',
};

export default {
  async fetch(request, env) {
    // CORS preflight
    if (request.method === 'OPTIONS') {
      return new Response(null, { status: 204, headers: CORS_HEADERS });
    }

    const url = new URL(request.url);
    const path = url.pathname;

    try {
      let response;

      // ----------- AUTH ROUTES -----------
      if (path.startsWith('/auth/')) {
        response = await handleAuth(request, env, path);

      // ----------- MOVIES ROUTES -----------
      } else if (path.startsWith('/movies')) {
        response = await handleMovies(request, env);

      // ----------- HEALTH CHECK -----------
      } else if (path === '/') {
        response = new Response(
          JSON.stringify({ status: 'ok', service: 'Rooflix Worker' }),
          { status: 200, headers: { 'Content-Type': 'application/json' } }
        );

      } else {
        response = new Response(
          JSON.stringify({ error: 'Not found' }),
          { status: 404, headers: { 'Content-Type': 'application/json' } }
        );
      }

      // Attach CORS headers to every response
      const newHeaders = new Headers(response.headers);
      Object.entries(CORS_HEADERS).forEach(([k, v]) => newHeaders.set(k, v));
      return new Response(response.body, {
        status: response.status,
        headers: newHeaders,
      });

    } catch (err) {
      console.error('Worker error:', err);
      return new Response(
        JSON.stringify({ error: 'Internal server error', details: err.message }),
        { status: 500, headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' } }
      );
    }
  },
};
