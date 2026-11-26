# TestDZ-V2-Runner

A separate, disposable GitHub Actions runner for verifying one immutable, curated TestDZ V2 candidate. This repository is a test harness only; it is not the TestDZ application and does not replace the official TestDZ repository.

## Current candidate

- TestDZ repository: `laidktif67-sketch/TestDZ`
- Pinned candidate commit: `9d802376a0bb675b46c3811a5a1ab7206fe407ca`
- Candidate integration series: PR #150 (Algerian day boundary), PR #151 (notification lifecycle), PR #152 (Support privacy and developer feedback replies), and PR #153 (developer monitoring, role-explicit Support, and invitations).
- Expected SQL migrations: 26 (001–021, then 030–034). Migrations 022–029 remain intentionally excluded pending separate dependency/security review.
- Post-migration V2 contracts: 13 explicitly listed scripts, including aggregate-monitoring privacy, role-explicit Support ticket creation, and invitation lifecycle. The phase-one `security_contract.sql` is run immediately after migration 006.
- Frontend RPC verification: retains the 46-function curated V2 frontend RPC contract, exact named-argument checks, role-boundary checks, PostgREST exposure checks, and per-user isolation checks for session/security activity.
- Privacy guard: aggregate monitoring metrics and daily activity are both suppressed below three distinct testers.
- Edge Function checks: notification dispatcher and developer invitations.

## Safety model

- This repository is public. Never commit credentials, access tokens, Supabase keys, database URLs, or production data here.
- The workflow is manual-only (`workflow_dispatch`). It does not run for pushes or pull requests.
- The workflow checks out the exact TestDZ commit above and verifies the checked-out SHA before running tests.
- It starts a disposable local Supabase stack on a GitHub-hosted Ubuntu runner. It does not connect to the user's Supabase project.
- The workflow requests read-only repository contents access. It does not write to TestDZ, run production migrations, or deploy the app.
- The database job stops the local Supabase stack even when a test fails.
- A green run is evidence only for this pinned candidate and the checks listed here. It is not a full end-to-end test of every page or every RPC with realistic records, and it does not approve production cutover or deployment.

## One-time setup: private TestDZ read access

The TestDZ source repository is private, so GitHub Actions needs a narrowly scoped token to clone it.

1. In GitHub, open **Settings → Developer settings → Personal access tokens → Fine-grained tokens**.
2. Generate a token with **Resource owner** set to your account.
3. Under **Repository access**, choose **Only select repositories**, then select `TestDZ` only.
4. Under **Repository permissions**, set **Contents: Read-only**. Do not grant write, administration, secrets, actions, or workflow permissions.
5. Create the token. Copy it once; do not paste it into chat, a file, an issue, or a commit.
6. Open this repository's **Settings → Secrets and variables → Actions → New repository secret**.
7. Set the name to exactly `TESTDZ_READ_TOKEN`, paste the token as its value, and save.

If GitHub does not let the token read the private repository, check whether the account's organization or repository policy requires approval. Do not broaden permissions to write access.

## Start the verification

After the secret is saved:

1. Open **Actions**.
2. Select **TestDZ V2 isolated verification**.
3. Press **Run workflow** and select branch `integration/runner-v2-candidate-9e28de2`.

The workflow has two jobs:

- **Database contracts:** apply all 26 pinned V2 SQL migrations to a fresh local Supabase database; run the phase-one security contract and the 13 explicitly listed post-migration contracts; then run the Runner's frontend RPC contract and representative PostgREST role/identity-isolation checks.
- **Notification Edge Function:** type-check `supabase/functions/dispatch-notifications/index.ts` and `supabase/functions/developer-invitations/index.ts` with the pinned Deno version.

## If the workflow fails

Open the failed job and share the run URL and failing step name. Do not share secret values, generated keys, database URLs, or token-bearing logs.

## Scope discipline

Do not add migrations 022–032, legacy PR contracts, PR #117 cohort-transition tests, catalog fingerprint probes, or other old branch artifacts to this runner without a separate dependency review and an explicit decision to include them. Do not change the pinned candidate merely because another branch exists; update the pin only after its exact commit and CI evidence are verified.
