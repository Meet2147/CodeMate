# Product Spec - Pair Programming Extension + Subscription Platform

## Goal
Build a two-person-first paired programming experience where a user can invite a friend or mentor using GitHub identity and collaborate in live coding sessions.

## Core user flow
1. User installs extension from website.
2. User signs in with GitHub.
3. User enters partner GitHub ID and sends invite.
4. Partner accepts invite.
5. Both users join a shared coding session.
6. Session usage is counted against account limits.

## Roles
- Account owner: pays for plan and creates sessions
- Partner: invited collaborator in a room

## Plan constraints
- Free trial: first 30 days
- Plan controls:
  - max concurrent participants per room
  - monthly/yearly session-hour quota

## Technical building blocks
- Identity: GitHub OAuth
- Billing: Stripe products + prices + webhook-driven entitlements
- Room/session: session service with participant + quota checks
- Frontend:
  - Marketing/pricing website
  - Extension popup for auth + invite + start/join

## Data model (MVP)
- `users(id, github_id, github_username, email, trial_ends_at)`
- `subscriptions(id, user_id, plan_code, status, current_period_end, session_hours_used)`
- `pair_invites(id, sender_user_id, receiver_github_username, status)`
- `coding_sessions(id, owner_user_id, room_code, started_at, ended_at, duration_minutes)`
- `session_participants(id, session_id, user_id, joined_at, left_at)`

## API surface (MVP)
- `GET /auth/github/start?redirect_uri=...`
- `GET /auth/github/callback`
- `GET /auth/me`
- `POST /pairing/invite`
- `POST /pairing/accept`
- `POST /sessions/start`
- `POST /sessions/join`
- `POST /sessions/end`
- `GET /billing/plans`
- `POST /billing/checkout`
- `POST /billing/webhook`
- `WS /ws` (WebRTC signaling: offer/answer/ice-candidate)

## Non-functional requirements
- Enforce 2-person max for paired plans
- Prevent unauthorized room access
- Accurate usage metering (session-hours)
- Observability for billing and auth failures

## Open product questions
- Should partner need paid plan or only owner?
- Should quota reset monthly for yearly plan or yearly aggregate?
- How to handle overage after quota exhausted?
- Confirm Premium Yearly price (currently same as Pro Yearly).
