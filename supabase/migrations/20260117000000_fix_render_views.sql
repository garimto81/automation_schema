-- ============================================================================
-- Migration: fix_render_views
-- Description: 렌더링 뷰 수정 - manual_players 참조를 player_overrides로 변경
-- Version: 1.0.0
-- Date: 2026-01-17
-- Issue: manual_players 테이블 삭제(20260116) 후 뷰 참조 오류 수정
-- ============================================================================

-- ============================================================================
-- Phase 1: v_render_chip_display 뷰 재정의
-- manual_players → player_overrides (field_name 기반) 조인 변경
-- player_overrides 스키마: field_name + override_value 구조
-- ============================================================================

DROP VIEW IF EXISTS v_render_chip_display CASCADE;

CREATE OR REPLACE VIEW v_render_chip_display AS
SELECT
    gs.session_id,
    gh.hand_num,
    ROW_NUMBER() OVER (
        PARTITION BY gs.session_id, gh.hand_num
        ORDER BY ghp.end_stack_amt DESC
    ) AS slot_index,
    -- 이름: player_overrides(field_name='name') 우선, 없으면 gfx 원본
    UPPER(COALESCE(
        po_name.override_value,
        ghp.player_name
    )) AS name,
    format_chips(ghp.end_stack_amt) AS chips,
    format_bbs(ghp.end_stack_amt, COALESCE((gh.blinds->>'big_blind_amt')::BIGINT, 0)) AS bbs,
    (ROW_NUMBER() OVER (
        PARTITION BY gs.session_id, gh.hand_num
        ORDER BY ghp.end_stack_amt DESC
    ))::TEXT AS rank,
    -- 국기: player_overrides(field_name='country_code')에서 조회
    get_flag_path(COALESCE(po_country.override_value, 'XX')) AS flag,
    ghp.vpip_percent,
    ghp.end_stack_amt AS raw_chips,
    COALESCE((gh.blinds->>'big_blind_amt')::BIGINT, 0) AS big_blind,
    -- 추가 메타데이터
    ghp.player_id,
    gp.player_hash
FROM gfx_hand_players ghp
JOIN gfx_hands gh ON ghp.hand_id = gh.id
JOIN gfx_sessions gs ON gh.session_id = gs.session_id
-- GFX 플레이어 조인
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
WHERE ghp.sitting_out = FALSE
ORDER BY gs.session_id, gh.hand_num, ghp.end_stack_amt DESC;

COMMENT ON VIEW v_render_chip_display IS
'_MAIN/_SUB Mini Chip Count 컴포지션용 렌더링 데이터. player_overrides 테이블을 통해 이름/국적 오버라이드 적용.';

-- ============================================================================
-- Phase 2: v_render_elimination 뷰 재정의
-- player_overrides 스키마: field_name + override_value 구조
-- ============================================================================

DROP VIEW IF EXISTS v_render_elimination CASCADE;

CREATE OR REPLACE VIEW v_render_elimination AS
SELECT
    gs.session_id,
    gh.hand_num,
    -- 이름: player_overrides(field_name='name') 우선
    UPPER(COALESCE(po_name.override_value, ghp.player_name)) AS name,
    ghp.elimination_rank AS rank,
    -- 상금: gfx_sessions.payouts 배열에서 조회
    COALESCE(
        format_currency_from_int(gs.payouts[ghp.elimination_rank]),
        '$0'
    ) AS prize,
    -- 국기: player_overrides(field_name='country_code')에서 조회
    get_flag_path(COALESCE(po_country.override_value, 'XX')) AS flag,
    -- 추가 메타데이터
    ghp.player_id,
    gp.player_hash
FROM gfx_hand_players ghp
JOIN gfx_hands gh ON ghp.hand_id = gh.id
JOIN gfx_sessions gs ON gh.session_id = gs.session_id
-- GFX 플레이어 조인
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
WHERE ghp.elimination_rank > 0
ORDER BY gs.session_id, gh.hand_num, ghp.elimination_rank DESC;

COMMENT ON VIEW v_render_elimination IS
'Elimination 컴포지션용 렌더링 데이터. 탈락한 플레이어 정보 및 상금 표시.';

-- ============================================================================
-- Phase 3: v_render_at_risk 뷰 추가 (v2.0.0 신규)
-- At Risk of Elimination 컴포지션용 - 필드 분리
-- player_overrides 스키마: field_name + override_value 구조
-- ============================================================================

CREATE OR REPLACE VIEW v_render_at_risk AS
WITH ranked_players AS (
    SELECT
        gs.session_id,
        gh.hand_num,
        ghp.player_name,
        ghp.end_stack_amt,
        ghp.player_id,
        ROW_NUMBER() OVER (
            PARTITION BY gs.session_id, gh.hand_num
            ORDER BY ghp.end_stack_amt ASC
        ) AS risk_rank,
        COUNT(*) OVER (
            PARTITION BY gs.session_id, gh.hand_num
        ) AS remaining_players
    FROM gfx_hand_players ghp
    JOIN gfx_hands gh ON ghp.hand_id = gh.id
    JOIN gfx_sessions gs ON gh.session_id = gs.session_id
    WHERE ghp.sitting_out = FALSE
)
SELECT
    rp.session_id,
    rp.hand_num,
    -- v2.0.0 필드 분리: player_name, rank, prize, flag
    UPPER(COALESCE(po_name.override_value, rp.player_name)) AS player_name,
    rp.remaining_players AS rank,  -- 현재 남은 인원 = 탈락 시 순위
    COALESCE(
        format_currency_from_int(gs.payouts[rp.remaining_players]),
        '$0'
    ) AS prize,
    get_flag_path(COALESCE(po_country.override_value, 'XX')) AS flag,
    -- 추가 정보
    format_chips(rp.end_stack_amt) AS chips,
    rp.player_id
FROM ranked_players rp
JOIN gfx_sessions gs ON rp.session_id = gs.session_id
LEFT JOIN gfx_players gp ON rp.player_id = gp.id
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
WHERE rp.risk_rank = 1;  -- 최소 스택 = 탈락 위기

COMMENT ON VIEW v_render_at_risk IS
'At Risk of Elimination 컴포지션용 렌더링 데이터. v2.0.0에서 필드 분리 (player_name, rank, prize, flag).';

-- ============================================================================
-- Phase 4: get_chip_display_data 함수 업데이트
-- v2 → v3 스키마 반환, player_overrides 참조
-- ============================================================================

CREATE OR REPLACE FUNCTION get_chip_display_data(
    p_session_id BIGINT,
    p_hand_num INTEGER,
    p_slot_count INTEGER DEFAULT 9
)
RETURNS JSONB AS $$
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
$$ LANGUAGE plpgsql STABLE;

-- ============================================================================
-- Phase 5: get_at_risk_data 함수 추가 (v2.0.0 신규)
-- ============================================================================

CREATE OR REPLACE FUNCTION get_at_risk_data(
    p_session_id BIGINT,
    p_hand_num INTEGER
)
RETURNS JSONB AS $$
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
$$ LANGUAGE plpgsql STABLE;

COMMENT ON FUNCTION get_at_risk_data IS
'At Risk of Elimination 컴포지션용 gfx_data JSON 생성 (v3 스키마, 필드 분리)';

-- ============================================================================
-- 완료 메시지
-- ============================================================================

DO $$
BEGIN
    RAISE NOTICE '렌더링 뷰 수정 마이그레이션 완료:';
    RAISE NOTICE '  - v_render_chip_display: manual_players → player_overrides 변경';
    RAISE NOTICE '  - v_render_elimination: manual_players → player_overrides 변경';
    RAISE NOTICE '  - v_render_at_risk: 신규 추가 (v2.0.0 필드 분리)';
    RAISE NOTICE '  - get_chip_display_data(): v3 스키마 반환';
    RAISE NOTICE '  - get_at_risk_data(): 신규 추가';
END $$;
