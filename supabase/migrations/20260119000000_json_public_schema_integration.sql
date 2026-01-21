-- ============================================================================
-- Migration: json_public_schema_integration
-- Description: json 스키마 → public 스키마 통합 (Phase 1-2)
-- Version: 1.0.0
-- Date: 2026-01-19
-- PRD Reference: docs/02-GFX-JSON-DB.md Section 12
-- ============================================================================

-- ============================================================================
-- Phase 1: public 스키마 확장 (기존 테이블에 컬럼 추가)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1.1 gfx_hands 테이블 확장
-- json.hands 테이블의 필드를 public.gfx_hands에 추가
-- ----------------------------------------------------------------------------

ALTER TABLE public.gfx_hands ADD COLUMN IF NOT EXISTS
    grade CHAR(1) CHECK (grade IN ('A', 'B', 'C', 'D', 'F'));

ALTER TABLE public.gfx_hands ADD COLUMN IF NOT EXISTS
    is_premium BOOLEAN DEFAULT FALSE;

ALTER TABLE public.gfx_hands ADD COLUMN IF NOT EXISTS
    is_showdown BOOLEAN DEFAULT FALSE;

ALTER TABLE public.gfx_hands ADD COLUMN IF NOT EXISTS
    grade_factors JSONB DEFAULT '{}'::JSONB;

ALTER TABLE public.gfx_hands ADD COLUMN IF NOT EXISTS
    flop_cards JSONB;

ALTER TABLE public.gfx_hands ADD COLUMN IF NOT EXISTS
    turn_card VARCHAR(3);

ALTER TABLE public.gfx_hands ADD COLUMN IF NOT EXISTS
    river_card VARCHAR(3);

ALTER TABLE public.gfx_hands ADD COLUMN IF NOT EXISTS
    winning_hand VARCHAR(100);

ALTER TABLE public.gfx_hands ADD COLUMN IF NOT EXISTS
    winning_hand_rank VARCHAR(50);

ALTER TABLE public.gfx_hands ADD COLUMN IF NOT EXISTS
    winning_rank_value INTEGER;

-- 인덱스 추가
CREATE INDEX IF NOT EXISTS idx_gfx_hands_grade
    ON public.gfx_hands(grade) WHERE grade IN ('A', 'B');

CREATE INDEX IF NOT EXISTS idx_gfx_hands_premium
    ON public.gfx_hands(is_premium) WHERE is_premium = TRUE;

CREATE INDEX IF NOT EXISTS idx_gfx_hands_showdown
    ON public.gfx_hands(is_showdown) WHERE is_showdown = TRUE;

-- ----------------------------------------------------------------------------
-- 1.2 gfx_hand_players 테이블 확장
-- json.hand_players 테이블의 필드를 public.gfx_hand_players에 추가
-- ----------------------------------------------------------------------------

ALTER TABLE public.gfx_hand_players ADD COLUMN IF NOT EXISTS
    hole_cards_normalized VARCHAR(10);

ALTER TABLE public.gfx_hand_players ADD COLUMN IF NOT EXISTS
    hole_card_1 VARCHAR(3);

ALTER TABLE public.gfx_hand_players ADD COLUMN IF NOT EXISTS
    hole_card_2 VARCHAR(3);

ALTER TABLE public.gfx_hand_players ADD COLUMN IF NOT EXISTS
    hole_card_3 VARCHAR(3);

ALTER TABLE public.gfx_hand_players ADD COLUMN IF NOT EXISTS
    hole_card_4 VARCHAR(3);

ALTER TABLE public.gfx_hand_players ADD COLUMN IF NOT EXISTS
    hand_description VARCHAR(100);

ALTER TABLE public.gfx_hand_players ADD COLUMN IF NOT EXISTS
    hand_rank VARCHAR(50);

ALTER TABLE public.gfx_hand_players ADD COLUMN IF NOT EXISTS
    rank_value INTEGER;

ALTER TABLE public.gfx_hand_players ADD COLUMN IF NOT EXISTS
    won_amount NUMERIC(12,2) DEFAULT 0;

ALTER TABLE public.gfx_hand_players ADD COLUMN IF NOT EXISTS
    total_bet_amount NUMERIC(12,2) DEFAULT 0;

ALTER TABLE public.gfx_hand_players ADD COLUMN IF NOT EXISTS
    is_eliminated BOOLEAN DEFAULT FALSE;

-- 인덱스 추가
CREATE INDEX IF NOT EXISTS idx_gfx_hand_players_rank_value
    ON public.gfx_hand_players(rank_value) WHERE rank_value IS NOT NULL;

-- ----------------------------------------------------------------------------
-- 1.3 gfx_events 테이블 확장
-- json.hand_actions 테이블의 필드를 public.gfx_events에 추가
-- ----------------------------------------------------------------------------

ALTER TABLE public.gfx_events ADD COLUMN IF NOT EXISTS
    street VARCHAR(20);

ALTER TABLE public.gfx_events ADD COLUMN IF NOT EXISTS
    street_order INTEGER;

ALTER TABLE public.gfx_events ADD COLUMN IF NOT EXISTS
    action VARCHAR(20);

ALTER TABLE public.gfx_events ADD COLUMN IF NOT EXISTS
    player_name VARCHAR(255);

ALTER TABLE public.gfx_events ADD COLUMN IF NOT EXISTS
    raise_to_amount NUMERIC(12,2);

ALTER TABLE public.gfx_events ADD COLUMN IF NOT EXISTS
    pot_size_before NUMERIC(12,2);

ALTER TABLE public.gfx_events ADD COLUMN IF NOT EXISTS
    pot_size_after NUMERIC(12,2);

ALTER TABLE public.gfx_events ADD COLUMN IF NOT EXISTS
    cards_drawn JSONB;

ALTER TABLE public.gfx_events ADD COLUMN IF NOT EXISTS
    action_time TIMESTAMPTZ;

ALTER TABLE public.gfx_events ADD COLUMN IF NOT EXISTS
    time_to_act_seconds INTEGER;

-- 인덱스 추가
CREATE INDEX IF NOT EXISTS idx_gfx_events_street
    ON public.gfx_events(street) WHERE street IS NOT NULL;

-- ----------------------------------------------------------------------------
-- 1.4 gfx_sessions 테이블 확장
-- json.gfx_sessions 테이블의 필드를 public.gfx_sessions에 추가
-- ----------------------------------------------------------------------------

ALTER TABLE public.gfx_sessions ADD COLUMN IF NOT EXISTS
    grade_summary JSONB DEFAULT '{}'::JSONB;

ALTER TABLE public.gfx_sessions ADD COLUMN IF NOT EXISTS
    premium_hands_count INTEGER DEFAULT 0;

ALTER TABLE public.gfx_sessions ADD COLUMN IF NOT EXISTS
    avg_hand_duration INTERVAL;

ALTER TABLE public.gfx_sessions ADD COLUMN IF NOT EXISTS
    import_status VARCHAR(30) DEFAULT 'complete';

ALTER TABLE public.gfx_sessions ADD COLUMN IF NOT EXISTS
    import_errors JSONB DEFAULT '[]'::JSONB;

-- ============================================================================
-- Phase 2: 신규 테이블 추가
-- json 스키마 전용 테이블을 public 스키마에 생성
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 2.1 gfx_hand_cards 테이블 생성
-- json.hand_cards 테이블 대응
-- ----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS public.gfx_hand_cards (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    hand_id UUID NOT NULL REFERENCES public.gfx_hands(id) ON DELETE CASCADE,

    -- 카드 정보
    card_rank VARCHAR(2) NOT NULL,
    card_suit CHAR(1) NOT NULL CHECK (card_suit IN ('h', 'd', 'c', 's')),
    card_normalized VARCHAR(3) GENERATED ALWAYS AS (card_rank || card_suit) STORED,

    -- 카드 유형
    card_type VARCHAR(20) NOT NULL CHECK (card_type IN ('hole', 'flop', 'turn', 'river', 'draw')),

    -- 위치 정보
    seat_number INTEGER CHECK (seat_number BETWEEN 1 AND 10),
    card_order INTEGER,
    board_num INTEGER DEFAULT 0,

    -- 원본 정보
    gfx_card VARCHAR(10),  -- 원본 형식 (10d)
    source VARCHAR(20) DEFAULT 'gfx',  -- gfx, manual, ai
    confidence NUMERIC(3,2) DEFAULT 1.0,

    -- 타임스탬프
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 인덱스
CREATE INDEX IF NOT EXISTS idx_gfx_hand_cards_hand
    ON public.gfx_hand_cards(hand_id);

CREATE INDEX IF NOT EXISTS idx_gfx_hand_cards_type
    ON public.gfx_hand_cards(hand_id, card_type);

CREATE INDEX IF NOT EXISTS idx_gfx_hand_cards_seat
    ON public.gfx_hand_cards(hand_id, seat_number)
    WHERE seat_number IS NOT NULL;

-- 복합 유니크 제약 (같은 핸드, 같은 카드 타입, 같은 순서)
CREATE UNIQUE INDEX IF NOT EXISTS uq_gfx_hand_cards_position
    ON public.gfx_hand_cards(hand_id, card_type, card_order, COALESCE(seat_number, 0), board_num);

-- 코멘트
COMMENT ON TABLE public.gfx_hand_cards IS 'Individual cards (community + hole cards) - json.hand_cards 대응';
COMMENT ON COLUMN public.gfx_hand_cards.card_type IS 'Card type: hole, flop, turn, river, draw';
COMMENT ON COLUMN public.gfx_hand_cards.gfx_card IS 'Original GFX format: 10d (10 instead of T)';
COMMENT ON COLUMN public.gfx_hand_cards.source IS 'Data source: gfx (auto), manual (override), ai (vision)';

-- ----------------------------------------------------------------------------
-- 2.2 gfx_hand_results 테이블 생성
-- json.hand_results 테이블 대응
-- ----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS public.gfx_hand_results (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    hand_id UUID NOT NULL REFERENCES public.gfx_hands(id) ON DELETE CASCADE,

    -- 플레이어 정보
    seat_number INTEGER NOT NULL CHECK (seat_number BETWEEN 1 AND 10),
    player_name VARCHAR(255),

    -- 결과 정보
    is_winner BOOLEAN NOT NULL DEFAULT FALSE,
    won_amount NUMERIC(12,2) DEFAULT 0,
    pot_contribution NUMERIC(12,2) DEFAULT 0,
    net_result NUMERIC(12,2) GENERATED ALWAYS AS (won_amount - pot_contribution) STORED,

    -- 핸드 랭크 정보
    hand_description VARCHAR(100),
    hand_rank VARCHAR(50),
    rank_value INTEGER,  -- phevaluator: 1 (best) to 7462 (worst)

    -- 카드 정보
    kickers JSONB,
    cards_used JSONB,
    best_five JSONB,

    -- 팟 분배
    board_num INTEGER DEFAULT 0,  -- 0: single board, 1+: Run It Twice/Thrice
    main_pot_won NUMERIC(12,2),
    side_pot_won NUMERIC(12,2),
    showdown_order INTEGER,

    -- 타임스탬프
    created_at TIMESTAMPTZ DEFAULT NOW(),

    -- 복합 유니크 제약
    CONSTRAINT uq_gfx_hand_results UNIQUE (hand_id, seat_number, board_num)
);

-- 인덱스
CREATE INDEX IF NOT EXISTS idx_gfx_hand_results_hand
    ON public.gfx_hand_results(hand_id);

CREATE INDEX IF NOT EXISTS idx_gfx_hand_results_winner
    ON public.gfx_hand_results(is_winner) WHERE is_winner = TRUE;

CREATE INDEX IF NOT EXISTS idx_gfx_hand_results_rank
    ON public.gfx_hand_results(rank_value) WHERE rank_value IS NOT NULL;

-- 코멘트
COMMENT ON TABLE public.gfx_hand_results IS 'Final hand results per player per board - json.hand_results 대응';
COMMENT ON COLUMN public.gfx_hand_results.rank_value IS 'phevaluator: 1 (Royal Flush) to 7462 (7-5-4-3-2 high)';
COMMENT ON COLUMN public.gfx_hand_results.board_num IS '0 for single board, 1+ for Run It Twice/Thrice';
COMMENT ON COLUMN public.gfx_hand_results.best_five IS 'Best 5-card hand: ["As", "Ks", "Qs", "Js", "Ts"]';

-- ============================================================================
-- RLS 정책 설정
-- ============================================================================

-- gfx_hand_cards RLS
ALTER TABLE public.gfx_hand_cards ENABLE ROW LEVEL SECURITY;

CREATE POLICY "gfx_hand_cards_select_authenticated"
    ON public.gfx_hand_cards FOR SELECT
    USING (auth.role() = 'authenticated');

CREATE POLICY "gfx_hand_cards_insert_service"
    ON public.gfx_hand_cards FOR INSERT
    WITH CHECK (auth.role() = 'service_role');

CREATE POLICY "gfx_hand_cards_update_service"
    ON public.gfx_hand_cards FOR UPDATE
    USING (auth.role() = 'service_role');

CREATE POLICY "gfx_hand_cards_delete_service"
    ON public.gfx_hand_cards FOR DELETE
    USING (auth.role() = 'service_role');

-- gfx_hand_results RLS
ALTER TABLE public.gfx_hand_results ENABLE ROW LEVEL SECURITY;

CREATE POLICY "gfx_hand_results_select_authenticated"
    ON public.gfx_hand_results FOR SELECT
    USING (auth.role() = 'authenticated');

CREATE POLICY "gfx_hand_results_insert_service"
    ON public.gfx_hand_results FOR INSERT
    WITH CHECK (auth.role() = 'service_role');

CREATE POLICY "gfx_hand_results_update_service"
    ON public.gfx_hand_results FOR UPDATE
    USING (auth.role() = 'service_role');

CREATE POLICY "gfx_hand_results_delete_service"
    ON public.gfx_hand_results FOR DELETE
    USING (auth.role() = 'service_role');

-- ============================================================================
-- 완료 메시지
-- ============================================================================

DO $$
BEGIN
    RAISE NOTICE 'Migration completed: json → public schema integration (Phase 1-2)';
    RAISE NOTICE '  - gfx_hands: 11 columns added (grade, is_premium, flop_cards, etc.)';
    RAISE NOTICE '  - gfx_hand_players: 12 columns added (hole_cards_normalized, rank_value, etc.)';
    RAISE NOTICE '  - gfx_events: 10 columns added (street, action, pot_size_before, etc.)';
    RAISE NOTICE '  - gfx_sessions: 5 columns added (grade_summary, premium_hands_count, etc.)';
    RAISE NOTICE '  - gfx_hand_cards: NEW TABLE created';
    RAISE NOTICE '  - gfx_hand_results: NEW TABLE created';
END $$;
