# Cursor Agent prompt — paste everything below the line into a new Agent chat

---

Create a new Ruby on Rails API-only backend for a Flutter mobile app (90's Match / nineties_match).

## Goal
Build production-ready auth APIs:
1. Login (email + password → JWT)
2. New user registration
3. DigiLocker-supported identity verification during signup (India DigiLocker OAuth)

Do NOT build Flutter UI. Expose clean JSON REST APIs and OpenAPI/Swagger docs the mobile team can consume.

## Stack (required)
- Ruby 3.3+ / Rails 7.2+ or 8.x, `--api` mode
- PostgreSQL
- JWT auth (e.g. `jwt` gem + custom middleware or `devise-jwt` / `warden-jwt_auth` — pick one and stay consistent)
- `bcrypt` for passwords
- `rack-cors` for Flutter (dev + staging origins configurable)
- `dotenv-rails` / credentials for secrets
- RSpec + FactoryBot + request specs for auth + DigiLocker flows
- Docker Compose: `web` + `db` for local run
- README with setup, env vars, API examples (curl)

## Domain model
User:
- email (unique, required)
- password_digest
- full_name
- phone (optional, unique if present)
- digilocker_id / digilocker_subject (unique, nullable)
- digilocker_verified_at (datetime, nullable)
- digilocker_raw_profile (jsonb, store non-sensitive verified claims only — NEVER store full Aadhaar number in plaintext; mask or hash if needed)
- status: pending_verification | active | suspended
- timestamps

DigilockerSession (or equivalent):
- user_id
- state (CSRF/OAuth state)
- code_verifier if PKCE
- status: started | completed | failed
- expires_at
- error_message (nullable)

## API endpoints (version under /api/v1)

### Auth
- POST /api/v1/auth/register
  Body: { email, password, password_confirmation, full_name, phone? }
  Creates user with status pending_verification
  Returns: { user, access_token?, digilocker: { authorize_url, state } }
  Prefer: return JWT only after DigiLocker success OR return limited token that cannot access protected features until verified — document the choice in README.

- POST /api/v1/auth/login
  Body: { email, password }
  Returns: { access_token, token_type, expires_in, user }
  Reject suspended users; allow pending_verification with a clear `verification_required` flag.

- POST /api/v1/auth/logout (optional blacklist/jti if implemented)
- GET  /api/v1/auth/me (Bearer JWT) → current user

### DigiLocker
Implement against DigiLocker OAuth2 / API Gateway patterns used by MeitY DigiLocker (configurable base URLs for sandbox vs production).

- GET  /api/v1/digilocker/authorize
  Auth: optional Bearer or registration session
  Query: user_id or registration_token
  Returns: { authorize_url, state }
  Builds DigiLocker authorize URL with client_id, redirect_uri, response_type=code, state, scope, PKCE if required.

- GET  /api/v1/digilocker/callback
  DigiLocker redirects here with ?code=&state=
  Validate state, exchange code for access token, fetch user profile / issued documents as configured.
  Link digilocker identity to user, set digilocker_verified_at, status=active.
  Redirect to a deep-link / success URL for the Flutter app:
    e.g. ninetiesmatch://digilocker/success?status=ok
    and failure: ninetiesmatch://digilocker/failure?reason=...
  Also support JSON response mode for testing (?format=json).

- GET  /api/v1/digilocker/status
  Auth: Bearer → { verified: bool, verified_at, digilocker_id masked }

Service object pattern:
- Digilocker::AuthorizeUrlBuilder
- Digilocker::TokenExchanger
- Digilocker::ProfileFetcher
- Digilocker::UserLinker

Stub DigiLocker HTTP in tests; provide a `DIGILOCKER_MOCK=true` mode that completes verification without real DigiLocker for local Flutter work.

## Config / env
Document and use:
- DATABASE_URL
- SECRET_KEY_BASE
- JWT_SECRET / JWT_EXPIRY_SECONDS
- CORS_ORIGINS
- DIGILOCKER_CLIENT_ID
- DIGILOCKER_CLIENT_SECRET
- DIGILOCKER_REDIRECT_URI
- DIGILOCKER_AUTHORIZE_URL
- DIGILOCKER_TOKEN_URL
- DIGILOCKER_API_BASE_URL
- DIGILOCKER_SCOPES
- APP_DEEP_LINK_SUCCESS
- APP_DEEP_LINK_FAILURE
- DIGILOCKER_MOCK

## Security requirements
- Strong password validation
- Rate limit login + DigiLocker start (rack-attack)
- State + PKCE for OAuth
- No secrets in repo; .env.example only
- Mask PII in logs
- HTTPS assumed in production

## Project structure expectations
- app/controllers/api/v1/...
- app/services/digilocker/...
- app/models/user.rb, digilocker_session.rb
- config/routes.rb with namespace api/v1
- swagger or rswag for API docs
- db/migrate for users + digilocker_sessions
- spec/requests for register, login, me, digilocker callback happy/sad paths

## Deliverables when done
1. Working Rails API scaffold with migrations
2. Seed admin/test user for login (password in README for local only)
3. Mock DigiLocker path that Flutter can use immediately
4. README: setup, docker-compose up, curl examples for register → digilocker mock → login → me
5. Short API contract section the Flutter coworker can copy (request/response JSON samples)

Start by generating the Rails API app, then implement models, services, controllers, specs, and README in that order. Ask before inventing DigiLocker document types beyond basic profile linkage unless needed for verification.
