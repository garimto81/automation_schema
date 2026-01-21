


SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;


CREATE SCHEMA IF NOT EXISTS "public";


ALTER SCHEMA "public" OWNER TO "pg_database_owner";


COMMENT ON SCHEMA "public" IS 'standard public schema';



CREATE TYPE "public"."aep_composition_category" AS ENUM (
    'chip_display',
    'payout',
    'event_info',
    'schedule',
    'staff',
    'player_info',
    'elimination',
    'transition',
    'other'
);


ALTER TYPE "public"."aep_composition_category" OWNER TO "postgres";


CREATE TYPE "public"."aep_transform_type" AS ENUM (
    'UPPER',
    'LOWER',
    'format_chips',
    'format_bbs',
    'format_currency',
    'format_date',
    'format_time',
    'format_percent',
    'format_number',
    'get_flag_path',
    'direct',
    'custom'
);


ALTER TYPE "public"."aep_transform_type" OWNER TO "postgres";


CREATE TYPE "public"."ante_type" AS ENUM (
    'NO_ANTE',
    'BB_ANTE_BB1ST',
    'BB_ANTE_BTN1ST',
    'ALL_ANTE',
    'DEAD_ANTE'
);


ALTER TYPE "public"."ante_type" OWNER TO "postgres";


CREATE TYPE "public"."bet_structure" AS ENUM (
    'NOLIMIT',
    'POTLIMIT',
    'LIMIT',
    'SPREAD_LIMIT'
);


ALTER TYPE "public"."bet_structure" OWNER TO "postgres";


CREATE TYPE "public"."cue_broadcast_status" AS ENUM (
    'draft',
    'scheduled',
    'preparing',
    'standby',
    'live',
    'break',
    'completed',
    'cancelled',
    'postponed'
);


ALTER TYPE "public"."cue_broadcast_status" OWNER TO "postgres";


CREATE TYPE "public"."cue_content_type" AS ENUM (
    'opening_sequence',
    'main',
    'sub',
    'virtual',
    'leaderboard',
    'break',
    'closing'
);


ALTER TYPE "public"."cue_content_type" OWNER TO "postgres";


CREATE TYPE "public"."cue_hand_rank" AS ENUM (
    'A',
    'B',
    'B-',
    'C',
    'SOFT'
);


ALTER TYPE "public"."cue_hand_rank" OWNER TO "postgres";


CREATE TYPE "public"."cue_item_status" AS ENUM (
    'draft',
    'pending',
    'ready',
    'standby',
    'on_air',
    'completed',
    'skipped',
    'failed',
    'cancelled'
);


ALTER TYPE "public"."cue_item_status" OWNER TO "postgres";


CREATE TYPE "public"."cue_item_type" AS ENUM (
    'intro',
    'location',
    'commentators',
    'broadcast_schedule',
    'event_info',
    'payouts',
    'chip_count',
    'mini_chip_table',
    'leaderboard',
    'chip_flow',
    'chip_comparison',
    'chips_in_play',
    'player_profile',
    'player_info',
    'elimination',
    'elimination_risk',
    'money_list',
    'hand_main',
    'hand_sub',
    'vpip',
    'blinds_info',
    'transition',
    'bumper',
    'sponsor',
    'custom'
);


ALTER TYPE "public"."cue_item_type" OWNER TO "postgres";


CREATE TYPE "public"."cue_render_status" AS ENUM (
    'pending',
    'queued',
    'rendering',
    'completed',
    'failed',
    'cancelled',
    'cached'
);


ALTER TYPE "public"."cue_render_status" OWNER TO "postgres";


CREATE TYPE "public"."cue_sheet_status" AS ENUM (
    'draft',
    'pending_review',
    'approved',
    'ready',
    'active',
    'paused',
    'completed',
    'archived'
);


ALTER TYPE "public"."cue_sheet_status" OWNER TO "postgres";


CREATE TYPE "public"."cue_sheet_type" AS ENUM (
    'pre_show',
    'main_show',
    'segment',
    'break',
    'post_show',
    'highlight',
    'emergency'
);


ALTER TYPE "public"."cue_sheet_type" OWNER TO "postgres";


CREATE TYPE "public"."cue_template_type" AS ENUM (
    'mini_chip_left',
    'mini_chip_right',
    'feature_table_chip',
    'mini_payouts',
    'elimination_risk',
    'current_stack',
    'eliminated',
    'money_list',
    'chips_in_play',
    'vpip',
    'chip_flow',
    'chip_comparison',
    'blinds',
    'player_profile',
    'custom'
);


ALTER TYPE "public"."cue_template_type" OWNER TO "postgres";


CREATE TYPE "public"."cue_trigger_type" AS ENUM (
    'manual',
    'scheduled',
    'auto',
    'api',
    'hotkey',
    'external'
);


ALTER TYPE "public"."cue_trigger_type" OWNER TO "postgres";


CREATE TYPE "public"."event_type" AS ENUM (
    'FOLD',
    'CHECK',
    'CALL',
    'BET',
    'RAISE',
    'ALL_IN',
    'BOARD_CARD',
    'ANTE',
    'BLIND',
    'STRADDLE',
    'BRING_IN',
    'MUCK',
    'SHOW',
    'WIN'
);


ALTER TYPE "public"."event_type" OWNER TO "postgres";


CREATE TYPE "public"."game_class" AS ENUM (
    'FLOP',
    'STUD',
    'DRAW',
    'MIXED'
);


ALTER TYPE "public"."game_class" OWNER TO "postgres";


CREATE TYPE "public"."game_variant" AS ENUM (
    'HOLDEM',
    'OMAHA',
    'OMAHA_HILO',
    'STUD',
    'STUD_HILO',
    'RAZZ',
    'DRAW',
    'MIXED'
);


ALTER TYPE "public"."game_variant" OWNER TO "postgres";


CREATE TYPE "public"."gfx_sync_status" AS ENUM (
    'pending',
    'synced',
    'updated',
    'failed',
    'archived'
);


ALTER TYPE "public"."gfx_sync_status" OWNER TO "postgres";


CREATE TYPE "public"."manual_image_type" AS ENUM (
    'profile',
    'thumbnail',
    'broadcast',
    'headshot',
    'action',
    'flag_overlay'
);


ALTER TYPE "public"."manual_image_type" OWNER TO "postgres";


CREATE TYPE "public"."manual_match_method" AS ENUM (
    'exact_name',
    'fuzzy_name',
    'manual',
    'wsop_id',
    'hendon_mob_id',
    'auto'
);


ALTER TYPE "public"."manual_match_method" OWNER TO "postgres";


CREATE TYPE "public"."manual_override_field" AS ENUM (
    'name',
    'name_korean',
    'name_display',
    'country_code',
    'country_name',
    'profile_image_url',
    'bio',
    'notable_wins',
    'social_links'
);


ALTER TYPE "public"."manual_override_field" OWNER TO "postgres";


CREATE TYPE "public"."orch_actor_type" AS ENUM (
    'user',
    'service',
    'system',
    'api',
    'scheduler'
);


ALTER TYPE "public"."orch_actor_type" OWNER TO "postgres";


CREATE TYPE "public"."orch_data_source" AS ENUM (
    'gfx',
    'wsop',
    'manual',
    'cuesheet',
    'external',
    'system'
);


ALTER TYPE "public"."orch_data_source" OWNER TO "postgres";


CREATE TYPE "public"."orch_job_status" AS ENUM (
    'pending',
    'queued',
    'running',
    'paused',
    'completed',
    'failed',
    'cancelled',
    'timeout'
);


ALTER TYPE "public"."orch_job_status" OWNER TO "postgres";


CREATE TYPE "public"."orch_job_type" AS ENUM (
    'sync_gfx',
    'sync_wsop',
    'sync_manual',
    'import_json',
    'import_csv',
    'export_data',
    'render_gfx',
    'render_batch',
    'process_hands',
    'grade_hands',
    'match_players',
    'cleanup',
    'backup',
    'archive'
);


ALTER TYPE "public"."orch_job_type" OWNER TO "postgres";


CREATE TYPE "public"."orch_notification_level" AS ENUM (
    'low',
    'medium',
    'high',
    'critical'
);


ALTER TYPE "public"."orch_notification_level" OWNER TO "postgres";


CREATE TYPE "public"."orch_notification_type" AS ENUM (
    'info',
    'success',
    'warning',
    'error',
    'alert'
);


ALTER TYPE "public"."orch_notification_type" OWNER TO "postgres";


CREATE TYPE "public"."orch_render_status" AS ENUM (
    'pending',
    'queued',
    'preparing',
    'rendering',
    'encoding',
    'uploading',
    'completed',
    'failed',
    'cancelled'
);


ALTER TYPE "public"."orch_render_status" OWNER TO "postgres";


CREATE TYPE "public"."orch_render_type" AS ENUM (
    'chip_count',
    'leaderboard',
    'player_info',
    'hand_replay',
    'elimination',
    'payout',
    'custom'
);


ALTER TYPE "public"."orch_render_type" OWNER TO "postgres";


CREATE TYPE "public"."orch_sync_operation" AS ENUM (
    'full_sync',
    'incremental',
    'manual',
    'scheduled',
    'webhook'
);


ALTER TYPE "public"."orch_sync_operation" OWNER TO "postgres";


CREATE TYPE "public"."orch_sync_status" AS ENUM (
    'pending',
    'in_progress',
    'synced',
    'outdated',
    'failed',
    'disabled'
);


ALTER TYPE "public"."orch_sync_status" OWNER TO "postgres";


CREATE TYPE "public"."table_type" AS ENUM (
    'FEATURE_TABLE',
    'MAIN_TABLE',
    'FINAL_TABLE',
    'SIDE_TABLE',
    'UNKNOWN'
);


ALTER TYPE "public"."table_type" OWNER TO "postgres";


CREATE TYPE "public"."wsop_chip_source" AS ENUM (
    'import',
    'manual',
    'realtime',
    'snapshot'
);


ALTER TYPE "public"."wsop_chip_source" OWNER TO "postgres";


CREATE TYPE "public"."wsop_event_status" AS ENUM (
    'upcoming',
    'registration',
    'running',
    'day_break',
    'final_table',
    'heads_up',
    'completed',
    'cancelled'
);


ALTER TYPE "public"."wsop_event_status" OWNER TO "postgres";


CREATE TYPE "public"."wsop_event_type" AS ENUM (
    'MAIN_EVENT',
    'BRACELET_EVENT',
    'SIDE_EVENT',
    'SATELLITE',
    'DEEPSTACK',
    'MYSTERY_BOUNTY',
    'HIGH_ROLLER',
    'SENIOR',
    'LADIES',
    'OTHER'
);


ALTER TYPE "public"."wsop_event_type" OWNER TO "postgres";


CREATE TYPE "public"."wsop_import_status" AS ENUM (
    'pending',
    'processing',
    'completed',
    'failed',
    'partial'
);


ALTER TYPE "public"."wsop_import_status" OWNER TO "postgres";


CREATE TYPE "public"."wsop_import_type" AS ENUM (
    'json',
    'csv',
    'api'
);


ALTER TYPE "public"."wsop_import_type" OWNER TO "postgres";


CREATE TYPE "public"."wsop_player_status" AS ENUM (
    'registered',
    'active',
    'eliminated',
    'winner'
);


ALTER TYPE "public"."wsop_player_status" OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."claim_next_job"("p_worker_id" "text", "p_job_types" "public"."orch_job_type"[] DEFAULT NULL::"public"."orch_job_type"[], "p_lock_duration_minutes" integer DEFAULT 30) RETURNS TABLE("job_id" "uuid", "job_type" "public"."orch_job_type", "job_name" "text", "payload" "jsonb")
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    v_job_id UUID;
BEGIN
    -- 대기 중인 작업 중 가장 높은 우선순위 선택 및 락
    UPDATE job_queue jq
    SET
        status = 'running',
        worker_id = p_worker_id,
        started_at = NOW(),
        locked_at = NOW(),
        lock_expires_at = NOW() + (p_lock_duration_minutes || ' minutes')::INTERVAL
    WHERE jq.id = (
        SELECT id FROM job_queue
        WHERE status = 'pending'
          AND (scheduled_at IS NULL OR scheduled_at <= NOW())
          AND (p_job_types IS NULL OR job_type = ANY(p_job_types))
          AND (lock_expires_at IS NULL OR lock_expires_at < NOW())
        ORDER BY priority ASC, created_at ASC
        LIMIT 1
        FOR UPDATE SKIP LOCKED
    )
    RETURNING jq.id INTO v_job_id;

    -- 결과 반환
    RETURN QUERY
    SELECT jq.id, jq.job_type, jq.job_name, jq.payload
    FROM job_queue jq
    WHERE jq.id = v_job_id;
END;
$$;


ALTER FUNCTION "public"."claim_next_job"("p_worker_id" "text", "p_job_types" "public"."orch_job_type"[], "p_lock_duration_minutes" integer) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."complete_job"("p_job_id" "uuid", "p_result" "jsonb" DEFAULT NULL::"jsonb", "p_success" boolean DEFAULT true, "p_error_message" "text" DEFAULT NULL::"text", "p_error_details" "jsonb" DEFAULT NULL::"jsonb") RETURNS "void"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    UPDATE job_queue
    SET
        status = CASE WHEN p_success THEN 'completed' ELSE 'failed' END,
        result = p_result,
        error_message = p_error_message,
        error_details = p_error_details,
        completed_at = NOW(),
        worker_id = NULL,
        locked_at = NULL,
        lock_expires_at = NULL,
        progress = CASE WHEN p_success THEN 100 ELSE progress END
    WHERE id = p_job_id;

    -- 알림 생성
    INSERT INTO notifications (type, level, title, message, job_id, source)
    SELECT
        CASE WHEN p_success THEN 'success' ELSE 'error' END,
        CASE WHEN p_success THEN 'low' ELSE 'high' END,
        CASE WHEN p_success THEN 'Job Completed' ELSE 'Job Failed' END,
        CASE
            WHEN p_success THEN 'Job ' || job_name || ' completed successfully'
            ELSE 'Job ' || job_name || ' failed: ' || COALESCE(p_error_message, 'Unknown error')
        END,
        p_job_id,
        'system'
    FROM job_queue
    WHERE id = p_job_id;
END;
$$;


ALTER FUNCTION "public"."complete_job"("p_job_id" "uuid", "p_result" "jsonb", "p_success" boolean, "p_error_message" "text", "p_error_details" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."format_bbs"("chips" bigint, "bb" bigint) RETURNS "text"
    LANGUAGE "sql" IMMUTABLE
    AS $$
    SELECT CASE
        WHEN bb IS NULL OR bb = 0 THEN ''
        WHEN chips IS NULL THEN ''
        ELSE TRIM(TO_CHAR(chips::NUMERIC / bb, 'FM999,999.9'))
    END
$$;


ALTER FUNCTION "public"."format_bbs"("chips" bigint, "bb" bigint) OWNER TO "postgres";


COMMENT ON FUNCTION "public"."format_bbs"("chips" bigint, "bb" bigint) IS 'BB 단위로 변환: 1500000 / 20000 → "75.0"';



CREATE OR REPLACE FUNCTION "public"."format_bbs_safe"("chips" bigint, "bb" bigint) RETURNS "text"
    LANGUAGE "plpgsql" IMMUTABLE
    AS $$
BEGIN
    IF chips IS NULL OR bb IS NULL OR bb = 0 THEN
        RETURN '';
    END IF;
    RETURN TRIM(TO_CHAR(chips::NUMERIC / bb, 'FM999,999.9'));
EXCEPTION
    WHEN OTHERS THEN
        RETURN '';
END;
$$;


ALTER FUNCTION "public"."format_bbs_safe"("chips" bigint, "bb" bigint) OWNER TO "postgres";


COMMENT ON FUNCTION "public"."format_bbs_safe"("chips" bigint, "bb" bigint) IS 'NULL 안전 버전의 format_bbs';



CREATE OR REPLACE FUNCTION "public"."format_blinds"("sb" bigint, "bb" bigint, "ante" bigint DEFAULT 0) RETURNS "text"
    LANGUAGE "sql" IMMUTABLE
    AS $$
    SELECT CASE
        WHEN sb IS NULL OR bb IS NULL THEN ''
        ELSE format_chips(sb) || '/' || format_chips(bb) ||
             CASE WHEN ante > 0 THEN ' (' || format_chips(ante) || ')' ELSE '' END
    END
$$;


ALTER FUNCTION "public"."format_blinds"("sb" bigint, "bb" bigint, "ante" bigint) OWNER TO "postgres";


COMMENT ON FUNCTION "public"."format_blinds"("sb" bigint, "bb" bigint, "ante" bigint) IS '블라인드 포맷: 10000/20000 (20000) → "10K/20K (20K)"';



CREATE OR REPLACE FUNCTION "public"."format_chips"("amount" bigint) RETURNS "text"
    LANGUAGE "plpgsql" IMMUTABLE
    AS $$
BEGIN
    IF amount IS NULL THEN
        RETURN '';
    END IF;
    RETURN TO_CHAR(amount, 'FM999,999,999,999');
END;
$$;


ALTER FUNCTION "public"."format_chips"("amount" bigint) OWNER TO "postgres";


COMMENT ON FUNCTION "public"."format_chips"("amount" bigint) IS '칩 포맷팅: 1500000 → "1,500,000"';



CREATE OR REPLACE FUNCTION "public"."format_chips_comma"("amount" bigint) RETURNS "text"
    LANGUAGE "sql" IMMUTABLE
    AS $$
    SELECT CASE
        WHEN amount IS NULL THEN ''
        ELSE TO_CHAR(amount, 'FM999,999,999,999')
    END
$$;


ALTER FUNCTION "public"."format_chips_comma"("amount" bigint) OWNER TO "postgres";


COMMENT ON FUNCTION "public"."format_chips_comma"("amount" bigint) IS '천단위 콤마: 1500000 → "1,500,000"';



CREATE OR REPLACE FUNCTION "public"."format_chips_safe"("amount" bigint) RETURNS "text"
    LANGUAGE "plpgsql" IMMUTABLE
    AS $$
BEGIN
    IF amount IS NULL OR amount < 0 THEN
        RETURN '';
    END IF;
    RETURN format_chips(amount);
EXCEPTION
    WHEN OTHERS THEN
        RETURN '';
END;
$$;


ALTER FUNCTION "public"."format_chips_safe"("amount" bigint) OWNER TO "postgres";


COMMENT ON FUNCTION "public"."format_chips_safe"("amount" bigint) IS 'NULL 안전 버전의 format_chips';



CREATE OR REPLACE FUNCTION "public"."format_chips_short"("amount" bigint) RETURNS "text"
    LANGUAGE "plpgsql" IMMUTABLE
    AS $$
BEGIN
    IF amount IS NULL THEN
        RETURN '';
    END IF;

    IF amount >= 1000000 THEN
        RETURN ROUND(amount::NUMERIC / 1000000, 1)::TEXT || 'M';
    ELSIF amount >= 1000 THEN
        RETURN ROUND(amount::NUMERIC / 1000, 0)::TEXT || 'K';
    ELSE
        RETURN amount::TEXT;
    END IF;
END;
$$;


ALTER FUNCTION "public"."format_chips_short"("amount" bigint) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."format_currency"("amount" bigint) RETURNS "text"
    LANGUAGE "plpgsql" IMMUTABLE
    AS $_$
BEGIN
    IF amount IS NULL THEN
        RETURN '$0';
    END IF;
    RETURN '$' || TO_CHAR(amount / 100, 'FM999,999,999');
END;
$_$;


ALTER FUNCTION "public"."format_currency"("amount" bigint) OWNER TO "postgres";


COMMENT ON FUNCTION "public"."format_currency"("amount" bigint) IS '통화 포맷팅 (cents): 100000000 → "$1,000,000"';



CREATE OR REPLACE FUNCTION "public"."format_currency_cents"("amount" bigint) RETURNS "text"
    LANGUAGE "sql" IMMUTABLE
    AS $_$
    SELECT CASE
        WHEN amount IS NULL THEN '$0'
        ELSE '$' || TO_CHAR(amount / 100, 'FM999,999,999,999')
    END
$_$;


ALTER FUNCTION "public"."format_currency_cents"("amount" bigint) OWNER TO "postgres";


COMMENT ON FUNCTION "public"."format_currency_cents"("amount" bigint) IS 'cents를 달러로 변환: 100000000 → "$1,000,000"';



CREATE OR REPLACE FUNCTION "public"."format_currency_from_int"("amount" bigint) RETURNS "text"
    LANGUAGE "plpgsql" IMMUTABLE
    AS $_$
BEGIN
    IF amount IS NULL THEN
        RETURN '$0';
    END IF;
    RETURN '$' || TO_CHAR(amount, 'FM999,999,999');
END;
$_$;


ALTER FUNCTION "public"."format_currency_from_int"("amount" bigint) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."format_currency_safe"("amount" bigint) RETURNS "text"
    LANGUAGE "plpgsql" IMMUTABLE
    AS $_$
BEGIN
    IF amount IS NULL THEN
        RETURN '$0';
    END IF;
    RETURN format_currency(amount);
EXCEPTION
    WHEN OTHERS THEN
        RETURN '$0';
END;
$_$;


ALTER FUNCTION "public"."format_currency_safe"("amount" bigint) OWNER TO "postgres";


COMMENT ON FUNCTION "public"."format_currency_safe"("amount" bigint) IS 'NULL 안전 버전의 format_currency';



CREATE OR REPLACE FUNCTION "public"."format_date"("d" "date") RETURNS "text"
    LANGUAGE "sql" IMMUTABLE
    AS $$
    SELECT CASE
        WHEN d IS NULL THEN ''
        ELSE TO_CHAR(d, 'Mon DD')
    END
$$;


ALTER FUNCTION "public"."format_date"("d" "date") OWNER TO "postgres";


COMMENT ON FUNCTION "public"."format_date"("d" "date") IS '날짜를 "Mon DD" 형태로 변환: 2026-01-14 → "Jan 14"';



CREATE OR REPLACE FUNCTION "public"."format_date_short"("d" "date") RETURNS "text"
    LANGUAGE "plpgsql" IMMUTABLE
    AS $$
BEGIN
    IF d IS NULL THEN
        RETURN '';
    END IF;
    RETURN TO_CHAR(d, 'Mon DD');
END;
$$;


ALTER FUNCTION "public"."format_date_short"("d" "date") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."format_number"("num" bigint) RETURNS "text"
    LANGUAGE "plpgsql" IMMUTABLE
    AS $$
BEGIN
    IF num IS NULL THEN
        RETURN '';
    END IF;
    RETURN TO_CHAR(num, 'FM999,999,999');
END;
$$;


ALTER FUNCTION "public"."format_number"("num" bigint) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."format_percent"("value" numeric) RETURNS "text"
    LANGUAGE "plpgsql" IMMUTABLE
    AS $$
BEGIN
    IF value IS NULL THEN
        RETURN '';
    END IF;
    RETURN ROUND(value * 100, 1)::TEXT || '%';
END;
$$;


ALTER FUNCTION "public"."format_percent"("value" numeric) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."format_time"("t" time without time zone) RETURNS "text"
    LANGUAGE "sql" IMMUTABLE
    AS $$
    SELECT CASE
        WHEN t IS NULL THEN ''
        ELSE TO_CHAR(t, 'HH:MI AM')
    END
$$;


ALTER FUNCTION "public"."format_time"("t" time without time zone) OWNER TO "postgres";


COMMENT ON FUNCTION "public"."format_time"("t" time without time zone) IS '시간을 12시간제로 변환: 17:30 → "05:30 PM"';



CREATE OR REPLACE FUNCTION "public"."format_time_12h"("t" time without time zone) RETURNS "text"
    LANGUAGE "plpgsql" IMMUTABLE
    AS $$
BEGIN
    IF t IS NULL THEN
        RETURN '';
    END IF;
    RETURN TO_CHAR(t, 'HH:MI AM');
END;
$$;


ALTER FUNCTION "public"."format_time_12h"("t" time without time zone) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."generate_player_code"() RETURNS "text"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    v_code TEXT;
    v_seq INTEGER;
BEGIN
    -- 현재 최대 번호 조회
    SELECT COALESCE(MAX(CAST(SUBSTRING(player_code FROM 4) AS INTEGER)), 0) + 1
    INTO v_seq
    FROM manual_players
    WHERE player_code LIKE 'MP-%';

    -- 코드 생성 (MP-00001 형식)
    v_code := 'MP-' || LPAD(v_seq::TEXT, 5, '0');

    RETURN v_code;
END;
$$;


ALTER FUNCTION "public"."generate_player_code"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."generate_player_hash"("p_name" "text", "p_long_name" "text") RETURNS "text"
    LANGUAGE "plpgsql" IMMUTABLE
    AS $$
BEGIN
    RETURN md5(LOWER(TRIM(COALESCE(p_name, ''))) || ':' || LOWER(TRIM(COALESCE(p_long_name, ''))));
END;
$$;


ALTER FUNCTION "public"."generate_player_hash"("p_name" "text", "p_long_name" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_at_risk_data"("p_session_id" bigint, "p_hand_num" integer) RETURNS "jsonb"
    LANGUAGE "plpgsql" STABLE
    AS $_$
DECLARE
    v_result JSONB;
BEGIN
    SELECT jsonb_build_object(
        '$schema', 'render_gfx_data_v3',
        'version', '3.0.0',
        'comp_name', 'At Risk of Elimination',
        'render_type', 'at_risk',
        'at_risk', jsonb_build_object(
            'player_name', player_name,
            'rank', rank,
            'prize', prize,
            'flag', flag,
            'chips', chips
        ),
        'metadata', jsonb_build_object(
            'session_id', p_session_id,
            'hand_num', p_hand_num,
            'data_sources', ARRAY['gfx_hand_players', 'gfx_sessions', 'player_overrides'],
            'generated_at', NOW(),
            'schema_version', '3.0.0'
        )
    )
    INTO v_result
    FROM v_render_at_risk
    WHERE session_id = p_session_id
      AND hand_num = p_hand_num;

    RETURN COALESCE(v_result, '{}'::JSONB);
END;
$_$;


ALTER FUNCTION "public"."get_at_risk_data"("p_session_id" bigint, "p_hand_num" integer) OWNER TO "postgres";


COMMENT ON FUNCTION "public"."get_at_risk_data"("p_session_id" bigint, "p_hand_num" integer) IS 'At Risk of Elimination 컴포지션용 gfx_data JSON 생성 (v3 스키마, 필드 분리)';



CREATE OR REPLACE FUNCTION "public"."get_chip_comparison_data"("p_session_id" bigint, "p_hand_num" integer, "p_selected_player_name" "text") RETURNS "jsonb"
    LANGUAGE "plpgsql" STABLE
    AS $_$
DECLARE
    v_result JSONB;
    v_total_chips BIGINT;
    v_selected_chips BIGINT;
    v_selected_name TEXT;
BEGIN
    -- 전체 칩 합계
    SELECT SUM(ghp.end_stack_amt) INTO v_total_chips
    FROM gfx_hand_players ghp
    JOIN gfx_hands gh ON ghp.hand_id = gh.id
    WHERE gh.session_id = p_session_id
      AND gh.hand_num = p_hand_num
      AND ghp.sitting_out = FALSE;

    -- 선택된 플레이어 칩
    SELECT ghp.end_stack_amt, UPPER(ghp.player_name)
    INTO v_selected_chips, v_selected_name
    FROM gfx_hand_players ghp
    JOIN gfx_hands gh ON ghp.hand_id = gh.id
    WHERE gh.session_id = p_session_id
      AND gh.hand_num = p_hand_num
      AND LOWER(ghp.player_name) = LOWER(p_selected_player_name)
      AND ghp.sitting_out = FALSE;

    IF v_selected_chips IS NULL OR v_total_chips IS NULL OR v_total_chips = 0 THEN
        RETURN '{}'::JSONB;
    END IF;

    -- 결과 JSON 생성 (v3 스키마)
    v_result := jsonb_build_object(
        '$schema', 'render_gfx_data_v3',
        'version', '3.0.0',
        'comp_name', 'Chip Comparison',
        'render_type', 'chip_comparison',
        'chip_comparison', jsonb_build_object(
            'selected_player_name', v_selected_name,
            'selected_player_chips', format_chips(v_selected_chips),
            'selected_player_percent', format_percent(v_selected_chips::NUMERIC / v_total_chips),
            'others_chips', format_chips(v_total_chips - v_selected_chips),
            'others_percent', format_percent((v_total_chips - v_selected_chips)::NUMERIC / v_total_chips)
        ),
        'metadata', jsonb_build_object(
            'session_id', p_session_id,
            'hand_num', p_hand_num,
            'total_chips_in_play', v_total_chips,
            'data_sources', ARRAY['gfx_hand_players', 'gfx_hands'],
            'generated_at', NOW(),
            'schema_version', '3.0.0'
        )
    );

    RETURN v_result;
END;
$_$;


ALTER FUNCTION "public"."get_chip_comparison_data"("p_session_id" bigint, "p_hand_num" integer, "p_selected_player_name" "text") OWNER TO "postgres";


COMMENT ON FUNCTION "public"."get_chip_comparison_data"("p_session_id" bigint, "p_hand_num" integer, "p_selected_player_name" "text") IS 'Chip Comparison 컴포지션용 gfx_data JSON 생성. 선택 플레이어 vs 나머지 백분율.';



CREATE OR REPLACE FUNCTION "public"."get_chip_display_data"("p_session_id" bigint, "p_hand_num" integer, "p_slot_count" integer DEFAULT 9) RETURNS "jsonb"
    LANGUAGE "plpgsql" STABLE
    AS $_$
DECLARE
    v_result JSONB;
    v_slots JSONB;
    v_avg_stack BIGINT;
    v_big_blind BIGINT;
BEGIN
    -- 슬롯 데이터 조회 (v_render_chip_display 뷰 사용)
    SELECT jsonb_agg(
        jsonb_build_object(
            'slot_index', slot_index,
            'fields', jsonb_build_object(
                'name', name,
                'chips', chips,
                'bbs', bbs,
                'rank', rank,
                'flag', flag
            )
        ) ORDER BY slot_index
    )
    INTO v_slots
    FROM v_render_chip_display
    WHERE session_id = p_session_id
      AND hand_num = p_hand_num
      AND slot_index <= p_slot_count;

    -- 평균 스택 및 블라인드 계산
    SELECT AVG(raw_chips), MAX(big_blind)
    INTO v_avg_stack, v_big_blind
    FROM v_render_chip_display
    WHERE session_id = p_session_id
      AND hand_num = p_hand_num;

    -- 결과 JSON 생성 (v3 스키마)
    v_result := jsonb_build_object(
        '$schema', 'render_gfx_data_v3',  -- v2 → v3 업그레이드
        'version', '3.0.0',
        'comp_name', '_MAIN Mini Chip Count',
        'render_type', 'chip_count',
        'slots', COALESCE(v_slots, '[]'::JSONB),
        'single_fields', jsonb_build_object(
            'AVERAGE STACK', format_chips(v_avg_stack) || ' (' || format_bbs(v_avg_stack, v_big_blind) || 'BB)'
        ),
        'metadata', jsonb_build_object(
            'session_id', p_session_id,
            'hand_num', p_hand_num,
            'blind_level', format_blinds(v_big_blind / 2, v_big_blind, 0),
            'data_sources', ARRAY['gfx_hand_players', 'gfx_hands', 'gfx_sessions', 'player_overrides'],
            'generated_at', NOW(),
            'schema_version', '3.0.0'
        )
    );

    RETURN v_result;
END;
$_$;


ALTER FUNCTION "public"."get_chip_display_data"("p_session_id" bigint, "p_hand_num" integer, "p_slot_count" integer) OWNER TO "postgres";


COMMENT ON FUNCTION "public"."get_chip_display_data"("p_session_id" bigint, "p_hand_num" integer, "p_slot_count" integer) IS 'Chip Display 컴포지션용 gfx_data JSON 생성';



CREATE OR REPLACE FUNCTION "public"."get_chip_flow_data"("p_session_id" bigint, "p_current_hand_num" integer, "p_player_name" "text") RETURNS "jsonb"
    LANGUAGE "plpgsql" STABLE
    AS $_$
DECLARE
    v_result JSONB;
    v_chips_10h BIGINT[];
    v_chips_20h BIGINT[];
    v_chips_30h BIGINT[];
    v_max_chips BIGINT;
    v_min_chips BIGINT;
    v_player_name_upper TEXT;
BEGIN
    -- 플레이어 이름 대문자 변환
    v_player_name_upper := UPPER(p_player_name);

    -- 최근 30핸드 칩 히스토리 조회
    WITH hand_sequence AS (
        SELECT
            gh.hand_num,
            ghp.end_stack_amt AS chips,
            ROW_NUMBER() OVER (ORDER BY gh.hand_num DESC) AS rn
        FROM gfx_hand_players ghp
        JOIN gfx_hands gh ON ghp.hand_id = gh.id
        WHERE gh.session_id = p_session_id
          AND gh.hand_num <= p_current_hand_num
          AND LOWER(ghp.player_name) = LOWER(p_player_name)
          AND ghp.sitting_out = FALSE
        ORDER BY gh.hand_num DESC
        LIMIT 30
    )
    SELECT
        -- 최근 10핸드 배열 (시간순)
        ARRAY(SELECT chips FROM hand_sequence WHERE rn <= 10 ORDER BY rn DESC),
        -- 최근 20핸드 배열
        ARRAY(SELECT chips FROM hand_sequence WHERE rn <= 20 ORDER BY rn DESC),
        -- 최근 30핸드 배열
        ARRAY(SELECT chips FROM hand_sequence ORDER BY rn DESC),
        -- 최대/최소값
        MAX(chips),
        MIN(chips)
    INTO v_chips_10h, v_chips_20h, v_chips_30h, v_max_chips, v_min_chips
    FROM hand_sequence;

    IF v_chips_10h IS NULL OR array_length(v_chips_10h, 1) = 0 THEN
        RETURN '{}'::JSONB;
    END IF;

    -- 결과 JSON 생성 (v3 스키마)
    v_result := jsonb_build_object(
        '$schema', 'render_gfx_data_v3',
        'version', '3.0.0',
        'comp_name', 'Chip Flow',
        'render_type', 'chip_flow',
        'chip_flow', jsonb_build_object(
            'player_name', v_player_name_upper,
            'chips_10h', to_jsonb(v_chips_10h),
            'chips_20h', to_jsonb(v_chips_20h),
            'chips_30h', to_jsonb(v_chips_30h),
            'max_label', format_chips(v_max_chips),
            'min_label', format_chips(v_min_chips)
        ),
        'metadata', jsonb_build_object(
            'session_id', p_session_id,
            'current_hand_num', p_current_hand_num,
            'history_count', array_length(v_chips_30h, 1),
            'data_sources', ARRAY['gfx_hand_players', 'gfx_hands'],
            'generated_at', NOW(),
            'schema_version', '3.0.0'
        )
    );

    RETURN v_result;
END;
$_$;


ALTER FUNCTION "public"."get_chip_flow_data"("p_session_id" bigint, "p_current_hand_num" integer, "p_player_name" "text") OWNER TO "postgres";


COMMENT ON FUNCTION "public"."get_chip_flow_data"("p_session_id" bigint, "p_current_hand_num" integer, "p_player_name" "text") IS 'Chip Flow 컴포지션용 gfx_data JSON 생성. 10/20/30 핸드 칩 히스토리 배열.';



CREATE OR REPLACE FUNCTION "public"."get_chips_n_hands_ago"("p_session_id" bigint, "p_current_hand_num" integer, "p_player_name" "text", "p_n_hands" integer) RETURNS bigint
    LANGUAGE "plpgsql" STABLE
    AS $$
DECLARE
    v_chips BIGINT;
BEGIN
    SELECT ghp.end_stack_amt INTO v_chips
    FROM gfx_hand_players ghp
    JOIN gfx_hands gh ON ghp.hand_id = gh.id
    WHERE gh.session_id = p_session_id
      AND gh.hand_num = p_current_hand_num - p_n_hands
      AND LOWER(ghp.player_name) = LOWER(p_player_name)
      AND ghp.sitting_out = FALSE
    LIMIT 1;

    RETURN v_chips;
END;
$$;


ALTER FUNCTION "public"."get_chips_n_hands_ago"("p_session_id" bigint, "p_current_hand_num" integer, "p_player_name" "text", "p_n_hands" integer) OWNER TO "postgres";


COMMENT ON FUNCTION "public"."get_chips_n_hands_ago"("p_session_id" bigint, "p_current_hand_num" integer, "p_player_name" "text", "p_n_hands" integer) IS '특정 플레이어의 N핸드 전 칩 스택 조회. NAME 3줄+ 컴포지션용.';



CREATE OR REPLACE FUNCTION "public"."get_config"("p_key" "text", "p_environment" "text" DEFAULT 'production'::"text") RETURNS "jsonb"
    LANGUAGE "plpgsql" STABLE
    AS $$
DECLARE
    v_value JSONB;
    v_override JSONB;
BEGIN
    SELECT value, environment_overrides->p_environment
    INTO v_value, v_override
    FROM system_config
    WHERE key = p_key;

    -- 환경별 오버라이드가 있으면 적용
    IF v_override IS NOT NULL THEN
        RETURN COALESCE(v_override->'value', v_value);
    END IF;

    RETURN v_value;
END;
$$;


ALTER FUNCTION "public"."get_config"("p_key" "text", "p_environment" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_elimination_data"("p_session_id" bigint, "p_hand_num" integer) RETURNS "jsonb"
    LANGUAGE "plpgsql" STABLE
    AS $_$
DECLARE
    v_result JSONB;
    v_slots JSONB;
BEGIN
    -- 슬롯 데이터 조회
    SELECT jsonb_agg(
        jsonb_build_object(
            'slot_index', ROW_NUMBER() OVER (ORDER BY rank DESC),
            'fields', jsonb_build_object(
                'name', name,
                'rank', rank::TEXT,
                'prize', prize,
                'flag', flag
            )
        )
    )
    INTO v_slots
    FROM v_render_elimination
    WHERE session_id = p_session_id
      AND hand_num = p_hand_num;

    -- 결과 JSON 생성 (v3 스키마)
    v_result := jsonb_build_object(
        '$schema', 'render_gfx_data_v3',
        'version', '3.0.0',
        'comp_name', 'Elimination',
        'render_type', 'elimination',
        'slots', COALESCE(v_slots, '[]'::JSONB),
        'metadata', jsonb_build_object(
            'session_id', p_session_id,
            'hand_num', p_hand_num,
            'data_sources', ARRAY['gfx_hand_players', 'gfx_sessions', 'player_overrides'],
            'generated_at', NOW(),
            'schema_version', '3.0.0'
        )
    );

    RETURN v_result;
END;
$_$;


ALTER FUNCTION "public"."get_elimination_data"("p_session_id" bigint, "p_hand_num" integer) OWNER TO "postgres";


COMMENT ON FUNCTION "public"."get_elimination_data"("p_session_id" bigint, "p_hand_num" integer) IS 'Elimination 컴포지션용 gfx_data JSON 생성.';



CREATE OR REPLACE FUNCTION "public"."get_flag_path"("country_code" character varying) RETURNS "text"
    LANGUAGE "plpgsql" IMMUTABLE
    AS $$
DECLARE
    v_country_name TEXT;
BEGIN
    IF country_code IS NULL OR country_code = '' OR country_code = 'XX' THEN
        RETURN 'Flag/Unknown.png';
    END IF;

    -- 국가 코드 → 국가명 매핑
    SELECT CASE UPPER(country_code)
        WHEN 'US' THEN 'United States'
        WHEN 'KR' THEN 'Korea'
        WHEN 'GB' THEN 'United Kingdom'
        WHEN 'UK' THEN 'United Kingdom'
        WHEN 'DE' THEN 'Germany'
        WHEN 'FR' THEN 'France'
        WHEN 'JP' THEN 'Japan'
        WHEN 'CN' THEN 'China'
        WHEN 'CA' THEN 'Canada'
        WHEN 'AU' THEN 'Australia'
        WHEN 'BR' THEN 'Brazil'
        WHEN 'RU' THEN 'Russia'
        WHEN 'IT' THEN 'Italy'
        WHEN 'ES' THEN 'Spain'
        WHEN 'NL' THEN 'Netherlands'
        WHEN 'SE' THEN 'Sweden'
        WHEN 'NO' THEN 'Norway'
        WHEN 'FI' THEN 'Finland'
        WHEN 'DK' THEN 'Denmark'
        WHEN 'PL' THEN 'Poland'
        WHEN 'AT' THEN 'Austria'
        WHEN 'CH' THEN 'Switzerland'
        WHEN 'BE' THEN 'Belgium'
        WHEN 'IE' THEN 'Ireland'
        WHEN 'PT' THEN 'Portugal'
        WHEN 'GR' THEN 'Greece'
        WHEN 'CZ' THEN 'Czech Republic'
        WHEN 'HU' THEN 'Hungary'
        WHEN 'IL' THEN 'Israel'
        WHEN 'UA' THEN 'Ukraine'
        WHEN 'LT' THEN 'Lithuania'
        WHEN 'LV' THEN 'Latvia'
        WHEN 'EE' THEN 'Estonia'
        WHEN 'CY' THEN 'Cyprus'
        WHEN 'MT' THEN 'Malta'
        WHEN 'MX' THEN 'Mexico'
        WHEN 'AR' THEN 'Argentina'
        WHEN 'CL' THEN 'Chile'
        WHEN 'CO' THEN 'Colombia'
        WHEN 'PE' THEN 'Peru'
        WHEN 'VE' THEN 'Venezuela'
        WHEN 'IN' THEN 'India'
        WHEN 'PH' THEN 'Philippines'
        WHEN 'TH' THEN 'Thailand'
        WHEN 'VN' THEN 'Vietnam'
        WHEN 'MY' THEN 'Malaysia'
        WHEN 'SG' THEN 'Singapore'
        WHEN 'ID' THEN 'Indonesia'
        WHEN 'NZ' THEN 'New Zealand'
        WHEN 'ZA' THEN 'South Africa'
        WHEN 'EG' THEN 'Egypt'
        WHEN 'TR' THEN 'Turkey'
        WHEN 'AE' THEN 'United Arab Emirates'
        ELSE 'Unknown'
    END INTO v_country_name;

    RETURN 'Flag/' || v_country_name || '.png';
END;
$$;


ALTER FUNCTION "public"."get_flag_path"("country_code" character varying) OWNER TO "postgres";


COMMENT ON FUNCTION "public"."get_flag_path"("country_code" character varying) IS '국기 경로: "KR" → "Flag/Korea.png"';



CREATE OR REPLACE FUNCTION "public"."get_next_cue_item"("p_sheet_id" "uuid") RETURNS TABLE("id" "uuid", "cue_number" "text", "cue_type" "public"."cue_item_type", "gfx_data" "jsonb", "duration_seconds" integer)
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    RETURN QUERY
    SELECT
        ci.id,
        ci.cue_number,
        ci.cue_type,
        ci.gfx_data,
        ci.duration_seconds
    FROM cue_items ci
    JOIN cue_sheets cs ON ci.sheet_id = cs.id
    WHERE ci.sheet_id = p_sheet_id
      AND ci.status IN ('pending', 'ready', 'standby')
      AND ci.sort_order > COALESCE(
          (SELECT sort_order FROM cue_items WHERE id = cs.current_item_id),
          -1
      )
    ORDER BY ci.sort_order
    LIMIT 1;
END;
$$;


ALTER FUNCTION "public"."get_next_cue_item"("p_sheet_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_payout_data"("p_event_id" "uuid", "p_slot_count" integer DEFAULT 9, "p_start_rank" integer DEFAULT 1) RETURNS "jsonb"
    LANGUAGE "plpgsql" STABLE
    AS $_$
DECLARE
    v_result JSONB;
    v_slots JSONB;
    v_event_name TEXT;
    v_total_prize BIGINT;
BEGIN
    -- 이벤트 정보 조회
    SELECT event_name, prize_pool
    INTO v_event_name, v_total_prize
    FROM wsop_events
    WHERE id = p_event_id;

    -- 슬롯 데이터 조회
    SELECT jsonb_agg(
        jsonb_build_object(
            'slot_index', slot_index - p_start_rank + 1,
            'fields', jsonb_build_object(
                'rank', rank,
                'prize', prize
            )
        ) ORDER BY slot_index
    )
    INTO v_slots
    FROM v_render_payout
    WHERE event_id = p_event_id
      AND slot_index >= p_start_rank
      AND slot_index < p_start_rank + p_slot_count;

    -- 결과 JSON 생성 (v3 스키마)
    v_result := jsonb_build_object(
        '$schema', 'render_gfx_data_v3',  -- v2 → v3 업그레이드
        'version', '3.0.0',
        'comp_name', CASE
            WHEN p_start_rank > 1 THEN 'Payouts 등수 바꾸기 가능'
            ELSE 'Payouts'
        END,
        'render_type', 'payout',
        'slots', COALESCE(v_slots, '[]'::JSONB),
        'payouts', jsonb_build_object(  -- v2.0.0 구조 추가
            'event_name', v_event_name,
            'start_rank', p_start_rank,
            'entries', COALESCE(v_slots, '[]'::JSONB)
        ),
        'single_fields', jsonb_build_object(
            'wsop_super_circuit_cyprus', '2025 WSOP SUPER CIRCUIT CYPRUS',
            'payouts', 'PAYOUTS',
            'total_prize', format_currency(v_total_prize),
            'event_name', v_event_name  -- v2.0.0 추가
        ),
        'metadata', jsonb_build_object(
            'event_id', p_event_id,
            'event_name', v_event_name,
            'start_rank', p_start_rank,
            'slot_count', p_slot_count,
            'data_sources', ARRAY['wsop_events'],
            'generated_at', NOW(),
            'schema_version', '3.0.0'
        )
    );

    RETURN v_result;
END;
$_$;


ALTER FUNCTION "public"."get_payout_data"("p_event_id" "uuid", "p_slot_count" integer, "p_start_rank" integer) OWNER TO "postgres";


COMMENT ON FUNCTION "public"."get_payout_data"("p_event_id" "uuid", "p_slot_count" integer, "p_start_rank" integer) IS 'Payout 컴포지션용 gfx_data JSON 생성';



CREATE OR REPLACE FUNCTION "public"."get_player_field_with_override"("p_player_id" "uuid", "p_field_name" "text", "p_default_value" "text") RETURNS "text"
    LANGUAGE "plpgsql" STABLE
    AS $$
DECLARE
    v_override_value TEXT;
BEGIN
    -- 활성 오버라이드 조회 (우선순위 순)
    SELECT override_value
    INTO v_override_value
    FROM player_overrides
    WHERE (manual_player_id = p_player_id OR wsop_player_id = p_player_id)
      AND field_name = p_field_name
      AND active = TRUE
      AND (valid_from IS NULL OR valid_from <= NOW())
      AND (valid_until IS NULL OR valid_until > NOW())
    ORDER BY priority ASC
    LIMIT 1;

    RETURN COALESCE(v_override_value, p_default_value);
END;
$$;


ALTER FUNCTION "public"."get_player_field_with_override"("p_player_id" "uuid", "p_field_name" "text", "p_default_value" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_player_history_data"("p_session_id" bigint, "p_hand_num" integer, "p_player_name" "text") RETURNS "jsonb"
    LANGUAGE "plpgsql" STABLE
    AS $_$
DECLARE
    v_result JSONB;
    v_current_chips BIGINT;
    v_chips_10h BIGINT;
    v_chips_20h BIGINT;
    v_chips_30h BIGINT;
    v_vpip NUMERIC;
    v_player_name_upper TEXT;
    v_flag TEXT;
    v_big_blind BIGINT;
BEGIN
    -- 현재 칩 및 VPIP 조회 (player_overrides: field_name + override_value 구조)
    SELECT
        ghp.end_stack_amt,
        ghp.vpip_percent,
        UPPER(COALESCE(po_name.override_value, ghp.player_name)),
        get_flag_path(COALESCE(po_country.override_value, 'XX')),
        COALESCE((gh.blinds->>'big_blind_amt')::BIGINT, 0)
    INTO v_current_chips, v_vpip, v_player_name_upper, v_flag, v_big_blind
    FROM gfx_hand_players ghp
    JOIN gfx_hands gh ON ghp.hand_id = gh.id
    LEFT JOIN gfx_players gp ON ghp.player_id = gp.id
    -- player_overrides 조인 (이름 오버라이드)
    LEFT JOIN player_overrides po_name
        ON po_name.gfx_player_id = gp.id
        AND po_name.field_name = 'name'
        AND po_name.active = TRUE
    -- player_overrides 조인 (국가 코드 오버라이드)
    LEFT JOIN player_overrides po_country
        ON po_country.gfx_player_id = gp.id
        AND po_country.field_name = 'country_code'
        AND po_country.active = TRUE
    WHERE gh.session_id = p_session_id
      AND gh.hand_num = p_hand_num
      AND LOWER(ghp.player_name) = LOWER(p_player_name)
      AND ghp.sitting_out = FALSE;

    IF v_current_chips IS NULL THEN
        RETURN '{}'::JSONB;
    END IF;

    -- 히스토리 칩 조회
    v_chips_10h := get_chips_n_hands_ago(p_session_id, p_hand_num, p_player_name, 10);
    v_chips_20h := get_chips_n_hands_ago(p_session_id, p_hand_num, p_player_name, 20);
    v_chips_30h := get_chips_n_hands_ago(p_session_id, p_hand_num, p_player_name, 30);

    -- 결과 JSON 생성 (v3 스키마)
    v_result := jsonb_build_object(
        '$schema', 'render_gfx_data_v3',
        'version', '3.0.0',
        'comp_name', 'NAME 3줄+',
        'render_type', 'player_history',
        'single_fields', jsonb_build_object(
            'player_name', v_player_name_upper,
            'chips', format_chips(v_current_chips),
            'bbs', format_bbs(v_current_chips, v_big_blind),
            'vpip', COALESCE(TO_CHAR(v_vpip, 'FM99.9') || '%', 'N/A'),
            'flag', v_flag
        ),
        'player_history', jsonb_build_object(
            'current_chips', v_current_chips,
            'chips_10_hands_ago', v_chips_10h,
            'chips_20_hands_ago', v_chips_20h,
            'chips_30_hands_ago', v_chips_30h,
            'chip_change_10h', CASE
                WHEN v_chips_10h IS NOT NULL THEN
                    CASE WHEN v_current_chips >= v_chips_10h THEN '+' ELSE '' END ||
                    format_chips(v_current_chips - v_chips_10h)
                ELSE NULL
            END,
            'chip_change_20h', CASE
                WHEN v_chips_20h IS NOT NULL THEN
                    CASE WHEN v_current_chips >= v_chips_20h THEN '+' ELSE '' END ||
                    format_chips(v_current_chips - v_chips_20h)
                ELSE NULL
            END,
            'chip_change_30h', CASE
                WHEN v_chips_30h IS NOT NULL THEN
                    CASE WHEN v_current_chips >= v_chips_30h THEN '+' ELSE '' END ||
                    format_chips(v_current_chips - v_chips_30h)
                ELSE NULL
            END
        ),
        'metadata', jsonb_build_object(
            'session_id', p_session_id,
            'hand_num', p_hand_num,
            'data_sources', ARRAY['gfx_hand_players', 'gfx_hands', 'player_overrides'],
            'generated_at', NOW(),
            'schema_version', '3.0.0'
        )
    );

    RETURN v_result;
END;
$_$;


ALTER FUNCTION "public"."get_player_history_data"("p_session_id" bigint, "p_hand_num" integer, "p_player_name" "text") OWNER TO "postgres";


COMMENT ON FUNCTION "public"."get_player_history_data"("p_session_id" bigint, "p_hand_num" integer, "p_player_name" "text") IS 'NAME 3줄+ 컴포지션용 gfx_data JSON 생성. 히스토리 칩 및 VPIP 통합.';



CREATE OR REPLACE FUNCTION "public"."get_player_name_data"("p_session_id" bigint, "p_hand_num" integer, "p_seat_num" integer, "p_variant" "text" DEFAULT 'NAME'::"text") RETURNS "jsonb"
    LANGUAGE "plpgsql" STABLE
    AS $_$
DECLARE
    v_result JSONB;
    v_player_name TEXT;
    v_chips TEXT;
    v_bbs TEXT;
    v_flag TEXT;
BEGIN
    -- 플레이어 정보 조회 (player_overrides: field_name + override_value 구조)
    SELECT
        UPPER(COALESCE(po_name.override_value, ghp.player_name)),
        format_chips(ghp.end_stack_amt),
        format_bbs(ghp.end_stack_amt, COALESCE((gh.blinds->>'big_blind_amt')::BIGINT, 0)),
        get_flag_path(COALESCE(po_country.override_value, 'XX'))
    INTO v_player_name, v_chips, v_bbs, v_flag
    FROM gfx_hand_players ghp
    JOIN gfx_hands gh ON ghp.hand_id = gh.id
    LEFT JOIN gfx_players gp ON ghp.player_id = gp.id
    -- player_overrides 조인 (이름 오버라이드)
    LEFT JOIN player_overrides po_name
        ON po_name.gfx_player_id = gp.id
        AND po_name.field_name = 'name'
        AND po_name.active = TRUE
    -- player_overrides 조인 (국가 코드 오버라이드)
    LEFT JOIN player_overrides po_country
        ON po_country.gfx_player_id = gp.id
        AND po_country.field_name = 'country_code'
        AND po_country.active = TRUE
    WHERE gh.session_id = p_session_id
      AND gh.hand_num = p_hand_num
      AND ghp.seat_num = p_seat_num;

    IF v_player_name IS NULL THEN
        RETURN '{}'::JSONB;
    END IF;

    -- 변형별 결과 생성
    v_result := jsonb_build_object(
        '$schema', 'render_gfx_data_v3',
        'version', '3.0.0',
        'comp_name', p_variant,
        'render_type', 'player_name',
        'single_fields', CASE p_variant
            WHEN 'NAME' THEN jsonb_build_object(
                'player_name', v_player_name,
                'chips', v_chips,
                'bbs', v_bbs,
                'flag', v_flag
            )
            WHEN 'NAME 1줄' THEN jsonb_build_object(
                'player_name', v_player_name,
                'flag', v_flag
            )
            WHEN 'NAME 2줄 (국기 빼고)' THEN jsonb_build_object(
                'player_name', v_player_name,
                'chips', v_chips,
                'bbs', v_bbs
            )
            ELSE jsonb_build_object(
                'player_name', v_player_name
            )
        END,
        'metadata', jsonb_build_object(
            'session_id', p_session_id,
            'hand_num', p_hand_num,
            'seat_num', p_seat_num,
            'variant', p_variant,
            'data_sources', ARRAY['gfx_hand_players', 'gfx_hands', 'player_overrides'],
            'generated_at', NOW(),
            'schema_version', '3.0.0'
        )
    );

    RETURN v_result;
END;
$_$;


ALTER FUNCTION "public"."get_player_name_data"("p_session_id" bigint, "p_hand_num" integer, "p_seat_num" integer, "p_variant" "text") OWNER TO "postgres";


COMMENT ON FUNCTION "public"."get_player_name_data"("p_session_id" bigint, "p_hand_num" integer, "p_seat_num" integer, "p_variant" "text") IS 'NAME/NAME 1줄/NAME 2줄 컴포지션용 gfx_data JSON 생성. v2.0.0 필드 확장.';



CREATE OR REPLACE FUNCTION "public"."increment_template_usage"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    IF NEW.template_id IS NOT NULL THEN
        UPDATE cue_templates
        SET
            usage_count = usage_count + 1,
            last_used_at = NOW()
        WHERE id = NEW.template_id;
    END IF;
    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."increment_template_usage"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."log_activity"("p_action" "text", "p_actor" "text", "p_actor_type" "public"."orch_actor_type", "p_entity_type" "text" DEFAULT NULL::"text", "p_entity_id" "uuid" DEFAULT NULL::"uuid", "p_changes" "jsonb" DEFAULT NULL::"jsonb", "p_metadata" "jsonb" DEFAULT NULL::"jsonb") RETURNS "uuid"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    v_log_id UUID;
BEGIN
    INSERT INTO activity_log (
        action,
        actor,
        actor_type,
        entity_type,
        entity_id,
        changes,
        metadata,
        ip_address,
        request_id
    ) VALUES (
        p_action,
        p_actor,
        p_actor_type,
        p_entity_type,
        p_entity_id,
        p_changes,
        p_metadata,
        NULLIF(current_setting('app.client_ip', TRUE), '')::INET,
        current_setting('app.request_id', TRUE)
    )
    RETURNING id INTO v_log_id;

    RETURN v_log_id;
END;
$$;


ALTER FUNCTION "public"."log_activity"("p_action" "text", "p_actor" "text", "p_actor_type" "public"."orch_actor_type", "p_entity_type" "text", "p_entity_id" "uuid", "p_changes" "jsonb", "p_metadata" "jsonb") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."log_manual_audit"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    v_old_values JSONB;
    v_new_values JSONB;
    v_changed_fields TEXT[];
    v_action manual_audit_action;
BEGIN
    -- 액션 결정
    IF TG_OP = 'INSERT' THEN
        v_action := 'INSERT';
        v_new_values := to_jsonb(NEW);
        v_old_values := NULL;
    ELSIF TG_OP = 'UPDATE' THEN
        v_action := 'UPDATE';
        v_old_values := to_jsonb(OLD);
        v_new_values := to_jsonb(NEW);

        -- 변경된 필드 찾기
        SELECT ARRAY_AGG(key)
        INTO v_changed_fields
        FROM jsonb_each(v_old_values) old_kv
        JOIN jsonb_each(v_new_values) new_kv USING (key)
        WHERE old_kv.value IS DISTINCT FROM new_kv.value;
    ELSIF TG_OP = 'DELETE' THEN
        v_action := 'DELETE';
        v_old_values := to_jsonb(OLD);
        v_new_values := NULL;
    END IF;

    -- 로그 기록
    INSERT INTO manual_audit_log (
        table_name,
        record_id,
        action,
        old_values,
        new_values,
        changed_fields,
        changed_by,
        changed_at
    ) VALUES (
        TG_TABLE_NAME,
        COALESCE(NEW.id, OLD.id),
        v_action,
        v_old_values,
        v_new_values,
        v_changed_fields,
        COALESCE(current_setting('app.current_user', TRUE), 'system'),
        NOW()
    );

    RETURN COALESCE(NEW, OLD);
END;
$$;


ALTER FUNCTION "public"."log_manual_audit"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."normalize_manual_player_name"("p_name" "text") RETURNS "text"
    LANGUAGE "plpgsql" IMMUTABLE
    AS $$
BEGIN
    RETURN LOWER(
        REGEXP_REPLACE(
            TRIM(p_name),
            '[^a-zA-Z0-9가-힣\s]',
            '',
            'g'
        )
    );
END;
$$;


ALTER FUNCTION "public"."normalize_manual_player_name"("p_name" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."normalize_player_name"("p_name" "text") RETURNS "text"
    LANGUAGE "plpgsql" IMMUTABLE
    AS $$
BEGIN
    IF p_name IS NULL THEN
        RETURN '';
    END IF;
    RETURN LOWER(TRIM(p_name));
END;
$$;


ALTER FUNCTION "public"."normalize_player_name"("p_name" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."parse_iso8601_duration"("duration" "text") RETURNS numeric
    LANGUAGE "plpgsql" IMMUTABLE
    AS $$
DECLARE
    days_match TEXT[];
    hours_match TEXT[];
    minutes_match TEXT[];
    seconds_match TEXT[];
    total_seconds NUMERIC := 0;
BEGIN
    IF duration IS NULL OR duration = '' THEN
        RETURN 0;
    END IF;

    -- 일 (D)
    days_match := regexp_match(duration, '(\d+(?:\.\d+)?)D', 'i');
    IF days_match IS NOT NULL THEN
        total_seconds := total_seconds + (days_match[1]::NUMERIC * 86400);
    END IF;

    -- 시간 (H)
    hours_match := regexp_match(duration, '(\d+(?:\.\d+)?)H', 'i');
    IF hours_match IS NOT NULL THEN
        total_seconds := total_seconds + (hours_match[1]::NUMERIC * 3600);
    END IF;

    -- 분 (M) - T 이후에만
    minutes_match := regexp_match(duration, 'T.*?(\d+(?:\.\d+)?)M', 'i');
    IF minutes_match IS NOT NULL THEN
        total_seconds := total_seconds + (minutes_match[1]::NUMERIC * 60);
    END IF;

    -- 초 (S)
    seconds_match := regexp_match(duration, '(\d+(?:\.\d+)?)S', 'i');
    IF seconds_match IS NOT NULL THEN
        total_seconds := total_seconds + seconds_match[1]::NUMERIC;
    END IF;

    RETURN total_seconds;
END;
$$;


ALTER FUNCTION "public"."parse_iso8601_duration"("duration" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."set_manual_normalized_name"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    NEW.name_normalized = normalize_manual_player_name(NEW.name);
    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."set_manual_normalized_name"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."set_normalized_name"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    NEW.name_normalized = normalize_player_name(NEW.name);
    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."set_normalized_name"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."set_player_code"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    IF NEW.player_code IS NULL OR NEW.player_code = '' THEN
        NEW.player_code = generate_player_code();
    END IF;
    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."set_player_code"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."transition_cue_item_status"("p_item_id" "uuid", "p_new_status" "public"."cue_item_status", "p_triggered_by" "text" DEFAULT 'system'::"text") RETURNS "void"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    v_item RECORD;
BEGIN
    -- 아이템 조회
    SELECT * INTO v_item FROM cue_items WHERE id = p_item_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Cue item not found: %', p_item_id;
    END IF;

    -- 상태 업데이트
    UPDATE cue_items
    SET
        status = p_new_status,
        actual_time = CASE WHEN p_new_status = 'on_air' THEN NOW() ELSE actual_time END,
        last_triggered_by = p_triggered_by,
        last_triggered_at = NOW()
    WHERE id = p_item_id;

    -- on_air 상태로 전환 시 트리거 로그 기록
    IF p_new_status = 'on_air' THEN
        INSERT INTO gfx_triggers (
            cue_item_id,
            session_id,
            sheet_id,
            trigger_type,
            triggered_by,
            cue_type,
            aep_comp_name,
            gfx_template_name,
            gfx_data
        )
        SELECT
            ci.id,
            cs.session_id,
            ci.sheet_id,
            'manual',
            p_triggered_by,
            ci.cue_type,
            ci.gfx_comp_name,
            ci.gfx_template_name,
            ci.gfx_data
        FROM cue_items ci
        JOIN cue_sheets cs ON ci.sheet_id = cs.id
        WHERE ci.id = p_item_id;

        -- 큐시트의 현재 아이템 업데이트
        UPDATE cue_sheets
        SET current_item_id = p_item_id
        WHERE id = v_item.sheet_id;
    END IF;
END;
$$;


ALTER FUNCTION "public"."transition_cue_item_status"("p_item_id" "uuid", "p_new_status" "public"."cue_item_status", "p_triggered_by" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_cue_sheet_stats"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    -- 큐시트 통계 업데이트
    UPDATE cue_sheets
    SET
        total_items = (
            SELECT COUNT(*) FROM cue_items WHERE sheet_id = COALESCE(NEW.sheet_id, OLD.sheet_id)
        ),
        completed_items = (
            SELECT COUNT(*) FROM cue_items
            WHERE sheet_id = COALESCE(NEW.sheet_id, OLD.sheet_id)
              AND status = 'completed'
        ),
        updated_at = NOW()
    WHERE id = COALESCE(NEW.sheet_id, OLD.sheet_id);

    RETURN COALESCE(NEW, OLD);
END;
$$;


ALTER FUNCTION "public"."update_cue_sheet_stats"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_cue_updated_at_column"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."update_cue_updated_at_column"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_event_player_stats"("p_event_id" "uuid") RETURNS "void"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    v_total_entries INTEGER;
    v_avg_stack BIGINT;
BEGIN
    -- 총 참가자 수
    SELECT COUNT(*)
    INTO v_total_entries
    FROM wsop_event_players
    WHERE event_id = p_event_id;

    -- 평균 스택 (활성 플레이어 기준)
    SELECT AVG(current_chips)::BIGINT
    INTO v_avg_stack
    FROM wsop_event_players
    WHERE event_id = p_event_id AND status = 'active';

    -- 이벤트 업데이트
    UPDATE wsop_events
    SET
        total_entries = v_total_entries,
        updated_at = NOW()
    WHERE id = p_event_id;
END;
$$;


ALTER FUNCTION "public"."update_event_player_stats"("p_event_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_event_rankings"("p_event_id" "uuid") RETURNS "void"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    -- 활성 플레이어 순위 업데이트
    UPDATE wsop_event_players ep
    SET rank = ranking.new_rank
    FROM (
        SELECT
            id,
            ROW_NUMBER() OVER (ORDER BY current_chips DESC) AS new_rank
        FROM wsop_event_players
        WHERE event_id = p_event_id AND status = 'active'
    ) ranking
    WHERE ep.id = ranking.id AND ep.event_id = p_event_id;
END;
$$;


ALTER FUNCTION "public"."update_event_rankings"("p_event_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_manual_updated_at_column"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."update_manual_updated_at_column"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_session_stats"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    -- 세션 통계 업데이트
    UPDATE broadcast_sessions
    SET
        total_cue_items = (
            SELECT COALESCE(SUM(total_items), 0)
            FROM cue_sheets
            WHERE session_id = COALESCE(NEW.session_id, OLD.session_id)
        ),
        completed_cue_items = (
            SELECT COALESCE(SUM(completed_items), 0)
            FROM cue_sheets
            WHERE session_id = COALESCE(NEW.session_id, OLD.session_id)
        ),
        updated_at = NOW()
    WHERE id = COALESCE(NEW.session_id, OLD.session_id);

    RETURN COALESCE(NEW, OLD);
END;
$$;


ALTER FUNCTION "public"."update_session_stats"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_session_stats"("p_session_id" bigint) RETURNS "void"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    UPDATE gfx_sessions
    SET
        hand_count = (
            SELECT COUNT(*) FROM gfx_hands WHERE session_id = p_session_id
        ),
        total_duration_seconds = (
            SELECT COALESCE(SUM(duration_seconds), 0)
            FROM gfx_hands WHERE session_id = p_session_id
        ),
        session_start_time = (
            SELECT MIN(start_time) FROM gfx_hands WHERE session_id = p_session_id
        ),
        session_end_time = (
            SELECT MAX(start_time + (duration_seconds || ' seconds')::INTERVAL)
            FROM gfx_hands WHERE session_id = p_session_id
        ),
        updated_at = NOW()
    WHERE session_id = p_session_id;
END;
$$;


ALTER FUNCTION "public"."update_session_stats"("p_session_id" bigint) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_sync_completion"("p_sync_status_id" "uuid", "p_success" boolean, "p_records_processed" integer DEFAULT 0, "p_records_created" integer DEFAULT 0, "p_records_updated" integer DEFAULT 0, "p_records_failed" integer DEFAULT 0, "p_duration_ms" integer DEFAULT 0, "p_error_message" "text" DEFAULT NULL::"text", "p_sync_hash" "text" DEFAULT NULL::"text") RETURNS "void"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    -- sync_status 업데이트
    UPDATE sync_status
    SET
        status = CASE WHEN p_success THEN 'synced' ELSE 'failed' END,
        last_synced_at = NOW(),
        last_sync_duration_ms = p_duration_ms,
        sync_hash = COALESCE(p_sync_hash, sync_hash),
        last_record_count = p_records_processed,
        last_created_count = p_records_created,
        last_updated_count = p_records_updated,
        total_records = CASE WHEN p_success THEN total_records + p_records_created ELSE total_records END,
        last_error = p_error_message,
        last_error_at = CASE WHEN NOT p_success THEN NOW() ELSE last_error_at END,
        consecutive_failures = CASE WHEN p_success THEN 0 ELSE consecutive_failures + 1 END,
        next_sync_at = NOW() + (sync_interval_minutes || ' minutes')::INTERVAL,
        updated_at = NOW()
    WHERE id = p_sync_status_id;

    -- sync_history 기록
    INSERT INTO sync_history (
        sync_status_id,
        operation,
        source,
        entity_type,
        records_processed,
        records_created,
        records_updated,
        records_failed,
        duration_ms,
        started_at,
        completed_at
    )
    SELECT
        p_sync_status_id,
        'incremental',
        source,
        entity_type,
        p_records_processed,
        p_records_created,
        p_records_updated,
        p_records_failed,
        p_duration_ms,
        NOW() - (p_duration_ms || ' milliseconds')::INTERVAL,
        NOW()
    FROM sync_status
    WHERE id = p_sync_status_id;
END;
$$;


ALTER FUNCTION "public"."update_sync_completion"("p_sync_status_id" "uuid", "p_success" boolean, "p_records_processed" integer, "p_records_created" integer, "p_records_updated" integer, "p_records_failed" integer, "p_duration_ms" integer, "p_error_message" "text", "p_sync_hash" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_updated_at_column"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."update_updated_at_column"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_wsop_updated_at_column"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."update_wsop_updated_at_column"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."validate_mapping_slot_range"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    v_slot_count INTEGER;
    v_slot_field_keys TEXT[];
    v_single_field_keys TEXT[];
BEGIN
    -- 컴포지션 정보 조회
    SELECT slot_count, slot_field_keys, single_field_keys
    INTO v_slot_count, v_slot_field_keys, v_single_field_keys
    FROM gfx_aep_compositions
    WHERE name = NEW.composition_name;

    -- 컴포지션이 없으면 FK에서 처리하므로 패스
    IF NOT FOUND THEN
        RETURN NEW;
    END IF;

    -- 슬롯 범위 검증 (slot_count > 0인 경우만)
    IF v_slot_count > 0 AND NEW.slot_range_end IS NOT NULL THEN
        IF NEW.slot_range_end > v_slot_count THEN
            RAISE EXCEPTION 'slot_range_end (%) exceeds composition slot_count (%) for composition "%"',
                NEW.slot_range_end, v_slot_count, NEW.composition_name;
        END IF;
    END IF;

    -- target_field_key 검증 (슬롯 필드인 경우)
    IF NEW.slot_range_start IS NOT NULL THEN
        -- 슬롯 필드인 경우 slot_field_keys에 있어야 함
        IF v_slot_field_keys IS NOT NULL AND array_length(v_slot_field_keys, 1) > 0 THEN
            IF NOT (NEW.target_field_key = ANY(v_slot_field_keys)) THEN
                RAISE EXCEPTION 'target_field_key "%" not in slot_field_keys for composition "%"',
                    NEW.target_field_key, NEW.composition_name;
            END IF;
        END IF;
    END IF;

    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."validate_mapping_slot_range"() OWNER TO "postgres";


COMMENT ON FUNCTION "public"."validate_mapping_slot_range"() IS '매핑 규칙의 슬롯 범위와 필드 키 유효성 검증';



CREATE OR REPLACE FUNCTION "public"."validate_transform_params"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    -- format_bbs는 big_blind 정보가 필요하지만,
    -- 현재 구조에서는 런타임에 결정되므로 여기서는 검증하지 않음

    -- 향후 필요시 transform_params JSON 스키마 검증 추가
    -- 예: format_bbs인 경우 bb_column 파라미터 필수 등

    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."validate_transform_params"() OWNER TO "postgres";


COMMENT ON FUNCTION "public"."validate_transform_params"() IS 'transform 파라미터 유효성 검증 (향후 확장용)';


SET default_tablespace = '';

SET default_table_access_method = "heap";


CREATE TABLE IF NOT EXISTS "public"."activity_log" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "action" "text" NOT NULL,
    "action_category" "text",
    "actor" "text" NOT NULL,
    "actor_type" "public"."orch_actor_type" NOT NULL,
    "actor_id" "uuid",
    "entity_type" "text",
    "entity_id" "uuid",
    "entity_name" "text",
    "changes" "jsonb",
    "metadata" "jsonb" DEFAULT '{}'::"jsonb",
    "ip_address" "inet",
    "user_agent" "text",
    "request_id" "text",
    "success" boolean DEFAULT true,
    "error_message" "text",
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."activity_log" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."aep_media_sources" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "category" character varying(50) NOT NULL,
    "country_code" character varying(10),
    "name" "text" NOT NULL,
    "file_path" "text" NOT NULL,
    "file_type" character varying(20) DEFAULT 'png'::character varying,
    "is_active" boolean DEFAULT true,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."aep_media_sources" OWNER TO "postgres";


COMMENT ON TABLE "public"."aep_media_sources" IS 'AEP 미디어 소스 경로 관리 (국기, 프로필 이미지 등)';



COMMENT ON COLUMN "public"."aep_media_sources"."category" IS 'Flag, Profile, Logo 등 미디어 카테고리';



COMMENT ON COLUMN "public"."aep_media_sources"."country_code" IS 'ISO 3166-1 alpha-2 국가 코드';



COMMENT ON COLUMN "public"."aep_media_sources"."file_path" IS 'AEP 프로젝트 내부 상대 경로';



CREATE TABLE IF NOT EXISTS "public"."api_keys" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "key_hash" "text" NOT NULL,
    "key_prefix" "text" NOT NULL,
    "name" "text" NOT NULL,
    "permissions" "jsonb" DEFAULT '[]'::"jsonb",
    "rate_limit_per_minute" integer DEFAULT 60,
    "rate_limit_per_day" integer DEFAULT 10000,
    "allowed_ips" "inet"[] DEFAULT ARRAY[]::"inet"[],
    "allowed_origins" "text"[] DEFAULT ARRAY[]::"text"[],
    "is_active" boolean DEFAULT true,
    "expires_at" timestamp with time zone,
    "last_used_at" timestamp with time zone,
    "total_requests" integer DEFAULT 0,
    "last_request_ip" "inet",
    "description" "text",
    "metadata" "jsonb" DEFAULT '{}'::"jsonb",
    "created_by" "text" NOT NULL,
    "revoked_by" "text",
    "revoked_at" timestamp with time zone,
    "revoke_reason" "text",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."api_keys" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."broadcast_sessions" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "session_code" "text" NOT NULL,
    "event_id" "uuid",
    "event_name" "text" NOT NULL,
    "event_description" "text",
    "broadcast_date" "date" NOT NULL,
    "scheduled_start" timestamp with time zone NOT NULL,
    "scheduled_end" timestamp with time zone,
    "actual_start" timestamp with time zone,
    "actual_end" timestamp with time zone,
    "status" "public"."cue_broadcast_status" DEFAULT 'draft'::"public"."cue_broadcast_status",
    "current_sheet_id" "uuid",
    "director" "text",
    "technical_director" "text",
    "producer" "text",
    "commentators" "jsonb" DEFAULT '[]'::"jsonb",
    "reporters" "jsonb" DEFAULT '[]'::"jsonb",
    "settings" "jsonb" DEFAULT '{}'::"jsonb",
    "total_cue_items" integer DEFAULT 0,
    "completed_cue_items" integer DEFAULT 0,
    "total_duration_minutes" integer DEFAULT 0,
    "notes" "text",
    "tags" "text"[] DEFAULT ARRAY[]::"text"[],
    "created_by" "text" NOT NULL,
    "approved_by" "text",
    "approved_at" timestamp with time zone,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."broadcast_sessions" OWNER TO "postgres";


COMMENT ON TABLE "public"."broadcast_sessions" IS '방송 세션 정보';



COMMENT ON COLUMN "public"."broadcast_sessions"."commentators" IS '[{"name": "홍길동", "role": "main", "language": "ko"}]';



COMMENT ON COLUMN "public"."broadcast_sessions"."settings" IS '{"default_gfx_duration": 10, "auto_advance": true}';



CREATE TABLE IF NOT EXISTS "public"."cue_items" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "sheet_id" "uuid" NOT NULL,
    "template_id" "uuid",
    "special_info" "text",
    "content_type" "public"."cue_content_type" NOT NULL,
    "hand_number" integer,
    "hand_rank" "public"."cue_hand_rank",
    "hand_history" "text",
    "edit_point" "text",
    "pd_note" "text",
    "recording_time" time without time zone,
    "subtitle_flag" boolean DEFAULT false,
    "blind_level" "text",
    "subtitle_confirm" "text",
    "subtitle_team" "text",
    "post_flag" boolean DEFAULT false,
    "copy_status" "text",
    "file_name" "text",
    "transition" "text",
    "timecode_in" "text",
    "timecode_out" "text",
    "cue_number" "text",
    "cue_type" "public"."cue_item_type",
    "gfx_template_name" "text",
    "gfx_comp_name" "text",
    "gfx_data" "jsonb" DEFAULT '{}'::"jsonb",
    "duration_seconds" integer DEFAULT 10,
    "scheduled_time" timestamp with time zone,
    "actual_time" timestamp with time zone,
    "sort_order" integer DEFAULT 0 NOT NULL,
    "status" "public"."cue_item_status" DEFAULT 'pending'::"public"."cue_item_status",
    "created_by" "text",
    "last_triggered_by" "text",
    "last_triggered_at" timestamp with time zone,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."cue_items" OWNER TO "postgres";


COMMENT ON TABLE "public"."cue_items" IS '개별 큐 아이템 (Google Sheets LIVE 시트 매핑)';



COMMENT ON COLUMN "public"."cue_items"."hand_history" IS 'Pre: AK RAISE\nFlop: 44 CHECK, AK BET\nTurn: 44 BET, AK CALL';



CREATE TABLE IF NOT EXISTS "public"."cue_sheets" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "sheet_code" "text" NOT NULL,
    "session_id" "uuid" NOT NULL,
    "sheet_name" "text" NOT NULL,
    "sheet_type" "public"."cue_sheet_type" DEFAULT 'main_show'::"public"."cue_sheet_type" NOT NULL,
    "sheet_order" integer DEFAULT 0 NOT NULL,
    "version" integer DEFAULT 1,
    "parent_version_id" "uuid",
    "status" "public"."cue_sheet_status" DEFAULT 'draft'::"public"."cue_sheet_status",
    "total_items" integer DEFAULT 0,
    "completed_items" integer DEFAULT 0,
    "current_item_id" "uuid",
    "current_item_index" integer DEFAULT 0,
    "estimated_duration_minutes" integer,
    "actual_duration_minutes" integer,
    "settings_override" "jsonb" DEFAULT '{}'::"jsonb",
    "description" "text",
    "notes" "text",
    "created_by" "text" NOT NULL,
    "last_modified_by" "text",
    "started_at" timestamp with time zone,
    "completed_at" timestamp with time zone,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."cue_sheets" OWNER TO "postgres";


COMMENT ON TABLE "public"."cue_sheets" IS '방송 큐시트 (방송 세션 내의 구간별 큐 목록)';



CREATE TABLE IF NOT EXISTS "public"."cue_templates" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "template_code" "text" NOT NULL,
    "template_name" "text" NOT NULL,
    "description" "text",
    "template_type" "public"."cue_template_type" NOT NULL,
    "position" "text",
    "gfx_template_name" "text",
    "gfx_comp_name" "text",
    "default_duration" integer DEFAULT 10,
    "data_schema" "jsonb" DEFAULT '{}'::"jsonb",
    "sample_data" "jsonb" DEFAULT '{}'::"jsonb",
    "preview_image_url" "text",
    "category" "text",
    "tags" "text"[] DEFAULT ARRAY[]::"text"[],
    "is_active" boolean DEFAULT true,
    "usage_count" integer DEFAULT 0,
    "last_used_at" timestamp with time zone,
    "created_by" "text",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."cue_templates" OWNER TO "postgres";


COMMENT ON TABLE "public"."cue_templates" IS '재사용 가능한 큐 템플릿 (Google Sheets template 시트)';



CREATE TABLE IF NOT EXISTS "public"."gfx_aep_compositions" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" character varying(255) NOT NULL,
    "category" "public"."aep_composition_category" NOT NULL,
    "display_name" character varying(255),
    "description" "text",
    "slot_count" integer DEFAULT 0,
    "slot_field_keys" "text"[],
    "single_field_keys" "text"[],
    "aep_project_path" "text",
    "aep_comp_name" "text",
    "default_output_format" character varying(20) DEFAULT 'mp4'::character varying,
    "default_duration_seconds" numeric(10,2),
    "metadata" "jsonb" DEFAULT '{}'::"jsonb",
    "is_active" boolean DEFAULT true,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."gfx_aep_compositions" OWNER TO "postgres";


COMMENT ON TABLE "public"."gfx_aep_compositions" IS '26개 AEP 컴포지션 메타데이터. 카테고리, 슬롯 수, 필드 키 정보.';



CREATE TABLE IF NOT EXISTS "public"."gfx_aep_field_mappings" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "composition_name" character varying(255) NOT NULL,
    "composition_category" "public"."aep_composition_category" NOT NULL,
    "target_field_key" character varying(100) NOT NULL,
    "target_layer_pattern" character varying(255),
    "slot_range_start" integer,
    "slot_range_end" integer,
    "source_table" character varying(100) NOT NULL,
    "source_column" character varying(100) NOT NULL,
    "source_join" "text",
    "source_filter" "text",
    "transform" "public"."aep_transform_type" DEFAULT 'direct'::"public"."aep_transform_type",
    "transform_params" "jsonb",
    "slot_order_by" character varying(100),
    "slot_order_direction" character varying(10) DEFAULT 'ASC'::character varying,
    "default_value" "text" DEFAULT ''::"text",
    "priority" integer DEFAULT 100,
    "is_active" boolean DEFAULT true,
    "notes" "text",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    CONSTRAINT "chk_order_direction" CHECK ((("slot_order_direction" IS NULL) OR (("slot_order_direction")::"text" = ANY ((ARRAY['ASC'::character varying, 'DESC'::character varying])::"text"[])))),
    CONSTRAINT "chk_priority_range" CHECK ((("priority" >= 0) AND ("priority" <= 1000))),
    CONSTRAINT "chk_slot_range_valid" CHECK ((("slot_range_start" IS NULL) OR ("slot_range_end" IS NULL) OR (("slot_range_start" >= 1) AND ("slot_range_end" >= "slot_range_start"))))
);


ALTER TABLE "public"."gfx_aep_field_mappings" OWNER TO "postgres";


COMMENT ON TABLE "public"."gfx_aep_field_mappings" IS 'GFX JSON DB → AEP 컴포지션 필드 매핑 규칙. GFX_AEP_FIELD_MAPPING.md 문서 기반.';



COMMENT ON CONSTRAINT "chk_order_direction" ON "public"."gfx_aep_field_mappings" IS '정렬 방향 제한: ASC 또는 DESC만 허용';



COMMENT ON CONSTRAINT "chk_priority_range" ON "public"."gfx_aep_field_mappings" IS '우선순위 범위: 0-1000 (낮을수록 높은 우선순위)';



COMMENT ON CONSTRAINT "chk_slot_range_valid" ON "public"."gfx_aep_field_mappings" IS '슬롯 범위 유효성: start >= 1, end >= start';



CREATE TABLE IF NOT EXISTS "public"."gfx_events" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "hand_id" "uuid" NOT NULL,
    "event_order" integer NOT NULL,
    "event_type" "public"."event_type" NOT NULL,
    "player_num" integer DEFAULT 0,
    "bet_amt" integer DEFAULT 0,
    "pot" integer DEFAULT 0,
    "board_cards" "text",
    "board_num" integer DEFAULT 0,
    "num_cards_drawn" integer DEFAULT 0,
    "event_time" timestamp with time zone,
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."gfx_events" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."gfx_hand_players" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "hand_id" "uuid" NOT NULL,
    "player_id" "uuid",
    "seat_num" integer NOT NULL,
    "player_name" "text" NOT NULL,
    "hole_cards" "text"[] DEFAULT ARRAY[]::"text"[],
    "has_shown" boolean DEFAULT false,
    "start_stack_amt" integer DEFAULT 0,
    "end_stack_amt" integer DEFAULT 0,
    "cumulative_winnings_amt" integer DEFAULT 0,
    "blind_bet_straddle_amt" integer DEFAULT 0,
    "sitting_out" boolean DEFAULT false,
    "elimination_rank" integer DEFAULT '-1'::integer,
    "is_winner" boolean DEFAULT false,
    "vpip_percent" numeric(5,2) DEFAULT 0,
    "preflop_raise_percent" numeric(5,2) DEFAULT 0,
    "aggression_frequency_percent" numeric(5,2) DEFAULT 0,
    "went_to_showdown_percent" numeric(5,2) DEFAULT 0,
    "created_at" timestamp with time zone DEFAULT "now"(),
    CONSTRAINT "gfx_hand_players_seat_num_check" CHECK ((("seat_num" >= 1) AND ("seat_num" <= 10)))
);


ALTER TABLE "public"."gfx_hand_players" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."gfx_hands" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "session_id" bigint NOT NULL,
    "hand_num" integer NOT NULL,
    "game_variant" "public"."game_variant" DEFAULT 'HOLDEM'::"public"."game_variant",
    "game_class" "public"."game_class" DEFAULT 'FLOP'::"public"."game_class",
    "bet_structure" "public"."bet_structure" DEFAULT 'NOLIMIT'::"public"."bet_structure",
    "duration_seconds" integer DEFAULT 0,
    "start_time" timestamp with time zone NOT NULL,
    "recording_offset_iso" "text",
    "recording_offset_seconds" bigint,
    "num_boards" integer DEFAULT 1,
    "run_it_num_times" integer DEFAULT 1,
    "ante_amt" integer DEFAULT 0,
    "bomb_pot_amt" integer DEFAULT 0,
    "description" "text" DEFAULT ''::"text",
    "blinds" "jsonb" DEFAULT '{}'::"jsonb",
    "stud_limits" "jsonb" DEFAULT '{}'::"jsonb",
    "pot_size" integer DEFAULT 0,
    "player_count" integer DEFAULT 0,
    "showdown_count" integer DEFAULT 0,
    "board_cards" "text"[] DEFAULT ARRAY[]::"text"[],
    "winner_name" "text",
    "winner_seat" integer,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."gfx_hands" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."gfx_players" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "player_hash" "text" NOT NULL,
    "name" "text" NOT NULL,
    "long_name" "text" DEFAULT ''::"text",
    "total_hands_played" integer DEFAULT 0,
    "total_sessions" integer DEFAULT 0,
    "first_seen_at" timestamp with time zone DEFAULT "now"(),
    "last_seen_at" timestamp with time zone DEFAULT "now"(),
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."gfx_players" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."gfx_sessions" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "session_id" bigint NOT NULL,
    "file_name" "text" NOT NULL,
    "file_hash" "text" NOT NULL,
    "nas_path" "text",
    "table_type" "public"."table_type" DEFAULT 'UNKNOWN'::"public"."table_type" NOT NULL,
    "event_title" "text" DEFAULT ''::"text",
    "software_version" "text" DEFAULT ''::"text",
    "payouts" integer[] DEFAULT ARRAY[]::integer[],
    "hand_count" integer DEFAULT 0,
    "player_count" integer DEFAULT 0,
    "total_duration_seconds" integer DEFAULT 0,
    "session_created_at" timestamp with time zone,
    "session_start_time" timestamp with time zone,
    "session_end_time" timestamp with time zone,
    "raw_json" "jsonb" NOT NULL,
    "sync_status" "public"."gfx_sync_status" DEFAULT 'pending'::"public"."gfx_sync_status",
    "sync_error" "text",
    "processed_at" timestamp with time zone DEFAULT "now"(),
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."gfx_sessions" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."gfx_triggers" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "cue_item_id" "uuid",
    "session_id" "uuid",
    "sheet_id" "uuid",
    "trigger_type" "public"."cue_trigger_type" NOT NULL,
    "trigger_time" timestamp with time zone DEFAULT "now"() NOT NULL,
    "triggered_by" "text" NOT NULL,
    "cue_type" "public"."cue_item_type",
    "aep_comp_name" "text",
    "gfx_template_name" "text",
    "gfx_data" "jsonb",
    "render_status" "public"."cue_render_status" DEFAULT 'pending'::"public"."cue_render_status",
    "render_job_id" "uuid",
    "render_started_at" timestamp with time zone,
    "render_completed_at" timestamp with time zone,
    "output_path" "text",
    "output_format" "text",
    "output_resolution" "text",
    "file_size_bytes" bigint,
    "duration_ms" integer,
    "render_duration_ms" integer,
    "queue_wait_ms" integer,
    "error_message" "text",
    "error_details" "jsonb",
    "retry_count" integer DEFAULT 0,
    "notes" "text",
    "metadata" "jsonb" DEFAULT '{}'::"jsonb",
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."gfx_triggers" OWNER TO "postgres";


COMMENT ON TABLE "public"."gfx_triggers" IS 'GFX 송출 트리거 로그 (모든 GFX 송출 이력)';



CREATE TABLE IF NOT EXISTS "public"."hand_grades" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "hand_id" "uuid" NOT NULL,
    "grade" character(1) NOT NULL,
    "has_premium_hand" boolean DEFAULT false,
    "has_long_playtime" boolean DEFAULT false,
    "has_premium_board_combo" boolean DEFAULT false,
    "conditions_met" integer NOT NULL,
    "broadcast_eligible" boolean DEFAULT false,
    "suggested_edit_start_offset" integer,
    "edit_start_confidence" numeric(3,2),
    "graded_by" "text",
    "graded_at" timestamp with time zone DEFAULT "now"(),
    "notes" "text",
    "created_at" timestamp with time zone DEFAULT "now"(),
    CONSTRAINT "hand_grades_conditions_met_check" CHECK ((("conditions_met" >= 0) AND ("conditions_met" <= 3))),
    CONSTRAINT "hand_grades_grade_check" CHECK (("grade" = ANY (ARRAY['A'::"bpchar", 'B'::"bpchar", 'C'::"bpchar"])))
);


ALTER TABLE "public"."hand_grades" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."job_queue" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "job_type" "public"."orch_job_type" NOT NULL,
    "job_name" "text" NOT NULL,
    "job_group" "text",
    "priority" integer DEFAULT 100,
    "payload" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "status" "public"."orch_job_status" DEFAULT 'pending'::"public"."orch_job_status",
    "progress" integer DEFAULT 0,
    "progress_message" "text",
    "result" "jsonb",
    "retry_count" integer DEFAULT 0,
    "max_retries" integer DEFAULT 3,
    "retry_delay_seconds" integer DEFAULT 60,
    "scheduled_at" timestamp with time zone,
    "started_at" timestamp with time zone,
    "completed_at" timestamp with time zone,
    "timeout_seconds" integer DEFAULT 3600,
    "error_message" "text",
    "error_details" "jsonb",
    "error_stack" "text",
    "worker_id" "text",
    "locked_at" timestamp with time zone,
    "lock_expires_at" timestamp with time zone,
    "depends_on" "uuid"[] DEFAULT ARRAY[]::"uuid"[],
    "parent_job_id" "uuid",
    "tags" "text"[] DEFAULT ARRAY[]::"text"[],
    "metadata" "jsonb" DEFAULT '{}'::"jsonb",
    "created_by" "text" NOT NULL,
    "cancelled_by" "text",
    "cancelled_at" timestamp with time zone,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."job_queue" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."notifications" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "type" "public"."orch_notification_type" NOT NULL,
    "level" "public"."orch_notification_level" DEFAULT 'medium'::"public"."orch_notification_level",
    "title" "text" NOT NULL,
    "message" "text" NOT NULL,
    "data" "jsonb" DEFAULT '{}'::"jsonb",
    "source" "public"."orch_data_source",
    "entity_type" "text",
    "entity_id" "uuid",
    "job_id" "uuid",
    "target_user" "text",
    "target_role" "text",
    "read" boolean DEFAULT false,
    "read_at" timestamp with time zone,
    "read_by" "text",
    "dismissed" boolean DEFAULT false,
    "dismissed_at" timestamp with time zone,
    "dismissed_by" "text",
    "expires_at" timestamp with time zone,
    "action_url" "text",
    "action_label" "text",
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."notifications" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."player_link_mapping" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "wsop_player_id" "uuid",
    "gfx_player_id" "uuid",
    "match_confidence" numeric(5,2),
    "match_method" "public"."manual_match_method" DEFAULT 'manual'::"public"."manual_match_method" NOT NULL,
    "match_score" numeric(5,2),
    "match_evidence" "jsonb" DEFAULT '{}'::"jsonb",
    "is_verified" boolean DEFAULT false,
    "verified_by" "text",
    "verified_at" timestamp with time zone,
    "notes" "text",
    "merge_priority" character varying(20) DEFAULT 'manual'::character varying,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."player_link_mapping" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."player_overrides" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "wsop_player_id" "uuid",
    "field_name" "text" NOT NULL,
    "field_type" "public"."manual_override_field",
    "override_value" "text" NOT NULL,
    "original_value" "text",
    "reason" "text" NOT NULL,
    "priority" integer DEFAULT 100,
    "active" boolean DEFAULT true,
    "valid_from" timestamp with time zone,
    "valid_until" timestamp with time zone,
    "created_by" "text" NOT NULL,
    "approved_by" "text",
    "approved_at" timestamp with time zone,
    "notes" "text",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "gfx_player_id" "uuid",
    CONSTRAINT "chk_player_override_target" CHECK ((("gfx_player_id" IS NOT NULL) OR ("wsop_player_id" IS NOT NULL)))
);


ALTER TABLE "public"."player_overrides" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."profile_images" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "image_type" "public"."manual_image_type" DEFAULT 'profile'::"public"."manual_image_type" NOT NULL,
    "file_path" "text" NOT NULL,
    "file_name" "text" NOT NULL,
    "file_extension" character varying(20),
    "file_size" integer,
    "mime_type" character varying(100),
    "width" integer,
    "height" integer,
    "aspect_ratio" numeric(5,2),
    "original_url" "text",
    "alt_text" "text",
    "caption" "text",
    "is_primary" boolean DEFAULT false,
    "is_approved" boolean DEFAULT true,
    "processing_status" character varying(50) DEFAULT 'completed'::character varying,
    "uploaded_by" "text" NOT NULL,
    "approved_by" "text",
    "notes" "text",
    "uploaded_at" timestamp with time zone DEFAULT "now"(),
    "created_at" timestamp with time zone DEFAULT "now"(),
    "wsop_player_id" "uuid",
    "gfx_player_id" "uuid",
    CONSTRAINT "chk_profile_player_ref" CHECK ((("wsop_player_id" IS NOT NULL) OR ("gfx_player_id" IS NOT NULL)))
);


ALTER TABLE "public"."profile_images" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."render_queue" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "job_id" "uuid",
    "cue_item_id" "uuid",
    "render_type" "public"."orch_render_type" NOT NULL,
    "aep_project" "text" NOT NULL,
    "aep_comp_name" "text" NOT NULL,
    "gfx_data" "jsonb" NOT NULL,
    "data_hash" "text",
    "output_format" "text" DEFAULT 'mp4'::"text",
    "output_path" "text",
    "output_resolution" "text" DEFAULT '1920x1080'::"text",
    "output_frame_rate" integer DEFAULT 30,
    "output_codec" "text" DEFAULT 'h264'::"text",
    "output_quality" "text" DEFAULT 'high'::"text",
    "start_frame" integer DEFAULT 0,
    "end_frame" integer,
    "duration_seconds" numeric(10,2),
    "status" "public"."orch_render_status" DEFAULT 'pending'::"public"."orch_render_status",
    "progress" integer DEFAULT 0,
    "current_frame" integer DEFAULT 0,
    "total_frames" integer,
    "priority" integer DEFAULT 100,
    "queued_at" timestamp with time zone DEFAULT "now"(),
    "started_at" timestamp with time zone,
    "completed_at" timestamp with time zone,
    "estimated_completion" timestamp with time zone,
    "output_file_size" bigint,
    "output_duration_seconds" numeric(10,2),
    "render_duration_ms" integer,
    "error_message" "text",
    "error_details" "jsonb",
    "error_frame" integer,
    "worker_id" "text",
    "worker_host" "text",
    "aerender_pid" integer,
    "cache_hit" boolean DEFAULT false,
    "cached_output_path" "text",
    "metadata" "jsonb" DEFAULT '{}'::"jsonb",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."render_queue" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."sync_history" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "sync_status_id" "uuid" NOT NULL,
    "job_id" "uuid",
    "operation" "public"."orch_sync_operation" NOT NULL,
    "source" "public"."orch_data_source" NOT NULL,
    "entity_type" "text" NOT NULL,
    "records_processed" integer DEFAULT 0,
    "records_created" integer DEFAULT 0,
    "records_updated" integer DEFAULT 0,
    "records_deleted" integer DEFAULT 0,
    "records_skipped" integer DEFAULT 0,
    "records_failed" integer DEFAULT 0,
    "duration_ms" integer,
    "throughput_per_second" numeric(10,2),
    "before_hash" "text",
    "after_hash" "text",
    "error_count" integer DEFAULT 0,
    "errors" "jsonb" DEFAULT '[]'::"jsonb",
    "metadata" "jsonb" DEFAULT '{}'::"jsonb",
    "started_at" timestamp with time zone NOT NULL,
    "completed_at" timestamp with time zone,
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."sync_history" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."sync_log" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "file_name" "text" NOT NULL,
    "file_path" "text" NOT NULL,
    "file_hash" "text" NOT NULL,
    "file_size_bytes" bigint,
    "operation" "text" NOT NULL,
    "status" "text" DEFAULT 'processing'::"text",
    "session_id" "uuid",
    "error_message" "text",
    "retry_count" integer DEFAULT 0,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "completed_at" timestamp with time zone
);


ALTER TABLE "public"."sync_log" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."sync_status" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "source" "public"."orch_data_source" NOT NULL,
    "entity_type" "text" NOT NULL,
    "entity_id" "uuid",
    "status" "public"."orch_sync_status" DEFAULT 'pending'::"public"."orch_sync_status",
    "sync_direction" "text" DEFAULT 'pull'::"text",
    "last_synced_at" timestamp with time zone,
    "last_sync_duration_ms" integer,
    "sync_hash" "text",
    "total_records" integer DEFAULT 0,
    "last_record_count" integer DEFAULT 0,
    "last_created_count" integer DEFAULT 0,
    "last_updated_count" integer DEFAULT 0,
    "last_deleted_count" integer DEFAULT 0,
    "last_error" "text",
    "last_error_at" timestamp with time zone,
    "consecutive_failures" integer DEFAULT 0,
    "retry_count" integer DEFAULT 0,
    "sync_interval_minutes" integer DEFAULT 60,
    "next_sync_at" timestamp with time zone,
    "sync_enabled" boolean DEFAULT true,
    "metadata" "jsonb" DEFAULT '{}'::"jsonb",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."sync_status" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."system_config" (
    "key" "text" NOT NULL,
    "value" "jsonb" NOT NULL,
    "value_type" "text" NOT NULL,
    "category" "text" DEFAULT 'general'::"text" NOT NULL,
    "subcategory" "text",
    "description" "text",
    "display_name" "text",
    "help_text" "text",
    "validation" "jsonb",
    "default_value" "jsonb",
    "is_sensitive" boolean DEFAULT false,
    "is_readonly" boolean DEFAULT false,
    "environment_overrides" "jsonb" DEFAULT '{}'::"jsonb",
    "tags" "text"[] DEFAULT ARRAY[]::"text"[],
    "sort_order" integer DEFAULT 0,
    "updated_by" "text",
    "updated_reason" "text",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."system_config" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."wsop_chip_counts" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "event_id" "uuid" NOT NULL,
    "player_id" "uuid" NOT NULL,
    "table_num" integer,
    "seat_num" integer,
    "chip_count" bigint NOT NULL,
    "chip_change" bigint DEFAULT 0,
    "rank" integer,
    "big_blind_at_time" bigint,
    "stack_in_bbs" numeric(10,2),
    "recorded_at" timestamp with time zone NOT NULL,
    "day_number" integer DEFAULT 1,
    "level_number" integer,
    "source" "public"."wsop_chip_source" DEFAULT 'import'::"public"."wsop_chip_source",
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."wsop_chip_counts" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."wsop_players" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "wsop_player_id" "text" NOT NULL,
    "name" "text" NOT NULL,
    "name_normalized" "text",
    "nickname" "text",
    "country_code" character varying(10),
    "country_name" character varying(100),
    "city" "text",
    "profile_image_url" "text",
    "wsop_bracelets" integer DEFAULT 0,
    "wsop_rings" integer DEFAULT 0,
    "wsop_cashes" integer DEFAULT 0,
    "lifetime_earnings" bigint DEFAULT 0,
    "additional_info" "jsonb" DEFAULT '{}'::"jsonb",
    "source_file" "text",
    "source_import_id" "uuid",
    "first_seen_at" timestamp with time zone DEFAULT "now"(),
    "last_seen_at" timestamp with time zone DEFAULT "now"(),
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."wsop_players" OWNER TO "postgres";


CREATE OR REPLACE VIEW "public"."unified_chip_data" AS
 SELECT 'wsop'::"text" AS "source",
    "wcc"."id",
    "wcc"."event_id",
    "wcc"."player_id",
    "wp"."name" AS "player_name",
    "wp"."country_code",
    "wcc"."chip_count",
    "wcc"."rank",
    "wcc"."table_num",
    "wcc"."seat_num",
    "wcc"."recorded_at",
    ("wcc"."source")::"text" AS "data_source"
   FROM ("public"."wsop_chip_counts" "wcc"
     LEFT JOIN "public"."wsop_players" "wp" ON (("wcc"."player_id" = "wp"."id")))
UNION ALL
 SELECT 'gfx'::"text" AS "source",
    "ghp"."id",
    NULL::"uuid" AS "event_id",
    "ghp"."player_id",
    "ghp"."player_name",
    NULL::character varying AS "country_code",
    ("ghp"."end_stack_amt")::bigint AS "chip_count",
    NULL::integer AS "rank",
    NULL::integer AS "table_num",
    "ghp"."seat_num",
    "gh"."start_time" AS "recorded_at",
    'gfx_hand'::"text" AS "data_source"
   FROM ("public"."gfx_hand_players" "ghp"
     JOIN "public"."gfx_hands" "gh" ON (("ghp"."hand_id" = "gh"."id")));


ALTER VIEW "public"."unified_chip_data" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."wsop_events" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "event_id" "text" NOT NULL,
    "event_name" "text" NOT NULL,
    "event_number" integer,
    "event_type" "public"."wsop_event_type" DEFAULT 'OTHER'::"public"."wsop_event_type" NOT NULL,
    "start_date" "date" NOT NULL,
    "end_date" "date",
    "start_time" time without time zone,
    "timezone" "text" DEFAULT 'UTC'::"text",
    "buy_in" bigint NOT NULL,
    "rake" bigint DEFAULT 0,
    "fee" bigint DEFAULT 0,
    "total_entries" integer DEFAULT 0,
    "unique_entries" integer DEFAULT 0,
    "reentries_count" integer DEFAULT 0,
    "starting_chips" bigint,
    "blind_structure" "jsonb" DEFAULT '[]'::"jsonb",
    "prize_pool" bigint DEFAULT 0,
    "guaranteed_pool" bigint,
    "payouts" "jsonb" DEFAULT '[]'::"jsonb",
    "venue" "text",
    "table_count" integer,
    "status" "public"."wsop_event_status" DEFAULT 'upcoming'::"public"."wsop_event_status",
    "description" "text",
    "notes" "text",
    "tags" "text"[] DEFAULT ARRAY[]::"text"[],
    "source_file" "text",
    "source_import_id" "uuid",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."wsop_events" OWNER TO "postgres";


CREATE OR REPLACE VIEW "public"."unified_events" AS
 SELECT 'wsop'::"text" AS "source",
    "we"."id" AS "source_id",
    "we"."event_id" AS "source_code",
    "we"."event_name" AS "name",
    ("we"."event_type")::"text" AS "event_type",
    "we"."start_date",
    "we"."end_date",
    "we"."buy_in",
    "we"."prize_pool",
    "we"."total_entries",
    ("we"."status")::"text" AS "status",
    "we"."venue",
    "we"."created_at",
    "we"."updated_at"
   FROM "public"."wsop_events" "we"
UNION ALL
 SELECT 'gfx'::"text" AS "source",
    "gs"."id" AS "source_id",
    ("gs"."session_id")::"text" AS "source_code",
    "gs"."event_title" AS "name",
    ("gs"."table_type")::"text" AS "event_type",
    ("gs"."session_created_at")::"date" AS "start_date",
    ("gs"."session_created_at")::"date" AS "end_date",
    NULL::bigint AS "buy_in",
    NULL::bigint AS "prize_pool",
    "gs"."player_count" AS "total_entries",
    ("gs"."sync_status")::"text" AS "status",
    NULL::"text" AS "venue",
    "gs"."created_at",
    "gs"."updated_at"
   FROM "public"."gfx_sessions" "gs"
UNION ALL
 SELECT 'cuesheet'::"text" AS "source",
    "bs"."id" AS "source_id",
    "bs"."session_code" AS "source_code",
    "bs"."event_name" AS "name",
    'broadcast'::"text" AS "event_type",
    "bs"."broadcast_date" AS "start_date",
    "bs"."broadcast_date" AS "end_date",
    NULL::bigint AS "buy_in",
    NULL::bigint AS "prize_pool",
    "bs"."total_cue_items" AS "total_entries",
    ("bs"."status")::"text" AS "status",
    NULL::"text" AS "venue",
    "bs"."created_at",
    "bs"."updated_at"
   FROM "public"."broadcast_sessions" "bs"
  ORDER BY 6 DESC;


ALTER VIEW "public"."unified_events" OWNER TO "postgres";


COMMENT ON VIEW "public"."unified_events" IS '모든 소스(WSOP+, GFX, Cuesheet)의 이벤트 데이터 통합 뷰';



CREATE OR REPLACE VIEW "public"."unified_players" AS
 SELECT "gfx_players"."id",
    'gfx'::"text" AS "source",
    "gfx_players"."player_hash" AS "external_id",
    "gfx_players"."name",
    "gfx_players"."name" AS "name_display",
    NULL::character varying AS "country_code",
    NULL::"text" AS "profile_image_url",
    "gfx_players"."created_at",
    "gfx_players"."updated_at"
   FROM "public"."gfx_players"
UNION ALL
 SELECT "wsop_players"."id",
    'wsop'::"text" AS "source",
    "wsop_players"."wsop_player_id" AS "external_id",
    "wsop_players"."name",
    "wsop_players"."name" AS "name_display",
    "wsop_players"."country_code",
    "wsop_players"."profile_image_url",
    "wsop_players"."created_at",
    "wsop_players"."updated_at"
   FROM "public"."wsop_players";


ALTER VIEW "public"."unified_players" OWNER TO "postgres";


CREATE OR REPLACE VIEW "public"."v_chip_count_latest" AS
 SELECT DISTINCT ON ("cc"."event_id", "cc"."player_id") "cc"."id",
    "cc"."event_id",
    "cc"."player_id",
    "p"."name" AS "player_name",
    "p"."country_code",
    "cc"."table_num",
    "cc"."seat_num",
    "cc"."chip_count",
    "cc"."rank",
    "cc"."stack_in_bbs",
    "cc"."recorded_at",
    "cc"."day_number"
   FROM ("public"."wsop_chip_counts" "cc"
     JOIN "public"."wsop_players" "p" ON (("cc"."player_id" = "p"."id")))
  ORDER BY "cc"."event_id", "cc"."player_id", "cc"."recorded_at" DESC;


ALTER VIEW "public"."v_chip_count_latest" OWNER TO "postgres";


CREATE OR REPLACE VIEW "public"."v_event_summary" AS
SELECT
    NULL::"uuid" AS "id",
    NULL::"text" AS "event_id",
    NULL::"text" AS "event_name",
    NULL::integer AS "event_number",
    NULL::"public"."wsop_event_type" AS "event_type",
    NULL::"date" AS "start_date",
    NULL::bigint AS "buy_in",
    NULL::bigint AS "prize_pool",
    NULL::integer AS "total_entries",
    NULL::"public"."wsop_event_status" AS "status",
    NULL::bigint AS "registered_players",
    NULL::bigint AS "active_players",
    NULL::bigint AS "eliminated_players",
    NULL::"uuid" AS "chip_leader_id",
    NULL::numeric AS "avg_stack",
    NULL::timestamp with time zone AS "updated_at";


ALTER VIEW "public"."v_event_summary" OWNER TO "postgres";


CREATE OR REPLACE VIEW "public"."v_job_queue_summary" AS
 SELECT "job_type",
    "status",
    "count"(*) AS "count",
    "avg"(EXTRACT(epoch FROM ("completed_at" - "started_at"))) AS "avg_duration_seconds",
    "max"("created_at") AS "last_created",
    "max"("completed_at") AS "last_completed"
   FROM "public"."job_queue"
  WHERE ("created_at" > ("now"() - '24:00:00'::interval))
  GROUP BY "job_type", "status"
  ORDER BY "job_type", "status";


ALTER VIEW "public"."v_job_queue_summary" OWNER TO "postgres";


COMMENT ON VIEW "public"."v_job_queue_summary" IS '작업 큐 상태 요약 (최근 24시간)';



CREATE TABLE IF NOT EXISTS "public"."wsop_event_players" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "event_id" "uuid" NOT NULL,
    "player_id" "uuid" NOT NULL,
    "table_num" integer,
    "seat_num" integer,
    "starting_chips" bigint,
    "current_chips" bigint DEFAULT 0,
    "peak_chips" bigint DEFAULT 0,
    "rank" integer,
    "rank_at_end_of_day" integer,
    "status" "public"."wsop_player_status" DEFAULT 'registered'::"public"."wsop_player_status",
    "eliminated_at" timestamp with time zone,
    "eliminated_by_player_id" "uuid",
    "elimination_hand" "text",
    "prize_won" bigint DEFAULT 0,
    "bounties_collected" integer DEFAULT 0,
    "bounties_collected_amount" bigint DEFAULT 0,
    "notes" "text",
    "source_file" "text",
    "source_import_id" "uuid",
    "registered_at" timestamp with time zone DEFAULT "now"(),
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    CONSTRAINT "wsop_event_players_seat_num_check" CHECK ((("seat_num" >= 1) AND ("seat_num" <= 10)))
);


ALTER TABLE "public"."wsop_event_players" OWNER TO "postgres";


CREATE OR REPLACE VIEW "public"."v_leaderboard" AS
 SELECT "ep"."event_id",
    "e"."event_name",
    "ep"."player_id",
    "p"."name" AS "player_name",
    "p"."country_code",
    "p"."profile_image_url",
    "ep"."current_chips",
    "ep"."rank",
    "ep"."table_num",
    "ep"."seat_num",
    "ep"."status",
    ("ep"."current_chips" - COALESCE(( SELECT "wsop_chip_counts"."chip_count"
           FROM "public"."wsop_chip_counts"
          WHERE (("wsop_chip_counts"."event_id" = "ep"."event_id") AND ("wsop_chip_counts"."player_id" = "ep"."player_id"))
          ORDER BY "wsop_chip_counts"."recorded_at" DESC
         OFFSET 1
         LIMIT 1), "ep"."starting_chips")) AS "chip_change",
    "ep"."updated_at"
   FROM (("public"."wsop_event_players" "ep"
     JOIN "public"."wsop_events" "e" ON (("ep"."event_id" = "e"."id")))
     JOIN "public"."wsop_players" "p" ON (("ep"."player_id" = "p"."id")))
  WHERE ("ep"."status" = ANY (ARRAY['active'::"public"."wsop_player_status", 'winner'::"public"."wsop_player_status"]))
  ORDER BY "ep"."current_chips" DESC;


ALTER VIEW "public"."v_leaderboard" OWNER TO "postgres";


CREATE OR REPLACE VIEW "public"."v_player_stats" AS
SELECT
    NULL::"uuid" AS "id",
    NULL::"text" AS "wsop_player_id",
    NULL::"text" AS "name",
    NULL::character varying(10) AS "country_code",
    NULL::character varying(100) AS "country_name",
    NULL::integer AS "wsop_bracelets",
    NULL::bigint AS "lifetime_earnings",
    NULL::bigint AS "events_played",
    NULL::bigint AS "wins",
    NULL::bigint AS "cashes",
    NULL::numeric AS "total_prize_won",
    NULL::numeric AS "avg_finish",
    NULL::timestamp with time zone AS "last_event_date",
    NULL::timestamp with time zone AS "updated_at";


ALTER VIEW "public"."v_player_stats" OWNER TO "postgres";


CREATE OR REPLACE VIEW "public"."v_recent_hands" AS
 SELECT "h"."id",
    "h"."session_id",
    "h"."hand_num",
    "h"."game_variant",
    "h"."bet_structure",
    "h"."duration_seconds",
    "h"."start_time",
    "h"."pot_size",
    "h"."board_cards",
    "h"."winner_name",
    "h"."player_count",
    "h"."showdown_count",
    "s"."table_type",
    "s"."event_title",
    "g"."grade",
    "g"."broadcast_eligible",
    "g"."conditions_met"
   FROM (("public"."gfx_hands" "h"
     LEFT JOIN "public"."gfx_sessions" "s" ON (("h"."session_id" = "s"."session_id")))
     LEFT JOIN "public"."hand_grades" "g" ON (("h"."id" = "g"."hand_id")))
  ORDER BY "h"."start_time" DESC;


ALTER VIEW "public"."v_recent_hands" OWNER TO "postgres";


CREATE OR REPLACE VIEW "public"."v_render_at_risk" AS
 WITH "ranked_players" AS (
         SELECT "gs_1"."session_id",
            "gh"."hand_num",
            "ghp"."player_name",
            "ghp"."end_stack_amt",
            "ghp"."player_id",
            "row_number"() OVER (PARTITION BY "gs_1"."session_id", "gh"."hand_num" ORDER BY "ghp"."end_stack_amt") AS "risk_rank",
            "count"(*) OVER (PARTITION BY "gs_1"."session_id", "gh"."hand_num") AS "remaining_players"
           FROM (("public"."gfx_hand_players" "ghp"
             JOIN "public"."gfx_hands" "gh" ON (("ghp"."hand_id" = "gh"."id")))
             JOIN "public"."gfx_sessions" "gs_1" ON (("gh"."session_id" = "gs_1"."session_id")))
          WHERE ("ghp"."sitting_out" = false)
        )
 SELECT "rp"."session_id",
    "rp"."hand_num",
    "upper"(COALESCE("po_name"."override_value", "rp"."player_name")) AS "player_name",
    "rp"."remaining_players" AS "rank",
    COALESCE("public"."format_currency_from_int"(("gs"."payouts"["rp"."remaining_players"])::bigint), '$0'::"text") AS "prize",
    "public"."get_flag_path"((COALESCE("po_country"."override_value", 'XX'::"text"))::character varying) AS "flag",
    "public"."format_chips"(("rp"."end_stack_amt")::bigint) AS "chips",
    "rp"."player_id"
   FROM (((("ranked_players" "rp"
     JOIN "public"."gfx_sessions" "gs" ON (("rp"."session_id" = "gs"."session_id")))
     LEFT JOIN "public"."gfx_players" "gp" ON (("rp"."player_id" = "gp"."id")))
     LEFT JOIN "public"."player_overrides" "po_name" ON ((("po_name"."gfx_player_id" = "gp"."id") AND ("po_name"."field_name" = 'name'::"text") AND ("po_name"."active" = true))))
     LEFT JOIN "public"."player_overrides" "po_country" ON ((("po_country"."gfx_player_id" = "gp"."id") AND ("po_country"."field_name" = 'country_code'::"text") AND ("po_country"."active" = true))))
  WHERE ("rp"."risk_rank" = 1);


ALTER VIEW "public"."v_render_at_risk" OWNER TO "postgres";


COMMENT ON VIEW "public"."v_render_at_risk" IS 'At Risk of Elimination 컴포지션용 렌더링 데이터. v2.0.0에서 필드 분리 (player_name, rank, prize, flag).';



CREATE OR REPLACE VIEW "public"."v_render_chip_display" AS
 SELECT "gs"."session_id",
    "gh"."hand_num",
    "row_number"() OVER (PARTITION BY "gs"."session_id", "gh"."hand_num" ORDER BY "ghp"."end_stack_amt" DESC) AS "slot_index",
    "upper"(COALESCE("po_name"."override_value", "ghp"."player_name")) AS "name",
    "public"."format_chips"(("ghp"."end_stack_amt")::bigint) AS "chips",
    "public"."format_bbs"(("ghp"."end_stack_amt")::bigint, (("gh"."blinds" ->> 'big_blind_amt'::"text"))::bigint) AS "bbs",
    ("row_number"() OVER (PARTITION BY "gs"."session_id", "gh"."hand_num" ORDER BY "ghp"."end_stack_amt" DESC))::"text" AS "rank",
    "public"."get_flag_path"((COALESCE("po_country"."override_value", 'XX'::"text"))::character varying) AS "flag",
    "ghp"."vpip_percent",
    "ghp"."end_stack_amt" AS "raw_chips",
    (("gh"."blinds" ->> 'big_blind_amt'::"text"))::bigint AS "big_blind"
   FROM ((((("public"."gfx_hand_players" "ghp"
     JOIN "public"."gfx_hands" "gh" ON (("ghp"."hand_id" = "gh"."id")))
     JOIN "public"."gfx_sessions" "gs" ON (("gh"."session_id" = "gs"."session_id")))
     LEFT JOIN "public"."gfx_players" "gp" ON (("ghp"."player_id" = "gp"."id")))
     LEFT JOIN "public"."player_overrides" "po_name" ON ((("po_name"."gfx_player_id" = "gp"."id") AND ("po_name"."field_name" = 'name'::"text") AND ("po_name"."active" = true))))
     LEFT JOIN "public"."player_overrides" "po_country" ON ((("po_country"."gfx_player_id" = "gp"."id") AND ("po_country"."field_name" = 'country_code'::"text") AND ("po_country"."active" = true))))
  WHERE ("ghp"."sitting_out" = false)
  ORDER BY "gs"."session_id", "gh"."hand_num", "ghp"."end_stack_amt" DESC;


ALTER VIEW "public"."v_render_chip_display" OWNER TO "postgres";


COMMENT ON VIEW "public"."v_render_chip_display" IS 'Chip Display 렌더링 뷰. player_overrides 기반으로 플레이어 정보 오버라이드 적용.';



CREATE OR REPLACE VIEW "public"."v_render_elimination" AS
 SELECT "gs"."session_id",
    "gh"."hand_num",
    "upper"(COALESCE("po_name"."override_value", "ghp"."player_name")) AS "name",
    "ghp"."elimination_rank" AS "rank",
    COALESCE("public"."format_currency_from_int"(("gs"."payouts"["ghp"."elimination_rank"])::bigint), '$0'::"text") AS "prize",
    "public"."get_flag_path"((COALESCE("po_country"."override_value", 'XX'::"text"))::character varying) AS "flag"
   FROM ((((("public"."gfx_hand_players" "ghp"
     JOIN "public"."gfx_hands" "gh" ON (("ghp"."hand_id" = "gh"."id")))
     JOIN "public"."gfx_sessions" "gs" ON (("gh"."session_id" = "gs"."session_id")))
     LEFT JOIN "public"."gfx_players" "gp" ON (("ghp"."player_id" = "gp"."id")))
     LEFT JOIN "public"."player_overrides" "po_name" ON ((("po_name"."gfx_player_id" = "gp"."id") AND ("po_name"."field_name" = 'name'::"text") AND ("po_name"."active" = true))))
     LEFT JOIN "public"."player_overrides" "po_country" ON ((("po_country"."gfx_player_id" = "gp"."id") AND ("po_country"."field_name" = 'country_code'::"text") AND ("po_country"."active" = true))))
  WHERE ("ghp"."elimination_rank" > 0)
  ORDER BY "gs"."session_id", "gh"."hand_num", "ghp"."elimination_rank" DESC;


ALTER VIEW "public"."v_render_elimination" OWNER TO "postgres";


COMMENT ON VIEW "public"."v_render_elimination" IS 'Elimination 렌더링 뷰. player_overrides 기반으로 플레이어 정보 오버라이드 적용.';



CREATE OR REPLACE VIEW "public"."v_render_payout" AS
 SELECT "e"."id" AS "event_id",
    (("payout"."value" ->> 'place'::"text"))::integer AS "slot_index",
    ("payout"."value" ->> 'place'::"text") AS "rank",
    "public"."format_currency"((("payout"."value" ->> 'amount'::"text"))::bigint) AS "prize",
    (("payout"."value" ->> 'amount'::"text"))::bigint AS "raw_amount"
   FROM ("public"."wsop_events" "e"
     CROSS JOIN LATERAL "jsonb_array_elements"("e"."payouts") "payout"("value"))
  ORDER BY "e"."id", (("payout"."value" ->> 'place'::"text"))::integer;


ALTER VIEW "public"."v_render_payout" OWNER TO "postgres";


CREATE OR REPLACE VIEW "public"."v_render_payout_gfx" AS
 SELECT "gs"."session_id",
    "t"."idx" AS "slot_index",
    ("t"."idx")::"text" AS "rank",
    "public"."format_currency_from_int"(("t"."payout_amount")::bigint) AS "prize",
    "t"."payout_amount" AS "raw_amount"
   FROM ("public"."gfx_sessions" "gs"
     CROSS JOIN LATERAL "unnest"("gs"."payouts") WITH ORDINALITY "t"("payout_amount", "idx"))
  ORDER BY "gs"."session_id", "t"."idx";


ALTER VIEW "public"."v_render_payout_gfx" OWNER TO "postgres";


CREATE OR REPLACE VIEW "public"."v_session_summary" AS
 SELECT "s"."id",
    "s"."session_id",
    "s"."file_name",
    "s"."table_type",
    "s"."event_title",
    "s"."hand_count",
    "s"."total_duration_seconds",
    "s"."session_created_at",
    "s"."sync_status",
    "count"(
        CASE
            WHEN ("g"."grade" = 'A'::"bpchar") THEN 1
            ELSE NULL::integer
        END) AS "grade_a_count",
    "count"(
        CASE
            WHEN ("g"."grade" = 'B'::"bpchar") THEN 1
            ELSE NULL::integer
        END) AS "grade_b_count",
    "count"(
        CASE
            WHEN ("g"."grade" = 'C'::"bpchar") THEN 1
            ELSE NULL::integer
        END) AS "grade_c_count",
    "count"(
        CASE
            WHEN "g"."broadcast_eligible" THEN 1
            ELSE NULL::integer
        END) AS "eligible_count"
   FROM (("public"."gfx_sessions" "s"
     LEFT JOIN "public"."gfx_hands" "h" ON (("s"."session_id" = "h"."session_id")))
     LEFT JOIN "public"."hand_grades" "g" ON (("h"."id" = "g"."hand_id")))
  GROUP BY "s"."id", "s"."session_id", "s"."file_name", "s"."table_type", "s"."event_title", "s"."hand_count", "s"."total_duration_seconds", "s"."session_created_at", "s"."sync_status"
  ORDER BY "s"."session_created_at" DESC;


ALTER VIEW "public"."v_session_summary" OWNER TO "postgres";


CREATE OR REPLACE VIEW "public"."v_showdown_players" AS
 SELECT "hp"."id",
    "hp"."hand_id",
    "hp"."player_name",
    "hp"."seat_num",
    "hp"."hole_cards",
    "hp"."start_stack_amt",
    "hp"."end_stack_amt",
    "hp"."cumulative_winnings_amt",
    "hp"."is_winner",
    "h"."hand_num",
    "h"."board_cards",
    "h"."pot_size",
    "h"."session_id"
   FROM ("public"."gfx_hand_players" "hp"
     JOIN "public"."gfx_hands" "h" ON (("hp"."hand_id" = "h"."id")))
  WHERE ("hp"."has_shown" = true)
  ORDER BY "h"."start_time" DESC, "hp"."seat_num";


ALTER VIEW "public"."v_showdown_players" OWNER TO "postgres";


CREATE OR REPLACE VIEW "public"."v_sync_dashboard" AS
 SELECT "ss"."id",
    "ss"."source",
    "ss"."entity_type",
    "ss"."status",
    "ss"."last_synced_at",
    "ss"."next_sync_at",
    "ss"."consecutive_failures",
    "ss"."total_records",
    "ss"."sync_enabled",
    "sh"."records_processed" AS "last_records_processed",
    "sh"."records_created" AS "last_records_created",
    "sh"."records_failed" AS "last_records_failed",
    "sh"."duration_ms" AS "last_duration_ms",
        CASE
            WHEN (("ss"."status" = 'failed'::"public"."orch_sync_status") OR ("ss"."consecutive_failures" > 3)) THEN 'error'::"text"
            WHEN ("ss"."status" = 'in_progress'::"public"."orch_sync_status") THEN 'syncing'::"text"
            WHEN ("ss"."last_synced_at" < ("now"() - (("ss"."sync_interval_minutes")::double precision * '00:02:00'::interval))) THEN 'stale'::"text"
            ELSE 'healthy'::"text"
        END AS "health_status",
    "ss"."updated_at"
   FROM ("public"."sync_status" "ss"
     LEFT JOIN LATERAL ( SELECT "sync_history"."id",
            "sync_history"."sync_status_id",
            "sync_history"."job_id",
            "sync_history"."operation",
            "sync_history"."source",
            "sync_history"."entity_type",
            "sync_history"."records_processed",
            "sync_history"."records_created",
            "sync_history"."records_updated",
            "sync_history"."records_deleted",
            "sync_history"."records_skipped",
            "sync_history"."records_failed",
            "sync_history"."duration_ms",
            "sync_history"."throughput_per_second",
            "sync_history"."before_hash",
            "sync_history"."after_hash",
            "sync_history"."error_count",
            "sync_history"."errors",
            "sync_history"."metadata",
            "sync_history"."started_at",
            "sync_history"."completed_at",
            "sync_history"."created_at"
           FROM "public"."sync_history"
          WHERE ("sync_history"."sync_status_id" = "ss"."id")
          ORDER BY "sync_history"."created_at" DESC
         LIMIT 1) "sh" ON (true))
  ORDER BY "ss"."source", "ss"."entity_type";


ALTER VIEW "public"."v_sync_dashboard" OWNER TO "postgres";


COMMENT ON VIEW "public"."v_sync_dashboard" IS '동기화 상태 대시보드 (전체 소스 모니터링)';



CREATE TABLE IF NOT EXISTS "public"."wsop_import_logs" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "file_name" "text" NOT NULL,
    "file_path" "text",
    "file_hash" "text" NOT NULL,
    "file_size_bytes" bigint,
    "file_type" "public"."wsop_import_type" NOT NULL,
    "target_table" "text",
    "event_id" "uuid",
    "record_count" integer DEFAULT 0,
    "records_created" integer DEFAULT 0,
    "records_updated" integer DEFAULT 0,
    "records_skipped" integer DEFAULT 0,
    "records_failed" integer DEFAULT 0,
    "status" "public"."wsop_import_status" DEFAULT 'pending'::"public"."wsop_import_status",
    "error_message" "text",
    "error_details" "jsonb",
    "started_at" timestamp with time zone,
    "completed_at" timestamp with time zone,
    "processing_duration_ms" integer,
    "imported_by" "text",
    "notes" "text",
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."wsop_import_logs" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."wsop_standings" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "event_id" "uuid" NOT NULL,
    "snapshot_at" timestamp with time zone NOT NULL,
    "day_number" integer DEFAULT 1,
    "level_number" integer,
    "players_remaining" integer NOT NULL,
    "players_eliminated" integer DEFAULT 0,
    "avg_stack" bigint,
    "median_stack" bigint,
    "total_chips" bigint,
    "standings" "jsonb" NOT NULL,
    "chip_leader_player_id" "uuid",
    "chip_leader_name" "text",
    "chip_leader_count" bigint,
    "source" "public"."wsop_chip_source" DEFAULT 'import'::"public"."wsop_chip_source",
    "source_file" "text",
    "source_import_id" "uuid",
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."wsop_standings" OWNER TO "postgres";


ALTER TABLE ONLY "public"."activity_log"
    ADD CONSTRAINT "activity_log_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."aep_media_sources"
    ADD CONSTRAINT "aep_media_sources_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."api_keys"
    ADD CONSTRAINT "api_keys_key_hash_key" UNIQUE ("key_hash");



ALTER TABLE ONLY "public"."api_keys"
    ADD CONSTRAINT "api_keys_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."broadcast_sessions"
    ADD CONSTRAINT "broadcast_sessions_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."broadcast_sessions"
    ADD CONSTRAINT "broadcast_sessions_session_code_key" UNIQUE ("session_code");



ALTER TABLE ONLY "public"."cue_items"
    ADD CONSTRAINT "cue_items_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."cue_sheets"
    ADD CONSTRAINT "cue_sheets_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."cue_sheets"
    ADD CONSTRAINT "cue_sheets_sheet_code_key" UNIQUE ("sheet_code");



ALTER TABLE ONLY "public"."cue_templates"
    ADD CONSTRAINT "cue_templates_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."cue_templates"
    ADD CONSTRAINT "cue_templates_template_code_key" UNIQUE ("template_code");



ALTER TABLE ONLY "public"."gfx_aep_compositions"
    ADD CONSTRAINT "gfx_aep_compositions_name_key" UNIQUE ("name");



ALTER TABLE ONLY "public"."gfx_aep_compositions"
    ADD CONSTRAINT "gfx_aep_compositions_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."gfx_aep_field_mappings"
    ADD CONSTRAINT "gfx_aep_field_mappings_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."gfx_events"
    ADD CONSTRAINT "gfx_events_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."gfx_hand_players"
    ADD CONSTRAINT "gfx_hand_players_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."gfx_hands"
    ADD CONSTRAINT "gfx_hands_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."gfx_players"
    ADD CONSTRAINT "gfx_players_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."gfx_players"
    ADD CONSTRAINT "gfx_players_player_hash_key" UNIQUE ("player_hash");



ALTER TABLE ONLY "public"."gfx_sessions"
    ADD CONSTRAINT "gfx_sessions_file_hash_key" UNIQUE ("file_hash");



ALTER TABLE ONLY "public"."gfx_sessions"
    ADD CONSTRAINT "gfx_sessions_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."gfx_sessions"
    ADD CONSTRAINT "gfx_sessions_session_id_key" UNIQUE ("session_id");



ALTER TABLE ONLY "public"."gfx_triggers"
    ADD CONSTRAINT "gfx_triggers_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."hand_grades"
    ADD CONSTRAINT "hand_grades_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."job_queue"
    ADD CONSTRAINT "job_queue_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."notifications"
    ADD CONSTRAINT "notifications_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."player_link_mapping"
    ADD CONSTRAINT "player_link_mapping_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."player_overrides"
    ADD CONSTRAINT "player_overrides_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."profile_images"
    ADD CONSTRAINT "profile_images_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."render_queue"
    ADD CONSTRAINT "render_queue_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."sync_history"
    ADD CONSTRAINT "sync_history_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."sync_log"
    ADD CONSTRAINT "sync_log_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."sync_status"
    ADD CONSTRAINT "sync_status_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."system_config"
    ADD CONSTRAINT "system_config_pkey" PRIMARY KEY ("key");



ALTER TABLE ONLY "public"."cue_items"
    ADD CONSTRAINT "uq_cue_items_sheet_order" UNIQUE ("sheet_id", "sort_order");



ALTER TABLE ONLY "public"."cue_sheets"
    ADD CONSTRAINT "uq_cue_sheets_session_order" UNIQUE ("session_id", "sheet_order");



ALTER TABLE ONLY "public"."gfx_events"
    ADD CONSTRAINT "uq_hand_event_order" UNIQUE ("hand_id", "event_order");



ALTER TABLE ONLY "public"."hand_grades"
    ADD CONSTRAINT "uq_hand_grade" UNIQUE ("hand_id");



ALTER TABLE ONLY "public"."gfx_hand_players"
    ADD CONSTRAINT "uq_hand_seat" UNIQUE ("hand_id", "seat_num");



ALTER TABLE ONLY "public"."gfx_hands"
    ADD CONSTRAINT "uq_session_hand" UNIQUE ("session_id", "hand_num");



ALTER TABLE ONLY "public"."sync_status"
    ADD CONSTRAINT "uq_sync_status_source_entity" UNIQUE ("source", "entity_type", "entity_id");



ALTER TABLE ONLY "public"."wsop_event_players"
    ADD CONSTRAINT "uq_wsop_event_player" UNIQUE ("event_id", "player_id");



ALTER TABLE ONLY "public"."wsop_standings"
    ADD CONSTRAINT "uq_wsop_standings_snapshot" UNIQUE ("event_id", "snapshot_at");



ALTER TABLE ONLY "public"."wsop_chip_counts"
    ADD CONSTRAINT "wsop_chip_counts_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."wsop_event_players"
    ADD CONSTRAINT "wsop_event_players_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."wsop_events"
    ADD CONSTRAINT "wsop_events_event_id_key" UNIQUE ("event_id");



ALTER TABLE ONLY "public"."wsop_events"
    ADD CONSTRAINT "wsop_events_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."wsop_import_logs"
    ADD CONSTRAINT "wsop_import_logs_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."wsop_players"
    ADD CONSTRAINT "wsop_players_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."wsop_players"
    ADD CONSTRAINT "wsop_players_wsop_player_id_key" UNIQUE ("wsop_player_id");



ALTER TABLE ONLY "public"."wsop_standings"
    ADD CONSTRAINT "wsop_standings_pkey" PRIMARY KEY ("id");



CREATE INDEX "idx_activity_log_action" ON "public"."activity_log" USING "btree" ("action");



CREATE INDEX "idx_activity_log_actor" ON "public"."activity_log" USING "btree" ("actor");



CREATE INDEX "idx_activity_log_actor_type" ON "public"."activity_log" USING "btree" ("actor_type");



CREATE INDEX "idx_activity_log_created" ON "public"."activity_log" USING "btree" ("created_at" DESC);



CREATE INDEX "idx_activity_log_entity" ON "public"."activity_log" USING "btree" ("entity_type", "entity_id");



CREATE INDEX "idx_aep_media_sources_category" ON "public"."aep_media_sources" USING "btree" ("category");



CREATE INDEX "idx_aep_media_sources_country_code" ON "public"."aep_media_sources" USING "btree" ("country_code");



CREATE UNIQUE INDEX "idx_aep_media_sources_unique" ON "public"."aep_media_sources" USING "btree" ("category", "country_code") WHERE ("country_code" IS NOT NULL);



CREATE INDEX "idx_api_keys_active" ON "public"."api_keys" USING "btree" ("is_active") WHERE ("is_active" = true);



CREATE INDEX "idx_api_keys_expires" ON "public"."api_keys" USING "btree" ("expires_at") WHERE ("expires_at" IS NOT NULL);



CREATE INDEX "idx_api_keys_hash" ON "public"."api_keys" USING "btree" ("key_hash");



CREATE INDEX "idx_api_keys_prefix" ON "public"."api_keys" USING "btree" ("key_prefix");



CREATE INDEX "idx_broadcast_sessions_code" ON "public"."broadcast_sessions" USING "btree" ("session_code");



CREATE INDEX "idx_broadcast_sessions_date" ON "public"."broadcast_sessions" USING "btree" ("broadcast_date" DESC);



CREATE INDEX "idx_broadcast_sessions_event" ON "public"."broadcast_sessions" USING "btree" ("event_id");



CREATE INDEX "idx_broadcast_sessions_scheduled" ON "public"."broadcast_sessions" USING "btree" ("scheduled_start" DESC);



CREATE INDEX "idx_broadcast_sessions_status" ON "public"."broadcast_sessions" USING "btree" ("status");



CREATE INDEX "idx_broadcast_sessions_tags" ON "public"."broadcast_sessions" USING "gin" ("tags");



CREATE INDEX "idx_cue_items_content_type" ON "public"."cue_items" USING "btree" ("content_type");



CREATE INDEX "idx_cue_items_file_name" ON "public"."cue_items" USING "btree" ("file_name") WHERE ("file_name" IS NOT NULL);



CREATE INDEX "idx_cue_items_gfx_data" ON "public"."cue_items" USING "gin" ("gfx_data");



CREATE INDEX "idx_cue_items_hand_number" ON "public"."cue_items" USING "btree" ("hand_number") WHERE ("hand_number" IS NOT NULL);



CREATE INDEX "idx_cue_items_order" ON "public"."cue_items" USING "btree" ("sheet_id", "sort_order");



CREATE INDEX "idx_cue_items_sheet" ON "public"."cue_items" USING "btree" ("sheet_id");



CREATE INDEX "idx_cue_items_status" ON "public"."cue_items" USING "btree" ("status");



CREATE INDEX "idx_cue_items_template" ON "public"."cue_items" USING "btree" ("template_id");



CREATE INDEX "idx_cue_sheets_code" ON "public"."cue_sheets" USING "btree" ("sheet_code");



CREATE INDEX "idx_cue_sheets_order" ON "public"."cue_sheets" USING "btree" ("session_id", "sheet_order");



CREATE INDEX "idx_cue_sheets_session" ON "public"."cue_sheets" USING "btree" ("session_id");



CREATE INDEX "idx_cue_sheets_status" ON "public"."cue_sheets" USING "btree" ("status");



CREATE INDEX "idx_cue_sheets_type" ON "public"."cue_sheets" USING "btree" ("sheet_type");



CREATE INDEX "idx_cue_templates_active" ON "public"."cue_templates" USING "btree" ("is_active") WHERE ("is_active" = true);



CREATE INDEX "idx_cue_templates_category" ON "public"."cue_templates" USING "btree" ("category");



CREATE INDEX "idx_cue_templates_code" ON "public"."cue_templates" USING "btree" ("template_code");



CREATE INDEX "idx_cue_templates_tags" ON "public"."cue_templates" USING "gin" ("tags");



CREATE INDEX "idx_cue_templates_type" ON "public"."cue_templates" USING "btree" ("template_type");



CREATE INDEX "idx_cue_templates_usage" ON "public"."cue_templates" USING "btree" ("usage_count" DESC);



CREATE INDEX "idx_gfx_aep_comp_active" ON "public"."gfx_aep_compositions" USING "btree" ("is_active") WHERE ("is_active" = true);



CREATE INDEX "idx_gfx_aep_comp_category" ON "public"."gfx_aep_compositions" USING "btree" ("category");



CREATE INDEX "idx_gfx_aep_comp_name" ON "public"."gfx_aep_compositions" USING "btree" ("name");



CREATE INDEX "idx_gfx_aep_mapping_active" ON "public"."gfx_aep_field_mappings" USING "btree" ("is_active") WHERE ("is_active" = true);



CREATE INDEX "idx_gfx_aep_mapping_category" ON "public"."gfx_aep_field_mappings" USING "btree" ("composition_category");



CREATE INDEX "idx_gfx_aep_mapping_comp" ON "public"."gfx_aep_field_mappings" USING "btree" ("composition_name");



CREATE INDEX "idx_gfx_aep_mapping_source" ON "public"."gfx_aep_field_mappings" USING "btree" ("source_table");



CREATE INDEX "idx_gfx_events_board" ON "public"."gfx_events" USING "btree" ("event_type") WHERE ("event_type" = 'BOARD_CARD'::"public"."event_type");



CREATE INDEX "idx_gfx_events_hand_id" ON "public"."gfx_events" USING "btree" ("hand_id");



CREATE INDEX "idx_gfx_events_order" ON "public"."gfx_events" USING "btree" ("hand_id", "event_order");



CREATE INDEX "idx_gfx_events_player" ON "public"."gfx_events" USING "btree" ("player_num") WHERE ("player_num" > 0);



CREATE INDEX "idx_gfx_events_type" ON "public"."gfx_events" USING "btree" ("event_type");



CREATE INDEX "idx_gfx_hand_players_cards" ON "public"."gfx_hand_players" USING "gin" ("hole_cards");



CREATE INDEX "idx_gfx_hand_players_hand_id" ON "public"."gfx_hand_players" USING "btree" ("hand_id");



CREATE INDEX "idx_gfx_hand_players_player_id" ON "public"."gfx_hand_players" USING "btree" ("player_id");



CREATE INDEX "idx_gfx_hand_players_seat" ON "public"."gfx_hand_players" USING "btree" ("seat_num");



CREATE INDEX "idx_gfx_hand_players_shown" ON "public"."gfx_hand_players" USING "btree" ("has_shown") WHERE ("has_shown" = true);



CREATE INDEX "idx_gfx_hand_players_winner" ON "public"."gfx_hand_players" USING "btree" ("is_winner") WHERE ("is_winner" = true);



CREATE INDEX "idx_gfx_hands_board_cards" ON "public"."gfx_hands" USING "gin" ("board_cards");



CREATE INDEX "idx_gfx_hands_duration" ON "public"."gfx_hands" USING "btree" ("duration_seconds" DESC);



CREATE INDEX "idx_gfx_hands_game_variant" ON "public"."gfx_hands" USING "btree" ("game_variant");



CREATE INDEX "idx_gfx_hands_hand_num" ON "public"."gfx_hands" USING "btree" ("hand_num");



CREATE INDEX "idx_gfx_hands_pot_size" ON "public"."gfx_hands" USING "btree" ("pot_size" DESC);



CREATE INDEX "idx_gfx_hands_session_id" ON "public"."gfx_hands" USING "btree" ("session_id");



CREATE INDEX "idx_gfx_hands_start_time" ON "public"."gfx_hands" USING "btree" ("start_time" DESC);



CREATE INDEX "idx_gfx_players_hash" ON "public"."gfx_players" USING "btree" ("player_hash");



CREATE INDEX "idx_gfx_players_name" ON "public"."gfx_players" USING "btree" ("name");



CREATE INDEX "idx_gfx_sessions_created_at" ON "public"."gfx_sessions" USING "btree" ("session_created_at" DESC);



CREATE INDEX "idx_gfx_sessions_file_hash" ON "public"."gfx_sessions" USING "btree" ("file_hash");



CREATE INDEX "idx_gfx_sessions_processed_at" ON "public"."gfx_sessions" USING "btree" ("processed_at" DESC);



CREATE INDEX "idx_gfx_sessions_raw_json_type" ON "public"."gfx_sessions" USING "gin" ((("raw_json" -> 'Type'::"text")));



CREATE INDEX "idx_gfx_sessions_session_id" ON "public"."gfx_sessions" USING "btree" ("session_id");



CREATE INDEX "idx_gfx_sessions_sync_status" ON "public"."gfx_sessions" USING "btree" ("sync_status");



CREATE INDEX "idx_gfx_sessions_table_type" ON "public"."gfx_sessions" USING "btree" ("table_type");



CREATE INDEX "idx_gfx_triggers_cue_item" ON "public"."gfx_triggers" USING "btree" ("cue_item_id");



CREATE INDEX "idx_gfx_triggers_cue_type" ON "public"."gfx_triggers" USING "btree" ("cue_type");



CREATE INDEX "idx_gfx_triggers_recent" ON "public"."gfx_triggers" USING "btree" ("session_id", "trigger_time" DESC);



CREATE INDEX "idx_gfx_triggers_session" ON "public"."gfx_triggers" USING "btree" ("session_id");



CREATE INDEX "idx_gfx_triggers_sheet" ON "public"."gfx_triggers" USING "btree" ("sheet_id");



CREATE INDEX "idx_gfx_triggers_status" ON "public"."gfx_triggers" USING "btree" ("render_status");



CREATE INDEX "idx_gfx_triggers_time" ON "public"."gfx_triggers" USING "btree" ("trigger_time" DESC);



CREATE INDEX "idx_gfx_triggers_triggered_by" ON "public"."gfx_triggers" USING "btree" ("triggered_by");



CREATE INDEX "idx_gfx_triggers_type" ON "public"."gfx_triggers" USING "btree" ("trigger_type");



CREATE INDEX "idx_hand_grades_eligible" ON "public"."hand_grades" USING "btree" ("broadcast_eligible") WHERE ("broadcast_eligible" = true);



CREATE INDEX "idx_hand_grades_grade" ON "public"."hand_grades" USING "btree" ("grade");



CREATE INDEX "idx_hand_grades_hand_id" ON "public"."hand_grades" USING "btree" ("hand_id");



CREATE INDEX "idx_job_queue_created" ON "public"."job_queue" USING "btree" ("created_at" DESC);



CREATE INDEX "idx_job_queue_parent" ON "public"."job_queue" USING "btree" ("parent_job_id");



CREATE INDEX "idx_job_queue_pending" ON "public"."job_queue" USING "btree" ("priority", "created_at") WHERE ("status" = 'pending'::"public"."orch_job_status");



CREATE INDEX "idx_job_queue_priority" ON "public"."job_queue" USING "btree" ("priority", "created_at");



CREATE INDEX "idx_job_queue_running" ON "public"."job_queue" USING "btree" ("worker_id", "started_at") WHERE ("status" = 'running'::"public"."orch_job_status");



CREATE INDEX "idx_job_queue_scheduled" ON "public"."job_queue" USING "btree" ("scheduled_at") WHERE ("scheduled_at" IS NOT NULL);



CREATE INDEX "idx_job_queue_status" ON "public"."job_queue" USING "btree" ("status");



CREATE INDEX "idx_job_queue_tags" ON "public"."job_queue" USING "gin" ("tags");



CREATE INDEX "idx_job_queue_type" ON "public"."job_queue" USING "btree" ("job_type");



CREATE INDEX "idx_notifications_created" ON "public"."notifications" USING "btree" ("created_at" DESC);



CREATE INDEX "idx_notifications_job" ON "public"."notifications" USING "btree" ("job_id");



CREATE INDEX "idx_notifications_level" ON "public"."notifications" USING "btree" ("level");



CREATE INDEX "idx_notifications_source" ON "public"."notifications" USING "btree" ("source");



CREATE INDEX "idx_notifications_type" ON "public"."notifications" USING "btree" ("type");



CREATE INDEX "idx_notifications_unread" ON "public"."notifications" USING "btree" ("target_user", "read") WHERE ("read" = false);



CREATE INDEX "idx_player_link_confidence" ON "public"."player_link_mapping" USING "btree" ("match_confidence" DESC);



CREATE INDEX "idx_player_link_gfx" ON "public"."player_link_mapping" USING "btree" ("gfx_player_id");



CREATE INDEX "idx_player_link_method" ON "public"."player_link_mapping" USING "btree" ("match_method");



CREATE INDEX "idx_player_link_verified" ON "public"."player_link_mapping" USING "btree" ("is_verified") WHERE ("is_verified" = true);



CREATE INDEX "idx_player_link_wsop" ON "public"."player_link_mapping" USING "btree" ("wsop_player_id");



CREATE INDEX "idx_player_overrides_active" ON "public"."player_overrides" USING "btree" ("active") WHERE ("active" = true);



CREATE INDEX "idx_player_overrides_field" ON "public"."player_overrides" USING "btree" ("field_name");



CREATE INDEX "idx_player_overrides_priority" ON "public"."player_overrides" USING "btree" ("priority");



CREATE INDEX "idx_player_overrides_wsop" ON "public"."player_overrides" USING "btree" ("wsop_player_id");



CREATE INDEX "idx_profile_images_gfx" ON "public"."profile_images" USING "btree" ("gfx_player_id") WHERE ("gfx_player_id" IS NOT NULL);



CREATE INDEX "idx_profile_images_type" ON "public"."profile_images" USING "btree" ("image_type");



CREATE INDEX "idx_profile_images_wsop" ON "public"."profile_images" USING "btree" ("wsop_player_id") WHERE ("wsop_player_id" IS NOT NULL);



CREATE INDEX "idx_render_queue_cue_item" ON "public"."render_queue" USING "btree" ("cue_item_id");



CREATE INDEX "idx_render_queue_data_hash" ON "public"."render_queue" USING "btree" ("data_hash");



CREATE INDEX "idx_render_queue_job" ON "public"."render_queue" USING "btree" ("job_id");



CREATE INDEX "idx_render_queue_pending" ON "public"."render_queue" USING "btree" ("priority", "queued_at") WHERE ("status" = 'pending'::"public"."orch_render_status");



CREATE INDEX "idx_render_queue_priority" ON "public"."render_queue" USING "btree" ("priority", "queued_at");



CREATE INDEX "idx_render_queue_status" ON "public"."render_queue" USING "btree" ("status");



CREATE INDEX "idx_render_queue_type" ON "public"."render_queue" USING "btree" ("render_type");



CREATE INDEX "idx_render_queue_worker" ON "public"."render_queue" USING "btree" ("worker_id") WHERE ("worker_id" IS NOT NULL);



CREATE INDEX "idx_sync_history_created" ON "public"."sync_history" USING "btree" ("created_at" DESC);



CREATE INDEX "idx_sync_history_job" ON "public"."sync_history" USING "btree" ("job_id");



CREATE INDEX "idx_sync_history_operation" ON "public"."sync_history" USING "btree" ("operation");



CREATE INDEX "idx_sync_history_source" ON "public"."sync_history" USING "btree" ("source");



CREATE INDEX "idx_sync_history_status" ON "public"."sync_history" USING "btree" ("sync_status_id");



CREATE INDEX "idx_sync_log_created" ON "public"."sync_log" USING "btree" ("created_at" DESC);



CREATE INDEX "idx_sync_log_hash" ON "public"."sync_log" USING "btree" ("file_hash");



CREATE INDEX "idx_sync_log_status" ON "public"."sync_log" USING "btree" ("status");



CREATE INDEX "idx_sync_status_entity_type" ON "public"."sync_status" USING "btree" ("entity_type");



CREATE INDEX "idx_sync_status_last_synced" ON "public"."sync_status" USING "btree" ("last_synced_at" DESC);



CREATE INDEX "idx_sync_status_next_sync" ON "public"."sync_status" USING "btree" ("next_sync_at") WHERE ("sync_enabled" = true);



CREATE INDEX "idx_sync_status_source" ON "public"."sync_status" USING "btree" ("source");



CREATE INDEX "idx_sync_status_status" ON "public"."sync_status" USING "btree" ("status");



CREATE INDEX "idx_system_config_category" ON "public"."system_config" USING "btree" ("category");



CREATE INDEX "idx_system_config_tags" ON "public"."system_config" USING "gin" ("tags");



CREATE INDEX "idx_wsop_chip_counts_day" ON "public"."wsop_chip_counts" USING "btree" ("event_id", "day_number");



CREATE INDEX "idx_wsop_chip_counts_event" ON "public"."wsop_chip_counts" USING "btree" ("event_id");



CREATE INDEX "idx_wsop_chip_counts_event_player" ON "public"."wsop_chip_counts" USING "btree" ("event_id", "player_id", "recorded_at" DESC);



CREATE INDEX "idx_wsop_chip_counts_player" ON "public"."wsop_chip_counts" USING "btree" ("player_id");



CREATE INDEX "idx_wsop_chip_counts_rank" ON "public"."wsop_chip_counts" USING "btree" ("rank") WHERE ("rank" IS NOT NULL);



CREATE INDEX "idx_wsop_chip_counts_recorded" ON "public"."wsop_chip_counts" USING "btree" ("recorded_at" DESC);



CREATE INDEX "idx_wsop_event_players_chips" ON "public"."wsop_event_players" USING "btree" ("current_chips" DESC);



CREATE INDEX "idx_wsop_event_players_event" ON "public"."wsop_event_players" USING "btree" ("event_id");



CREATE INDEX "idx_wsop_event_players_player" ON "public"."wsop_event_players" USING "btree" ("player_id");



CREATE INDEX "idx_wsop_event_players_prize" ON "public"."wsop_event_players" USING "btree" ("prize_won" DESC) WHERE ("prize_won" > 0);



CREATE INDEX "idx_wsop_event_players_rank" ON "public"."wsop_event_players" USING "btree" ("rank") WHERE ("rank" IS NOT NULL);



CREATE INDEX "idx_wsop_event_players_status" ON "public"."wsop_event_players" USING "btree" ("status");



CREATE INDEX "idx_wsop_event_players_table_seat" ON "public"."wsop_event_players" USING "btree" ("table_num", "seat_num") WHERE ("table_num" IS NOT NULL);



CREATE INDEX "idx_wsop_events_buy_in" ON "public"."wsop_events" USING "btree" ("buy_in");



CREATE INDEX "idx_wsop_events_event_id" ON "public"."wsop_events" USING "btree" ("event_id");



CREATE INDEX "idx_wsop_events_prize_pool" ON "public"."wsop_events" USING "btree" ("prize_pool" DESC);



CREATE INDEX "idx_wsop_events_start_date" ON "public"."wsop_events" USING "btree" ("start_date" DESC);



CREATE INDEX "idx_wsop_events_status" ON "public"."wsop_events" USING "btree" ("status");



CREATE INDEX "idx_wsop_events_tags" ON "public"."wsop_events" USING "gin" ("tags");



CREATE INDEX "idx_wsop_events_type" ON "public"."wsop_events" USING "btree" ("event_type");



CREATE INDEX "idx_wsop_import_logs_created" ON "public"."wsop_import_logs" USING "btree" ("created_at" DESC);



CREATE INDEX "idx_wsop_import_logs_event" ON "public"."wsop_import_logs" USING "btree" ("event_id");



CREATE INDEX "idx_wsop_import_logs_hash" ON "public"."wsop_import_logs" USING "btree" ("file_hash");



CREATE INDEX "idx_wsop_import_logs_status" ON "public"."wsop_import_logs" USING "btree" ("status");



CREATE INDEX "idx_wsop_import_logs_target" ON "public"."wsop_import_logs" USING "btree" ("target_table");



CREATE INDEX "idx_wsop_players_bracelets" ON "public"."wsop_players" USING "btree" ("wsop_bracelets" DESC);



CREATE INDEX "idx_wsop_players_country" ON "public"."wsop_players" USING "btree" ("country_code");



CREATE INDEX "idx_wsop_players_earnings" ON "public"."wsop_players" USING "btree" ("lifetime_earnings" DESC);



CREATE INDEX "idx_wsop_players_name" ON "public"."wsop_players" USING "btree" ("name");



CREATE INDEX "idx_wsop_players_name_normalized" ON "public"."wsop_players" USING "btree" ("name_normalized");



CREATE INDEX "idx_wsop_players_wsop_id" ON "public"."wsop_players" USING "btree" ("wsop_player_id");



CREATE INDEX "idx_wsop_standings_data" ON "public"."wsop_standings" USING "gin" ("standings");



CREATE INDEX "idx_wsop_standings_event" ON "public"."wsop_standings" USING "btree" ("event_id");



CREATE INDEX "idx_wsop_standings_event_day" ON "public"."wsop_standings" USING "btree" ("event_id", "day_number");



CREATE INDEX "idx_wsop_standings_remaining" ON "public"."wsop_standings" USING "btree" ("players_remaining");



CREATE INDEX "idx_wsop_standings_snapshot" ON "public"."wsop_standings" USING "btree" ("snapshot_at" DESC);



CREATE UNIQUE INDEX "uq_gfx_aep_mapping" ON "public"."gfx_aep_field_mappings" USING "btree" ("composition_name", "target_field_key", COALESCE("slot_range_start", 0));



CREATE OR REPLACE VIEW "public"."v_event_summary" AS
 SELECT "e"."id",
    "e"."event_id",
    "e"."event_name",
    "e"."event_number",
    "e"."event_type",
    "e"."start_date",
    "e"."buy_in",
    "e"."prize_pool",
    "e"."total_entries",
    "e"."status",
    "count"("ep"."id") AS "registered_players",
    "count"(
        CASE
            WHEN ("ep"."status" = 'active'::"public"."wsop_player_status") THEN 1
            ELSE NULL::integer
        END) AS "active_players",
    "count"(
        CASE
            WHEN ("ep"."status" = 'eliminated'::"public"."wsop_player_status") THEN 1
            ELSE NULL::integer
        END) AS "eliminated_players",
    ( SELECT "ep2"."player_id"
           FROM "public"."wsop_event_players" "ep2"
          WHERE (("ep2"."event_id" = "e"."id") AND ("ep2"."status" = 'active'::"public"."wsop_player_status"))
          ORDER BY "ep2"."current_chips" DESC
         LIMIT 1) AS "chip_leader_id",
    "avg"("ep"."current_chips") FILTER (WHERE ("ep"."status" = 'active'::"public"."wsop_player_status")) AS "avg_stack",
    "e"."updated_at"
   FROM ("public"."wsop_events" "e"
     LEFT JOIN "public"."wsop_event_players" "ep" ON (("e"."id" = "ep"."event_id")))
  GROUP BY "e"."id"
  ORDER BY "e"."start_date" DESC;



CREATE OR REPLACE VIEW "public"."v_player_stats" AS
 SELECT "p"."id",
    "p"."wsop_player_id",
    "p"."name",
    "p"."country_code",
    "p"."country_name",
    "p"."wsop_bracelets",
    "p"."lifetime_earnings",
    "count"(DISTINCT "ep"."event_id") AS "events_played",
    "count"(
        CASE
            WHEN ("ep"."status" = 'winner'::"public"."wsop_player_status") THEN 1
            ELSE NULL::integer
        END) AS "wins",
    "count"(
        CASE
            WHEN ("ep"."prize_won" > 0) THEN 1
            ELSE NULL::integer
        END) AS "cashes",
    "sum"("ep"."prize_won") AS "total_prize_won",
    "avg"("ep"."rank") FILTER (WHERE ("ep"."rank" IS NOT NULL)) AS "avg_finish",
    "max"("ep"."created_at") AS "last_event_date",
    "p"."updated_at"
   FROM ("public"."wsop_players" "p"
     LEFT JOIN "public"."wsop_event_players" "ep" ON (("p"."id" = "ep"."player_id")))
  GROUP BY "p"."id"
  ORDER BY "p"."lifetime_earnings" DESC;



CREATE OR REPLACE TRIGGER "audit_player_link_mapping" AFTER INSERT OR DELETE OR UPDATE ON "public"."player_link_mapping" FOR EACH ROW EXECUTE FUNCTION "public"."log_manual_audit"();



CREATE OR REPLACE TRIGGER "audit_player_overrides" AFTER INSERT OR DELETE OR UPDATE ON "public"."player_overrides" FOR EACH ROW EXECUTE FUNCTION "public"."log_manual_audit"();



CREATE OR REPLACE TRIGGER "increment_template_usage_on_item" AFTER INSERT ON "public"."cue_items" FOR EACH ROW EXECUTE FUNCTION "public"."increment_template_usage"();



CREATE OR REPLACE TRIGGER "normalize_wsop_player_name" BEFORE INSERT OR UPDATE ON "public"."wsop_players" FOR EACH ROW EXECUTE FUNCTION "public"."set_normalized_name"();



CREATE OR REPLACE TRIGGER "trigger_aep_media_sources_updated_at" BEFORE UPDATE ON "public"."aep_media_sources" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "trigger_api_keys_updated_at" BEFORE UPDATE ON "public"."api_keys" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "trigger_gfx_aep_comp_updated_at" BEFORE UPDATE ON "public"."gfx_aep_compositions" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "trigger_gfx_aep_mapping_updated_at" BEFORE UPDATE ON "public"."gfx_aep_field_mappings" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "trigger_job_queue_updated_at" BEFORE UPDATE ON "public"."job_queue" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "trigger_render_queue_updated_at" BEFORE UPDATE ON "public"."render_queue" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "trigger_sync_status_updated_at" BEFORE UPDATE ON "public"."sync_status" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "trigger_system_config_updated_at" BEFORE UPDATE ON "public"."system_config" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "trigger_validate_mapping_slot_range" BEFORE INSERT OR UPDATE ON "public"."gfx_aep_field_mappings" FOR EACH ROW EXECUTE FUNCTION "public"."validate_mapping_slot_range"();



CREATE OR REPLACE TRIGGER "trigger_validate_transform_params" BEFORE INSERT OR UPDATE ON "public"."gfx_aep_field_mappings" FOR EACH ROW EXECUTE FUNCTION "public"."validate_transform_params"();



CREATE OR REPLACE TRIGGER "update_broadcast_sessions_updated_at" BEFORE UPDATE ON "public"."broadcast_sessions" FOR EACH ROW EXECUTE FUNCTION "public"."update_cue_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_cue_items_updated_at" BEFORE UPDATE ON "public"."cue_items" FOR EACH ROW EXECUTE FUNCTION "public"."update_cue_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_cue_sheets_updated_at" BEFORE UPDATE ON "public"."cue_sheets" FOR EACH ROW EXECUTE FUNCTION "public"."update_cue_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_cue_templates_updated_at" BEFORE UPDATE ON "public"."cue_templates" FOR EACH ROW EXECUTE FUNCTION "public"."update_cue_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_gfx_hands_updated_at" BEFORE UPDATE ON "public"."gfx_hands" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_gfx_players_updated_at" BEFORE UPDATE ON "public"."gfx_players" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_gfx_sessions_updated_at" BEFORE UPDATE ON "public"."gfx_sessions" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_player_link_mapping_updated_at" BEFORE UPDATE ON "public"."player_link_mapping" FOR EACH ROW EXECUTE FUNCTION "public"."update_manual_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_player_overrides_updated_at" BEFORE UPDATE ON "public"."player_overrides" FOR EACH ROW EXECUTE FUNCTION "public"."update_manual_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_session_stats_on_sheet_change" AFTER INSERT OR DELETE OR UPDATE ON "public"."cue_sheets" FOR EACH ROW EXECUTE FUNCTION "public"."update_session_stats"();



CREATE OR REPLACE TRIGGER "update_sheet_stats_on_item_change" AFTER INSERT OR DELETE OR UPDATE ON "public"."cue_items" FOR EACH ROW EXECUTE FUNCTION "public"."update_cue_sheet_stats"();



CREATE OR REPLACE TRIGGER "update_wsop_event_players_updated_at" BEFORE UPDATE ON "public"."wsop_event_players" FOR EACH ROW EXECUTE FUNCTION "public"."update_wsop_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_wsop_events_updated_at" BEFORE UPDATE ON "public"."wsop_events" FOR EACH ROW EXECUTE FUNCTION "public"."update_wsop_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_wsop_players_updated_at" BEFORE UPDATE ON "public"."wsop_players" FOR EACH ROW EXECUTE FUNCTION "public"."update_wsop_updated_at_column"();



ALTER TABLE ONLY "public"."cue_items"
    ADD CONSTRAINT "cue_items_sheet_id_fkey" FOREIGN KEY ("sheet_id") REFERENCES "public"."cue_sheets"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."cue_items"
    ADD CONSTRAINT "cue_items_template_id_fkey" FOREIGN KEY ("template_id") REFERENCES "public"."cue_templates"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."cue_sheets"
    ADD CONSTRAINT "cue_sheets_parent_version_id_fkey" FOREIGN KEY ("parent_version_id") REFERENCES "public"."cue_sheets"("id");



ALTER TABLE ONLY "public"."cue_sheets"
    ADD CONSTRAINT "cue_sheets_session_id_fkey" FOREIGN KEY ("session_id") REFERENCES "public"."broadcast_sessions"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."cue_sheets"
    ADD CONSTRAINT "fk_cue_sheets_current_item" FOREIGN KEY ("current_item_id") REFERENCES "public"."cue_items"("id") ON DELETE SET NULL DEFERRABLE INITIALLY DEFERRED;



ALTER TABLE ONLY "public"."gfx_aep_field_mappings"
    ADD CONSTRAINT "fk_mapping_composition" FOREIGN KEY ("composition_name") REFERENCES "public"."gfx_aep_compositions"("name") ON UPDATE CASCADE ON DELETE RESTRICT;



COMMENT ON CONSTRAINT "fk_mapping_composition" ON "public"."gfx_aep_field_mappings" IS '컴포지션 이름 참조 무결성: 존재하지 않는 컴포지션 참조 방지';



ALTER TABLE ONLY "public"."gfx_events"
    ADD CONSTRAINT "gfx_events_hand_id_fkey" FOREIGN KEY ("hand_id") REFERENCES "public"."gfx_hands"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."gfx_hand_players"
    ADD CONSTRAINT "gfx_hand_players_hand_id_fkey" FOREIGN KEY ("hand_id") REFERENCES "public"."gfx_hands"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."gfx_hand_players"
    ADD CONSTRAINT "gfx_hand_players_player_id_fkey" FOREIGN KEY ("player_id") REFERENCES "public"."gfx_players"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."gfx_triggers"
    ADD CONSTRAINT "gfx_triggers_cue_item_id_fkey" FOREIGN KEY ("cue_item_id") REFERENCES "public"."cue_items"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."gfx_triggers"
    ADD CONSTRAINT "gfx_triggers_session_id_fkey" FOREIGN KEY ("session_id") REFERENCES "public"."broadcast_sessions"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."gfx_triggers"
    ADD CONSTRAINT "gfx_triggers_sheet_id_fkey" FOREIGN KEY ("sheet_id") REFERENCES "public"."cue_sheets"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."hand_grades"
    ADD CONSTRAINT "hand_grades_hand_id_fkey" FOREIGN KEY ("hand_id") REFERENCES "public"."gfx_hands"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."job_queue"
    ADD CONSTRAINT "job_queue_parent_job_id_fkey" FOREIGN KEY ("parent_job_id") REFERENCES "public"."job_queue"("id");



ALTER TABLE ONLY "public"."notifications"
    ADD CONSTRAINT "notifications_job_id_fkey" FOREIGN KEY ("job_id") REFERENCES "public"."job_queue"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."player_overrides"
    ADD CONSTRAINT "player_overrides_gfx_player_id_fkey" FOREIGN KEY ("gfx_player_id") REFERENCES "public"."gfx_players"("id");



ALTER TABLE ONLY "public"."profile_images"
    ADD CONSTRAINT "profile_images_gfx_player_id_fkey" FOREIGN KEY ("gfx_player_id") REFERENCES "public"."gfx_players"("id");



ALTER TABLE ONLY "public"."profile_images"
    ADD CONSTRAINT "profile_images_wsop_player_id_fkey" FOREIGN KEY ("wsop_player_id") REFERENCES "public"."wsop_players"("id");



ALTER TABLE ONLY "public"."render_queue"
    ADD CONSTRAINT "render_queue_job_id_fkey" FOREIGN KEY ("job_id") REFERENCES "public"."job_queue"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."sync_history"
    ADD CONSTRAINT "sync_history_job_id_fkey" FOREIGN KEY ("job_id") REFERENCES "public"."job_queue"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."sync_history"
    ADD CONSTRAINT "sync_history_sync_status_id_fkey" FOREIGN KEY ("sync_status_id") REFERENCES "public"."sync_status"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."sync_log"
    ADD CONSTRAINT "sync_log_session_id_fkey" FOREIGN KEY ("session_id") REFERENCES "public"."gfx_sessions"("id");



ALTER TABLE ONLY "public"."wsop_chip_counts"
    ADD CONSTRAINT "wsop_chip_counts_event_id_fkey" FOREIGN KEY ("event_id") REFERENCES "public"."wsop_events"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."wsop_chip_counts"
    ADD CONSTRAINT "wsop_chip_counts_player_id_fkey" FOREIGN KEY ("player_id") REFERENCES "public"."wsop_players"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."wsop_event_players"
    ADD CONSTRAINT "wsop_event_players_eliminated_by_player_id_fkey" FOREIGN KEY ("eliminated_by_player_id") REFERENCES "public"."wsop_players"("id");



ALTER TABLE ONLY "public"."wsop_event_players"
    ADD CONSTRAINT "wsop_event_players_event_id_fkey" FOREIGN KEY ("event_id") REFERENCES "public"."wsop_events"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."wsop_event_players"
    ADD CONSTRAINT "wsop_event_players_player_id_fkey" FOREIGN KEY ("player_id") REFERENCES "public"."wsop_players"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."wsop_import_logs"
    ADD CONSTRAINT "wsop_import_logs_event_id_fkey" FOREIGN KEY ("event_id") REFERENCES "public"."wsop_events"("id");



ALTER TABLE ONLY "public"."wsop_standings"
    ADD CONSTRAINT "wsop_standings_chip_leader_player_id_fkey" FOREIGN KEY ("chip_leader_player_id") REFERENCES "public"."wsop_players"("id");



ALTER TABLE ONLY "public"."wsop_standings"
    ADD CONSTRAINT "wsop_standings_event_id_fkey" FOREIGN KEY ("event_id") REFERENCES "public"."wsop_events"("id") ON DELETE CASCADE;



CREATE POLICY "Authenticated read on aep_media_sources" ON "public"."aep_media_sources" FOR SELECT USING (("auth"."role"() = 'authenticated'::"text"));



CREATE POLICY "Service role full access on aep_media_sources" ON "public"."aep_media_sources" USING (("auth"."role"() = 'service_role'::"text")) WITH CHECK (("auth"."role"() = 'service_role'::"text"));



ALTER TABLE "public"."activity_log" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "activity_log_insert_service" ON "public"."activity_log" FOR INSERT WITH CHECK (("auth"."role"() = 'service_role'::"text"));



CREATE POLICY "activity_log_select_authenticated" ON "public"."activity_log" FOR SELECT USING (("auth"."role"() = 'authenticated'::"text"));



ALTER TABLE "public"."aep_media_sources" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."api_keys" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "api_keys_all_service" ON "public"."api_keys" USING (("auth"."role"() = 'service_role'::"text"));



CREATE POLICY "api_keys_select_service" ON "public"."api_keys" FOR SELECT USING (("auth"."role"() = 'service_role'::"text"));



ALTER TABLE "public"."broadcast_sessions" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "broadcast_sessions_insert_service" ON "public"."broadcast_sessions" FOR INSERT WITH CHECK (("auth"."role"() = 'service_role'::"text"));



CREATE POLICY "broadcast_sessions_select_authenticated" ON "public"."broadcast_sessions" FOR SELECT USING (("auth"."role"() = 'authenticated'::"text"));



CREATE POLICY "broadcast_sessions_update_service" ON "public"."broadcast_sessions" FOR UPDATE USING (("auth"."role"() = 'service_role'::"text"));



ALTER TABLE "public"."cue_items" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "cue_items_all_service" ON "public"."cue_items" USING (("auth"."role"() = 'service_role'::"text"));



CREATE POLICY "cue_items_select_authenticated" ON "public"."cue_items" FOR SELECT USING (("auth"."role"() = 'authenticated'::"text"));



ALTER TABLE "public"."cue_sheets" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "cue_sheets_all_service" ON "public"."cue_sheets" USING (("auth"."role"() = 'service_role'::"text"));



CREATE POLICY "cue_sheets_select_authenticated" ON "public"."cue_sheets" FOR SELECT USING (("auth"."role"() = 'authenticated'::"text"));



ALTER TABLE "public"."cue_templates" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "cue_templates_all_service" ON "public"."cue_templates" USING (("auth"."role"() = 'service_role'::"text"));



CREATE POLICY "cue_templates_select_authenticated" ON "public"."cue_templates" FOR SELECT USING (("auth"."role"() = 'authenticated'::"text"));



CREATE POLICY "gfx_aep_comp_all_service" ON "public"."gfx_aep_compositions" USING (("auth"."role"() = 'service_role'::"text"));



CREATE POLICY "gfx_aep_comp_select_authenticated" ON "public"."gfx_aep_compositions" FOR SELECT USING (("auth"."role"() = 'authenticated'::"text"));



ALTER TABLE "public"."gfx_aep_compositions" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."gfx_aep_field_mappings" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "gfx_aep_mapping_all_service" ON "public"."gfx_aep_field_mappings" USING (("auth"."role"() = 'service_role'::"text"));



CREATE POLICY "gfx_aep_mapping_select_authenticated" ON "public"."gfx_aep_field_mappings" FOR SELECT USING (("auth"."role"() = 'authenticated'::"text"));



ALTER TABLE "public"."gfx_events" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "gfx_events_insert_service" ON "public"."gfx_events" FOR INSERT WITH CHECK (("auth"."role"() = 'service_role'::"text"));



CREATE POLICY "gfx_events_select_authenticated" ON "public"."gfx_events" FOR SELECT USING (("auth"."role"() = 'authenticated'::"text"));



ALTER TABLE "public"."gfx_hand_players" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "gfx_hand_players_insert_service" ON "public"."gfx_hand_players" FOR INSERT WITH CHECK (("auth"."role"() = 'service_role'::"text"));



CREATE POLICY "gfx_hand_players_select_authenticated" ON "public"."gfx_hand_players" FOR SELECT USING (("auth"."role"() = 'authenticated'::"text"));



ALTER TABLE "public"."gfx_hands" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "gfx_hands_insert_service" ON "public"."gfx_hands" FOR INSERT WITH CHECK (("auth"."role"() = 'service_role'::"text"));



CREATE POLICY "gfx_hands_select_authenticated" ON "public"."gfx_hands" FOR SELECT USING (("auth"."role"() = 'authenticated'::"text"));



ALTER TABLE "public"."gfx_players" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "gfx_players_insert_service" ON "public"."gfx_players" FOR INSERT WITH CHECK (("auth"."role"() = 'service_role'::"text"));



CREATE POLICY "gfx_players_select_authenticated" ON "public"."gfx_players" FOR SELECT USING (("auth"."role"() = 'authenticated'::"text"));



CREATE POLICY "gfx_players_update_service" ON "public"."gfx_players" FOR UPDATE USING (("auth"."role"() = 'service_role'::"text"));



ALTER TABLE "public"."gfx_sessions" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "gfx_sessions_insert_service" ON "public"."gfx_sessions" FOR INSERT WITH CHECK (("auth"."role"() = 'service_role'::"text"));



CREATE POLICY "gfx_sessions_select_authenticated" ON "public"."gfx_sessions" FOR SELECT USING (("auth"."role"() = 'authenticated'::"text"));



CREATE POLICY "gfx_sessions_update_service" ON "public"."gfx_sessions" FOR UPDATE USING (("auth"."role"() = 'service_role'::"text"));



ALTER TABLE "public"."gfx_triggers" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "gfx_triggers_insert_service" ON "public"."gfx_triggers" FOR INSERT WITH CHECK (("auth"."role"() = 'service_role'::"text"));



CREATE POLICY "gfx_triggers_select_authenticated" ON "public"."gfx_triggers" FOR SELECT USING (("auth"."role"() = 'authenticated'::"text"));



ALTER TABLE "public"."hand_grades" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "hand_grades_insert_service" ON "public"."hand_grades" FOR INSERT WITH CHECK (("auth"."role"() = 'service_role'::"text"));



CREATE POLICY "hand_grades_select_authenticated" ON "public"."hand_grades" FOR SELECT USING (("auth"."role"() = 'authenticated'::"text"));



CREATE POLICY "hand_grades_update_service" ON "public"."hand_grades" FOR UPDATE USING (("auth"."role"() = 'service_role'::"text"));



ALTER TABLE "public"."job_queue" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "job_queue_all_service" ON "public"."job_queue" USING (("auth"."role"() = 'service_role'::"text"));



CREATE POLICY "job_queue_select_authenticated" ON "public"."job_queue" FOR SELECT USING (("auth"."role"() = 'authenticated'::"text"));



ALTER TABLE "public"."notifications" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "notifications_all_service" ON "public"."notifications" USING (("auth"."role"() = 'service_role'::"text"));



CREATE POLICY "notifications_select_own" ON "public"."notifications" FOR SELECT USING ((("auth"."role"() = 'authenticated'::"text") AND (("target_user" IS NULL) OR ("target_user" = ("auth"."uid"())::"text"))));



CREATE POLICY "notifications_update_own" ON "public"."notifications" FOR UPDATE USING ((("auth"."role"() = 'authenticated'::"text") AND (("target_user" IS NULL) OR ("target_user" = ("auth"."uid"())::"text"))));



ALTER TABLE "public"."player_link_mapping" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "player_link_mapping_all_service" ON "public"."player_link_mapping" USING (("auth"."role"() = 'service_role'::"text"));



CREATE POLICY "player_link_mapping_select_authenticated" ON "public"."player_link_mapping" FOR SELECT USING (("auth"."role"() = 'authenticated'::"text"));



ALTER TABLE "public"."player_overrides" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "player_overrides_all_service" ON "public"."player_overrides" USING (("auth"."role"() = 'service_role'::"text"));



CREATE POLICY "player_overrides_select_authenticated" ON "public"."player_overrides" FOR SELECT USING (("auth"."role"() = 'authenticated'::"text"));



ALTER TABLE "public"."profile_images" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "profile_images_delete_service" ON "public"."profile_images" FOR DELETE USING (("auth"."role"() = 'service_role'::"text"));



CREATE POLICY "profile_images_insert_service" ON "public"."profile_images" FOR INSERT WITH CHECK (("auth"."role"() = 'service_role'::"text"));



CREATE POLICY "profile_images_select_authenticated" ON "public"."profile_images" FOR SELECT USING (("auth"."role"() = 'authenticated'::"text"));



CREATE POLICY "profile_images_update_service" ON "public"."profile_images" FOR UPDATE USING (("auth"."role"() = 'service_role'::"text"));



ALTER TABLE "public"."render_queue" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "render_queue_all_service" ON "public"."render_queue" USING (("auth"."role"() = 'service_role'::"text"));



CREATE POLICY "render_queue_select_authenticated" ON "public"."render_queue" FOR SELECT USING (("auth"."role"() = 'authenticated'::"text"));



ALTER TABLE "public"."sync_history" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "sync_history_all_service" ON "public"."sync_history" USING (("auth"."role"() = 'service_role'::"text"));



CREATE POLICY "sync_history_select_authenticated" ON "public"."sync_history" FOR SELECT USING (("auth"."role"() = 'authenticated'::"text"));



ALTER TABLE "public"."sync_log" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "sync_log_all_service" ON "public"."sync_log" USING (("auth"."role"() = 'service_role'::"text"));



CREATE POLICY "sync_log_select_authenticated" ON "public"."sync_log" FOR SELECT USING (("auth"."role"() = 'authenticated'::"text"));



ALTER TABLE "public"."sync_status" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "sync_status_all_service" ON "public"."sync_status" USING (("auth"."role"() = 'service_role'::"text"));



CREATE POLICY "sync_status_select_authenticated" ON "public"."sync_status" FOR SELECT USING (("auth"."role"() = 'authenticated'::"text"));



ALTER TABLE "public"."system_config" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "system_config_select_authenticated" ON "public"."system_config" FOR SELECT USING ((("auth"."role"() = 'authenticated'::"text") AND ("is_sensitive" = false)));



CREATE POLICY "system_config_select_service" ON "public"."system_config" FOR SELECT USING (("auth"."role"() = 'service_role'::"text"));



CREATE POLICY "system_config_update_service" ON "public"."system_config" FOR UPDATE USING ((("auth"."role"() = 'service_role'::"text") AND ("is_readonly" = false)));



ALTER TABLE "public"."wsop_chip_counts" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "wsop_chip_counts_insert_service" ON "public"."wsop_chip_counts" FOR INSERT WITH CHECK (("auth"."role"() = 'service_role'::"text"));



CREATE POLICY "wsop_chip_counts_select_authenticated" ON "public"."wsop_chip_counts" FOR SELECT USING (("auth"."role"() = 'authenticated'::"text"));



ALTER TABLE "public"."wsop_event_players" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "wsop_event_players_insert_service" ON "public"."wsop_event_players" FOR INSERT WITH CHECK (("auth"."role"() = 'service_role'::"text"));



CREATE POLICY "wsop_event_players_select_authenticated" ON "public"."wsop_event_players" FOR SELECT USING (("auth"."role"() = 'authenticated'::"text"));



CREATE POLICY "wsop_event_players_update_service" ON "public"."wsop_event_players" FOR UPDATE USING (("auth"."role"() = 'service_role'::"text"));



ALTER TABLE "public"."wsop_events" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "wsop_events_insert_service" ON "public"."wsop_events" FOR INSERT WITH CHECK (("auth"."role"() = 'service_role'::"text"));



CREATE POLICY "wsop_events_select_authenticated" ON "public"."wsop_events" FOR SELECT USING (("auth"."role"() = 'authenticated'::"text"));



CREATE POLICY "wsop_events_update_service" ON "public"."wsop_events" FOR UPDATE USING (("auth"."role"() = 'service_role'::"text"));



ALTER TABLE "public"."wsop_import_logs" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "wsop_import_logs_all_service" ON "public"."wsop_import_logs" USING (("auth"."role"() = 'service_role'::"text"));



CREATE POLICY "wsop_import_logs_select_authenticated" ON "public"."wsop_import_logs" FOR SELECT USING (("auth"."role"() = 'authenticated'::"text"));



ALTER TABLE "public"."wsop_players" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "wsop_players_insert_service" ON "public"."wsop_players" FOR INSERT WITH CHECK (("auth"."role"() = 'service_role'::"text"));



CREATE POLICY "wsop_players_select_authenticated" ON "public"."wsop_players" FOR SELECT USING (("auth"."role"() = 'authenticated'::"text"));



CREATE POLICY "wsop_players_update_service" ON "public"."wsop_players" FOR UPDATE USING (("auth"."role"() = 'service_role'::"text"));



ALTER TABLE "public"."wsop_standings" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "wsop_standings_insert_service" ON "public"."wsop_standings" FOR INSERT WITH CHECK (("auth"."role"() = 'service_role'::"text"));



CREATE POLICY "wsop_standings_select_authenticated" ON "public"."wsop_standings" FOR SELECT USING (("auth"."role"() = 'authenticated'::"text"));



GRANT USAGE ON SCHEMA "public" TO "postgres";
GRANT USAGE ON SCHEMA "public" TO "anon";
GRANT USAGE ON SCHEMA "public" TO "authenticated";
GRANT USAGE ON SCHEMA "public" TO "service_role";



GRANT ALL ON FUNCTION "public"."claim_next_job"("p_worker_id" "text", "p_job_types" "public"."orch_job_type"[], "p_lock_duration_minutes" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."claim_next_job"("p_worker_id" "text", "p_job_types" "public"."orch_job_type"[], "p_lock_duration_minutes" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."claim_next_job"("p_worker_id" "text", "p_job_types" "public"."orch_job_type"[], "p_lock_duration_minutes" integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."complete_job"("p_job_id" "uuid", "p_result" "jsonb", "p_success" boolean, "p_error_message" "text", "p_error_details" "jsonb") TO "anon";
GRANT ALL ON FUNCTION "public"."complete_job"("p_job_id" "uuid", "p_result" "jsonb", "p_success" boolean, "p_error_message" "text", "p_error_details" "jsonb") TO "authenticated";
GRANT ALL ON FUNCTION "public"."complete_job"("p_job_id" "uuid", "p_result" "jsonb", "p_success" boolean, "p_error_message" "text", "p_error_details" "jsonb") TO "service_role";



GRANT ALL ON FUNCTION "public"."format_bbs"("chips" bigint, "bb" bigint) TO "anon";
GRANT ALL ON FUNCTION "public"."format_bbs"("chips" bigint, "bb" bigint) TO "authenticated";
GRANT ALL ON FUNCTION "public"."format_bbs"("chips" bigint, "bb" bigint) TO "service_role";



GRANT ALL ON FUNCTION "public"."format_bbs_safe"("chips" bigint, "bb" bigint) TO "anon";
GRANT ALL ON FUNCTION "public"."format_bbs_safe"("chips" bigint, "bb" bigint) TO "authenticated";
GRANT ALL ON FUNCTION "public"."format_bbs_safe"("chips" bigint, "bb" bigint) TO "service_role";



GRANT ALL ON FUNCTION "public"."format_blinds"("sb" bigint, "bb" bigint, "ante" bigint) TO "anon";
GRANT ALL ON FUNCTION "public"."format_blinds"("sb" bigint, "bb" bigint, "ante" bigint) TO "authenticated";
GRANT ALL ON FUNCTION "public"."format_blinds"("sb" bigint, "bb" bigint, "ante" bigint) TO "service_role";



GRANT ALL ON FUNCTION "public"."format_chips"("amount" bigint) TO "anon";
GRANT ALL ON FUNCTION "public"."format_chips"("amount" bigint) TO "authenticated";
GRANT ALL ON FUNCTION "public"."format_chips"("amount" bigint) TO "service_role";



GRANT ALL ON FUNCTION "public"."format_chips_comma"("amount" bigint) TO "anon";
GRANT ALL ON FUNCTION "public"."format_chips_comma"("amount" bigint) TO "authenticated";
GRANT ALL ON FUNCTION "public"."format_chips_comma"("amount" bigint) TO "service_role";



GRANT ALL ON FUNCTION "public"."format_chips_safe"("amount" bigint) TO "anon";
GRANT ALL ON FUNCTION "public"."format_chips_safe"("amount" bigint) TO "authenticated";
GRANT ALL ON FUNCTION "public"."format_chips_safe"("amount" bigint) TO "service_role";



GRANT ALL ON FUNCTION "public"."format_chips_short"("amount" bigint) TO "anon";
GRANT ALL ON FUNCTION "public"."format_chips_short"("amount" bigint) TO "authenticated";
GRANT ALL ON FUNCTION "public"."format_chips_short"("amount" bigint) TO "service_role";



GRANT ALL ON FUNCTION "public"."format_currency"("amount" bigint) TO "anon";
GRANT ALL ON FUNCTION "public"."format_currency"("amount" bigint) TO "authenticated";
GRANT ALL ON FUNCTION "public"."format_currency"("amount" bigint) TO "service_role";



GRANT ALL ON FUNCTION "public"."format_currency_cents"("amount" bigint) TO "anon";
GRANT ALL ON FUNCTION "public"."format_currency_cents"("amount" bigint) TO "authenticated";
GRANT ALL ON FUNCTION "public"."format_currency_cents"("amount" bigint) TO "service_role";



GRANT ALL ON FUNCTION "public"."format_currency_from_int"("amount" bigint) TO "anon";
GRANT ALL ON FUNCTION "public"."format_currency_from_int"("amount" bigint) TO "authenticated";
GRANT ALL ON FUNCTION "public"."format_currency_from_int"("amount" bigint) TO "service_role";



GRANT ALL ON FUNCTION "public"."format_currency_safe"("amount" bigint) TO "anon";
GRANT ALL ON FUNCTION "public"."format_currency_safe"("amount" bigint) TO "authenticated";
GRANT ALL ON FUNCTION "public"."format_currency_safe"("amount" bigint) TO "service_role";



GRANT ALL ON FUNCTION "public"."format_date"("d" "date") TO "anon";
GRANT ALL ON FUNCTION "public"."format_date"("d" "date") TO "authenticated";
GRANT ALL ON FUNCTION "public"."format_date"("d" "date") TO "service_role";



GRANT ALL ON FUNCTION "public"."format_date_short"("d" "date") TO "anon";
GRANT ALL ON FUNCTION "public"."format_date_short"("d" "date") TO "authenticated";
GRANT ALL ON FUNCTION "public"."format_date_short"("d" "date") TO "service_role";



GRANT ALL ON FUNCTION "public"."format_number"("num" bigint) TO "anon";
GRANT ALL ON FUNCTION "public"."format_number"("num" bigint) TO "authenticated";
GRANT ALL ON FUNCTION "public"."format_number"("num" bigint) TO "service_role";



GRANT ALL ON FUNCTION "public"."format_percent"("value" numeric) TO "anon";
GRANT ALL ON FUNCTION "public"."format_percent"("value" numeric) TO "authenticated";
GRANT ALL ON FUNCTION "public"."format_percent"("value" numeric) TO "service_role";



GRANT ALL ON FUNCTION "public"."format_time"("t" time without time zone) TO "anon";
GRANT ALL ON FUNCTION "public"."format_time"("t" time without time zone) TO "authenticated";
GRANT ALL ON FUNCTION "public"."format_time"("t" time without time zone) TO "service_role";



GRANT ALL ON FUNCTION "public"."format_time_12h"("t" time without time zone) TO "anon";
GRANT ALL ON FUNCTION "public"."format_time_12h"("t" time without time zone) TO "authenticated";
GRANT ALL ON FUNCTION "public"."format_time_12h"("t" time without time zone) TO "service_role";



GRANT ALL ON FUNCTION "public"."generate_player_code"() TO "anon";
GRANT ALL ON FUNCTION "public"."generate_player_code"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."generate_player_code"() TO "service_role";



GRANT ALL ON FUNCTION "public"."generate_player_hash"("p_name" "text", "p_long_name" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."generate_player_hash"("p_name" "text", "p_long_name" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."generate_player_hash"("p_name" "text", "p_long_name" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."get_at_risk_data"("p_session_id" bigint, "p_hand_num" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."get_at_risk_data"("p_session_id" bigint, "p_hand_num" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_at_risk_data"("p_session_id" bigint, "p_hand_num" integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."get_chip_comparison_data"("p_session_id" bigint, "p_hand_num" integer, "p_selected_player_name" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."get_chip_comparison_data"("p_session_id" bigint, "p_hand_num" integer, "p_selected_player_name" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_chip_comparison_data"("p_session_id" bigint, "p_hand_num" integer, "p_selected_player_name" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."get_chip_display_data"("p_session_id" bigint, "p_hand_num" integer, "p_slot_count" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."get_chip_display_data"("p_session_id" bigint, "p_hand_num" integer, "p_slot_count" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_chip_display_data"("p_session_id" bigint, "p_hand_num" integer, "p_slot_count" integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."get_chip_flow_data"("p_session_id" bigint, "p_current_hand_num" integer, "p_player_name" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."get_chip_flow_data"("p_session_id" bigint, "p_current_hand_num" integer, "p_player_name" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_chip_flow_data"("p_session_id" bigint, "p_current_hand_num" integer, "p_player_name" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."get_chips_n_hands_ago"("p_session_id" bigint, "p_current_hand_num" integer, "p_player_name" "text", "p_n_hands" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."get_chips_n_hands_ago"("p_session_id" bigint, "p_current_hand_num" integer, "p_player_name" "text", "p_n_hands" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_chips_n_hands_ago"("p_session_id" bigint, "p_current_hand_num" integer, "p_player_name" "text", "p_n_hands" integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."get_config"("p_key" "text", "p_environment" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."get_config"("p_key" "text", "p_environment" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_config"("p_key" "text", "p_environment" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."get_elimination_data"("p_session_id" bigint, "p_hand_num" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."get_elimination_data"("p_session_id" bigint, "p_hand_num" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_elimination_data"("p_session_id" bigint, "p_hand_num" integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."get_flag_path"("country_code" character varying) TO "anon";
GRANT ALL ON FUNCTION "public"."get_flag_path"("country_code" character varying) TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_flag_path"("country_code" character varying) TO "service_role";



GRANT ALL ON FUNCTION "public"."get_next_cue_item"("p_sheet_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."get_next_cue_item"("p_sheet_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_next_cue_item"("p_sheet_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."get_payout_data"("p_event_id" "uuid", "p_slot_count" integer, "p_start_rank" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."get_payout_data"("p_event_id" "uuid", "p_slot_count" integer, "p_start_rank" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_payout_data"("p_event_id" "uuid", "p_slot_count" integer, "p_start_rank" integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."get_player_field_with_override"("p_player_id" "uuid", "p_field_name" "text", "p_default_value" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."get_player_field_with_override"("p_player_id" "uuid", "p_field_name" "text", "p_default_value" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_player_field_with_override"("p_player_id" "uuid", "p_field_name" "text", "p_default_value" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."get_player_history_data"("p_session_id" bigint, "p_hand_num" integer, "p_player_name" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."get_player_history_data"("p_session_id" bigint, "p_hand_num" integer, "p_player_name" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_player_history_data"("p_session_id" bigint, "p_hand_num" integer, "p_player_name" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."get_player_name_data"("p_session_id" bigint, "p_hand_num" integer, "p_seat_num" integer, "p_variant" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."get_player_name_data"("p_session_id" bigint, "p_hand_num" integer, "p_seat_num" integer, "p_variant" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_player_name_data"("p_session_id" bigint, "p_hand_num" integer, "p_seat_num" integer, "p_variant" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."increment_template_usage"() TO "anon";
GRANT ALL ON FUNCTION "public"."increment_template_usage"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."increment_template_usage"() TO "service_role";



GRANT ALL ON FUNCTION "public"."log_activity"("p_action" "text", "p_actor" "text", "p_actor_type" "public"."orch_actor_type", "p_entity_type" "text", "p_entity_id" "uuid", "p_changes" "jsonb", "p_metadata" "jsonb") TO "anon";
GRANT ALL ON FUNCTION "public"."log_activity"("p_action" "text", "p_actor" "text", "p_actor_type" "public"."orch_actor_type", "p_entity_type" "text", "p_entity_id" "uuid", "p_changes" "jsonb", "p_metadata" "jsonb") TO "authenticated";
GRANT ALL ON FUNCTION "public"."log_activity"("p_action" "text", "p_actor" "text", "p_actor_type" "public"."orch_actor_type", "p_entity_type" "text", "p_entity_id" "uuid", "p_changes" "jsonb", "p_metadata" "jsonb") TO "service_role";



GRANT ALL ON FUNCTION "public"."log_manual_audit"() TO "anon";
GRANT ALL ON FUNCTION "public"."log_manual_audit"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."log_manual_audit"() TO "service_role";



GRANT ALL ON FUNCTION "public"."normalize_manual_player_name"("p_name" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."normalize_manual_player_name"("p_name" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."normalize_manual_player_name"("p_name" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."normalize_player_name"("p_name" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."normalize_player_name"("p_name" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."normalize_player_name"("p_name" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."parse_iso8601_duration"("duration" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."parse_iso8601_duration"("duration" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."parse_iso8601_duration"("duration" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."set_manual_normalized_name"() TO "anon";
GRANT ALL ON FUNCTION "public"."set_manual_normalized_name"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."set_manual_normalized_name"() TO "service_role";



GRANT ALL ON FUNCTION "public"."set_normalized_name"() TO "anon";
GRANT ALL ON FUNCTION "public"."set_normalized_name"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."set_normalized_name"() TO "service_role";



GRANT ALL ON FUNCTION "public"."set_player_code"() TO "anon";
GRANT ALL ON FUNCTION "public"."set_player_code"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."set_player_code"() TO "service_role";



GRANT ALL ON FUNCTION "public"."transition_cue_item_status"("p_item_id" "uuid", "p_new_status" "public"."cue_item_status", "p_triggered_by" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."transition_cue_item_status"("p_item_id" "uuid", "p_new_status" "public"."cue_item_status", "p_triggered_by" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."transition_cue_item_status"("p_item_id" "uuid", "p_new_status" "public"."cue_item_status", "p_triggered_by" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."update_cue_sheet_stats"() TO "anon";
GRANT ALL ON FUNCTION "public"."update_cue_sheet_stats"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_cue_sheet_stats"() TO "service_role";



GRANT ALL ON FUNCTION "public"."update_cue_updated_at_column"() TO "anon";
GRANT ALL ON FUNCTION "public"."update_cue_updated_at_column"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_cue_updated_at_column"() TO "service_role";



GRANT ALL ON FUNCTION "public"."update_event_player_stats"("p_event_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."update_event_player_stats"("p_event_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_event_player_stats"("p_event_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."update_event_rankings"("p_event_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."update_event_rankings"("p_event_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_event_rankings"("p_event_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."update_manual_updated_at_column"() TO "anon";
GRANT ALL ON FUNCTION "public"."update_manual_updated_at_column"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_manual_updated_at_column"() TO "service_role";



GRANT ALL ON FUNCTION "public"."update_session_stats"() TO "anon";
GRANT ALL ON FUNCTION "public"."update_session_stats"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_session_stats"() TO "service_role";



GRANT ALL ON FUNCTION "public"."update_session_stats"("p_session_id" bigint) TO "anon";
GRANT ALL ON FUNCTION "public"."update_session_stats"("p_session_id" bigint) TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_session_stats"("p_session_id" bigint) TO "service_role";



GRANT ALL ON FUNCTION "public"."update_sync_completion"("p_sync_status_id" "uuid", "p_success" boolean, "p_records_processed" integer, "p_records_created" integer, "p_records_updated" integer, "p_records_failed" integer, "p_duration_ms" integer, "p_error_message" "text", "p_sync_hash" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."update_sync_completion"("p_sync_status_id" "uuid", "p_success" boolean, "p_records_processed" integer, "p_records_created" integer, "p_records_updated" integer, "p_records_failed" integer, "p_duration_ms" integer, "p_error_message" "text", "p_sync_hash" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_sync_completion"("p_sync_status_id" "uuid", "p_success" boolean, "p_records_processed" integer, "p_records_created" integer, "p_records_updated" integer, "p_records_failed" integer, "p_duration_ms" integer, "p_error_message" "text", "p_sync_hash" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."update_updated_at_column"() TO "anon";
GRANT ALL ON FUNCTION "public"."update_updated_at_column"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_updated_at_column"() TO "service_role";



GRANT ALL ON FUNCTION "public"."update_wsop_updated_at_column"() TO "anon";
GRANT ALL ON FUNCTION "public"."update_wsop_updated_at_column"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_wsop_updated_at_column"() TO "service_role";



GRANT ALL ON FUNCTION "public"."validate_mapping_slot_range"() TO "anon";
GRANT ALL ON FUNCTION "public"."validate_mapping_slot_range"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."validate_mapping_slot_range"() TO "service_role";



GRANT ALL ON FUNCTION "public"."validate_transform_params"() TO "anon";
GRANT ALL ON FUNCTION "public"."validate_transform_params"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."validate_transform_params"() TO "service_role";



GRANT ALL ON TABLE "public"."activity_log" TO "anon";
GRANT ALL ON TABLE "public"."activity_log" TO "authenticated";
GRANT ALL ON TABLE "public"."activity_log" TO "service_role";



GRANT ALL ON TABLE "public"."aep_media_sources" TO "anon";
GRANT ALL ON TABLE "public"."aep_media_sources" TO "authenticated";
GRANT ALL ON TABLE "public"."aep_media_sources" TO "service_role";



GRANT ALL ON TABLE "public"."api_keys" TO "anon";
GRANT ALL ON TABLE "public"."api_keys" TO "authenticated";
GRANT ALL ON TABLE "public"."api_keys" TO "service_role";



GRANT ALL ON TABLE "public"."broadcast_sessions" TO "anon";
GRANT ALL ON TABLE "public"."broadcast_sessions" TO "authenticated";
GRANT ALL ON TABLE "public"."broadcast_sessions" TO "service_role";



GRANT ALL ON TABLE "public"."cue_items" TO "anon";
GRANT ALL ON TABLE "public"."cue_items" TO "authenticated";
GRANT ALL ON TABLE "public"."cue_items" TO "service_role";



GRANT ALL ON TABLE "public"."cue_sheets" TO "anon";
GRANT ALL ON TABLE "public"."cue_sheets" TO "authenticated";
GRANT ALL ON TABLE "public"."cue_sheets" TO "service_role";



GRANT ALL ON TABLE "public"."cue_templates" TO "anon";
GRANT ALL ON TABLE "public"."cue_templates" TO "authenticated";
GRANT ALL ON TABLE "public"."cue_templates" TO "service_role";



GRANT ALL ON TABLE "public"."gfx_aep_compositions" TO "anon";
GRANT ALL ON TABLE "public"."gfx_aep_compositions" TO "authenticated";
GRANT ALL ON TABLE "public"."gfx_aep_compositions" TO "service_role";



GRANT ALL ON TABLE "public"."gfx_aep_field_mappings" TO "anon";
GRANT ALL ON TABLE "public"."gfx_aep_field_mappings" TO "authenticated";
GRANT ALL ON TABLE "public"."gfx_aep_field_mappings" TO "service_role";



GRANT ALL ON TABLE "public"."gfx_events" TO "anon";
GRANT ALL ON TABLE "public"."gfx_events" TO "authenticated";
GRANT ALL ON TABLE "public"."gfx_events" TO "service_role";



GRANT ALL ON TABLE "public"."gfx_hand_players" TO "anon";
GRANT ALL ON TABLE "public"."gfx_hand_players" TO "authenticated";
GRANT ALL ON TABLE "public"."gfx_hand_players" TO "service_role";



GRANT ALL ON TABLE "public"."gfx_hands" TO "anon";
GRANT ALL ON TABLE "public"."gfx_hands" TO "authenticated";
GRANT ALL ON TABLE "public"."gfx_hands" TO "service_role";



GRANT ALL ON TABLE "public"."gfx_players" TO "anon";
GRANT ALL ON TABLE "public"."gfx_players" TO "authenticated";
GRANT ALL ON TABLE "public"."gfx_players" TO "service_role";



GRANT ALL ON TABLE "public"."gfx_sessions" TO "anon";
GRANT ALL ON TABLE "public"."gfx_sessions" TO "authenticated";
GRANT ALL ON TABLE "public"."gfx_sessions" TO "service_role";



GRANT ALL ON TABLE "public"."gfx_triggers" TO "anon";
GRANT ALL ON TABLE "public"."gfx_triggers" TO "authenticated";
GRANT ALL ON TABLE "public"."gfx_triggers" TO "service_role";



GRANT ALL ON TABLE "public"."hand_grades" TO "anon";
GRANT ALL ON TABLE "public"."hand_grades" TO "authenticated";
GRANT ALL ON TABLE "public"."hand_grades" TO "service_role";



GRANT ALL ON TABLE "public"."job_queue" TO "anon";
GRANT ALL ON TABLE "public"."job_queue" TO "authenticated";
GRANT ALL ON TABLE "public"."job_queue" TO "service_role";



GRANT ALL ON TABLE "public"."notifications" TO "anon";
GRANT ALL ON TABLE "public"."notifications" TO "authenticated";
GRANT ALL ON TABLE "public"."notifications" TO "service_role";



GRANT ALL ON TABLE "public"."player_link_mapping" TO "anon";
GRANT ALL ON TABLE "public"."player_link_mapping" TO "authenticated";
GRANT ALL ON TABLE "public"."player_link_mapping" TO "service_role";



GRANT ALL ON TABLE "public"."player_overrides" TO "anon";
GRANT ALL ON TABLE "public"."player_overrides" TO "authenticated";
GRANT ALL ON TABLE "public"."player_overrides" TO "service_role";



GRANT ALL ON TABLE "public"."profile_images" TO "anon";
GRANT ALL ON TABLE "public"."profile_images" TO "authenticated";
GRANT ALL ON TABLE "public"."profile_images" TO "service_role";



GRANT ALL ON TABLE "public"."render_queue" TO "anon";
GRANT ALL ON TABLE "public"."render_queue" TO "authenticated";
GRANT ALL ON TABLE "public"."render_queue" TO "service_role";



GRANT ALL ON TABLE "public"."sync_history" TO "anon";
GRANT ALL ON TABLE "public"."sync_history" TO "authenticated";
GRANT ALL ON TABLE "public"."sync_history" TO "service_role";



GRANT ALL ON TABLE "public"."sync_log" TO "anon";
GRANT ALL ON TABLE "public"."sync_log" TO "authenticated";
GRANT ALL ON TABLE "public"."sync_log" TO "service_role";



GRANT ALL ON TABLE "public"."sync_status" TO "anon";
GRANT ALL ON TABLE "public"."sync_status" TO "authenticated";
GRANT ALL ON TABLE "public"."sync_status" TO "service_role";



GRANT ALL ON TABLE "public"."system_config" TO "anon";
GRANT ALL ON TABLE "public"."system_config" TO "authenticated";
GRANT ALL ON TABLE "public"."system_config" TO "service_role";



GRANT ALL ON TABLE "public"."wsop_chip_counts" TO "anon";
GRANT ALL ON TABLE "public"."wsop_chip_counts" TO "authenticated";
GRANT ALL ON TABLE "public"."wsop_chip_counts" TO "service_role";



GRANT ALL ON TABLE "public"."wsop_players" TO "anon";
GRANT ALL ON TABLE "public"."wsop_players" TO "authenticated";
GRANT ALL ON TABLE "public"."wsop_players" TO "service_role";



GRANT ALL ON TABLE "public"."unified_chip_data" TO "anon";
GRANT ALL ON TABLE "public"."unified_chip_data" TO "authenticated";
GRANT ALL ON TABLE "public"."unified_chip_data" TO "service_role";



GRANT ALL ON TABLE "public"."wsop_events" TO "anon";
GRANT ALL ON TABLE "public"."wsop_events" TO "authenticated";
GRANT ALL ON TABLE "public"."wsop_events" TO "service_role";



GRANT ALL ON TABLE "public"."unified_events" TO "anon";
GRANT ALL ON TABLE "public"."unified_events" TO "authenticated";
GRANT ALL ON TABLE "public"."unified_events" TO "service_role";



GRANT ALL ON TABLE "public"."unified_players" TO "anon";
GRANT ALL ON TABLE "public"."unified_players" TO "authenticated";
GRANT ALL ON TABLE "public"."unified_players" TO "service_role";



GRANT ALL ON TABLE "public"."v_chip_count_latest" TO "anon";
GRANT ALL ON TABLE "public"."v_chip_count_latest" TO "authenticated";
GRANT ALL ON TABLE "public"."v_chip_count_latest" TO "service_role";



GRANT ALL ON TABLE "public"."v_event_summary" TO "anon";
GRANT ALL ON TABLE "public"."v_event_summary" TO "authenticated";
GRANT ALL ON TABLE "public"."v_event_summary" TO "service_role";



GRANT ALL ON TABLE "public"."v_job_queue_summary" TO "anon";
GRANT ALL ON TABLE "public"."v_job_queue_summary" TO "authenticated";
GRANT ALL ON TABLE "public"."v_job_queue_summary" TO "service_role";



GRANT ALL ON TABLE "public"."wsop_event_players" TO "anon";
GRANT ALL ON TABLE "public"."wsop_event_players" TO "authenticated";
GRANT ALL ON TABLE "public"."wsop_event_players" TO "service_role";



GRANT ALL ON TABLE "public"."v_leaderboard" TO "anon";
GRANT ALL ON TABLE "public"."v_leaderboard" TO "authenticated";
GRANT ALL ON TABLE "public"."v_leaderboard" TO "service_role";



GRANT ALL ON TABLE "public"."v_player_stats" TO "anon";
GRANT ALL ON TABLE "public"."v_player_stats" TO "authenticated";
GRANT ALL ON TABLE "public"."v_player_stats" TO "service_role";



GRANT ALL ON TABLE "public"."v_recent_hands" TO "anon";
GRANT ALL ON TABLE "public"."v_recent_hands" TO "authenticated";
GRANT ALL ON TABLE "public"."v_recent_hands" TO "service_role";



GRANT ALL ON TABLE "public"."v_render_at_risk" TO "anon";
GRANT ALL ON TABLE "public"."v_render_at_risk" TO "authenticated";
GRANT ALL ON TABLE "public"."v_render_at_risk" TO "service_role";



GRANT ALL ON TABLE "public"."v_render_chip_display" TO "anon";
GRANT ALL ON TABLE "public"."v_render_chip_display" TO "authenticated";
GRANT ALL ON TABLE "public"."v_render_chip_display" TO "service_role";



GRANT ALL ON TABLE "public"."v_render_elimination" TO "anon";
GRANT ALL ON TABLE "public"."v_render_elimination" TO "authenticated";
GRANT ALL ON TABLE "public"."v_render_elimination" TO "service_role";



GRANT ALL ON TABLE "public"."v_render_payout" TO "anon";
GRANT ALL ON TABLE "public"."v_render_payout" TO "authenticated";
GRANT ALL ON TABLE "public"."v_render_payout" TO "service_role";



GRANT ALL ON TABLE "public"."v_render_payout_gfx" TO "anon";
GRANT ALL ON TABLE "public"."v_render_payout_gfx" TO "authenticated";
GRANT ALL ON TABLE "public"."v_render_payout_gfx" TO "service_role";



GRANT ALL ON TABLE "public"."v_session_summary" TO "anon";
GRANT ALL ON TABLE "public"."v_session_summary" TO "authenticated";
GRANT ALL ON TABLE "public"."v_session_summary" TO "service_role";



GRANT ALL ON TABLE "public"."v_showdown_players" TO "anon";
GRANT ALL ON TABLE "public"."v_showdown_players" TO "authenticated";
GRANT ALL ON TABLE "public"."v_showdown_players" TO "service_role";



GRANT ALL ON TABLE "public"."v_sync_dashboard" TO "anon";
GRANT ALL ON TABLE "public"."v_sync_dashboard" TO "authenticated";
GRANT ALL ON TABLE "public"."v_sync_dashboard" TO "service_role";



GRANT ALL ON TABLE "public"."wsop_import_logs" TO "anon";
GRANT ALL ON TABLE "public"."wsop_import_logs" TO "authenticated";
GRANT ALL ON TABLE "public"."wsop_import_logs" TO "service_role";



GRANT ALL ON TABLE "public"."wsop_standings" TO "anon";
GRANT ALL ON TABLE "public"."wsop_standings" TO "authenticated";
GRANT ALL ON TABLE "public"."wsop_standings" TO "service_role";



ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "service_role";







