-- ============================================================================
-- Migration: validation_tests
-- Description: 마이그레이션 적용 후 검증 테스트 (DO NOT APPLY IN PRODUCTION)
-- Version: 1.0.0
-- Date: 2026-01-17
-- Purpose: 뷰/함수 실행 테스트 및 스키마 검증
-- ============================================================================

-- ============================================================================
-- Phase 1: player_overrides 스키마 검증
-- ============================================================================

DO $$
DECLARE
    v_col_count INTEGER;
    v_has_field_name BOOLEAN;
    v_has_override_value BOOLEAN;
    v_has_gfx_player_id BOOLEAN;
    v_has_active BOOLEAN;
BEGIN
    -- player_overrides 컬럼 확인
    SELECT
        COUNT(*),
        BOOL_OR(column_name = 'field_name'),
        BOOL_OR(column_name = 'override_value'),
        BOOL_OR(column_name = 'gfx_player_id'),
        BOOL_OR(column_name = 'active')
    INTO v_col_count, v_has_field_name, v_has_override_value, v_has_gfx_player_id, v_has_active
    FROM information_schema.columns
    WHERE table_name = 'player_overrides'
      AND table_schema = 'public';

    -- 검증 결과 출력
    RAISE NOTICE '========================================';
    RAISE NOTICE 'player_overrides 스키마 검증';
    RAISE NOTICE '========================================';
    RAISE NOTICE '총 컬럼 수: %', v_col_count;
    RAISE NOTICE 'field_name 컬럼: %', CASE WHEN v_has_field_name THEN 'EXISTS' ELSE 'MISSING' END;
    RAISE NOTICE 'override_value 컬럼: %', CASE WHEN v_has_override_value THEN 'EXISTS' ELSE 'MISSING' END;
    RAISE NOTICE 'gfx_player_id 컬럼: %', CASE WHEN v_has_gfx_player_id THEN 'EXISTS' ELSE 'MISSING' END;
    RAISE NOTICE 'active 컬럼: %', CASE WHEN v_has_active THEN 'EXISTS' ELSE 'MISSING' END;

    -- 필수 컬럼 누락 시 경고
    IF NOT v_has_field_name OR NOT v_has_override_value THEN
        RAISE WARNING 'CRITICAL: player_overrides 테이블에 field_name/override_value 컬럼 누락!';
    END IF;

    IF NOT v_has_gfx_player_id THEN
        RAISE WARNING 'CRITICAL: player_overrides 테이블에 gfx_player_id 컬럼 누락!';
    END IF;

    IF NOT v_has_active THEN
        RAISE WARNING 'WARNING: active 컬럼 대신 is_active 사용 중일 수 있음';
    END IF;
END $$;

-- ============================================================================
-- Phase 2: 뷰 실행 테스트
-- ============================================================================

DO $$
DECLARE
    v_test_result RECORD;
    v_view_count INTEGER;
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '========================================';
    RAISE NOTICE '뷰 실행 테스트';
    RAISE NOTICE '========================================';

    -- v_render_chip_display 테스트
    BEGIN
        SELECT COUNT(*) INTO v_view_count FROM v_render_chip_display LIMIT 1;
        RAISE NOTICE 'v_render_chip_display: OK (rows: %)', v_view_count;
    EXCEPTION WHEN OTHERS THEN
        RAISE WARNING 'v_render_chip_display: FAILED - %', SQLERRM;
    END;

    -- v_render_elimination 테스트
    BEGIN
        SELECT COUNT(*) INTO v_view_count FROM v_render_elimination LIMIT 1;
        RAISE NOTICE 'v_render_elimination: OK (rows: %)', v_view_count;
    EXCEPTION WHEN OTHERS THEN
        RAISE WARNING 'v_render_elimination: FAILED - %', SQLERRM;
    END;

    -- v_render_at_risk 테스트
    BEGIN
        SELECT COUNT(*) INTO v_view_count FROM v_render_at_risk LIMIT 1;
        RAISE NOTICE 'v_render_at_risk: OK (rows: %)', v_view_count;
    EXCEPTION WHEN OTHERS THEN
        RAISE WARNING 'v_render_at_risk: FAILED - %', SQLERRM;
    END;
END $$;

-- ============================================================================
-- Phase 3: 함수 실행 테스트
-- ============================================================================

DO $$
DECLARE
    v_result JSONB;
    v_session_id BIGINT;
    v_hand_num INTEGER;
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '========================================';
    RAISE NOTICE '함수 실행 테스트';
    RAISE NOTICE '========================================';

    -- 테스트용 세션/핸드 조회
    SELECT session_id, hand_num
    INTO v_session_id, v_hand_num
    FROM gfx_hands
    LIMIT 1;

    IF v_session_id IS NULL THEN
        RAISE NOTICE 'SKIP: gfx_hands 테이블에 데이터 없음';
        RETURN;
    END IF;

    RAISE NOTICE '테스트 세션: %, 핸드: %', v_session_id, v_hand_num;

    -- get_chip_display_data 테스트
    BEGIN
        v_result := get_chip_display_data(v_session_id, v_hand_num, 9);
        RAISE NOTICE 'get_chip_display_data(): OK - schema: %', v_result->>'$schema';
    EXCEPTION WHEN OTHERS THEN
        RAISE WARNING 'get_chip_display_data(): FAILED - %', SQLERRM;
    END;

    -- get_at_risk_data 테스트
    BEGIN
        v_result := get_at_risk_data(v_session_id, v_hand_num);
        RAISE NOTICE 'get_at_risk_data(): OK - schema: %', v_result->>'$schema';
    EXCEPTION WHEN OTHERS THEN
        RAISE WARNING 'get_at_risk_data(): FAILED - %', SQLERRM;
    END;

    -- get_chip_comparison_data 테스트
    BEGIN
        v_result := get_chip_comparison_data(v_session_id, v_hand_num, 'TEST_PLAYER');
        RAISE NOTICE 'get_chip_comparison_data(): OK - schema: %', COALESCE(v_result->>'$schema', 'empty result');
    EXCEPTION WHEN OTHERS THEN
        RAISE WARNING 'get_chip_comparison_data(): FAILED - %', SQLERRM;
    END;

    -- get_chip_flow_data 테스트
    BEGIN
        v_result := get_chip_flow_data(v_session_id, v_hand_num, 'TEST_PLAYER');
        RAISE NOTICE 'get_chip_flow_data(): OK - schema: %', COALESCE(v_result->>'$schema', 'empty result');
    EXCEPTION WHEN OTHERS THEN
        RAISE WARNING 'get_chip_flow_data(): FAILED - %', SQLERRM;
    END;

    -- get_player_history_data 테스트
    BEGIN
        v_result := get_player_history_data(v_session_id, v_hand_num, 'TEST_PLAYER');
        RAISE NOTICE 'get_player_history_data(): OK - schema: %', COALESCE(v_result->>'$schema', 'empty result');
    EXCEPTION WHEN OTHERS THEN
        RAISE WARNING 'get_player_history_data(): FAILED - %', SQLERRM;
    END;

    -- get_player_name_data 테스트
    BEGIN
        v_result := get_player_name_data(v_session_id, v_hand_num, 1, 'NAME');
        RAISE NOTICE 'get_player_name_data(): OK - schema: %', COALESCE(v_result->>'$schema', 'empty result');
    EXCEPTION WHEN OTHERS THEN
        RAISE WARNING 'get_player_name_data(): FAILED - %', SQLERRM;
    END;

    -- get_elimination_data 테스트
    BEGIN
        v_result := get_elimination_data(v_session_id, v_hand_num);
        RAISE NOTICE 'get_elimination_data(): OK - schema: %', COALESCE(v_result->>'$schema', 'empty result');
    EXCEPTION WHEN OTHERS THEN
        RAISE WARNING 'get_elimination_data(): FAILED - %', SQLERRM;
    END;
END $$;

-- ============================================================================
-- Phase 4: 인덱스 권장 사항 확인
-- ============================================================================

DO $$
DECLARE
    v_idx_exists BOOLEAN;
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '========================================';
    RAISE NOTICE '인덱스 권장 사항';
    RAISE NOTICE '========================================';

    -- player_overrides 인덱스 확인
    SELECT EXISTS(
        SELECT 1 FROM pg_indexes
        WHERE tablename = 'player_overrides'
          AND indexdef LIKE '%gfx_player_id%'
    ) INTO v_idx_exists;

    IF v_idx_exists THEN
        RAISE NOTICE 'gfx_player_id 인덱스: EXISTS';
    ELSE
        RAISE WARNING 'RECOMMEND: player_overrides(gfx_player_id) 인덱스 추가 권장';
        RAISE NOTICE '  CREATE INDEX idx_player_overrides_gfx_player_id ON player_overrides(gfx_player_id);';
    END IF;

    -- field_name + active 복합 인덱스 확인
    SELECT EXISTS(
        SELECT 1 FROM pg_indexes
        WHERE tablename = 'player_overrides'
          AND indexdef LIKE '%field_name%'
          AND indexdef LIKE '%active%'
    ) INTO v_idx_exists;

    IF v_idx_exists THEN
        RAISE NOTICE 'field_name + active 복합 인덱스: EXISTS';
    ELSE
        RAISE WARNING 'RECOMMEND: player_overrides(gfx_player_id, field_name, active) 복합 인덱스 추가 권장';
        RAISE NOTICE '  CREATE INDEX idx_player_overrides_lookup ON player_overrides(gfx_player_id, field_name) WHERE active = TRUE;';
    END IF;
END $$;

-- ============================================================================
-- Phase 5: 마이그레이션 의존성 그래프 출력
-- ============================================================================

DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '========================================';
    RAISE NOTICE '마이그레이션 의존성 그래프';
    RAISE NOTICE '========================================';
    RAISE NOTICE '';
    RAISE NOTICE '20260113082705 (03_manual_schema)';
    RAISE NOTICE '  → player_overrides 정의 (field_name + override_value 구조)';
    RAISE NOTICE '';
    RAISE NOTICE '20260116000000 (schema_simplification)';
    RAISE NOTICE '  → manual_players 삭제';
    RAISE NOTICE '  → player_overrides.gfx_player_id 추가';
    RAISE NOTICE '';
    RAISE NOTICE '20260117000000 (fix_render_views) ✓ 수정됨';
    RAISE NOTICE '  → v_render_chip_display: field_name + override_value 패턴 적용';
    RAISE NOTICE '  → v_render_elimination: field_name + override_value 패턴 적용';
    RAISE NOTICE '  → v_render_at_risk: field_name + override_value 패턴 적용';
    RAISE NOTICE '';
    RAISE NOTICE '20260117100000 (update_compositions_v2)';
    RAISE NOTICE '  → 컴포지션 메타데이터 업데이트';
    RAISE NOTICE '';
    RAISE NOTICE '20260117200000 (upgrade_render_functions_v3) ✓ 수정됨';
    RAISE NOTICE '  → get_player_history_data(): field_name + override_value 패턴 적용';
    RAISE NOTICE '  → get_player_name_data(): field_name + override_value 패턴 적용';
    RAISE NOTICE '';
    RAISE NOTICE '========================================';
    RAISE NOTICE '검증 완료';
    RAISE NOTICE '========================================';
END $$;
