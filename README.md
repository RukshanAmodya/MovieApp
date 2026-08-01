# Rooflix Cloudflare Worker

Firebase Authentication + Realtime Database REST API backend for the Rooflix Flutter app.

## Project Structure

```
src/
  index.js                 # Main entry point, routing
  routes/
    auth.js                # POST /auth/signup, /auth/signin, /auth/signout
    movies.js              # GET /movies (requires Bearer token)
  middleware/
    firebase.js            # Firebase ID token verifier
wrangler.toml              # Cloudflare Worker config
package.json
```

## API Endpoints

| Method | Path           | Auth Required | Description          |
|--------|----------------|---------------|----------------------|
| POST   | /auth/signup   | No            | Create new account   |
| POST   | /auth/signin   | No            | Sign in, get token   |
| POST   | /auth/signout  | No            | Sign out (client)    |
| GET    | /movies        | Yes (Bearer)  | Fetch all movies     |
| GET    | /              | No            | Health check         |

## Setup

### 1. Install dependencies
```bash
npm install
```

### 2. Login to Cloudflare
```bash
npx wrangler login
```

### 3. Set Secret (Firebase Web API Key)
```bash
npx wrangler secret put FIREBASE_WEB_API_KEY
```
Enter when prompted: `AIzaSyC3eo55U9kgJA3m_XIEMmMJfGLK4TXnLRw`

### 4. Run locally
```bash
npm run dev
```

### 5. Deploy to Cloudflare
```bash
npm run deploy
```

## Flutter App Integration

After deploying, set the Worker URL in the Flutter app's `lib/services/api_service.dart`:
```
https://rooflix-worker.<your-account>.workers.dev
```
