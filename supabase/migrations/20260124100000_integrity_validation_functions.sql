-- Migration: GFX-Supabase DB 무결성 검증 함수
-- Date: 2026-01-24
-- Purpose: 데이터 무결성 검증을 위한 함수 및 뷰 생성

-- ============================================================
-- 1. FK 무결성 검증 함수
-- ============================================================

CREATE OR REPLACE FUNCTION validate_fk_integrity()
RETURNS TABLE (
    table_name TEXT,
    fk_name TEXT,
    orphan_count BIGINT,
    status TEXT
)
LANGUAGE plpgsql
AS $$
BEGIN
    -- gfx_hands → gfx_sessions
    RETURN QUERY
    SELECT
        'gfx_hands'::TEXT,
        'session_id → gfx_sessions'::TEXT,
        COUNT(*)::BIGINT,
        CASE WHEN COUNT(*) = 0 THEN 'OK' ELSE 'ORPHAN_FOUND' END
    FROM gfx_hands h
    WHERE NOT EXISTS (SELECT 1 FROM gfx_sessions s WHERE s.session_id = h.session_id);

    -- gfx_hand_players → gfx_hands
    RETURN QUERY
    SELECT
        'gfx_hand_players'::TEXT,
        'hand_id → gfx_hands'::TEXT,
        COUNT(*)::BIGINT,
        CASE WHEN COUNT(*) = 0 THEN 'OK' ELSE 'ORPHAN_FOUND' END
    FROM gfx_hand_players hp
    WHERE NOT EXISTS (SELECT 1 FROM gfx_hands h WHERE h.id = hp.hand_id);

    -- gfx_hand_players → gfx_players
    RETURN QUERY
    SELECT
        'gfx_hand_players'::TEXT,
        'player_id → gfx_players'::TEXT,
        COUNT(*)::BIGINT,
        CASE WHEN COUNT(*) = 0 THEN 'OK' ELSE 'ORPHAN_FOUND' END
    FROM gfx_hand_players hp
    WHERE hp.player_id IS NOT NULL
      AND NOT EXISTS (SELECT 1 FROM gfx_players p WHERE p.id = hp.player_id);

    -- gfx_events → gfx_hands
    RETURN QUERY
    SELECT
        'gfx_events'::TEXT,
        'hand_id → gfx_hands'::TEXT,
        COUNT(*)::BIGINT,
        CASE WHEN COUNT(*) = 0 THEN 'OK' ELSE 'ORPHAN_FOUND' END
    FROM gfx_events e
    WHERE NOT EXISTS (SELECT 1 FROM gfx_hands h WHERE h.id = e.hand_id);

    -- gfx_hand_results → gfx_hands
    RETURN QUERY
    SELECT
        'gfx_hand_results'::TEXT,
        'hand_id → gfx_hands'::TEXT,
        COUNT(*)::BIGINT,
        CASE WHEN COUNT(*) = 0 THEN 'OK' ELSE 'ORPHAN_FOUND' END
    FROM gfx_hand_results r
    WHERE NOT EXISTS (SELECT 1 FROM gfx_hands h WHERE h.id = r.hand_id);

    -- gfx_hand_cards → gfx_hands
    RETURN QUERY
    SELECT
        'gfx_hand_cards'::TEXT,
        'hand_id → gfx_hands'::TEXT,
        COUNT(*)::BIGINT,
        CASE WHEN COUNT(*) = 0 THEN 'OK' ELSE 'ORPHAN_FOUND' END
    FROM gfx_hand_cards c
    WHERE NOT EXISTS (SELECT 1 FROM gfx_hands h WHERE h.id = c.hand_id);

    -- hand_grades → gfx_hands
    RETURN QUERY
    SELECT
        'hand_grades'::TEXT,
        'hand_id → gfx_hands'::TEXT,
        COUNT(*)::BIGINT,
        CASE WHEN COUNT(*) = 0 THEN 'OK' ELSE 'ORPHAN_FOUND' END
    FROM hand_grades g
    WHERE NOT EXISTS (SELECT 1 FROM gfx_hands h WHERE h.id = g.hand_id);

    -- gfx_aep_field_mappings → gfx_aep_compositions
    RETURN QUERY
    SELECT
        'gfx_aep_field_mappings'::TEXT,
        'composition_name → gfx_aep_compositions'::TEXT,
        COUNT(*)::BIGINT,
        CASE WHEN COUNT(*) = 0 THEN 'OK' ELSE 'ORPHAN_FOUND' END
    FROM gfx_aep_field_mappings m
    WHERE NOT EXISTS (SELECT 1 FROM gfx_aep_compositions c WHERE c.name = m.composition_name);

    -- render_queue → job_queue
    RETURN QUERY
    SELECT
        'render_queue'::TEXT,
        'job_id → job_queue'::TEXT,
        COUNT(*)::BIGINT,
        CASE WHEN COUNT(*) = 0 THEN 'OK' ELSE 'ORPHAN_FOUND' END
    FROM render_queue r
    WHERE r.job_id IS NOT NULL
      AND NOT EXISTS (SELECT 1 FROM job_queue j WHERE j.id = r.job_id);

END;
$$;

COMMENT ON FUNCTION validate_fk_integrity() IS 'FK 참조 무결성 검증 - 고아 레코드 탐지';

-- ============================================================
-- 2. 데이터 일관성 검증 함수
-- ============================================================

CREATE OR REPLACE FUNCTION validate_data_consistency()
RETURNS TABLE (
    check_name TEXT,
    table_name TEXT,
    issue_count BIGINT,
    status TEXT,
    details TEXT
)
LANGUAGE plpgsql
AS $$
BEGIN
    -- 1. gfx_sessions: hand_count 일치 여부
    RETURN QUERY
    SELECT
        'hand_count_mismatch'::TEXT,
        'gfx_sessions'::TEXT,
        COUNT(*)::BIGINT,
        CASE WHEN COUNT(*) = 0 THEN 'OK' ELSE 'MISMATCH' END,
        ''::TEXT
    FROM gfx_sessions s
    WHERE s.hand_count != (SELECT COUNT(*) FROM gfx_hands h WHERE h.session_id = s.session_id);

    -- 2. gfx_hands: player_count 일치 여부
    RETURN QUERY
    SELECT
        'player_count_mismatch'::TEXT,
        'gfx_hands'::TEXT,
        COUNT(*)::BIGINT,
        CASE WHEN COUNT(*) = 0 THEN 'OK' ELSE 'MISMATCH' END,
        ''::TEXT
    FROM gfx_hands h
    WHERE h.player_count != (SELECT COUNT(*) FROM gfx_hand_players hp WHERE hp.hand_id = h.id);

    -- 3. gfx_hand_players: 동일 핸드 내 seat_num 중복
    RETURN QUERY
    SELECT
        'duplicate_seat_in_hand'::TEXT,
        'gfx_hand_players'::TEXT,
        COUNT(*)::BIGINT,
        CASE WHEN COUNT(*) = 0 THEN 'OK' ELSE 'DUPLICATE' END,
        ''::TEXT
    FROM (
        SELECT hand_id, seat_num, COUNT(*) as cnt
        FROM gfx_hand_players
        GROUP BY hand_id, seat_num
        HAVING COUNT(*) > 1
    ) dupes;

    -- 4. gfx_sessions: session_id 중복
    RETURN QUERY
    SELECT
        'duplicate_session_id'::TEXT,
        'gfx_sessions'::TEXT,
        COUNT(*)::BIGINT,
        CASE WHEN COUNT(*) = 0 THEN 'OK' ELSE 'DUPLICATE' END,
        ''::TEXT
    FROM (
        SELECT session_id, COUNT(*) as cnt
        FROM gfx_sessions
        GROUP BY session_id
        HAVING COUNT(*) > 1
    ) dupes;

    -- 5. gfx_aep_compositions: 활성 컴포지션 중 field_key 없음
    RETURN QUERY
    SELECT
        'missing_field_key'::TEXT,
        'gfx_aep_compositions'::TEXT,
        COUNT(*)::BIGINT,
        CASE WHEN COUNT(*) = 0 THEN 'OK' ELSE 'MISSING' END,
        ''::TEXT
    FROM gfx_aep_compositions c
    WHERE c.is_active = TRUE
      AND c.field_key IS NULL;

    -- 6. 음수 칩 금액 검증
    RETURN QUERY
    SELECT
        'negative_chip_amount'::TEXT,
        'gfx_hand_players'::TEXT,
        COUNT(*)::BIGINT,
        CASE WHEN COUNT(*) = 0 THEN 'OK' ELSE 'INVALID' END,
        ''::TEXT
    FROM gfx_hand_players
    WHERE start_stack_amt < 0 OR end_stack_amt < 0;

    -- 7. 음수 pot_size 검증
    RETURN QUERY
    SELECT
        'negative_pot_size'::TEXT,
        'gfx_hands'::TEXT,
        COUNT(*)::BIGINT,
        CASE WHEN COUNT(*) = 0 THEN 'OK' ELSE 'INVALID' END,
        ''::TEXT
    FROM gfx_hands
    WHERE pot_size < 0;

END;
$$;

COMMENT ON FUNCTION validate_data_consistency() IS '데이터 일관성 검증 - 카운트 불일치, 중복, 유효하지 않은 값 탐지';

-- ============================================================
-- 3. 스키마 간 참조 무결성 (json ↔ public)
-- ============================================================

CREATE OR REPLACE FUNCTION validate_cross_schema_integrity()
RETURNS TABLE (
    source_schema TEXT,
    target_schema TEXT,
    relationship TEXT,
    orphan_count BIGINT,
    status TEXT
)
LANGUAGE plpgsql
AS $$
BEGIN
    -- json.hands → json.gfx_sessions
    RETURN QUERY
    SELECT
        'json'::TEXT,
        'json'::TEXT,
        'hands.gfx_session_id → gfx_sessions.id'::TEXT,
        COUNT(*)::BIGINT,
        CASE WHEN COUNT(*) = 0 THEN 'OK' ELSE 'ORPHAN_FOUND' END
    FROM json.hands h
    WHERE NOT EXISTS (SELECT 1 FROM json.gfx_sessions s WHERE s.id = h.gfx_session_id);

    -- json.hand_players → json.hands
    RETURN QUERY
    SELECT
        'json'::TEXT,
        'json'::TEXT,
        'hand_players.hand_id → hands.id'::TEXT,
        COUNT(*)::BIGINT,
        CASE WHEN COUNT(*) = 0 THEN 'OK' ELSE 'ORPHAN_FOUND' END
    FROM json.hand_players hp
    WHERE NOT EXISTS (SELECT 1 FROM json.hands h WHERE h.id = hp.hand_id);

    -- json.hand_actions → json.hands
    RETURN QUERY
    SELECT
        'json'::TEXT,
        'json'::TEXT,
        'hand_actions.hand_id → hands.id'::TEXT,
        COUNT(*)::BIGINT,
        CASE WHEN COUNT(*) = 0 THEN 'OK' ELSE 'ORPHAN_FOUND' END
    FROM json.hand_actions a
    WHERE NOT EXISTS (SELECT 1 FROM json.hands h WHERE h.id = a.hand_id);

    -- json.hand_results → json.hands
    RETURN QUERY
    SELECT
        'json'::TEXT,
        'json'::TEXT,
        'hand_results.hand_id → hands.id'::TEXT,
        COUNT(*)::BIGINT,
        CASE WHEN COUNT(*) = 0 THEN 'OK' ELSE 'ORPHAN_FOUND' END
    FROM json.hand_results r
    WHERE NOT EXISTS (SELECT 1 FROM json.hands h WHERE h.id = r.hand_id);

    -- json.hand_cards → json.hands
    RETURN QUERY
    SELECT
        'json'::TEXT,
        'json'::TEXT,
        'hand_cards.hand_id → hands.id'::TEXT,
        COUNT(*)::BIGINT,
        CASE WHEN COUNT(*) = 0 THEN 'OK' ELSE 'ORPHAN_FOUND' END
    FROM json.hand_cards c
    WHERE NOT EXISTS (SELECT 1 FROM json.hands h WHERE h.id = c.hand_id);

    -- ae.composition_layers → ae.compositions
    RETURN QUERY
    SELECT
        'ae'::TEXT,
        'ae'::TEXT,
        'composition_layers.composition_id → compositions.id'::TEXT,
        COUNT(*)::BIGINT,
        CASE WHEN COUNT(*) = 0 THEN 'OK' ELSE 'ORPHAN_FOUND' END
    FROM ae.composition_layers l
    WHERE NOT EXISTS (SELECT 1 FROM ae.compositions c WHERE c.id = l.composition_id);

    -- ae.layer_data_mappings → ae.composition_layers
    RETURN QUERY
    SELECT
        'ae'::TEXT,
        'ae'::TEXT,
        'layer_data_mappings.layer_id → composition_layers.id'::TEXT,
        COUNT(*)::BIGINT,
        CASE WHEN COUNT(*) = 0 THEN 'OK' ELSE 'ORPHAN_FOUND' END
    FROM ae.layer_data_mappings m
    WHERE NOT EXISTS (SELECT 1 FROM ae.composition_layers l WHERE l.id = m.layer_id);

END;
$$;

COMMENT ON FUNCTION validate_cross_schema_integrity() IS '스키마 간 참조 무결성 검증';

-- ============================================================
-- 4. 전체 무결성 검증 실행 함수
-- ============================================================

CREATE OR REPLACE FUNCTION run_full_integrity_check()
RETURNS TABLE (
    category TEXT,
    check_name TEXT,
    issue_count BIGINT,
    status TEXT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_total_issues BIGINT := 0;
    v_fk_issues BIGINT := 0;
    v_data_issues BIGINT := 0;
    v_cross_issues BIGINT := 0;
BEGIN
    RAISE NOTICE '========================================';
    RAISE NOTICE 'GFX-Supabase DB 무결성 검증 시작';
    RAISE NOTICE '========================================';

    -- FK 무결성 검증
    RAISE NOTICE '';
    RAISE NOTICE '[1/3] FK 참조 무결성 검증...';

    FOR category, check_name, issue_count, status IN
        SELECT 'FK_INTEGRITY', v.table_name || '.' || v.fk_name, v.orphan_count, v.status
        FROM validate_fk_integrity() v
    LOOP
        IF issue_count > 0 THEN
            v_fk_issues := v_fk_issues + issue_count;
        END IF;
        RETURN NEXT;
    END LOOP;

    -- 데이터 일관성 검증
    RAISE NOTICE '';
    RAISE NOTICE '[2/3] 데이터 일관성 검증...';

    FOR category, check_name, issue_count, status IN
        SELECT 'DATA_CONSISTENCY', v.check_name || ' (' || v.table_name || ')', v.issue_count, v.status
        FROM validate_data_consistency() v
    LOOP
        IF issue_count > 0 THEN
            v_data_issues := v_data_issues + issue_count;
        END IF;
        RETURN NEXT;
    END LOOP;

    -- 스키마 간 무결성 검증
    RAISE NOTICE '';
    RAISE NOTICE '[3/3] 스키마 간 참조 무결성 검증...';

    FOR category, check_name, issue_count, status IN
        SELECT 'CROSS_SCHEMA', v.source_schema || ' → ' || v.target_schema || ': ' || v.relationship, v.orphan_count, v.status
        FROM validate_cross_schema_integrity() v
    LOOP
        IF issue_count > 0 THEN
            v_cross_issues := v_cross_issues + issue_count;
        END IF;
        RETURN NEXT;
    END LOOP;

    -- 요약
    v_total_issues := v_fk_issues + v_data_issues + v_cross_issues;

    RAISE NOTICE '';
    RAISE NOTICE '========================================';
    RAISE NOTICE '무결성 검증 완료';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'FK 이슈: %', v_fk_issues;
    RAISE NOTICE '데이터 일관성 이슈: %', v_data_issues;
    RAISE NOTICE '스키마 간 이슈: %', v_cross_issues;
    RAISE NOTICE '----------------------------------------';
    RAISE NOTICE '총 이슈: %', v_total_issues;

    IF v_total_issues = 0 THEN
        RAISE NOTICE '상태: ✅ 모든 검증 통과';
    ELSE
        RAISE NOTICE '상태: ⚠️ 이슈 발견됨';
    END IF;

END;
$$;

COMMENT ON FUNCTION run_full_integrity_check() IS 'GFX-Supabase DB 전체 무결성 검증 실행';

-- ============================================================
-- 5. 완료 메시지
-- ============================================================

DO $$
BEGIN
    RAISE NOTICE '무결성 검증 함수 생성 완료!';
    RAISE NOTICE '';
    RAISE NOTICE '사용법:';
    RAISE NOTICE '  전체 검증: SELECT * FROM run_full_integrity_check();';
    RAISE NOTICE '  FK 검증: SELECT * FROM validate_fk_integrity();';
    RAISE NOTICE '  데이터 일관성: SELECT * FROM validate_data_consistency();';
    RAISE NOTICE '  스키마 간 검증: SELECT * FROM validate_cross_schema_integrity();';
END $$;
