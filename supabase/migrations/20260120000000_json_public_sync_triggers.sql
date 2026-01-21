-- ============================================================================
-- Migration: json_public_sync_triggers
-- Description: json 스키마 → public 스키마 동기화 트리거 (Phase 3)
-- Version: 1.0.0
-- Date: 2026-01-20
-- PRD Reference: docs/02-GFX-JSON-DB.md Section 12.7
-- ============================================================================

-- ============================================================================
-- Phase 3: 동기화 트리거 생성
-- json 스키마의 INSERT/UPDATE → public 스키마 자동 동기화
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 3.1 gfx_sessions 동기화 트리거
-- json.gfx_sessions → public.gfx_sessions
-- ----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION sync_json_gfx_sessions_to_public()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.gfx_sessions (
        session_id,
        file_name,
        file_hash,
        table_type,
        event_title,
        software_version,
        payouts,
        hand_count,
        session_created_at,
        raw_json,
        sync_status,
        created_at,
        updated_at
    )
    VALUES (
        NEW.id,                          -- json.gfx_sessions.id → public.gfx_sessions.session_id
        NEW.source_file,                 -- file_name
        NEW.file_hash,
        COALESCE(NEW.table_type, 'UNKNOWN')::table_type,
        COALESCE(NEW.event_title, ''),
        NEW.software_version,
        COALESCE(NEW.payouts, ARRAY[]::INTEGER[]),
        COALESCE(NEW.total_hands, 0),
        NEW.created_at_utc,              -- session_created_at
        NEW.raw_json,
        'synced'::sync_status,
        NOW(),
        NOW()
    )
    ON CONFLICT (session_id) DO UPDATE SET
        file_name = EXCLUDED.file_name,
        file_hash = EXCLUDED.file_hash,
        table_type = EXCLUDED.table_type,
        event_title = EXCLUDED.event_title,
        software_version = EXCLUDED.software_version,
        payouts = EXCLUDED.payouts,
        hand_count = EXCLUDED.hand_count,
        session_created_at = EXCLUDED.session_created_at,
        raw_json = EXCLUDED.raw_json,
        sync_status = 'updated'::sync_status,
        updated_at = NOW();

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_sync_gfx_sessions_to_public
    AFTER INSERT OR UPDATE ON json.gfx_sessions
    FOR EACH ROW
    EXECUTE FUNCTION sync_json_gfx_sessions_to_public();

COMMENT ON FUNCTION sync_json_gfx_sessions_to_public() IS 'json.gfx_sessions → public.gfx_sessions 자동 동기화';

-- ----------------------------------------------------------------------------
-- 3.2 hands 동기화 트리거
-- json.hands → public.gfx_hands
-- ----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION sync_json_hands_to_public()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.gfx_hands (
        session_id,
        hand_num,
        game_variant,
        game_class,
        bet_structure,
        duration_seconds,
        start_time,
        recording_offset_iso,
        recording_offset_seconds,
        ante_amt,
        bomb_pot_amt,
        pot_size,
        player_count,
        board_cards,
        grade,
        is_premium,
        is_showdown,
        flop_cards,
        turn_card,
        river_card,
        winning_hand,
        created_at,
        updated_at
    )
    VALUES (
        NEW.session_id,
        NEW.hand_number,                 -- hand_number → hand_num
        COALESCE(NEW.game_variant, 'HOLDEM')::game_variant,
        COALESCE(NEW.game_class, 'FLOP')::game_class,
        COALESCE(NEW.bet_structure, 'NOLIMIT')::bet_structure,
        COALESCE(NEW.duration_seconds, 0),
        NEW.start_time,
        NEW.recording_offset,            -- recording_offset_iso
        COALESCE(NEW.recording_offset_seconds, 0),
        COALESCE(NEW.ante_amount, 0),    -- ante_amount → ante_amt
        COALESCE(NEW.bomb_pot_amount, 0), -- bomb_pot_amount → bomb_pot_amt
        COALESCE(NEW.final_pot_size, 0), -- final_pot_size → pot_size
        COALESCE(NEW.player_count, 0),
        COALESCE(NEW.board_cards, ARRAY[]::TEXT[]),
        NEW.grade,
        COALESCE(NEW.is_premium, FALSE),
        COALESCE(NEW.is_showdown, FALSE),
        NEW.flop_cards,
        NEW.turn_card,
        NEW.river_card,
        NEW.winning_hand,
        NOW(),
        NOW()
    )
    ON CONFLICT (session_id, hand_num) DO UPDATE SET
        game_variant = EXCLUDED.game_variant,
        game_class = EXCLUDED.game_class,
        bet_structure = EXCLUDED.bet_structure,
        duration_seconds = EXCLUDED.duration_seconds,
        start_time = EXCLUDED.start_time,
        recording_offset_iso = EXCLUDED.recording_offset_iso,
        recording_offset_seconds = EXCLUDED.recording_offset_seconds,
        ante_amt = EXCLUDED.ante_amt,
        bomb_pot_amt = EXCLUDED.bomb_pot_amt,
        pot_size = EXCLUDED.pot_size,
        player_count = EXCLUDED.player_count,
        board_cards = EXCLUDED.board_cards,
        grade = EXCLUDED.grade,
        is_premium = EXCLUDED.is_premium,
        is_showdown = EXCLUDED.is_showdown,
        flop_cards = EXCLUDED.flop_cards,
        turn_card = EXCLUDED.turn_card,
        river_card = EXCLUDED.river_card,
        winning_hand = EXCLUDED.winning_hand,
        updated_at = NOW();

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_sync_hands_to_public
    AFTER INSERT OR UPDATE ON json.hands
    FOR EACH ROW
    EXECUTE FUNCTION sync_json_hands_to_public();

COMMENT ON FUNCTION sync_json_hands_to_public() IS 'json.hands → public.gfx_hands 자동 동기화';

-- ----------------------------------------------------------------------------
-- 3.3 hand_players 동기화 트리거
-- json.hand_players → public.gfx_hand_players
-- ----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION sync_json_hand_players_to_public()
RETURNS TRIGGER AS $$
DECLARE
    v_hand_id UUID;
BEGIN
    -- session_id + hand_num으로 public.gfx_hands.id 조회
    SELECT id INTO v_hand_id
    FROM public.gfx_hands
    WHERE session_id = NEW.session_id
      AND hand_num = NEW.hand_number
    LIMIT 1;

    IF v_hand_id IS NULL THEN
        RAISE WARNING 'Hand not found for session_id=%, hand_number=%', NEW.session_id, NEW.hand_number;
        RETURN NEW;
    END IF;

    INSERT INTO public.gfx_hand_players (
        hand_id,
        seat_num,
        player_name,
        hole_cards,
        has_shown,
        start_stack_amt,
        end_stack_amt,
        cumulative_winnings_amt,
        sitting_out,
        is_winner,
        vpip_percent,
        preflop_raise_percent,
        aggression_frequency_percent,
        went_to_showdown_percent,
        hole_cards_normalized,
        hole_card_1,
        hole_card_2,
        hole_card_3,
        hole_card_4,
        hand_rank,
        rank_value,
        won_amount,
        created_at
    )
    VALUES (
        v_hand_id,
        NEW.seat_number,                 -- seat_number → seat_num
        NEW.player_name,
        COALESCE(NEW.hole_cards, ARRAY[]::TEXT[]),
        COALESCE(NEW.has_shown_cards, FALSE), -- has_shown_cards → has_shown
        COALESCE(NEW.start_stack, 0),    -- start_stack → start_stack_amt
        COALESCE(NEW.end_stack, 0),      -- end_stack → end_stack_amt
        COALESCE(NEW.net_result, 0),     -- net_result → cumulative_winnings_amt
        COALESCE(NEW.sitting_out, FALSE),
        COALESCE(NEW.is_winner, FALSE),
        COALESCE(NEW.vpip_percent, 0),
        COALESCE(NEW.preflop_raise_percent, 0),
        COALESCE(NEW.aggression_percent, 0), -- aggression_percent → aggression_frequency_percent
        COALESCE(NEW.showdown_percent, 0),   -- showdown_percent → went_to_showdown_percent
        NEW.hole_cards_normalized,
        NEW.hole_card_1,
        NEW.hole_card_2,
        NEW.hole_card_3,
        NEW.hole_card_4,
        NEW.hand_rank,
        NEW.rank_value,
        COALESCE(NEW.won_amount, 0),
        NOW()
    )
    ON CONFLICT (hand_id, seat_num) DO UPDATE SET
        player_name = EXCLUDED.player_name,
        hole_cards = EXCLUDED.hole_cards,
        has_shown = EXCLUDED.has_shown,
        start_stack_amt = EXCLUDED.start_stack_amt,
        end_stack_amt = EXCLUDED.end_stack_amt,
        cumulative_winnings_amt = EXCLUDED.cumulative_winnings_amt,
        sitting_out = EXCLUDED.sitting_out,
        is_winner = EXCLUDED.is_winner,
        vpip_percent = EXCLUDED.vpip_percent,
        preflop_raise_percent = EXCLUDED.preflop_raise_percent,
        aggression_frequency_percent = EXCLUDED.aggression_frequency_percent,
        went_to_showdown_percent = EXCLUDED.went_to_showdown_percent,
        hole_cards_normalized = EXCLUDED.hole_cards_normalized,
        hole_card_1 = EXCLUDED.hole_card_1,
        hole_card_2 = EXCLUDED.hole_card_2,
        hole_card_3 = EXCLUDED.hole_card_3,
        hole_card_4 = EXCLUDED.hole_card_4,
        hand_rank = EXCLUDED.hand_rank,
        rank_value = EXCLUDED.rank_value,
        won_amount = EXCLUDED.won_amount;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_sync_hand_players_to_public
    AFTER INSERT OR UPDATE ON json.hand_players
    FOR EACH ROW
    EXECUTE FUNCTION sync_json_hand_players_to_public();

COMMENT ON FUNCTION sync_json_hand_players_to_public() IS 'json.hand_players → public.gfx_hand_players 자동 동기화';

-- ----------------------------------------------------------------------------
-- 3.4 hand_actions 동기화 트리거
-- json.hand_actions → public.gfx_events
-- ----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION sync_json_hand_actions_to_public()
RETURNS TRIGGER AS $$
DECLARE
    v_hand_id UUID;
    v_event_type event_type;
BEGIN
    -- session_id + hand_num으로 public.gfx_hands.id 조회
    SELECT id INTO v_hand_id
    FROM public.gfx_hands
    WHERE session_id = NEW.session_id
      AND hand_num = NEW.hand_number
    LIMIT 1;

    IF v_hand_id IS NULL THEN
        RAISE WARNING 'Hand not found for session_id=%, hand_number=%', NEW.session_id, NEW.hand_number;
        RETURN NEW;
    END IF;

    -- action → event_type 변환
    v_event_type := CASE NEW.action
        WHEN 'FOLD' THEN 'FOLD'::event_type
        WHEN 'CHECK' THEN 'CHECK'::event_type
        WHEN 'CALL' THEN 'CALL'::event_type
        WHEN 'BET' THEN 'BET'::event_type
        WHEN 'RAISE' THEN 'RAISE'::event_type
        WHEN 'ALL_IN' THEN 'ALL_IN'::event_type
        WHEN 'BOARD_CARD' THEN 'BOARD_CARD'::event_type
        WHEN 'ANTE' THEN 'ANTE'::event_type
        WHEN 'BLIND' THEN 'BLIND'::event_type
        ELSE 'CHECK'::event_type  -- 기본값
    END;

    INSERT INTO public.gfx_events (
        hand_id,
        event_order,
        event_type,
        player_num,
        bet_amt,
        pot,
        board_cards,
        street,
        street_order,
        action,
        player_name,
        raise_to_amount,
        pot_size_before,
        pot_size_after,
        action_time,
        created_at
    )
    VALUES (
        v_hand_id,
        NEW.action_order,                -- action_order → event_order
        v_event_type,
        COALESCE(NEW.seat_number, 0),    -- seat_number → player_num
        COALESCE(NEW.bet_amount, 0),     -- bet_amount → bet_amt
        COALESCE(NEW.pot_after, 0),      -- pot_after → pot
        NEW.board_card,                  -- board_card → board_cards (TEXT)
        NEW.street,
        NEW.street_order,
        NEW.action,
        NEW.player_name,
        NEW.raise_to_amount,
        NEW.pot_before,                  -- pot_before → pot_size_before
        NEW.pot_after,                   -- pot_after → pot_size_after
        NEW.action_time,
        NOW()
    )
    ON CONFLICT (hand_id, event_order) DO UPDATE SET
        event_type = EXCLUDED.event_type,
        player_num = EXCLUDED.player_num,
        bet_amt = EXCLUDED.bet_amt,
        pot = EXCLUDED.pot,
        board_cards = EXCLUDED.board_cards,
        street = EXCLUDED.street,
        street_order = EXCLUDED.street_order,
        action = EXCLUDED.action,
        player_name = EXCLUDED.player_name,
        raise_to_amount = EXCLUDED.raise_to_amount,
        pot_size_before = EXCLUDED.pot_size_before,
        pot_size_after = EXCLUDED.pot_size_after,
        action_time = EXCLUDED.action_time;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_sync_hand_actions_to_public
    AFTER INSERT OR UPDATE ON json.hand_actions
    FOR EACH ROW
    EXECUTE FUNCTION sync_json_hand_actions_to_public();

COMMENT ON FUNCTION sync_json_hand_actions_to_public() IS 'json.hand_actions → public.gfx_events 자동 동기화';

-- ----------------------------------------------------------------------------
-- 3.5 hand_cards 동기화 트리거
-- json.hand_cards → public.gfx_hand_cards
-- ----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION sync_json_hand_cards_to_public()
RETURNS TRIGGER AS $$
DECLARE
    v_hand_id UUID;
BEGIN
    -- session_id + hand_num으로 public.gfx_hands.id 조회
    SELECT id INTO v_hand_id
    FROM public.gfx_hands
    WHERE session_id = NEW.session_id
      AND hand_num = NEW.hand_number
    LIMIT 1;

    IF v_hand_id IS NULL THEN
        RAISE WARNING 'Hand not found for session_id=%, hand_number=%', NEW.session_id, NEW.hand_number;
        RETURN NEW;
    END IF;

    INSERT INTO public.gfx_hand_cards (
        hand_id,
        card_rank,
        card_suit,
        card_type,
        seat_number,
        card_order,
        gfx_card,
        source,
        created_at
    )
    VALUES (
        v_hand_id,
        NEW.card_rank,
        NEW.card_suit,
        NEW.card_type,
        NEW.seat_number,
        NEW.card_order,
        NEW.card_original,               -- card_original → gfx_card
        COALESCE(NEW.source, 'gfx'),
        NOW()
    )
    ON CONFLICT (hand_id, card_type, card_order, COALESCE(seat_number, 0), board_num) DO UPDATE SET
        card_rank = EXCLUDED.card_rank,
        card_suit = EXCLUDED.card_suit,
        seat_number = EXCLUDED.seat_number,
        gfx_card = EXCLUDED.gfx_card,
        source = EXCLUDED.source;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_sync_hand_cards_to_public
    AFTER INSERT OR UPDATE ON json.hand_cards
    FOR EACH ROW
    EXECUTE FUNCTION sync_json_hand_cards_to_public();

COMMENT ON FUNCTION sync_json_hand_cards_to_public() IS 'json.hand_cards → public.gfx_hand_cards 자동 동기화';

-- ----------------------------------------------------------------------------
-- 3.6 hand_results 동기화 트리거
-- json.hand_results → public.gfx_hand_results
-- ----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION sync_json_hand_results_to_public()
RETURNS TRIGGER AS $$
DECLARE
    v_hand_id UUID;
BEGIN
    -- session_id + hand_num으로 public.gfx_hands.id 조회
    SELECT id INTO v_hand_id
    FROM public.gfx_hands
    WHERE session_id = NEW.session_id
      AND hand_num = NEW.hand_number
    LIMIT 1;

    IF v_hand_id IS NULL THEN
        RAISE WARNING 'Hand not found for session_id=%, hand_number=%', NEW.session_id, NEW.hand_number;
        RETURN NEW;
    END IF;

    INSERT INTO public.gfx_hand_results (
        hand_id,
        seat_number,
        player_name,
        is_winner,
        won_amount,
        pot_contribution,
        hand_description,
        hand_rank,
        rank_value,
        best_five,
        showdown_order,
        created_at
    )
    VALUES (
        v_hand_id,
        NEW.seat_number,
        NEW.player_name,
        COALESCE(NEW.is_winner, FALSE),
        COALESCE(NEW.won_amount, 0),
        COALESCE(NEW.total_bet, 0),      -- total_bet → pot_contribution
        NEW.hand_description,
        NEW.hand_rank,
        NEW.rank_value,
        NEW.best_five_cards,             -- best_five_cards → best_five
        NEW.showdown_order,
        NOW()
    )
    ON CONFLICT (hand_id, seat_number, board_num) DO UPDATE SET
        player_name = EXCLUDED.player_name,
        is_winner = EXCLUDED.is_winner,
        won_amount = EXCLUDED.won_amount,
        pot_contribution = EXCLUDED.pot_contribution,
        hand_description = EXCLUDED.hand_description,
        hand_rank = EXCLUDED.hand_rank,
        rank_value = EXCLUDED.rank_value,
        best_five = EXCLUDED.best_five,
        showdown_order = EXCLUDED.showdown_order;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_sync_hand_results_to_public
    AFTER INSERT OR UPDATE ON json.hand_results
    FOR EACH ROW
    EXECUTE FUNCTION sync_json_hand_results_to_public();

COMMENT ON FUNCTION sync_json_hand_results_to_public() IS 'json.hand_results → public.gfx_hand_results 자동 동기화';

-- ============================================================================
-- 트리거 활성화/비활성화 유틸리티 함수
-- ============================================================================

CREATE OR REPLACE FUNCTION disable_json_sync_triggers()
RETURNS VOID AS $$
BEGIN
    ALTER TABLE json.gfx_sessions DISABLE TRIGGER trg_sync_gfx_sessions_to_public;
    ALTER TABLE json.hands DISABLE TRIGGER trg_sync_hands_to_public;
    ALTER TABLE json.hand_players DISABLE TRIGGER trg_sync_hand_players_to_public;
    ALTER TABLE json.hand_actions DISABLE TRIGGER trg_sync_hand_actions_to_public;
    ALTER TABLE json.hand_cards DISABLE TRIGGER trg_sync_hand_cards_to_public;
    ALTER TABLE json.hand_results DISABLE TRIGGER trg_sync_hand_results_to_public;
    RAISE NOTICE 'json → public sync triggers DISABLED';
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION enable_json_sync_triggers()
RETURNS VOID AS $$
BEGIN
    ALTER TABLE json.gfx_sessions ENABLE TRIGGER trg_sync_gfx_sessions_to_public;
    ALTER TABLE json.hands ENABLE TRIGGER trg_sync_hands_to_public;
    ALTER TABLE json.hand_players ENABLE TRIGGER trg_sync_hand_players_to_public;
    ALTER TABLE json.hand_actions ENABLE TRIGGER trg_sync_hand_actions_to_public;
    ALTER TABLE json.hand_cards ENABLE TRIGGER trg_sync_hand_cards_to_public;
    ALTER TABLE json.hand_results ENABLE TRIGGER trg_sync_hand_results_to_public;
    RAISE NOTICE 'json → public sync triggers ENABLED';
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION disable_json_sync_triggers() IS 'json → public 동기화 트리거 일시 비활성화 (벌크 마이그레이션 시)';
COMMENT ON FUNCTION enable_json_sync_triggers() IS 'json → public 동기화 트리거 재활성화';

-- ============================================================================
-- 완료 메시지
-- ============================================================================

DO $$
BEGIN
    RAISE NOTICE 'Migration completed: json → public sync triggers (Phase 3)';
    RAISE NOTICE '  - gfx_sessions: TRIGGER trg_sync_gfx_sessions_to_public';
    RAISE NOTICE '  - hands: TRIGGER trg_sync_hands_to_public';
    RAISE NOTICE '  - hand_players: TRIGGER trg_sync_hand_players_to_public';
    RAISE NOTICE '  - hand_actions: TRIGGER trg_sync_hand_actions_to_public';
    RAISE NOTICE '  - hand_cards: TRIGGER trg_sync_hand_cards_to_public';
    RAISE NOTICE '  - hand_results: TRIGGER trg_sync_hand_results_to_public';
    RAISE NOTICE '';
    RAISE NOTICE 'Utility functions:';
    RAISE NOTICE '  - SELECT disable_json_sync_triggers(); -- 트리거 비활성화';
    RAISE NOTICE '  - SELECT enable_json_sync_triggers();  -- 트리거 활성화';
END $$;
