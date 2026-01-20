-- Migration: INTEGER → BIGINT 타입 변경
-- Date: 2026-01-25
-- Purpose: gfx_hand_players 칩 관련 컬럼을 BIGINT로 변경 (21억 초과 데이터 손실 방지)
--
-- 영향받는 컬럼:
--   - gfx_hand_players.start_stack_amt
--   - gfx_hand_players.end_stack_amt
--   - gfx_hand_players.cumulative_winnings_amt
--   - gfx_hand_players.blind_bet_straddle_amt
--
-- 의존 뷰:
--   - unified_chip_data (end_stack_amt 참조)

-- ============================================================
-- 1. 의존 뷰 임시 삭제 (CASCADE로 모든 의존 뷰 제거)
-- ============================================================

-- gfx_hand_players.start_stack_amt, end_stack_amt 참조 뷰
DROP VIEW IF EXISTS v_showdown_players CASCADE;
DROP VIEW IF EXISTS v_recent_hands CASCADE;
DROP VIEW IF EXISTS v_render_chip_display CASCADE;
DROP VIEW IF EXISTS v_render_at_risk CASCADE;
DROP VIEW IF EXISTS v_render_elimination CASCADE;
DROP VIEW IF EXISTS v_chip_count_latest CASCADE;
DROP VIEW IF EXISTS unified_chip_data CASCADE;

-- gfx_hands.pot_size 참조 뷰
DROP VIEW IF EXISTS v_player_stats CASCADE;
DROP VIEW IF EXISTS v_leaderboard CASCADE;

-- ============================================================
-- 2. gfx_hand_players 컬럼 타입 변경
-- ============================================================

ALTER TABLE gfx_hand_players
    ALTER COLUMN start_stack_amt TYPE BIGINT,
    ALTER COLUMN end_stack_amt TYPE BIGINT,
    ALTER COLUMN cumulative_winnings_amt TYPE BIGINT,
    ALTER COLUMN blind_bet_straddle_amt TYPE BIGINT;

-- ============================================================
-- 3. gfx_events 관련 컬럼도 BIGINT로 변경 (일관성)
-- ============================================================

ALTER TABLE gfx_events
    ALTER COLUMN bet_amt TYPE BIGINT USING bet_amt::BIGINT,
    ALTER COLUMN pot TYPE BIGINT USING pot::BIGINT;

-- ============================================================
-- 4. gfx_hands pot_size도 BIGINT로 변경
-- ============================================================

ALTER TABLE gfx_hands
    ALTER COLUMN pot_size TYPE BIGINT USING pot_size::BIGINT;

-- ============================================================
-- 5. unified_chip_data 뷰 재생성 (캐스팅 불필요해짐)
-- ============================================================

CREATE OR REPLACE VIEW unified_chip_data AS
-- WSOP Chip Counts
SELECT
    'wsop'::text AS source,
    wcc.id,
    wcc.event_id,
    wcc.player_id,
    wp.name AS player_name,
    wp.country_code,
    wcc.chip_count,
    wcc.rank,
    wcc.table_num,
    wcc.seat_num,
    wcc.recorded_at,
    (wcc.source)::text AS data_source
FROM wsop_chip_counts wcc
LEFT JOIN wsop_players wp ON wcc.player_id = wp.id
UNION ALL
-- GFX Hand Players (핸드 종료 시점 스택)
SELECT
    'gfx'::text AS source,
    ghp.id,
    NULL::UUID AS event_id,
    ghp.player_id,
    ghp.player_name,
    NULL::varchar AS country_code,
    ghp.end_stack_amt AS chip_count,  -- 이제 BIGINT, 캐스팅 불필요
    NULL::INTEGER AS rank,
    NULL::INTEGER AS table_num,
    ghp.seat_num,
    gh.start_time AS recorded_at,
    'gfx_hand'::text AS data_source
FROM gfx_hand_players ghp
JOIN gfx_hands gh ON ghp.hand_id = gh.id;

COMMENT ON VIEW unified_chip_data IS 'WSOP + GFX 통합 칩 데이터 (chip_snapshots 대체)';

-- ============================================================
-- 6. 삭제된 다른 뷰들 재생성
-- ============================================================

-- v_recent_hands
CREATE OR REPLACE VIEW v_recent_hands AS
SELECT
    h.id,
    h.session_id,
    h.hand_num,
    h.game_variant,
    h.bet_structure,
    h.duration_seconds,
    h.start_time,
    h.pot_size,
    h.board_cards,
    h.winner_name,
    h.player_count,
    h.showdown_count,
    s.table_type,
    s.event_title,
    g.grade,
    g.broadcast_eligible,
    g.conditions_met
FROM gfx_hands h
LEFT JOIN gfx_sessions s ON h.session_id = s.session_id
LEFT JOIN hand_grades g ON h.id = g.hand_id
ORDER BY h.start_time DESC;

-- v_showdown_players
CREATE OR REPLACE VIEW v_showdown_players AS
SELECT
    hp.id,
    hp.hand_id,
    hp.player_name,
    hp.seat_num,
    hp.hole_cards,
    hp.start_stack_amt,
    hp.end_stack_amt,
    hp.cumulative_winnings_amt,
    hp.is_winner,
    h.hand_num,
    h.board_cards,
    h.pot_size,
    h.session_id
FROM gfx_hand_players hp
JOIN gfx_hands h ON hp.hand_id = h.id
WHERE hp.has_shown = TRUE
ORDER BY h.start_time DESC, hp.seat_num;

-- v_render_chip_display (from actual DB schema)
CREATE OR REPLACE VIEW v_render_chip_display AS
SELECT
    gs.session_id,
    gh.hand_num,
    ROW_NUMBER() OVER (PARTITION BY gs.session_id, gh.hand_num ORDER BY ghp.end_stack_amt DESC) AS slot_index,
    UPPER(COALESCE(po_name.override_value, ghp.player_name)) AS name,
    format_chips(ghp.end_stack_amt) AS chips,
    format_bbs(ghp.end_stack_amt, (gh.blinds->>'big_blind_amt')::BIGINT) AS bbs,
    (ROW_NUMBER() OVER (PARTITION BY gs.session_id, gh.hand_num ORDER BY ghp.end_stack_amt DESC))::text AS rank,
    get_flag_path((COALESCE(po_country.override_value, 'XX'::text))::varchar) AS flag,
    ghp.vpip_percent,
    ghp.end_stack_amt AS raw_chips,
    (gh.blinds->>'big_blind_amt')::BIGINT AS big_blind
FROM gfx_hand_players ghp
JOIN gfx_hands gh ON ghp.hand_id = gh.id
JOIN gfx_sessions gs ON gh.session_id = gs.session_id
LEFT JOIN gfx_players gp ON ghp.player_id = gp.id
LEFT JOIN player_overrides po_name ON po_name.gfx_player_id = gp.id AND po_name.field_name = 'name' AND po_name.active = TRUE
LEFT JOIN player_overrides po_country ON po_country.gfx_player_id = gp.id AND po_country.field_name = 'country_code' AND po_country.active = TRUE
WHERE ghp.sitting_out = FALSE
ORDER BY gs.session_id, gh.hand_num, ghp.end_stack_amt DESC;

COMMENT ON VIEW v_render_chip_display IS 'Chip Display 렌더링 뷰. player_overrides 기반으로 플레이어 정보 오버라이드 적용.';

-- ============================================================
-- 7. 완료 메시지
-- ============================================================

DO $$
BEGIN
    RAISE NOTICE 'INTEGER → BIGINT 타입 변경 완료!';
    RAISE NOTICE '';
    RAISE NOTICE '변경된 컬럼:';
    RAISE NOTICE '  - gfx_hand_players.start_stack_amt';
    RAISE NOTICE '  - gfx_hand_players.end_stack_amt';
    RAISE NOTICE '  - gfx_hand_players.cumulative_winnings_amt';
    RAISE NOTICE '  - gfx_hand_players.blind_bet_straddle_amt';
    RAISE NOTICE '  - gfx_events.bet_amount';
    RAISE NOTICE '  - gfx_events.pot_size';
    RAISE NOTICE '  - gfx_events.stack_size';
    RAISE NOTICE '  - gfx_hands.pot_size';
    RAISE NOTICE '';
    RAISE NOTICE '재생성된 뷰: unified_chip_data';
END $$;
