# CodeMate Web App (MVP)

This repository now targets a browser-first paired programming product with:
- Web app for auth, invites, and one-click session join
- Browser collaborative workspace (shared code editor + video/audio)
- Backend API for auth, invites, sessions, and plan enforcement

## Monorepo layout

- `docs/` product and architecture notes
- `backend/` API scaffold (Node + TypeScript + Express)
- `web/` browser app (landing + workspace)
- `extension/` legacy prototype (not primary path)

## Core product idea

- Login with GitHub
- Send invite to partner GitHub username
- One-click `Send Invite + Create Room`
- Receiver uses `Accept & Join` from inbox
- Both enter browser workspace with code + video/audio side panel

## Plans (current)

- Pro Monthly: `$29.99` | 2 users at a time | 300 one-hour sessions
- Pro Yearly: `$99` | 2 users at a time | 300 one-hour sessions
- Premium Monthly: `$199` | 2 users at a time | 500 one-hour sessions
- Premium Yearly: `$349` | 2 users at a time | 500 one-hour sessions
- Lifetime: `$499` | 2 users at a time | unlimited sessions

## Run locally

1. Backend
   - Copy `backend/.env.example` to `backend/.env`
   - Set GitHub OAuth env values
   - Run:
     - `cd backend && npm install && npm run dev`
2. (Optional) ngrok for remote partner testing
   - `ngrok http 8080`
   - Update GitHub callback URL to `https://<ngrok>/auth/github/callback`
3. Web
   - Run:
     - `cd web && python3 -m http.server 5500`
   - Open:
     - `http://localhost:5500/?apiBase=http://localhost:8080`
   - If using ngrok backend:
     - `http://localhost:5500/?apiBase=https://<ngrok>`

## Billing (PayPal USD)

- Backend checkout uses PayPal Orders API (`CAPTURE`) in USD.
- Set these env vars in `backend/.env`:
  - `PAYPAL_ENV=sandbox` (or `live`)
  - `PAYPAL_CLIENT_ID=...`
  - `PAYPAL_CLIENT_SECRET=...`
  - `PAYPAL_WEBHOOK_ID=...` (for webhook verification, TODO in current scaffold)

## Deploy on Render (backend + web)

This repo includes [`render.yaml`](/Users/meetjethwa/Documents/CodeMate/render.yaml) with two services:
- `codemate-backend` (Node web service)
- `codemate-web` (static site)

Steps:
1. Push this repo to GitHub.
2. In Render, click `New +` -> `Blueprint` -> connect this repo.
3. Render will create both services from `render.yaml`.
4. Open backend service URL and copy it (example: `https://codemate-backend.onrender.com`).
5. In `codemate-web` service env, set:
   - `CODEMATE_API_BASE=https://<your-backend-url>`
6. In `codemate-backend` service env, set:
   - `GITHUB_CLIENT_ID`
   - `GITHUB_CLIENT_SECRET`
   - `GITHUB_CALLBACK_URL=https://<your-backend-url>/auth/github/callback`
   - `DEFAULT_AUTH_REDIRECT_URI=https://<your-web-url>`
   - `ALLOWED_AUTH_REDIRECTS=https://<your-web-url>`
   - `PAYPAL_CLIENT_ID`
   - `PAYPAL_CLIENT_SECRET`
   - `PAYPAL_WEBHOOK_ID` (optional until webhook verification is added)
7. In GitHub OAuth app settings:
   - Authorization callback URL must match `GITHUB_CALLBACK_URL`.
8. Redeploy both services.

## Next tasks

- Move in-memory state to Postgres
- Add TURN servers for robust media transport
- Add full PayPal webhook verification + entitlement persistence
- Add persistent audit logs and abuse detection
