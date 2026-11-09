# Mouleetech 90 Match — API

Rails API-only backend for the Flutter app **90's Match** (`nineties_match`).

## Stack

- Ruby / Rails 8.1 API mode
- PostgreSQL
- JWT auth (`jwt` + `has_secure_password` / bcrypt)
- DigiLocker OAuth (MeitY) with `DIGILOCKER_MOCK=true` for local Flutter
- RSpec + FactoryBot
- OpenAPI via rswag (`/api-docs`)
- Docker Compose (`web` + `db`)

## Auth token policy

Registration and login always return a JWT.

- **`pending_verification` users** receive a valid token with `verification_required: true`. Use it for DigiLocker authorize/status and `/auth/me` only. Treat feature APIs as blocked until verified.
- After DigiLocker success, user `status` becomes `active`, `verification_required` is `false`, and a fresh token is returned from the callback JSON mode.
- Suspended users cannot log in.

## Quick start (local)

```bash
cp .env.example .env
# edit JWT_SECRET / SECRET_KEY_BASE if needed

bundle config set --local path 'vendor/bundle'
bundle install

createdb mouleetech_90_match_api_development   # if needed
bundle exec rails db:prepare db:seed
bundle exec rails server
```

Swagger UI: [http://localhost:3000/api-docs](http://localhost:3000/api-docs)

## Docker Compose

```bash
cp .env.example .env
docker compose up --build
```

Requires Docker. App: `http://localhost:3000`.

## Seed users (local only)

| Email | Password | Status |
|-------|----------|--------|
| `admin@ninetiesmatch.local` | `Password1` | active (member) |
| `pending@ninetiesmatch.local` | `Password1` | pending_verification |

Staff admin (username/password, no DigiLocker):

| Username | Password | Role |
|----------|----------|------|
| `admin` | `Password1` | admin panel |

## Environment variables

See [`.env.example`](.env.example). Key ones:

| Variable | Purpose |
|----------|---------|
| `DATABASE_URL` | Postgres URL (Docker/production only; avoid in local `.env` or test DB breaks) |
| `SECRET_KEY_BASE` | Rails secrets |
| `JWT_SECRET` / `JWT_EXPIRY_SECONDS` | JWT signing |
| `CORS_ORIGINS` | Comma-separated Flutter/web origins |
| `DIGILOCKER_*` | OAuth client + endpoints |
| `APP_DEEP_LINK_SUCCESS` / `FAILURE` | Flutter deep links |
| `DIGILOCKER_MOCK` | Skip real DigiLocker HTTP |

## Curl walkthrough (mock DigiLocker)

```bash
# 1) Register
curl -s -X POST http://localhost:3000/api/v1/auth/register \
  -H 'Content-Type: application/json' \
  -d '{
    "email":"flutter.dev@example.com",
    "password":"Password1",
    "password_confirmation":"Password1",
    "full_name":"Flutter Dev"
  }' | tee /tmp/register.json

# 2) Open authorize_url from the response (mock URL hits callback with format=json)
AUTHORIZE_URL=$(ruby -rjson -e 'puts JSON.parse(File.read("/tmp/register.json"))["digilocker"]["authorize_url"]')
curl -s "$AUTHORIZE_URL" | tee /tmp/verified.json

# 3) Login
curl -s -X POST http://localhost:3000/api/v1/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"email":"flutter.dev@example.com","password":"Password1"}' | tee /tmp/login.json

# 4) Me
TOKEN=$(ruby -rjson -e 'puts JSON.parse(File.read("/tmp/login.json"))["access_token"]')
curl -s http://localhost:3000/api/v1/auth/me \
  -H "Authorization: Bearer $TOKEN"
```

---

## Matrimony profile onboarding

After register, complete profile steps (JWT required), then DigiLocker:

1. `PUT /api/v1/profile/basic`
2. `PUT /api/v1/profile/family`
3. `PUT /api/v1/profile/career`
4. `PUT /api/v1/profile/location`
5. `PUT /api/v1/profile/partner` → `profile_completed=true`, `signup_step=digilocker`
6. DigiLocker mock/verify → `status=active`; if profile done → `signup_step=done`

`GET /api/v1/profile` and `GET /api/v1/auth/me` return nested `profile` + `onboarding_required`.

Product-ready when `onboarding_required=false` (profile completed **and** DigiLocker verified).

### Update profile (member Profile screen)

`PUT /api/v1/profile/update` — partial edit after onboarding. Does **not** advance `signup_step`.

**Request** (send only fields/sections you want to change):
```json
{
  "full_name": "Updated Name",
  "phone": "9876543210",
  "email": "user@example.com",
  "basic": { "about_me": "Hello", "mother_tongue": "Tamil", "height_cm": 165 },
  "family": { "family_type": "nuclear", "native_place": "Madurai" },
  "career": { "occupation": "Engineer", "employed_in": "private" },
  "location": { "country": "India", "state": "Tamil Nadu", "city": "Madurai" },
  "partner": { "age_min": 25, "age_max": 32, "religions": ["Hindu"] }
}
```

**Response `200`**: `{ user, profile, profile_card }` (same shape as `GET /api/v1/profile`).

Onboarding step endpoints (`PUT /api/v1/profile/basic` … `/partner`) remain for signup.

## API contract (Flutter)

Base URL (dev): `http://localhost:3000`

All JSON. Auth header: `Authorization: Bearer <access_token>`.

### POST `/api/v1/auth/register`

**Request**
```json
{
  "email": "user@example.com",
  "password": "Password1",
  "password_confirmation": "Password1",
  "full_name": "Ada Lovelace",
  "phone": "+919876543210"
}
```

**Response `201`**
```json
{
  "user": {
    "id": 1,
    "email": "user@example.com",
    "full_name": "Ada Lovelace",
    "phone": "+919876543210",
    "status": "pending_verification",
    "digilocker_verified": false,
    "digilocker_verified_at": null,
    "digilocker_id": null,
    "verification_required": true,
    "created_at": "2025-11-02T10:00:00.000Z",
    "updated_at": "2025-11-02T10:00:00.000Z"
  },
  "access_token": "<jwt>",
  "token_type": "Bearer",
  "expires_in": 86400,
  "verification_required": true,
  "digilocker": {
    "authorize_url": "http://localhost:3000/api/v1/digilocker/callback?code=mock-code&state=...&format=json",
    "state": "abc123"
  }
}
```

Password rules: min 8 chars, at least one uppercase, one lowercase, one digit.

### POST `/api/v1/auth/login`

**Request**
```json
{ "email": "user@example.com", "password": "Password1" }
```

**Response `200`**
```json
{
  "access_token": "<jwt>",
  "token_type": "Bearer",
  "expires_in": 86400,
  "verification_required": true,
  "user": { "id": 1, "status": "pending_verification", "verification_required": true }
}
```

Errors: `401` invalid credentials, `403` suspended.

### GET `/api/v1/auth/me`

**Headers:** `Authorization: Bearer <jwt>`

**Response `200`**
```json
{ "user": { "id": 1, "email": "user@example.com", "status": "active" } }
```

### POST `/api/v1/auth/logout`

**Headers:** `Authorization: Bearer <jwt>`

Invalidates the current token (rotates `jti`).

**Response `200`**
```json
{ "message": "Logged out" }
```

### GET `/api/v1/digilocker/authorize`

Auth optional. Pass Bearer **or** `?user_id=` **or** `?registration_token=<jwt>`.

**Response `200`**
```json
{
  "authorize_url": "https://digilocker.../authorize?...&state=...",
  "state": "abc123"
}
```

With `DIGILOCKER_MOCK=true`, `authorize_url` points at this API’s callback with `format=json` so Flutter/local tools can complete verification without MeitY credentials.

### GET `/api/v1/digilocker/callback?code=&state=`

DigiLocker redirects here. Default: **302** to:

- success: `ninetiesmatch://digilocker/success?status=ok`
- failure: `ninetiesmatch://digilocker/failure?reason=...`

Add `format=json` for test/mock:

**Response `200`**
```json
{
  "status": "ok",
  "user": { "id": 1, "status": "active", "digilocker_verified": true },
  "access_token": "<jwt>",
  "token_type": "Bearer",
  "expires_in": 86400,
  "verification_required": false
}
```

### GET `/api/v1/digilocker/status`

**Headers:** `Authorization: Bearer <jwt>`

**Response `200`**
```json
{
  "verified": true,
  "verified_at": "2025-11-02T10:05:00.000Z",
  "digilocker_id": "************abcd",
  "status": "active"
}
```

## Tests

```bash
bundle exec rspec
```


## Staff admin APIs (Phase 1)

Used by the separate Next.js app `mouleetech-90-match-admin`.

| Method | Path | Notes |
|--------|------|-------|
| POST | `/api/v1/admin/auth/login` | `{ username, password }` — no DigiLocker |
| GET | `/api/v1/admin/dashboard` | Staff Bearer JWT |
| GET | `/api/v1/admin/users` | Members list |
| GET | `/api/v1/admin/users/:id` | Member detail |
| GET | `/api/v1/admin/digilocker_sessions` | Member KYC sessions |

Seed staff: username `admin` / password `Password1`

## Out of scope (for now)

- Flutter UI
- Production DigiLocker credentials
- Game score APIs
