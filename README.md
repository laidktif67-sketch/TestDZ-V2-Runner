# TestDZ-V2-Runner

A separate, disposable GitHub Actions runner for verifying the TestDZ V2 database rebuild against one immutable candidate commit.

## Safety model

- This repository is public. Never commit credentials, access tokens, Supabase keys, database URLs, or production data here.
- The workflow is manual-only (`workflow_dispatch`). It does not run for pushes or pull requests.
- It checks out TestDZ candidate commit `d9e01eeb7d6a23a6491241a8f6cfd22d0266193a` and separately fetches only the PR #117 cohort contract from exact commit `b99d846a455549b468a8a1624fe3dbd1f7db1ee2`.
- It starts a disposable local Supabase stack on a GitHub-hosted Ubuntu runner. It does not connect to the user's Supabase project.
- The workflow requests read-only repository contents access. It does not write to TestDZ, run production migrations, or deploy the app.
- The database job stops the local Supabase stack even when a test fails.

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
3. Press **Run workflow**, choose `main`, and confirm.

The workflow has two jobs:

- **Database and integration contracts:** apply all 34 V2 SQL files to a fresh local Supabase database; run 31 post-migration SQL contracts plus the phase-one security contract; include the PR #117 cohort-transition test from its exact reviewed SHA; verify all 47 unique frontend RPC names across 51 call sites: 45 functions in `rebuild_v2` plus two legacy-only identity functions in `public`; check exact named arguments and authenticated-versus-anonymous grants; exercise representative PostgREST calls and role boundaries for Tester, Developer, Admin, Financial, and Support; and verify cleanup of synthetic identities, profiles, roles, and wallets in both `public` and `rebuild_v2`. The PostgREST smoke checks also confirm that `rebuild_v2` is exposed and `rebuild_v2_private` is not. The two legacy-only identity functions (`get_my_active_sessions`, `get_my_security_activity`) are explicitly tested in `public` and recorded as a V2 cutover blocker: the frontend currently calls them through `getAppDataClient`, which routes to `rebuild_v2` when the V2 flag is enabled.
- **Edge Function type-check:** type-check the notification and developer-invitation functions with the pinned Deno version.

A green run is evidence only for the pinned candidate and the listed checks. It is not a complete end-to-end test of every frontend page or every RPC with realistic records, does not compare candidate data with production, and does not approve a production cutover or deployment.

## If the workflow fails

Open the failed job and share the run URL and failing step name. Do not share secret values, generated keys, database URLs, or token-bearing logs.
