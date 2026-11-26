-- Frontend RPC surface contract for the curated TestDZ V2 candidate through PR #155.
-- Run only against the disposable local Supabase database created by the Runner workflow.
-- Migrations 022-029 are intentionally excluded; selected migrations 030-032 add six curated RPCs.
BEGIN;

CREATE TEMP TABLE expected_frontend_rpc (
  function_name text PRIMARY KEY,
  argument_names text[] NOT NULL
) ON COMMIT DROP;

INSERT INTO expected_frontend_rpc(function_name, argument_names) VALUES
('add_support_attachment', ARRAY['p_ticket_id','p_message_id','p_storage_path','p_original_filename','p_mime_type','p_size_bytes']),
('admin_grant_role', ARRAY['p_user_id','p_role','p_reason']),
('admin_list_pending_role_requests', ARRAY[]::text[]),
('admin_review_role_request', ARRAY['p_request_id','p_decision','p_review_note']),
('archive_app', ARRAY['p_app_id']),
('complete_onboarding', ARRAY['p_roles','p_interests']),
('create_app', ARRAY['p_name','p_package_name','p_description','p_category']),
('create_assignment_submission', ARRAY['p_assignment_id','p_summary','p_comments']),
('create_support_ticket', ARRAY['p_subject','p_category','p_priority','p_description']),
('create_support_ticket_for_role', ARRAY['p_requester_role','p_subject','p_category','p_priority','p_description']),
('create_test', ARRAY['p_app_id','p_title','p_description','p_short_summary','p_test_type','p_min_testers','p_start_date','p_end_date','p_duration','p_instructions']),
('create_test_with_config', ARRAY['p_app_id','p_title','p_description','p_short_summary','p_test_type','p_min_testers','p_start_date','p_end_date','p_duration','p_instructions','p_test_config']),
('create_test_invitation', ARRAY['p_test_id','p_recipient_email','p_token_hash','p_expires_at','p_idempotency_key']),
('create_test_cohort', ARRAY['p_test_id','p_name','p_capacity','p_starts_at','p_ends_at']),
('finalize_assignment_submission', ARRAY['p_submission_id']),
('finalize_test_asset', ARRAY['p_asset_id']),
('finalize_test_build', ARRAY['p_build_id']),
('get_app_limit', ARRAY[]::text[]),
('get_developer_feedback', ARRAY[]::text[]),
('get_developer_feedback_messages', ARRAY['p_feedback_id']),
('get_developer_test_monitoring', ARRAY['p_test_id']),
('get_discoverable_tests', ARRAY[]::text[]),
('get_my_active_sessions', ARRAY[]::text[]),
('get_my_security_activity', ARRAY['p_limit']),
('get_tester_feedback_messages', ARRAY[]::text[]),
('join_test', ARRAY['p_test_id']),
('list_test_invitations', ARRAY['p_test_id']),
('mark_all_notifications_read', ARRAY['p_recipient_role']),
('mark_notification_read', ARRAY['p_notification_id','p_recipient_role']),
('register_assignment_submission_attachment', ARRAY['p_submission_id','p_file_id','p_extension','p_original_filename','p_mime_type','p_size_bytes']),
('register_test_asset', ARRAY['p_test_id','p_file_id','p_title','p_original_filename','p_mime_type','p_size_bytes']),
('register_test_build', ARRAY['p_test_id','p_file_id','p_version_label','p_original_filename','p_size_bytes','p_sha256']),
('restore_app', ARRAY['p_app_id']),
('revoke_test_invitation', ARRAY['p_invitation_id','p_reason']),
('review_app', ARRAY['p_app_id','p_decision','p_reason']),
('redeem_test_invitation', ARRAY['p_token_hash']),
('review_test', ARRAY['p_test_id','p_decision','p_reason']),
('save_test_content', ARRAY['p_test_id','p_steps','p_requirements']),
('send_developer_feedback_message', ARRAY['p_feedback_id','p_body']),
('send_support_message', ARRAY['p_ticket_id','p_body']),
('start_assignment', ARRAY['p_assignment_id']),
('submit_app_for_review', ARRAY['p_app_id']),
('submit_checkin', ARRAY['p_assignment_id','p_note']),
('submit_tester_feedback', ARRAY['p_assignment_id','p_category','p_body','p_rating']),
('submit_test_for_review', ARRAY['p_test_id']),
('transition_test_cohort', ARRAY['p_cohort_id','p_new_status','p_reason']),
('update_app', ARRAY['p_app_id','p_name','p_description','p_category','p_icon_url']),
('update_developer_feedback_review', ARRAY['p_feedback_id','p_status','p_priority','p_resolution_note']),
('update_support_ticket', ARRAY['p_ticket_id','p_status','p_priority','p_reason']),
('update_test', ARRAY['p_test_id','p_title','p_description','p_short_summary','p_test_type','p_min_testers','p_start_date','p_end_date','p_duration','p_instructions']),
('update_test_cohort', ARRAY['p_cohort_id','p_name','p_capacity','p_starts_at','p_ends_at','p_reason']);

DO $contract$
DECLARE
  v_expected record;
  v_oid oid;
  v_actual_names text[];
  v_checked integer := 0;
BEGIN
  IF (SELECT count(*) FROM expected_frontend_rpc) <> 51 THEN
    RAISE EXCEPTION 'Expected 51 unique frontend RPC functions; fixture contains %',
      (SELECT count(*) FROM expected_frontend_rpc);
  END IF;

  FOR v_expected IN SELECT * FROM expected_frontend_rpc ORDER BY function_name LOOP
    SELECT p.oid, COALESCE(p.proargnames[1:p.pronargs], ARRAY[]::text[])
      INTO v_oid, v_actual_names
    FROM pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'rebuild_v2'
      AND p.proname = v_expected.function_name
      AND p.prokind = 'f'
      AND p.pronargs = cardinality(v_expected.argument_names);

    IF NOT FOUND THEN
      RAISE EXCEPTION 'Frontend RPC missing or wrong argument count: rebuild_v2.%', v_expected.function_name;
    END IF;

    IF v_actual_names IS DISTINCT FROM v_expected.argument_names THEN
      RAISE EXCEPTION 'RPC argument-name mismatch for rebuild_v2.%: expected %, actual %',
        v_expected.function_name, v_expected.argument_names, v_actual_names;
    END IF;

    IF has_function_privilege('anon', v_oid, 'EXECUTE') THEN
      RAISE EXCEPTION 'Anonymous role must not execute rebuild_v2.%', v_expected.function_name;
    END IF;

    IF NOT has_function_privilege('authenticated', v_oid, 'EXECUTE') THEN
      RAISE EXCEPTION 'Authenticated role lacks EXECUTE on rebuild_v2.%', v_expected.function_name;
    END IF;

    v_checked := v_checked + 1;
  END LOOP;

  RAISE NOTICE 'PASS: % rebuild_v2 frontend RPC functions exist with exact named arguments and authenticated-only EXECUTE grants.', v_checked;
END;
$contract$;

-- Verify the private implementations independently from their public wrappers.
DO $identity_impl_contract$
DECLARE
  v_expected record;
  v_oid oid;
  v_checked integer := 0;
BEGIN
  FOR v_expected IN
    SELECT * FROM (VALUES
      ('get_my_active_sessions_impl'::text, 0),
      ('get_my_security_activity_impl'::text, 1)
    ) AS impl(function_name, argument_count)
  LOOP
    SELECT p.oid INTO v_oid
    FROM pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'rebuild_v2_private'
      AND p.proname = v_expected.function_name
      AND p.prokind = 'f'
      AND p.pronargs = v_expected.argument_count;

    IF NOT FOUND THEN
      RAISE EXCEPTION 'Identity implementation missing or has wrong signature: rebuild_v2_private.%', v_expected.function_name;
    END IF;

    IF has_function_privilege('anon', v_oid, 'EXECUTE') THEN
      RAISE EXCEPTION 'Anonymous role must not execute rebuild_v2_private.%', v_expected.function_name;
    END IF;

    IF NOT has_function_privilege('authenticated', v_oid, 'EXECUTE') THEN
      RAISE EXCEPTION 'Authenticated role lacks EXECUTE on rebuild_v2_private.%', v_expected.function_name;
    END IF;

    v_checked := v_checked + 1;
  END LOOP;

  IF has_schema_privilege('anon', 'rebuild_v2', 'USAGE')
     OR has_schema_privilege('anon', 'rebuild_v2_private', 'USAGE') THEN
    RAISE EXCEPTION 'Anonymous role must not have USAGE on rebuild_v2 or rebuild_v2_private';
  END IF;

  IF NOT has_schema_privilege('authenticated', 'rebuild_v2', 'USAGE')
     OR NOT has_schema_privilege('authenticated', 'rebuild_v2_private', 'USAGE') THEN
    RAISE EXCEPTION 'Authenticated role must have USAGE on rebuild_v2 and rebuild_v2_private';
  END IF;

  RAISE NOTICE 'PASS: % private identity implementations have authenticated-only EXECUTE; schema USAGE is denied to anon and granted to authenticated.', v_checked;
END;
$identity_impl_contract$;

ROLLBACK;
