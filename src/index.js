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
    // Normalize path by removing trailing slash if any
    const path = url.pathname.length > 1 ? url.pathname.replace(/\/$/, '') : url.pathname;

    try {
      let response;

      // ----------- AUTH ROUTES -----------
      if (path.startsWith('/auth')) {
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

      // Attach CORS headers directly to response object (preserves stream body)
      Object.entries(CORS_HEADERS).forEach(([k, v]) => response.headers.set(k, v));
      return response;

    } catch (err) {
      console.error('Worker error:', err);
      const errResponse = new Response(
        JSON.stringify({ error: 'Internal server error', details: err.message }),
        { status: 500, headers: { 'Content-Type': 'application/json' } }
      );
      Object.entries(CORS_HEADERS).forEach(([k, v]) => errResponse.headers.set(k, v));
      return errResponse;
    }
  },
};
