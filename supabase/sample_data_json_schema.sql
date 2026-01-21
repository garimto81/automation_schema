-- ============================================================================
-- Migration: sample_data_json_schema
-- Description: json 스키마 샘플 데이터 (트리거가 자동으로 public 스키마 동기화)
-- Version: 1.0.0
-- Date: 2026-01-20
-- Reference: docs/02-GFX-JSON-DB.md Section 12
-- ============================================================================

-- ============================================================================
-- 샘플 데이터 개요
-- ============================================================================
-- 1개 세션 (WSOP Cyprus Main Event Day 2)
-- 3개 핸드:
--   - Hand 1 (A급): 쇼다운, Full House vs Flush
--   - Hand 2 (B급): Preflop All-in, AA vs KK
--   - Hand 3 (C급): 일반 핸드, River Fold
-- 각 핸드당 6-8명 플레이어
-- 현실적인 포커 액션 시나리오
-- ============================================================================

-- ============================================================================
-- 1. json.gfx_sessions - 세션 데이터
-- ============================================================================

INSERT INTO json.gfx_sessions (
    id,
    source_file,
    file_hash,
    table_type,
    event_title,
    software_version,
    payouts,
    total_hands,
    created_at_utc,
    raw_json
) VALUES (
    638962967524560999,  -- session_id (int64)
    'PGFX_live_data_export GameID=638962967524560999.json',
    md5('sample_session_999'),
    'FEATURE_TABLE',
    'WSOP Super Circuit Cyprus - Main Event Day 2',
    'PokerGFX 3.2',
    ARRAY[0,0,0,0,0,0,0,0,0,0]::INTEGER[],
    3,  -- total_hands
    '2025-10-18T14:00:00Z'::TIMESTAMPTZ,
    '{"ID": 638962967524560999, "Type": "FEATURE_TABLE", "EventTitle": "WSOP Super Circuit Cyprus - Main Event Day 2", "SoftwareVersion": "PokerGFX 3.2"}'::JSONB
) ON CONFLICT (id) DO NOTHING;

-- ============================================================================
-- 2. json.hands - 핸드 데이터
-- ============================================================================

-- Hand 1 (A급): 쇼다운, Full House vs Flush
INSERT INTO json.hands (
    session_id,
    hand_number,
    game_variant,
    game_class,
    bet_structure,
    duration_seconds,
    start_time,
    recording_offset,
    recording_offset_seconds,
    ante_amount,
    bomb_pot_amount,
    final_pot_size,
    player_count,
    board_cards,
    grade,
    is_premium,
    is_showdown,
    flop_cards,
    turn_card,
    river_card,
    winning_hand
) VALUES (
    638962967524560999,
    1,
    'HOLDEM',
    'FLOP',
    'NOLIMIT',
    245,  -- 4분 5초
    '2025-10-18T14:05:00Z'::TIMESTAMPTZ,
    'PT5M00S',
    300,  -- 300초 오프셋
    1000,  -- 1K ante
    0,
    128000,  -- 128K pot
    8,
    ARRAY['ah', 'as', 'kh', '7d', '7s']::TEXT[],  -- A-A-K-7-7 (Full House 가능)
    'A',
    TRUE,
    TRUE,
    '["ah", "as", "kh"]'::JSONB,
    '7d',
    '7s',
    'Full House, Aces full of Sevens'
) ON CONFLICT (session_id, hand_number) DO NOTHING;

-- Hand 2 (B급): Preflop All-in, AA vs KK
INSERT INTO json.hands (
    session_id,
    hand_number,
    game_variant,
    game_class,
    bet_structure,
    duration_seconds,
    start_time,
    recording_offset,
    recording_offset_seconds,
    ante_amount,
    bomb_pot_amount,
    final_pot_size,
    player_count,
    board_cards,
    grade,
    is_premium,
    is_showdown,
    flop_cards,
    turn_card,
    river_card,
    winning_hand
) VALUES (
    638962967524560999,
    2,
    'HOLDEM',
    'FLOP',
    'NOLIMIT',
    185,  -- 3분 5초
    '2025-10-18T14:09:05Z'::TIMESTAMPTZ,
    'PT9M05S',
    545,
    1000,
    0,
    224000,  -- 224K pot (preflop all-in)
    6,
    ARRAY['2h', '9c', 'qd', '5s', '8h']::TEXT[],  -- 무난한 보드 (AA 승)
    'B',
    TRUE,
    TRUE,
    '["2h", "9c", "qd"]'::JSONB,
    '5s',
    '8h',
    'Pair of Aces'
) ON CONFLICT (session_id, hand_number) DO NOTHING;

-- Hand 3 (C급): 일반 핸드, River Fold
INSERT INTO json.hands (
    session_id,
    hand_number,
    game_variant,
    game_class,
    bet_structure,
    duration_seconds,
    start_time,
    recording_offset,
    recording_offset_seconds,
    ante_amount,
    bomb_pot_amount,
    final_pot_size,
    player_count,
    board_cards,
    grade,
    is_premium,
    is_showdown,
    flop_cards,
    turn_card,
    river_card,
    winning_hand
) VALUES (
    638962967524560999,
    3,
    'HOLDEM',
    'FLOP',
    'NOLIMIT',
    95,  -- 1분 35초
    '2025-10-18T14:12:10Z'::TIMESTAMPTZ,
    'PT12M10S',
    730,
    1000,
    0,
    18000,  -- 18K pot (river fold)
    7,
    ARRAY['3c', '7d', 'jh', '9s']::TEXT[],  -- Turn까지만 (River fold)
    'C',
    FALSE,
    FALSE,
    '["3c", "7d", "jh"]'::JSONB,
    '9s',
    NULL,
    'Jack high'
) ON CONFLICT (session_id, hand_number) DO NOTHING;

-- ============================================================================
-- 3. json.hand_players - 플레이어 상태 (핸드별)
-- ============================================================================

-- Hand 1 플레이어 (8명) - Full House vs Flush
INSERT INTO json.hand_players (
    session_id,
    hand_number,
    seat_number,
    player_name,
    start_stack,
    end_stack,
    net_result,
    hole_cards,
    has_shown_cards,
    sitting_out,
    is_winner,
    vpip_percent,
    preflop_raise_percent,
    aggression_percent,
    showdown_percent,
    hole_cards_normalized,
    hole_card_1,
    hole_card_2,
    hand_rank,
    rank_value,
    won_amount
) VALUES
    -- Seat 1: Winner (Full House)
    (638962967524560999, 1, 1, 'Ipekoglu', 95000, 159000, 64000, ARRAY['ad', 'ac']::TEXT[], TRUE, FALSE, TRUE, 32.5, 26.0, 40.0, 18.0, 'AcAd', 'ac', 'ad', 'Full House', 167, 128000),
    -- Seat 2: Loser (Flush)
    (638962967524560999, 1, 2, 'Khordbin', 88000, 24000, -64000, ARRAY['kh', 'qh']::TEXT[], TRUE, FALSE, FALSE, 28.0, 22.0, 35.0, 15.0, 'KhQh', 'kh', 'qh', 'Flush', 1610, 0),
    -- Seat 3-8: Folders
    (638962967524560999, 1, 3, 'Cucchiara', 72000, 71000, -1000, ARRAY[]::TEXT[], FALSE, FALSE, FALSE, 25.0, 18.0, 30.0, 12.0, NULL, NULL, NULL, NULL, NULL, 0),
    (638962967524560999, 1, 4, 'Gadeikis', 68000, 68000, 0, ARRAY[]::TEXT[], FALSE, FALSE, FALSE, 22.0, 15.0, 28.0, 10.0, NULL, NULL, NULL, NULL, NULL, 0),
    (638962967524560999, 1, 5, 'Haddad', 55000, 54000, -1000, ARRAY[]::TEXT[], FALSE, FALSE, FALSE, 30.0, 20.0, 32.0, 14.0, NULL, NULL, NULL, NULL, NULL, 0),
    (638962967524560999, 1, 6, 'Michalak', 48000, 48000, 0, ARRAY[]::TEXT[], FALSE, FALSE, FALSE, 18.0, 12.0, 25.0, 8.0, NULL, NULL, NULL, NULL, NULL, 0),
    (638962967524560999, 1, 7, 'Artamonov', 42000, 42000, 0, ARRAY[]::TEXT[], FALSE, FALSE, FALSE, 20.0, 14.0, 22.0, 9.0, NULL, NULL, NULL, NULL, NULL, 0),
    (638962967524560999, 1, 8, 'Korochenskiy', 38000, 38000, 0, ARRAY[]::TEXT[], FALSE, FALSE, FALSE, 24.0, 16.0, 26.0, 11.0, NULL, NULL, NULL, NULL, NULL, 0)
ON CONFLICT (session_id, hand_number, seat_number) DO NOTHING;

-- Hand 2 플레이어 (6명) - Preflop All-in AA vs KK
INSERT INTO json.hand_players (
    session_id,
    hand_number,
    seat_number,
    player_name,
    start_stack,
    end_stack,
    net_result,
    hole_cards,
    has_shown_cards,
    sitting_out,
    is_winner,
    vpip_percent,
    preflop_raise_percent,
    aggression_percent,
    showdown_percent,
    hole_cards_normalized,
    hole_card_1,
    hole_card_2,
    hand_rank,
    rank_value,
    won_amount
) VALUES
    -- Seat 1: Winner (AA)
    (638962967524560999, 2, 1, 'Ipekoglu', 159000, 271000, 112000, ARRAY['ah', 'ad']::TEXT[], TRUE, FALSE, TRUE, 32.5, 26.0, 40.0, 18.0, 'AhAd', 'ah', 'ad', 'Pair of Aces', 2861, 224000),
    -- Seat 3: Loser (KK)
    (638962967524560999, 2, 3, 'Cucchiara', 71000, 0, -71000, ARRAY['kc', 'kd']::TEXT[], TRUE, FALSE, FALSE, 25.0, 18.0, 30.0, 12.0, 'KcKd', 'kc', 'kd', 'Pair of Kings', 2992, 0),
    -- Seat 4-6: Folders
    (638962967524560999, 2, 4, 'Gadeikis', 68000, 67000, -1000, ARRAY[]::TEXT[], FALSE, FALSE, FALSE, 22.0, 15.0, 28.0, 10.0, NULL, NULL, NULL, NULL, NULL, 0),
    (638962967524560999, 2, 5, 'Haddad', 54000, 54000, 0, ARRAY[]::TEXT[], FALSE, FALSE, FALSE, 30.0, 20.0, 32.0, 14.0, NULL, NULL, NULL, NULL, NULL, 0),
    (638962967524560999, 2, 6, 'Michalak', 48000, 47000, -1000, ARRAY[]::TEXT[], FALSE, FALSE, FALSE, 18.0, 12.0, 25.0, 8.0, NULL, NULL, NULL, NULL, NULL, 0),
    (638962967524560999, 2, 8, 'Korochenskiy', 38000, 38000, 0, ARRAY[]::TEXT[], FALSE, FALSE, FALSE, 24.0, 16.0, 26.0, 11.0, NULL, NULL, NULL, NULL, NULL, 0)
ON CONFLICT (session_id, hand_number, seat_number) DO NOTHING;

-- Hand 3 플레이어 (7명) - River Fold
INSERT INTO json.hand_players (
    session_id,
    hand_number,
    seat_number,
    player_name,
    start_stack,
    end_stack,
    net_result,
    hole_cards,
    has_shown_cards,
    sitting_out,
    is_winner,
    vpip_percent,
    preflop_raise_percent,
    aggression_percent,
    showdown_percent,
    hole_cards_normalized,
    hole_card_1,
    hole_card_2,
    hand_rank,
    rank_value,
    won_amount
) VALUES
    -- Seat 1: Winner (Turn bet, River fold)
    (638962967524560999, 3, 1, 'Ipekoglu', 271000, 280000, 9000, ARRAY[]::TEXT[], FALSE, FALSE, TRUE, 32.5, 26.0, 40.0, 18.0, NULL, NULL, NULL, 'Jack high', NULL, 18000),
    -- Seat 2: Loser (River fold)
    (638962967524560999, 3, 2, 'Khordbin', 24000, 15000, -9000, ARRAY[]::TEXT[], FALSE, FALSE, FALSE, 28.0, 22.0, 35.0, 15.0, NULL, NULL, NULL, NULL, NULL, 0),
    -- Seat 4-8: Folders
    (638962967524560999, 3, 4, 'Gadeikis', 67000, 67000, 0, ARRAY[]::TEXT[], FALSE, FALSE, FALSE, 22.0, 15.0, 28.0, 10.0, NULL, NULL, NULL, NULL, NULL, 0),
    (638962967524560999, 3, 5, 'Haddad', 54000, 54000, 0, ARRAY[]::TEXT[], FALSE, FALSE, FALSE, 30.0, 20.0, 32.0, 14.0, NULL, NULL, NULL, NULL, NULL, 0),
    (638962967524560999, 3, 6, 'Michalak', 47000, 47000, 0, ARRAY[]::TEXT[], FALSE, FALSE, FALSE, 18.0, 12.0, 25.0, 8.0, NULL, NULL, NULL, NULL, NULL, 0),
    (638962967524560999, 3, 7, 'Artamonov', 42000, 42000, 0, ARRAY[]::TEXT[], FALSE, FALSE, FALSE, 20.0, 14.0, 22.0, 9.0, NULL, NULL, NULL, NULL, NULL, 0),
    (638962967524560999, 3, 8, 'Korochenskiy', 38000, 38000, 0, ARRAY[]::TEXT[], FALSE, FALSE, FALSE, 24.0, 16.0, 26.0, 11.0, NULL, NULL, NULL, NULL, NULL, 0)
ON CONFLICT (session_id, hand_number, seat_number) DO NOTHING;

-- ============================================================================
-- 4. json.hand_actions - 액션/이벤트 (핸드별)
-- ============================================================================

-- Hand 1 액션 (Full House vs Flush - 쇼다운)
INSERT INTO json.hand_actions (
    session_id,
    hand_number,
    action_order,
    street,
    street_order,
    action,
    seat_number,
    player_name,
    bet_amount,
    raise_to_amount,
    pot_before,
    pot_after,
    board_card,
    action_time
) VALUES
    -- Preflop
    (638962967524560999, 1, 1, 'preflop', 1, 'BLIND', 5, 'Haddad', 500, NULL, 0, 500, NULL, '2025-10-18T14:05:00Z'::TIMESTAMPTZ),
    (638962967524560999, 1, 2, 'preflop', 2, 'BLIND', 6, 'Michalak', 1000, NULL, 500, 1500, NULL, '2025-10-18T14:05:01Z'::TIMESTAMPTZ),
    (638962967524560999, 1, 3, 'preflop', 3, 'RAISE', 1, 'Ipekoglu', 3500, 3500, 1500, 5000, NULL, '2025-10-18T14:05:05Z'::TIMESTAMPTZ),
    (638962967524560999, 1, 4, 'preflop', 4, 'CALL', 2, 'Khordbin', 3500, NULL, 5000, 8500, NULL, '2025-10-18T14:05:10Z'::TIMESTAMPTZ),
    (638962967524560999, 1, 5, 'preflop', 5, 'FOLD', 3, 'Cucchiara', 0, NULL, 8500, 8500, NULL, '2025-10-18T14:05:12Z'::TIMESTAMPTZ),
    (638962967524560999, 1, 6, 'preflop', 6, 'FOLD', 4, 'Gadeikis', 0, NULL, 8500, 8500, NULL, '2025-10-18T14:05:13Z'::TIMESTAMPTZ),
    (638962967524560999, 1, 7, 'preflop', 7, 'FOLD', 5, 'Haddad', 0, NULL, 8500, 8500, NULL, '2025-10-18T14:05:14Z'::TIMESTAMPTZ),
    (638962967524560999, 1, 8, 'preflop', 8, 'FOLD', 6, 'Michalak', 0, NULL, 8500, 8500, NULL, '2025-10-18T14:05:15Z'::TIMESTAMPTZ),
    -- Flop
    (638962967524560999, 1, 9, 'flop', 1, 'BOARD_CARD', 0, NULL, 0, NULL, 8500, 8500, 'ah', '2025-10-18T14:05:20Z'::TIMESTAMPTZ),
    (638962967524560999, 1, 10, 'flop', 2, 'BOARD_CARD', 0, NULL, 0, NULL, 8500, 8500, 'as', '2025-10-18T14:05:21Z'::TIMESTAMPTZ),
    (638962967524560999, 1, 11, 'flop', 3, 'BOARD_CARD', 0, NULL, 0, NULL, 8500, 8500, 'kh', '2025-10-18T14:05:22Z'::TIMESTAMPTZ),
    (638962967524560999, 1, 12, 'flop', 4, 'CHECK', 1, 'Ipekoglu', 0, NULL, 8500, 8500, NULL, '2025-10-18T14:05:25Z'::TIMESTAMPTZ),
    (638962967524560999, 1, 13, 'flop', 5, 'BET', 2, 'Khordbin', 6000, NULL, 8500, 14500, NULL, '2025-10-18T14:05:30Z'::TIMESTAMPTZ),
    (638962967524560999, 1, 14, 'flop', 6, 'CALL', 1, 'Ipekoglu', 6000, NULL, 14500, 20500, NULL, '2025-10-18T14:05:35Z'::TIMESTAMPTZ),
    -- Turn
    (638962967524560999, 1, 15, 'turn', 1, 'BOARD_CARD', 0, NULL, 0, NULL, 20500, 20500, '7d', '2025-10-18T14:05:40Z'::TIMESTAMPTZ),
    (638962967524560999, 1, 16, 'turn', 2, 'BET', 1, 'Ipekoglu', 15000, NULL, 20500, 35500, NULL, '2025-10-18T14:05:50Z'::TIMESTAMPTZ),
    (638962967524560999, 1, 17, 'turn', 3, 'CALL', 2, 'Khordbin', 15000, NULL, 35500, 50500, NULL, '2025-10-18T14:06:00Z'::TIMESTAMPTZ),
    -- River
    (638962967524560999, 1, 18, 'river', 1, 'BOARD_CARD', 0, NULL, 0, NULL, 50500, 50500, '7s', '2025-10-18T14:06:05Z'::TIMESTAMPTZ),
    (638962967524560999, 1, 19, 'river', 2, 'BET', 1, 'Ipekoglu', 38500, NULL, 50500, 89000, NULL, '2025-10-18T14:06:20Z'::TIMESTAMPTZ),
    (638962967524560999, 1, 20, 'river', 3, 'CALL', 2, 'Khordbin', 38500, NULL, 89000, 128000, NULL, '2025-10-18T14:07:00Z'::TIMESTAMPTZ)
ON CONFLICT (session_id, hand_number, action_order) DO NOTHING;

-- Hand 2 액션 (Preflop All-in AA vs KK)
INSERT INTO json.hand_actions (
    session_id,
    hand_number,
    action_order,
    street,
    street_order,
    action,
    seat_number,
    player_name,
    bet_amount,
    raise_to_amount,
    pot_before,
    pot_after,
    board_card,
    action_time
) VALUES
    -- Preflop
    (638962967524560999, 2, 1, 'preflop', 1, 'BLIND', 4, 'Gadeikis', 500, NULL, 0, 500, NULL, '2025-10-18T14:09:05Z'::TIMESTAMPTZ),
    (638962967524560999, 2, 2, 'preflop', 2, 'BLIND', 5, 'Haddad', 1000, NULL, 500, 1500, NULL, '2025-10-18T14:09:06Z'::TIMESTAMPTZ),
    (638962967524560999, 2, 3, 'preflop', 3, 'RAISE', 3, 'Cucchiara', 3000, 3000, 1500, 4500, NULL, '2025-10-18T14:09:10Z'::TIMESTAMPTZ),
    (638962967524560999, 2, 4, 'preflop', 4, 'RAISE', 1, 'Ipekoglu', 12000, 12000, 4500, 16500, NULL, '2025-10-18T14:09:20Z'::TIMESTAMPTZ),
    (638962967524560999, 2, 5, 'preflop', 5, 'FOLD', 4, 'Gadeikis', 0, NULL, 16500, 16500, NULL, '2025-10-18T14:09:22Z'::TIMESTAMPTZ),
    (638962967524560999, 2, 6, 'preflop', 6, 'FOLD', 5, 'Haddad', 0, NULL, 16500, 16500, NULL, '2025-10-18T14:09:23Z'::TIMESTAMPTZ),
    (638962967524560999, 2, 7, 'preflop', 7, 'FOLD', 6, 'Michalak', 0, NULL, 16500, 16500, NULL, '2025-10-18T14:09:24Z'::TIMESTAMPTZ),
    (638962967524560999, 2, 8, 'preflop', 8, 'ALL_IN', 3, 'Cucchiara', 68000, 71000, 16500, 87500, NULL, '2025-10-18T14:09:40Z'::TIMESTAMPTZ),
    (638962967524560999, 2, 9, 'preflop', 9, 'CALL', 1, 'Ipekoglu', 59000, NULL, 87500, 146500, NULL, '2025-10-18T14:10:00Z'::TIMESTAMPTZ),
    -- Flop (런아웃)
    (638962967524560999, 2, 10, 'flop', 1, 'BOARD_CARD', 0, NULL, 0, NULL, 146500, 146500, '2h', '2025-10-18T14:10:10Z'::TIMESTAMPTZ),
    (638962967524560999, 2, 11, 'flop', 2, 'BOARD_CARD', 0, NULL, 0, NULL, 146500, 146500, '9c', '2025-10-18T14:10:11Z'::TIMESTAMPTZ),
    (638962967524560999, 2, 12, 'flop', 3, 'BOARD_CARD', 0, NULL, 0, NULL, 146500, 146500, 'qd', '2025-10-18T14:10:12Z'::TIMESTAMPTZ),
    -- Turn
    (638962967524560999, 2, 13, 'turn', 1, 'BOARD_CARD', 0, NULL, 0, NULL, 146500, 146500, '5s', '2025-10-18T14:10:15Z'::TIMESTAMPTZ),
    -- River
    (638962967524560999, 2, 14, 'river', 1, 'BOARD_CARD', 0, NULL, 0, NULL, 146500, 146500, '8h', '2025-10-18T14:10:18Z'::TIMESTAMPTZ)
ON CONFLICT (session_id, hand_number, action_order) DO NOTHING;

-- Hand 3 액션 (River Fold - 간단한 핸드)
INSERT INTO json.hand_actions (
    session_id,
    hand_number,
    action_order,
    street,
    street_order,
    action,
    seat_number,
    player_name,
    bet_amount,
    raise_to_amount,
    pot_before,
    pot_after,
    board_card,
    action_time
) VALUES
    -- Preflop
    (638962967524560999, 3, 1, 'preflop', 1, 'BLIND', 5, 'Haddad', 500, NULL, 0, 500, NULL, '2025-10-18T14:12:10Z'::TIMESTAMPTZ),
    (638962967524560999, 3, 2, 'preflop', 2, 'BLIND', 6, 'Michalak', 1000, NULL, 500, 1500, NULL, '2025-10-18T14:12:11Z'::TIMESTAMPTZ),
    (638962967524560999, 3, 3, 'preflop', 3, 'CALL', 1, 'Ipekoglu', 1000, NULL, 1500, 2500, NULL, '2025-10-18T14:12:15Z'::TIMESTAMPTZ),
    (638962967524560999, 3, 4, 'preflop', 4, 'CALL', 2, 'Khordbin', 1000, NULL, 2500, 3500, NULL, '2025-10-18T14:12:18Z'::TIMESTAMPTZ),
    (638962967524560999, 3, 5, 'preflop', 5, 'FOLD', 4, 'Gadeikis', 0, NULL, 3500, 3500, NULL, '2025-10-18T14:12:19Z'::TIMESTAMPTZ),
    (638962967524560999, 3, 6, 'preflop', 6, 'CHECK', 5, 'Haddad', 0, NULL, 3500, 3500, NULL, '2025-10-18T14:12:20Z'::TIMESTAMPTZ),
    (638962967524560999, 3, 7, 'preflop', 7, 'CHECK', 6, 'Michalak', 0, NULL, 3500, 3500, NULL, '2025-10-18T14:12:21Z'::TIMESTAMPTZ),
    -- Flop
    (638962967524560999, 3, 8, 'flop', 1, 'BOARD_CARD', 0, NULL, 0, NULL, 3500, 3500, '3c', '2025-10-18T14:12:25Z'::TIMESTAMPTZ),
    (638962967524560999, 3, 9, 'flop', 2, 'BOARD_CARD', 0, NULL, 0, NULL, 3500, 3500, '7d', '2025-10-18T14:12:26Z'::TIMESTAMPTZ),
    (638962967524560999, 3, 10, 'flop', 3, 'BOARD_CARD', 0, NULL, 0, NULL, 3500, 3500, 'jh', '2025-10-18T14:12:27Z'::TIMESTAMPTZ),
    (638962967524560999, 3, 11, 'flop', 4, 'CHECK', 5, 'Haddad', 0, NULL, 3500, 3500, NULL, '2025-10-18T14:12:30Z'::TIMESTAMPTZ),
    (638962967524560999, 3, 12, 'flop', 5, 'CHECK', 6, 'Michalak', 0, NULL, 3500, 3500, NULL, '2025-10-18T14:12:31Z'::TIMESTAMPTZ),
    (638962967524560999, 3, 13, 'flop', 6, 'CHECK', 1, 'Ipekoglu', 0, NULL, 3500, 3500, NULL, '2025-10-18T14:12:32Z'::TIMESTAMPTZ),
    (638962967524560999, 3, 14, 'flop', 7, 'CHECK', 2, 'Khordbin', 0, NULL, 3500, 3500, NULL, '2025-10-18T14:12:33Z'::TIMESTAMPTZ),
    -- Turn
    (638962967524560999, 3, 15, 'turn', 1, 'BOARD_CARD', 0, NULL, 0, NULL, 3500, 3500, '9s', '2025-10-18T14:12:37Z'::TIMESTAMPTZ),
    (638962967524560999, 3, 16, 'turn', 2, 'BET', 1, 'Ipekoglu', 4500, NULL, 3500, 8000, NULL, '2025-10-18T14:12:45Z'::TIMESTAMPTZ),
    (638962967524560999, 3, 17, 'turn', 3, 'CALL', 2, 'Khordbin', 4500, NULL, 8000, 12500, NULL, '2025-10-18T14:12:55Z'::TIMESTAMPTZ),
    (638962967524560999, 3, 18, 'turn', 4, 'FOLD', 5, 'Haddad', 0, NULL, 12500, 12500, NULL, '2025-10-18T14:12:56Z'::TIMESTAMPTZ),
    (638962967524560999, 3, 19, 'turn', 5, 'FOLD', 6, 'Michalak', 0, NULL, 12500, 12500, NULL, '2025-10-18T14:12:57Z'::TIMESTAMPTZ)
    -- River는 폴드로 종료 (보드카드 없음)
ON CONFLICT (session_id, hand_number, action_order) DO NOTHING;

-- ============================================================================
-- 5. json.hand_cards - 카드 데이터 (홀카드 + 커뮤니티 카드)
-- ============================================================================

-- Hand 1 카드 (Full House vs Flush)
INSERT INTO json.hand_cards (
    session_id,
    hand_number,
    card_rank,
    card_suit,
    card_type,
    seat_number,
    card_order,
    card_original,
    source
) VALUES
    -- Ipekoglu hole cards
    (638962967524560999, 1, 'a', 'd', 'hole', 1, 1, 'ad', 'gfx'),
    (638962967524560999, 1, 'a', 'c', 'hole', 1, 2, 'ac', 'gfx'),
    -- Khordbin hole cards
    (638962967524560999, 1, 'k', 'h', 'hole', 2, 1, 'kh', 'gfx'),
    (638962967524560999, 1, 'q', 'h', 'hole', 2, 2, 'qh', 'gfx'),
    -- Community cards (flop)
    (638962967524560999, 1, 'a', 'h', 'flop', NULL, 1, 'ah', 'gfx'),
    (638962967524560999, 1, 'a', 's', 'flop', NULL, 2, 'as', 'gfx'),
    (638962967524560999, 1, 'k', 'h', 'flop', NULL, 3, 'kh', 'gfx'),
    -- Turn
    (638962967524560999, 1, '7', 'd', 'turn', NULL, 1, '7d', 'gfx'),
    -- River
    (638962967524560999, 1, '7', 's', 'river', NULL, 1, '7s', 'gfx')
ON CONFLICT (session_id, hand_number, card_type, card_order, COALESCE(seat_number, 0)) DO NOTHING;

-- Hand 2 카드 (AA vs KK)
INSERT INTO json.hand_cards (
    session_id,
    hand_number,
    card_rank,
    card_suit,
    card_type,
    seat_number,
    card_order,
    card_original,
    source
) VALUES
    -- Ipekoglu hole cards (AA)
    (638962967524560999, 2, 'a', 'h', 'hole', 1, 1, 'ah', 'gfx'),
    (638962967524560999, 2, 'a', 'd', 'hole', 1, 2, 'ad', 'gfx'),
    -- Cucchiara hole cards (KK)
    (638962967524560999, 2, 'k', 'c', 'hole', 3, 1, 'kc', 'gfx'),
    (638962967524560999, 2, 'k', 'd', 'hole', 3, 2, 'kd', 'gfx'),
    -- Community cards
    (638962967524560999, 2, '2', 'h', 'flop', NULL, 1, '2h', 'gfx'),
    (638962967524560999, 2, '9', 'c', 'flop', NULL, 2, '9c', 'gfx'),
    (638962967524560999, 2, 'q', 'd', 'flop', NULL, 3, 'qd', 'gfx'),
    (638962967524560999, 2, '5', 's', 'turn', NULL, 1, '5s', 'gfx'),
    (638962967524560999, 2, '8', 'h', 'river', NULL, 1, '8h', 'gfx')
ON CONFLICT (session_id, hand_number, card_type, card_order, COALESCE(seat_number, 0)) DO NOTHING;

-- Hand 3 카드 (Turn까지만 - River fold)
INSERT INTO json.hand_cards (
    session_id,
    hand_number,
    card_rank,
    card_suit,
    card_type,
    seat_number,
    card_order,
    card_original,
    source
) VALUES
    -- Community cards (홀카드는 미공개)
    (638962967524560999, 3, '3', 'c', 'flop', NULL, 1, '3c', 'gfx'),
    (638962967524560999, 3, '7', 'd', 'flop', NULL, 2, '7d', 'gfx'),
    (638962967524560999, 3, 'j', 'h', 'flop', NULL, 3, 'jh', 'gfx'),
    (638962967524560999, 3, '9', 's', 'turn', NULL, 1, '9s', 'gfx')
    -- River 카드 없음 (fold)
ON CONFLICT (session_id, hand_number, card_type, card_order, COALESCE(seat_number, 0)) DO NOTHING;

-- ============================================================================
-- 6. json.hand_results - 핸드 결과
-- ============================================================================

-- Hand 1 결과 (쇼다운 2명)
INSERT INTO json.hand_results (
    session_id,
    hand_number,
    seat_number,
    player_name,
    is_winner,
    won_amount,
    total_bet,
    hand_description,
    hand_rank,
    rank_value,
    best_five_cards,
    showdown_order
) VALUES
    (638962967524560999, 1, 1, 'Ipekoglu', TRUE, 128000, 64000, 'Full House, Aces full of Sevens', 'Full House', 167, '["ad", "ac", "ah", "7d", "7s"]'::JSONB, 1),
    (638962967524560999, 1, 2, 'Khordbin', FALSE, 0, 64000, 'Flush, Ace high', 'Flush', 1610, '["ah", "kh", "qh", "7h", "3h"]'::JSONB, 2)
ON CONFLICT (session_id, hand_number, seat_number) DO NOTHING;

-- Hand 2 결과 (쇼다운 2명)
INSERT INTO json.hand_results (
    session_id,
    hand_number,
    seat_number,
    player_name,
    is_winner,
    won_amount,
    total_bet,
    hand_description,
    hand_rank,
    rank_value,
    best_five_cards,
    showdown_order
) VALUES
    (638962967524560999, 2, 1, 'Ipekoglu', TRUE, 224000, 112000, 'Pair of Aces', 'One Pair', 2861, '["ah", "ad", "qd", "9c", "8h"]'::JSONB, 1),
    (638962967524560999, 2, 3, 'Cucchiara', FALSE, 0, 112000, 'Pair of Kings', 'One Pair', 2992, '["kc", "kd", "qd", "9c", "8h"]'::JSONB, 2)
ON CONFLICT (session_id, hand_number, seat_number) DO NOTHING;

-- Hand 3 결과 (쇼다운 없음 - 폴드)
-- 결과 데이터 없음 (no showdown)

-- ============================================================================
-- 완료 메시지
-- ============================================================================

DO $$
BEGIN
    RAISE NOTICE '===========================================================';
    RAISE NOTICE 'json 스키마 샘플 데이터 삽입 완료';
    RAISE NOTICE '===========================================================';
    RAISE NOTICE '';
    RAISE NOTICE '삽입된 데이터:';
    RAISE NOTICE '  - json.gfx_sessions: 1개 세션';
    RAISE NOTICE '  - json.hands: 3개 핸드 (A급, B급, C급)';
    RAISE NOTICE '  - json.hand_players: 21개 (Hand1: 8명, Hand2: 6명, Hand3: 7명)';
    RAISE NOTICE '  - json.hand_actions: 53개 액션';
    RAISE NOTICE '  - json.hand_cards: 22개 카드';
    RAISE NOTICE '  - json.hand_results: 4개 결과 (쇼다운만)';
    RAISE NOTICE '';
    RAISE NOTICE '핸드 시나리오:';
    RAISE NOTICE '  - Hand 1 (A급): Full House vs Flush, 128K pot, 쇼다운';
    RAISE NOTICE '  - Hand 2 (B급): AA vs KK preflop all-in, 224K pot';
    RAISE NOTICE '  - Hand 3 (C급): Turn bet → River fold, 18K pot';
    RAISE NOTICE '';
    RAISE NOTICE '트리거 동기화:';
    RAISE NOTICE '  → 자동으로 public 스키마에 동기화됨 (Phase 3 트리거)';
    RAISE NOTICE '===========================================================';
END $$;
