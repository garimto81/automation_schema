-- ============================================================================
-- Migration: upgrade_render_functions_v3
-- Description: 렌더링 함수 v3 업그레이드 및 신규 함수 추가
-- Version: 1.0.0
-- Date: 2026-01-17
-- Reference: docs/08-GFX-AEP-Mapping.md v2.0.0 (render_gfx_data_v3)
-- ============================================================================

-- ============================================================================
-- Phase 1: get_chips_n_hands_ago() 함수 구현 (v2.0.0 신규)
-- 히스토리 칩 조회 함수
-- ============================================================================

CREATE OR REPLACE FUNCTION get_chips_n_hands_ago(
    p_session_id BIGINT,
    p_current_hand_num INTEGER,
    p_player_name TEXT,
    p_n_hands INTEGER
)
RETURNS BIGINT AS $$
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
$$ LANGUAGE plpgsql STABLE;

COMMENT ON FUNCTION get_chips_n_hands_ago IS
'특정 플레이어의 N핸드 전 칩 스택 조회. NAME 3줄+ 컴포지션용.';

-- ============================================================================
-- Phase 2: get_chip_comparison_data() 함수 구현 (v2.0.0 신규)
-- Chip Comparison 컴포지션용
-- ============================================================================

CREATE OR REPLACE FUNCTION get_chip_comparison_data(
    p_session_id BIGINT,
    p_hand_num INTEGER,
    p_selected_player_name TEXT
)
RETURNS JSONB AS $$
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
$$ LANGUAGE plpgsql STABLE;

COMMENT ON FUNCTION get_chip_comparison_data IS
'Chip Comparison 컴포지션용 gfx_data JSON 생성. 선택 플레이어 vs 나머지 백분율.';

-- ============================================================================
-- Phase 3: get_chip_flow_data() 함수 구현 (v2.0.0 신규)
-- Chip Flow 컴포지션용 (10/20/30 핸드 히스토리 배열)
-- ============================================================================

CREATE OR REPLACE FUNCTION get_chip_flow_data(
    p_session_id BIGINT,
    p_current_hand_num INTEGER,
    p_player_name TEXT
)
RETURNS JSONB AS $$
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
$$ LANGUAGE plpgsql STABLE;

COMMENT ON FUNCTION get_chip_flow_data IS
'Chip Flow 컴포지션용 gfx_data JSON 생성. 10/20/30 핸드 칩 히스토리 배열.';

-- ============================================================================
-- Phase 4: get_player_history_data() 함수 구현 (v2.0.0 신규)
-- NAME 3줄+ 컴포지션용 (히스토리 칩 + VPIP)
-- ============================================================================

CREATE OR REPLACE FUNCTION get_player_history_data(
    p_session_id BIGINT,
    p_hand_num INTEGER,
    p_player_name TEXT
)
RETURNS JSONB AS $$
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
$$ LANGUAGE plpgsql STABLE;

COMMENT ON FUNCTION get_player_history_data IS
'NAME 3줄+ 컴포지션용 gfx_data JSON 생성. 히스토리 칩 및 VPIP 통합.';

-- ============================================================================
-- Phase 5: get_payout_data() 함수 v3 업그레이드
-- ============================================================================

CREATE OR REPLACE FUNCTION get_payout_data(
    p_event_id UUID,
    p_slot_count INTEGER DEFAULT 9,
    p_start_rank INTEGER DEFAULT 1
)
RETURNS JSONB AS $$
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
$$ LANGUAGE plpgsql STABLE;

-- ============================================================================
-- Phase 6: get_elimination_data() 함수 추가
-- ============================================================================

CREATE OR REPLACE FUNCTION get_elimination_data(
    p_session_id BIGINT,
    p_hand_num INTEGER
)
RETURNS JSONB AS $$
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
$$ LANGUAGE plpgsql STABLE;

COMMENT ON FUNCTION get_elimination_data IS
'Elimination 컴포지션용 gfx_data JSON 생성.';

-- ============================================================================
-- Phase 7: get_player_name_data() 함수 추가 (NAME 컴포지션용)
-- ============================================================================

CREATE OR REPLACE FUNCTION get_player_name_data(
    p_session_id BIGINT,
    p_hand_num INTEGER,
    p_seat_num INTEGER,
    p_variant TEXT DEFAULT 'NAME'  -- 'NAME', 'NAME 1줄', 'NAME 2줄 (국기 빼고)'
)
RETURNS JSONB AS $$
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
$$ LANGUAGE plpgsql STABLE;

COMMENT ON FUNCTION get_player_name_data IS
'NAME/NAME 1줄/NAME 2줄 컴포지션용 gfx_data JSON 생성. v2.0.0 필드 확장.';

-- ============================================================================
-- 완료 메시지
-- ============================================================================

DO $$
BEGIN
    RAISE NOTICE '렌더링 함수 v3 업그레이드 완료:';
    RAISE NOTICE '  - get_chips_n_hands_ago(): 신규 추가 (히스토리 칩 조회)';
    RAISE NOTICE '  - get_chip_comparison_data(): 신규 추가 (칩 비율 비교)';
    RAISE NOTICE '  - get_chip_flow_data(): 신규 추가 (10/20/30 핸드 배열)';
    RAISE NOTICE '  - get_player_history_data(): 신규 추가 (NAME 3줄+ 통합)';
    RAISE NOTICE '  - get_payout_data(): v3 업그레이드 (event_name, start_rank)';
    RAISE NOTICE '  - get_elimination_data(): 신규 추가';
    RAISE NOTICE '  - get_player_name_data(): 신규 추가 (NAME 변형 통합)';
    RAISE NOTICE '  - 모든 함수 반환값: render_gfx_data_v3 스키마';
END $$;
