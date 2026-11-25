-- Frontend RPC surface contract for TestDZ candidate d9e01eeb.
-- Run only against the disposable local Supabase database created by the Runner workflow.
BEGIN;

CREATE TEMP TABLE expected_frontend_rpc (
  function_name text PRIMARY KEY,
  argument_names text[] NOT NULL
) ON COMMIT DROP;

INSERT INTO expected_frontend_rpc(function_name, argument_names) VALUES
('admin_list_pending_role_requests', ARRAY[]::text[]),
('admin_review_role_request', ARRAY['p_request_id','p_decision','p_review_note']),
('admin_grant_role', ARRAY['p_user_id','p_role','p_reason']),
('get_app_limit', ARRAY[]::text[]),
('get_my_active_sessions', ARRAY[]::text[]),
('get_my_security_activity', ARRAY['p_limit']),
('create_app', ARRAY['p_name','p_package_name','p_description','p_category']),
('update_app', ARRAY['p_app_id','p_name','p_description','p_category','p_icon_url']),
('archive_app', ARRAY['p_app_id']),
('restore_app', ARRAY['p_app_id']),
('get_developer_test_monitoring', ARRAY['p_test_id']),
('create_test', ARRAY['p_app_id','p_title','p_description','p_short_summary','p_test_type','p_min_testers','p_start_date','p_end_date','p_duration','p_instructions']),
('update_test', ARRAY['p_test_id','p_title','p_description','p_short_summary','p_test_type','p_min_testers','p_start_date','p_end_date','p_duration','p_instructions']),
('save_test_content', ARRAY['p_test_id','p_steps','p_requirements']),
('submit_test_for_review', ARRAY['p_test_id']),
('create_test_cohort', ARRAY['p_test_id','p_name','p_capacity','p_starts_at','p_ends_at']),
('update_test_cohort', ARRAY['p_cohort_id','p_name','p_capacity','p_starts_at','p_ends_at','p_reason']),
('transition_test_cohort', ARRAY['p_cohort_id','p_new_status','p_reason']),
('register_test_build', ARRAY['p_test_id','p_file_id','p_version_label','p_original_filename','p_size_bytes','p_sha256']),
('finalize_test_build', ARRAY['p_build_id']),
('register_test_asset', ARRAY['p_test_id','p_file_id','p_title','p_original_filename','p_mime_type','p_size_bytes']),
('finalize_test_asset', ARRAY['p_asset_id']),
('get_developer_feedback', ARRAY[]::text[]),
('update_developer_feedback_review', ARRAY['p_feedback_id','p_status','p_priority','p_resolution_note']),
('get_developer_feedback_messages', ARRAY['p_feedback_id']),
('send_developer_feedback_message', ARRAY['p_feedback_id','p_body']),
('submit_app_for_review', ARRAY['p_app_id']),
('review_app', ARRAY['p_app_id','p_decision','p_reason']),
('review_test', ARRAY['p_test_id','p_decision','p_reason']),
('create_test_with_config', ARRAY['p_app_id','p_title','p_description','p_short_summary','p_test_type','p_min_testers','p_start_date','p_end_date','p_duration','p_instructions','p_test_config']),
('mark_notification_read', ARRAY['p_notification_id','p_recipient_role']),
('mark_all_notifications_read', ARRAY['p_recipient_role']),
('complete_onboarding', ARRAY['p_roles','p_interests']),
('create_support_ticket', ARRAY['p_subject','p_category','p_priority','p_description']),
('create_support_ticket_for_role', ARRAY['p_requester_role','p_subject','p_category','p_priority','p_description']),
('send_support_message', ARRAY['p_ticket_id','p_body']),
('add_support_attachment', ARRAY['p_ticket_id','p_message_id','p_storage_path','p_original_filename','p_mime_type','p_size_bytes']),
('update_support_ticket', ARRAY['p_ticket_id','p_status','p_priority','p_reason']),
('get_tester_feedback_messages', ARRAY[]::text[]),
('start_assignment', ARRAY['p_assignment_id']),
('submit_checkin', ARRAY['p_assignment_id','p_note']),
('create_assignment_submission', ARRAY['p_assignment_id','p_summary','p_comments']),
('register_assignment_submission_attachment', ARRAY['p_submission_id','p_file_id','p_extension','p_original_filename','p_mime_type','p_size_bytes']),
('finalize_assignment_submission', ARRAY['p_submission_id']),
('get_discoverable_tests', ARRAY[]::text[]),
('submit_tester_feedback', ARRAY['p_assignment_id','p_category','p_body','p_rating']),
('join_test', ARRAY['p_test_id']);

DO $contract$
DECLARE
  v_expected record;
  v_oid oid;
  v_actual_names text[];
  v_checked integer := 0;
BEGIN
  IF (SELECT count(*) FROM expected_frontend_rpc) <> 47 THEN
    RAISE EXCEPTION 'Expected 47 unique frontend RPC functions; fixture contains %',
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

-- Both identity security RPCs are part of the V2 frontend contract.
-- Runtime isolation is exercised through PostgREST in the companion shell test.

ROLLBACK;
