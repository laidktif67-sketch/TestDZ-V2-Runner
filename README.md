# TestDZ-V2-Runner

A separate, disposable GitHub Actions runner for verifying the TestDZ V2 database rebuild against one immutable candidate commit.

## Safety model

- This repository is public. Never commit credentials, access tokens, Supabase keys, database URLs, or production data here.
- The workflow is manual-only (`workflow_dispatch`). It does not run for pushes or pull requests.
- It checks out only TestDZ commit `d9e01eeb7d6a23a6491241a8f6cfd22d0266193a`.
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
- Apply the 34 V2 SQL files to a fresh local Supabase database and execute the listed SQL contracts (including the phase-one security contract).
- Type-check the notification and developer-invitation Edge Functions with the pinned Deno version.

A green run is evidence only for this exact candidate commit and these checks. It does not cover the separate PR #117 cohort-transition contract, production deployment, frontend runtime behavior, or a full end-to-end application test. Those remain separate verification gates.

## If the workflow fails

Open the failed job and share the run URL and failing step name. Do not share secret values, generated keys, database URLs, or token-bearing logs.
