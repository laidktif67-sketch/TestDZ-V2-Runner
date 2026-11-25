# Wallet & Ledger Integrity — Execution Blocker Report

**Status:** BLOCKED — static review only; no wallet test SQL has been created or executed.  
**Runner repository:** `laidktif67-sketch/TestDZ-V2-Runner`  
**Working branch:** `test/wallet-ledger-integrity-d9e01ee`  
**Runner base commit:** `c4d86fa2c09fd4badadd8c8c2a25dc2a22cec21f`  
**Pinned TestDZ candidate:** `d9e01eeb7d6a23a6491241a8f6cfd22d0266193a`

## 1. Scope and safety boundary

This review is limited to the Runner repository and the immutable TestDZ candidate above. The candidate files were read through GitHub at the exact SHA; no TestDZ file, database, migration, deployment, production secret, or production credential was changed or used.

The new branch was created from the existing Run #7 runner branch because that branch is eight commits ahead of Runner `main` and contains the later Run #7 fixes. No work was performed on `main`.

The existing Runner workflow is manual-only (`workflow_dispatch`), checks out the TestDZ candidate by its exact SHA, and uses a narrowly scoped read-only repository token to fetch the private source. It does not require production Supabase credentials. This new branch has not been dispatched.

## 2. Exact candidate evidence reviewed

| Candidate file | Git blob SHA |
|---|---|
| `supabase/rebuild-v2/001_schema.sql` | `17b58876315743e0e4f754c1a5891cbfd9d6d5b0` |
| `supabase/rebuild-v2/002_security.sql` | `fe3dde896a0f8b55675b72c5709726ad97d96416` |
| `supabase/rebuild-v2/tests/009_wallet_idempotency_contract.sql` | `586684b012046bf3180979e7cb9e76559d304bd6` |
| `supabase/rebuild-v2/tests/013_wallet_role_boundary_contract.sql` | `004bec08ee85887fc2a402861466e84b28015cce` |

## 3. Confirmed architectural blocker — reversal linkage is absent

### 3.1 Ledger schema

At the pinned candidate SHA, `rebuild_v2.wallet_ledger` contains:

- `id`, `user_id`, `wallet_type`, `amount`, `entry_type`
- `reference_type`, `reference_id`
- `idempotency_key`, `actor_id`, `reason`, `created_at`

It does **not** contain a `reversal_of` column.

There is no foreign key from a reversal to its exact original ledger row and no partial unique index limiting an original movement to one reversal.

The generic `reference_type/reference_id` pair is not an enforced original-ledger relationship in this schema.

### 3.2 Posting function

The candidate defines:

```sql
rebuild_v2_private.post_wallet_entry(
  p_user_id uuid,
  p_wallet_type text,
  p_amount bigint,
  p_entry_type text,
  p_idempotency_key text,
  p_reason text,
  p_reference_type text DEFAULT NULL,
  p_reference_id uuid DEFAULT NULL
)
```

The function currently:

- permits `entry_type = 'reversal'`;
- validates idempotency-key reuse against the supplied user, wallet type, amount, entry type, generic reference fields, actor, and reason;
- locks the target wallet row;
- inserts the ledger row, updates the wallet balance, and inserts an audit event in the same function transaction.

However, it does not identify and lock a specific original ledger movement, validate the original user's identity or wallet type, enforce the exact opposite amount, reject reversal-of-reversal, or prevent a second reversal using a different idempotency key.

The wallet-row lock and idempotency key do not provide the accepted one-reversal-per-original invariant.

### 3.3 Existing tests do not close this gap

- `009_wallet_idempotency_contract.sql` covers same-key retries and several payload conflicts. It does not prove unique reversal linkage or reversal-of-reversal rejection.
- `013_wallet_role_boundary_contract.sql` covers direct client-write denial for `authenticated`, rejects Tester and Support posting, and permits Financial and Admin posting. It does not test the new reversal invariants, Developer, the effective `PUBLIC` ACL, anonymous direct writes, or the actual `service_role` privilege boundary.
- `002_security.sql` installs the immutable UPDATE/DELETE trigger on `wallet_ledger`, revokes direct table privileges from `PUBLIC`, `anon`, and `authenticated`, and grants the existing posting function to `authenticated`; the function itself checks Admin/Financial role membership. These definitions still require the separately approved runtime ACL tests.

## 4. Consequence for the approved test package

The REV contract cannot honestly be implemented against this candidate as it stands. Writing a test that passes `reference_id` as if it were an enforced original-ledger link would create a false positive. Inventing a new overload, argument name, column, index, trigger, or alternate reversal procedure in the Runner would also misrepresent the candidate and cross the agreed boundary.

Therefore:

- REV-01 through REV-09 are **BLOCKED** pending a separately reviewed V2 design that exposes and enforces an exact original-ledger relationship.
- REV-10 can only be accepted for reversal after the valid reversal path exists; the current function's general posting atomicity is not proof of reversal-specific atomicity.
- REV-11 and REV-12 have existing append-only protection, but still need independent runtime tests.
- BAL and ACL work could be developed separately, but the approved package is being held as a whole at this architecture gate rather than presenting a partial package as complete.
- No concurrency test will be written against generic references: without an original-row lock or uniqueness invariant, it cannot prove the agreed reversal guarantee.

## 5. Cleanup rule for the future Runner tests

The ledger's immutable trigger must not be disabled for cleanup. Future tests must:

1. clean up only synthetic records that can safely be removed;
2. query and record the final absence of synthetic identities, profiles, roles, wallets, ledger rows, and audit rows;
3. treat any failed absence check as a failed test run;
4. stop the disposable local Supabase stack and destroy the entire temporary database after checks.

A successful DELETE command alone is not cleanup evidence.

## 6. Required decision before implementation can resume

The V2 owner must separately review and implement the reversal data model and posting semantics in the V2 repository. That work is outside the present authorization and has not been attempted here.

At minimum, the reviewed V2 design must define:

- an exact, immutable link from each reversal to one original ledger row;
- a database-enforced maximum of one reversal per original;
- rejection of a reversal whose original is itself a reversal;
- original-row and wallet-row locking suitable for concurrent requests;
- complete idempotency comparison including the original movement;
- atomic ledger, wallet, and audit writes;
- explicit behavior for legacy movements without trustworthy linkage.

Only after a new immutable V2 candidate SHA includes that design can the Runner tests be authored against the actual interface and constraints.

## 7. Execution record

| Action | Status |
|---|---|
| Create isolated Runner branch | DONE |
| Pin reviewed TestDZ candidate SHA | DONE |
| Static review of wallet schema and posting function | DONE |
| Identify reversal architecture blocker | BLOCKED |
| Create REV/BAL/ACL SQL test files | NOT STARTED — intentionally stopped |
| Add two-session reversal concurrency script | NOT STARTED — blocked by missing reversal linkage |
| Modify TestDZ or V2 repository | NOT DONE |
| Connect to production database | NOT DONE |
| Run migration or deploy | NOT DONE |
| Merge to Runner `main` | NOT DONE |
| Run new workflow | NOT DONE |

**Final classification:** the Runner branch is prepared, but the new test package is not implemented or passed. This report records a real candidate-level blocker; it does not modify or waive the accepted wallet/ledger contract.
