#!/usr/bin/env bash
set -euo pipefail

: "${DB_URL:?DB_URL is required}"
: "${API_URL:?API_URL is required}"
: "${ANON_KEY:?ANON_KEY is required}"
: "${JWT_SECRET:?JWT_SECRET is required}"

psql "$DB_URL" -X -v ON_ERROR_STOP=1 -f "$GITHUB_WORKSPACE/Runner/tests/frontend_rpc_contract.sql"

ids=(
  "61000000-0000-4000-8000-000000000001"
  "61000000-0000-4000-8000-000000000002"
  "61000000-0000-4000-8000-000000000003"
  "61000000-0000-4000-8000-000000000004"
  "61000000-0000-4000-8000-000000000005"
)

cleanup() {
  psql "$DB_URL" -X -v ON_ERROR_STOP=1 <<'SQL'
BEGIN;

-- The legacy Auth bootstrap still creates public.wallets as well as V2 wallets.
-- Delete both explicitly; public.wallets also RESTRICTs deletion of public.profiles.
DELETE FROM public.wallets
WHERE user_id IN (
  '61000000-0000-4000-8000-000000000001',
  '61000000-0000-4000-8000-000000000002',
  '61000000-0000-4000-8000-000000000003',
  '61000000-0000-4000-8000-000000000004',
  '61000000-0000-4000-8000-000000000005'
);

DELETE FROM rebuild_v2.wallets
WHERE user_id IN (
  '61000000-0000-4000-8000-000000000001',
  '61000000-0000-4000-8000-000000000002',
  '61000000-0000-4000-8000-000000000003',
  '61000000-0000-4000-8000-000000000004',
  '61000000-0000-4000-8000-000000000005'
);

DELETE FROM auth.users
WHERE id IN (
  '61000000-0000-4000-8000-000000000001',
  '61000000-0000-4000-8000-000000000002',
  '61000000-0000-4000-8000-000000000003',
  '61000000-0000-4000-8000-000000000004',
  '61000000-0000-4000-8000-000000000005'
);

DO $cleanup$
BEGIN
  IF EXISTS (
    SELECT 1 FROM auth.users
    WHERE id IN (
      '61000000-0000-4000-8000-000000000001',
      '61000000-0000-4000-8000-000000000002',
      '61000000-0000-4000-8000-000000000003',
      '61000000-0000-4000-8000-000000000004',
      '61000000-0000-4000-8000-000000000005'
    )
  ) OR EXISTS (
    SELECT 1 FROM rebuild_v2.profiles
    WHERE id IN (
      '61000000-0000-4000-8000-000000000001',
      '61000000-0000-4000-8000-000000000002',
      '61000000-0000-4000-8000-000000000003',
      '61000000-0000-4000-8000-000000000004',
      '61000000-0000-4000-8000-000000000005'
    )
  ) OR EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id IN (
      '61000000-0000-4000-8000-000000000001',
      '61000000-0000-4000-8000-000000000002',
      '61000000-0000-4000-8000-000000000003',
      '61000000-0000-4000-8000-000000000004',
      '61000000-0000-4000-8000-000000000005'
    )
  ) OR EXISTS (
    SELECT 1 FROM public.user_roles
    WHERE user_id IN (
      '61000000-0000-4000-8000-000000000001',
      '61000000-0000-4000-8000-000000000002',
      '61000000-0000-4000-8000-000000000003',
      '61000000-0000-4000-8000-000000000004',
      '61000000-0000-4000-8000-000000000005'
    )
  ) OR EXISTS (
    SELECT 1 FROM rebuild_v2.user_roles
    WHERE user_id IN (
      '61000000-0000-4000-8000-000000000001',
      '61000000-0000-4000-8000-000000000002',
      '61000000-0000-4000-8000-000000000003',
      '61000000-0000-4000-8000-000000000004',
      '61000000-0000-4000-8000-000000000005'
    )
  ) OR EXISTS (
    SELECT 1 FROM public.wallets
    WHERE user_id IN (
      '61000000-0000-4000-8000-000000000001',
      '61000000-0000-4000-8000-000000000002',
      '61000000-0000-4000-8000-000000000003',
      '61000000-0000-4000-8000-000000000004',
      '61000000-0000-4000-8000-000000000005'
    )
  ) OR EXISTS (
    SELECT 1 FROM rebuild_v2.wallets
    WHERE user_id IN (
      '61000000-0000-4000-8000-000000000001',
      '61000000-0000-4000-8000-000000000002',
      '61000000-0000-4000-8000-000000000003',
      '61000000-0000-4000-8000-000000000004',
      '61000000-0000-4000-8000-000000000005'
    )
  ) THEN
    RAISE EXCEPTION 'Synthetic frontend RPC test identities were not fully cleaned up';
  END IF;
END;
$cleanup$;

COMMIT;
SQL
}
trap cleanup EXIT

psql "$DB_URL" -X -v ON_ERROR_STOP=1 <<'SQL'
INSERT INTO auth.users
  (id,aud,role,email,encrypted_password,email_confirmed_at,raw_app_meta_data,raw_user_meta_data,created_at,updated_at)
VALUES
  ('61000000-0000-4000-8000-000000000001','authenticated','authenticated','rpc-tester@example.invalid','',now(),'{ "provider":"email","providers":["email"] }'::jsonb,'{"name":"RPC Tester"}'::jsonb,now(),now()),
  ('61000000-0000-4000-8000-000000000002','authenticated','authenticated','rpc-developer@example.invalid','',now(),'{ "provider":"email","providers":["email"] }'::jsonb,'{"name":"RPC Developer"}'::jsonb,now(),now()),
  ('61000000-0000-4000-8000-000000000003','authenticated','authenticated','rpc-admin@example.invalid','',now(),'{ "provider":"email","providers":["email"] }'::jsonb,'{"name":"RPC Admin"}'::jsonb,now(),now()),
  ('61000000-0000-4000-8000-000000000004','authenticated','authenticated','rpc-financial@example.invalid','',now(),'{ "provider":"email","providers":["email"] }'::jsonb,'{"name":"RPC Financial"}'::jsonb,now(),now()),
  ('61000000-0000-4000-8000-000000000005','authenticated','authenticated','rpc-support@example.invalid','',now(),'{ "provider":"email","providers":["email"] }'::jsonb,'{"name":"RPC Support"}'::jsonb,now(),now())
ON CONFLICT (id) DO NOTHING;

DELETE FROM rebuild_v2.user_roles
WHERE user_id IN (
  '61000000-0000-4000-8000-000000000001',
  '61000000-0000-4000-8000-000000000002',
  '61000000-0000-4000-8000-000000000003',
  '61000000-0000-4000-8000-000000000004',
  '61000000-0000-4000-8000-000000000005'
);

INSERT INTO rebuild_v2.user_roles(user_id,role) VALUES
  ('61000000-0000-4000-8000-000000000001','tester'),
  ('61000000-0000-4000-8000-000000000002','developer'),
  ('61000000-0000-4000-8000-000000000003','admin'),
  ('61000000-0000-4000-8000-000000000004','financial'),
  ('61000000-0000-4000-8000-000000000005','support');
SQL

jwt_for() {
  python3 - "$1" "$JWT_SECRET" <<'PY'
import base64, hashlib, hmac, json, sys, time
sub, secret = sys.argv[1], sys.argv[2]
def b64(value):
    return base64.urlsafe_b64encode(value).rstrip(b"=").decode()
header = b64(json.dumps({"alg":"HS256","typ":"JWT"},separators=(",",":")).encode())
payload = b64(json.dumps({
    "aud":"authenticated","role":"authenticated","sub":sub,
    "iat":int(time.time()),"exp":int(time.time())+300
},separators=(",",":")).encode())
signing = f"{header}.{payload}".encode()
signature = hmac.new(secret.encode(),signing,hashlib.sha256).digest()
print(f"{header}.{payload}.{b64(signature)}")
PY
}

request_status() {
  local token="$1" method="$2" path="$3" profile_header="$4" body="$5"
  local output="$RUNNER_TEMP/rpc-role-response.json"
  local -a headers
  headers=(-H "apikey: $ANON_KEY" -H "Authorization: Bearer $token")
  if [[ "$profile_header" == "content" ]]; then
    headers+=(-H "Content-Profile: rebuild_v2")
  elif [[ "$profile_header" == "accept" ]]; then
    headers+=(-H "Accept-Profile: rebuild_v2")
  elif [[ "$profile_header" == "public" ]]; then
    headers+=(-H "Content-Profile: public")
  fi
  if [[ "$method" == "POST" ]]; then
    headers+=(-H "Content-Type: application/json")
    curl --silent --show-error --output "$output" --write-out "%{http_code}" \
      -X POST "${headers[@]}" "$API_URL/rest/v1/$path" --data "$body"
  else
    curl --silent --show-error --output "$output" --write-out "%{http_code}" \
      "${headers[@]}" "$API_URL/rest/v1/$path"
  fi
}

expect_status() {
  local expected="$1" actual="$2" label="$3"
  if [[ "$actual" != "$expected" ]]; then
    echo "::error::$label expected HTTP $expected, received $actual"
    cat "$RUNNER_TEMP/rpc-role-response.json"
    exit 1
  fi
  echo "PASS: $label (HTTP $actual)"
}

tester_jwt="$(jwt_for "${ids[0]}")"
developer_jwt="$(jwt_for "${ids[1]}")"
admin_jwt="$(jwt_for "${ids[2]}")"
financial_jwt="$(jwt_for "${ids[3]}")"
support_jwt="$(jwt_for "${ids[4]}")"

# Positive role-specific routes.
status="$(request_status "$tester_jwt" POST "rpc/get_discoverable_tests" content '{}')"
expect_status 200 "$status" "Tester can call get_discoverable_tests"

status="$(request_status "$developer_jwt" POST "rpc/get_developer_feedback" content '{}')"
expect_status 200 "$status" "Developer can call get_developer_feedback"

status="$(request_status "$admin_jwt" POST "rpc/admin_list_pending_role_requests" content '{}')"
expect_status 200 "$status" "Admin can call admin_list_pending_role_requests"

status="$(request_status "$financial_jwt" GET "payments?select=id&limit=0" accept '')"
expect_status 200 "$status" "Financial role can read the payments surface"

status="$(request_status "$support_jwt" GET "support_tickets?select=id&limit=0" accept '')"
expect_status 200 "$status" "Support role can read the support ticket surface"

# Negative role boundaries: these must be rejected, not silently return data.
status="$(request_status "$tester_jwt" POST "rpc/admin_list_pending_role_requests" content '{}')"
expect_status 403 "$status" "Tester is denied the Admin role-request RPC"

status="$(request_status "$developer_jwt" POST "rpc/admin_list_pending_role_requests" content '{}')"
expect_status 403 "$status" "Developer is denied the Admin role-request RPC"

status="$(request_status "$financial_jwt" POST "rpc/admin_list_pending_role_requests" content '{}')"
expect_status 403 "$status" "Financial is denied the Admin role-request RPC"

status="$(request_status "$support_jwt" POST "rpc/admin_list_pending_role_requests" content '{}')"
expect_status 403 "$status" "Support is denied the Admin role-request RPC"

status="$(request_status "$admin_jwt" POST "rpc/get_developer_feedback" content '{}')"
expect_status 403 "$status" "Admin without Developer role is denied the Developer feedback RPC"

# The two identity security RPCs are still legacy public-schema functions.
# Their public calls must work; the V2 schema must not pretend to provide them yet.
status="$(request_status "$tester_jwt" POST "rpc/get_my_active_sessions" public '{}')"
expect_status 200 "$status" "Legacy public get_my_active_sessions is callable"

status="$(request_status "$tester_jwt" POST "rpc/get_my_security_activity" public '{"p_limit":30}')"
expect_status 200 "$status" "Legacy public get_my_security_activity is callable"

status="$(request_status "$tester_jwt" POST "rpc/get_my_active_sessions" content '{}')"
expect_status 404 "$status" "V2 get_my_active_sessions remains a documented migration gap"

status="$(request_status "$tester_jwt" POST "rpc/get_my_security_activity" content '{"p_limit":30}')"
expect_status 404 "$status" "V2 get_my_security_activity remains a documented migration gap"

# Verify that PostgREST exposes rebuild_v2 but not the private implementation schema.
status="$(request_status "$tester_jwt" GET "profiles?select=id&limit=0" accept '')"
expect_status 200 "$status" "PostgREST exposes rebuild_v2"

private_status="$(curl --silent --show-error --output "$RUNNER_TEMP/rpc-private-openapi.json" --write-out "%{http_code}" \
  -H "apikey: $ANON_KEY" -H "Authorization: Bearer $tester_jwt" \
  -H "Accept-Profile: rebuild_v2_private" -H "Accept: application/openapi+json" \
  "$API_URL/rest/v1/")"
if [[ "$private_status" != "406" ]]; then
  echo "::error::Private implementation schema should remain unexposed; received HTTP $private_status"
  cat "$RUNNER_TEMP/rpc-private-openapi.json"
  exit 1
fi
echo "PASS: rebuild_v2_private remains unexposed to PostgREST"

echo "PASS: all 47 frontend RPC names accounted for (45 V2 + 2 legacy public); 2 V2 route gaps are explicitly documented."
