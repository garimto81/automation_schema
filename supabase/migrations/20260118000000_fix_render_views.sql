-- ============================================================================
-- Migration: fix_render_views
-- Description: manual_players → player_overrides 구조 변경에 따른 뷰 수정
-- Version: 1.0.0
-- Date: 2026-01-18
-- ============================================================================

-- ============================================================================
-- v_render_chip_display: 칩 디스플레이 뷰 수정
-- 변경 사항:
-- - player_link_mapping 조인 제거
-- - manual_players 조인 제거
-- - player_overrides (name, country_code) 조인 추가
-- ============================================================================

CREATE OR REPLACE VIEW v_render_chip_display AS
SELECT
    gs.session_id,
    gh.hand_num,
    ROW_NUMBER() OVER (
        PARTITION BY gs.session_id, gh.hand_num
        ORDER BY ghp.end_stack_amt DESC
    ) AS slot_index,
    -- 이름: player_overrides.name 우선, 없으면 gfx_hand_players.player_name
    UPPER(COALESCE(
        po_name.override_value,
        ghp.player_name
    )) AS name,
    format_chips(ghp.end_stack_amt) AS chips,
    format_bbs(ghp.end_stack_amt, (gh.blinds->>'big_blind_amt')::BIGINT) AS bbs,
    (ROW_NUMBER() OVER (
        PARTITION BY gs.session_id, gh.hand_num
        ORDER BY ghp.end_stack_amt DESC
    ))::TEXT AS rank,
    -- 국기: player_overrides.country_code 우선, 없으면 Unknown
    get_flag_path(COALESCE(po_country.override_value, 'XX')) AS flag,
    ghp.vpip_percent,
    ghp.end_stack_amt AS raw_chips,
    (gh.blinds->>'big_blind_amt')::BIGINT AS big_blind
FROM gfx_hand_players ghp
JOIN gfx_hands gh ON ghp.hand_id = gh.id
JOIN gfx_sessions gs ON gh.session_id = gs.session_id
-- GFX 플레이어 → player_overrides (name, country_code) 조인
LEFT JOIN gfx_players gp ON ghp.player_id = gp.id
LEFT JOIN player_overrides po_name
    ON po_name.gfx_player_id = gp.id
    AND po_name.field_name = 'name'
    AND po_name.active = TRUE
LEFT JOIN player_overrides po_country
    ON po_country.gfx_player_id = gp.id
    AND po_country.field_name = 'country_code'
    AND po_country.active = TRUE
WHERE ghp.sitting_out = FALSE
ORDER BY gs.session_id, gh.hand_num, ghp.end_stack_amt DESC;

-- ============================================================================
-- v_render_elimination: 탈락 뷰 수정
-- 변경 사항:
-- - player_link_mapping 조인 제거
-- - manual_players 조인 제거
-- - player_overrides (name, country_code) 조인 추가
-- ============================================================================

CREATE OR REPLACE VIEW v_render_elimination AS
SELECT
    gs.session_id,
    gh.hand_num,
    -- 이름: player_overrides.name 우선
    UPPER(COALESCE(po_name.override_value, ghp.player_name)) AS name,
    ghp.elimination_rank AS rank,
    COALESCE(
        format_currency_from_int(gs.payouts[ghp.elimination_rank]),
        '$0'
    ) AS prize,
    -- 국기: player_overrides.country_code 우선
    get_flag_path(COALESCE(po_country.override_value, 'XX')) AS flag
FROM gfx_hand_players ghp
JOIN gfx_hands gh ON ghp.hand_id = gh.id
JOIN gfx_sessions gs ON gh.session_id = gs.session_id
-- GFX 플레이어 → player_overrides (name, country_code) 조인
LEFT JOIN gfx_players gp ON ghp.player_id = gp.id
LEFT JOIN player_overrides po_name
    ON po_name.gfx_player_id = gp.id
    AND po_name.field_name = 'name'
    AND po_name.active = TRUE
LEFT JOIN player_overrides po_country
    ON po_country.gfx_player_id = gp.id
    AND po_country.field_name = 'country_code'
    AND po_country.active = TRUE
WHERE ghp.elimination_rank > 0
ORDER BY gs.session_id, gh.hand_num, ghp.elimination_rank DESC;

-- ============================================================================
-- Comments
-- ============================================================================

COMMENT ON VIEW v_render_chip_display IS 'Chip Display 렌더링 뷰. player_overrides 기반으로 플레이어 정보 오버라이드 적용.';
COMMENT ON VIEW v_render_elimination IS 'Elimination 렌더링 뷰. player_overrides 기반으로 플레이어 정보 오버라이드 적용.';
