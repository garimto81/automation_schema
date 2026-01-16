-- ============================================================================
-- Migration: gfx_aep_render_mapping
-- Description: GFX JSON DB → AEP 컴포지션 렌더링 매핑 시스템
-- Version: 1.0.0
-- Date: 2026-01-14
-- Reference: GFX_AEP_FIELD_MAPPING.md
-- ============================================================================

-- ============================================================================
-- ENUM Types (IF NOT EXISTS 패턴)
-- ============================================================================

-- AEP 컴포지션 카테고리
DO $$ BEGIN
    CREATE TYPE aep_composition_category AS ENUM (
        'chip_display',      -- 칩 표시 (7개)
        'payout',            -- 상금표 (3개)
        'event_info',        -- 이벤트 정보 (5개)
        'schedule',          -- 방송 일정 (1개)
        'staff',             -- 스태프 (2개)
        'player_info',       -- 플레이어 정보 (4개)
        'elimination',       -- 탈락 (2개)
        'transition',        -- 전환 화면 (2개)
        'other'              -- 기타
    );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- 변환 함수 타입
DO $$ BEGIN
    CREATE TYPE aep_transform_type AS ENUM (
        'UPPER',             -- 대문자 변환
        'LOWER',             -- 소문자 변환
        'format_chips',      -- 칩 포맷 (1,500,000)
        'format_bbs',        -- BB 포맷 (75.0)
        'format_currency',   -- 통화 포맷 ($1,000,000)
        'format_date',       -- 날짜 포맷 (Jan 14)
        'format_time',       -- 시간 포맷 (05:30 PM)
        'format_percent',    -- 퍼센트 포맷 (45.5%)
        'format_number',     -- 숫자 포맷 (1,234)
        'get_flag_path',     -- 국기 경로 (Flag/Korea.png)
        'direct',            -- 변환 없음
        'custom'             -- 커스텀 변환
    );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- ============================================================================
-- Tables (IF NOT EXISTS 패턴 - 부분 적용 대응)
-- ============================================================================

-- ============================================================================
-- gfx_aep_field_mappings: GFX 데이터 → AEP 컴포지션 필드 매핑 규칙
-- ============================================================================

CREATE TABLE IF NOT EXISTS gfx_aep_field_mappings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- 컴포지션 식별
    composition_name VARCHAR(255) NOT NULL,
    composition_category aep_composition_category NOT NULL,

    -- 타겟 필드 정보
    target_field_key VARCHAR(100) NOT NULL,      -- AEP 레이어 필드 키 (name, chips, rank)
    target_layer_pattern VARCHAR(255),           -- 레이어 이름 패턴 ("Name {slot}", "chips")

    -- 슬롯 범위 (슬롯 기반 필드인 경우)
    slot_range_start INTEGER,                    -- 슬롯 시작 인덱스 (1-based)
    slot_range_end INTEGER,                      -- 슬롯 끝 인덱스

    -- 데이터 소스
    source_table VARCHAR(100) NOT NULL,          -- gfx_hand_players, wsop_events, manual_*
    source_column VARCHAR(100) NOT NULL,         -- player_name, end_stack_amt, payouts
    source_join TEXT,                            -- 추가 JOIN 조건
    source_filter TEXT,                          -- WHERE 조건 (sitting_out = FALSE)

    -- 변환 함수
    transform aep_transform_type DEFAULT 'direct',
    transform_params JSONB,                      -- 변환 파라미터 ({"decimals": 1})

    -- 슬롯 정렬
    slot_order_by VARCHAR(100),                  -- end_stack_amt DESC
    slot_order_direction VARCHAR(10) DEFAULT 'ASC',

    -- 기본값 (NULL인 경우)
    default_value TEXT DEFAULT '',

    -- 우선순위 (동일 필드에 여러 소스가 있을 때)
    priority INTEGER DEFAULT 100,

    -- 활성화
    is_active BOOLEAN DEFAULT TRUE,

    -- 메타데이터
    notes TEXT,

    -- 타임스탬프
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 복합 유니크 인덱스 (COALESCE 사용을 위해 INDEX로 정의)
CREATE UNIQUE INDEX IF NOT EXISTS uq_gfx_aep_mapping
    ON gfx_aep_field_mappings(composition_name, target_field_key, COALESCE(slot_range_start, 0));

-- ============================================================================
-- gfx_aep_compositions: AEP 컴포지션 메타데이터
-- ============================================================================

CREATE TABLE IF NOT EXISTS gfx_aep_compositions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- 컴포지션 정보
    name VARCHAR(255) NOT NULL UNIQUE,
    category aep_composition_category NOT NULL,
    display_name VARCHAR(255),
    description TEXT,

    -- 슬롯 정보
    slot_count INTEGER DEFAULT 0,                -- 슬롯 개수 (0이면 단일 필드)
    slot_field_keys TEXT[],                      -- 슬롯별 필드 키 배열 ['name', 'chips', 'bbs']

    -- 단일 필드
    single_field_keys TEXT[],                    -- 단일 필드 키 배열 ['wsop_super_circuit_cyprus']

    -- AEP 프로젝트 정보
    aep_project_path TEXT,                       -- AEP 파일 경로
    aep_comp_name TEXT,                          -- AEP 내 컴포지션 이름

    -- 렌더링 설정
    default_output_format VARCHAR(20) DEFAULT 'mp4',
    default_duration_seconds NUMERIC(10,2),

    -- 메타데이터
    metadata JSONB DEFAULT '{}'::JSONB,

    -- 활성화
    is_active BOOLEAN DEFAULT TRUE,

    -- 타임스탬프
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================================
-- SQL 변환 함수
-- ============================================================================

-- ============================================================================
-- format_chips: 칩 포맷팅
-- 1500000 → "1,500,000"
-- ============================================================================

CREATE OR REPLACE FUNCTION format_chips(amount BIGINT)
RETURNS TEXT AS $$
BEGIN
    IF amount IS NULL THEN
        RETURN '';
    END IF;
    RETURN TO_CHAR(amount, 'FM999,999,999,999');
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- ============================================================================
-- format_chips_safe: NULL 안전 칩 포맷팅
-- ============================================================================

CREATE OR REPLACE FUNCTION format_chips_safe(amount BIGINT)
RETURNS TEXT AS $$
BEGIN
    IF amount IS NULL OR amount < 0 THEN
        RETURN '';
    END IF;
    RETURN TO_CHAR(amount, 'FM999,999,999,999');
EXCEPTION
    WHEN OTHERS THEN
        RETURN '';
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- ============================================================================
-- format_chips_short: 짧은 칩 포맷
-- 1500000 → "1.5M", 20000 → "20K"
-- ============================================================================

CREATE OR REPLACE FUNCTION format_chips_short(amount BIGINT)
RETURNS TEXT AS $$
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
$$ LANGUAGE plpgsql IMMUTABLE;

-- ============================================================================
-- format_bbs: BB 포맷팅
-- (1500000, 20000) → "75.0"
-- ============================================================================

CREATE OR REPLACE FUNCTION format_bbs(chips BIGINT, bb BIGINT)
RETURNS TEXT AS $$
BEGIN
    IF chips IS NULL OR bb IS NULL OR bb = 0 THEN
        RETURN '';
    END IF;
    RETURN TO_CHAR(chips::NUMERIC / bb, 'FM999,999.9');
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- ============================================================================
-- format_bbs_safe: NULL 안전 BB 포맷팅
-- ============================================================================

CREATE OR REPLACE FUNCTION format_bbs_safe(chips BIGINT, bb BIGINT)
RETURNS TEXT AS $$
BEGIN
    IF chips IS NULL OR bb IS NULL OR bb = 0 THEN
        RETURN '';
    END IF;
    RETURN TO_CHAR(chips::NUMERIC / bb, 'FM999,999.9');
EXCEPTION
    WHEN OTHERS THEN
        RETURN '';
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- ============================================================================
-- format_currency: 통화 포맷팅 (cents → dollars)
-- 100000000 → "$1,000,000"
-- ============================================================================

CREATE OR REPLACE FUNCTION format_currency(amount BIGINT)
RETURNS TEXT AS $$
BEGIN
    IF amount IS NULL THEN
        RETURN '$0';
    END IF;
    RETURN '$' || TO_CHAR(amount / 100, 'FM999,999,999');
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- ============================================================================
-- format_currency_from_int: 정수 통화 포맷팅 (dollars 단위)
-- 1000000 → "$1,000,000"
-- ============================================================================

CREATE OR REPLACE FUNCTION format_currency_from_int(amount BIGINT)
RETURNS TEXT AS $$
BEGIN
    IF amount IS NULL THEN
        RETURN '$0';
    END IF;
    RETURN '$' || TO_CHAR(amount, 'FM999,999,999');
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- ============================================================================
-- format_currency_safe: NULL 안전 통화 포맷팅
-- ============================================================================

CREATE OR REPLACE FUNCTION format_currency_safe(amount BIGINT)
RETURNS TEXT AS $$
BEGIN
    IF amount IS NULL THEN
        RETURN '$0';
    END IF;
    RETURN '$' || TO_CHAR(amount / 100, 'FM999,999,999');
EXCEPTION
    WHEN OTHERS THEN
        RETURN '$0';
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- ============================================================================
-- format_date_short: 짧은 날짜 포맷팅
-- 2026-01-14 → "Jan 14"
-- ============================================================================

CREATE OR REPLACE FUNCTION format_date_short(d DATE)
RETURNS TEXT AS $$
BEGIN
    IF d IS NULL THEN
        RETURN '';
    END IF;
    RETURN TO_CHAR(d, 'Mon DD');
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- ============================================================================
-- format_time_12h: 12시간제 시간 포맷팅
-- 17:30:00 → "05:30 PM"
-- ============================================================================

CREATE OR REPLACE FUNCTION format_time_12h(t TIME)
RETURNS TEXT AS $$
BEGIN
    IF t IS NULL THEN
        RETURN '';
    END IF;
    RETURN TO_CHAR(t, 'HH:MI AM');
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- ============================================================================
-- format_blinds: 블라인드 포맷팅
-- (10000, 20000, 20000) → "10K/20K (20K)"
-- ============================================================================

CREATE OR REPLACE FUNCTION format_blinds(sb BIGINT, bb BIGINT, ante BIGINT DEFAULT 0)
RETURNS TEXT AS $$
BEGIN
    IF sb IS NULL OR bb IS NULL THEN
        RETURN '';
    END IF;

    RETURN format_chips_short(sb) || '/' || format_chips_short(bb) ||
           CASE WHEN COALESCE(ante, 0) > 0
                THEN ' (' || format_chips_short(ante) || ')'
                ELSE ''
           END;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- ============================================================================
-- format_percent: 퍼센트 포맷팅
-- 0.455 → "45.5%"
-- ============================================================================

CREATE OR REPLACE FUNCTION format_percent(value NUMERIC)
RETURNS TEXT AS $$
BEGIN
    IF value IS NULL THEN
        RETURN '';
    END IF;
    RETURN ROUND(value * 100, 1)::TEXT || '%';
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- ============================================================================
-- format_number: 숫자 포맷팅
-- 1234 → "1,234"
-- ============================================================================

CREATE OR REPLACE FUNCTION format_number(num BIGINT)
RETURNS TEXT AS $$
BEGIN
    IF num IS NULL THEN
        RETURN '';
    END IF;
    RETURN TO_CHAR(num, 'FM999,999,999');
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- ============================================================================
-- get_flag_path: 국기 이미지 경로
-- "KR" → "Flag/Korea.png"
-- ============================================================================

CREATE OR REPLACE FUNCTION get_flag_path(country_code VARCHAR)
RETURNS TEXT AS $$
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
$$ LANGUAGE plpgsql IMMUTABLE;

-- ============================================================================
-- normalize_player_name: 플레이어 이름 정규화 (검색용)
-- "Phil Ivey" → "phil ivey"
-- ============================================================================

CREATE OR REPLACE FUNCTION normalize_player_name(p_name TEXT)
RETURNS TEXT AS $$
BEGIN
    IF p_name IS NULL THEN
        RETURN '';
    END IF;
    RETURN LOWER(TRIM(p_name));
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- ============================================================================
-- 렌더링 뷰: v_render_chip_display
-- _MAIN/_SUB Mini Chip Count 컴포지션용 데이터
-- 플레이어 정보는 player_link_mapping → manual_players 연결로 오버라이드
-- ============================================================================

CREATE OR REPLACE VIEW v_render_chip_display AS
SELECT
    gs.session_id,
    gh.hand_num,
    ROW_NUMBER() OVER (
        PARTITION BY gs.session_id, gh.hand_num
        ORDER BY ghp.end_stack_amt DESC
    ) AS slot_index,
    -- 이름: manual_players 우선, 없으면 gfx_players 원본
    UPPER(COALESCE(
        mp.name_display,
        mp.name,
        ghp.player_name
    )) AS name,
    format_chips(ghp.end_stack_amt) AS chips,
    format_bbs(ghp.end_stack_amt, (gh.blinds->>'big_blind_amt')::BIGINT) AS bbs,
    (ROW_NUMBER() OVER (
        PARTITION BY gs.session_id, gh.hand_num
        ORDER BY ghp.end_stack_amt DESC
    ))::TEXT AS rank,
    -- 국기: manual_players 우선, 없으면 Unknown
    get_flag_path(COALESCE(mp.country_code, 'XX')) AS flag,
    ghp.vpip_percent,
    ghp.end_stack_amt AS raw_chips,
    (gh.blinds->>'big_blind_amt')::BIGINT AS big_blind
FROM gfx_hand_players ghp
JOIN gfx_hands gh ON ghp.hand_id = gh.id
JOIN gfx_sessions gs ON gh.session_id = gs.session_id
-- GFX 플레이어 → player_link_mapping → manual_players 조인
LEFT JOIN gfx_players gp ON ghp.player_id = gp.id
LEFT JOIN player_link_mapping plm ON plm.gfx_player_id = gp.id AND plm.is_verified = TRUE
LEFT JOIN manual_players mp ON plm.manual_player_id = mp.id
WHERE ghp.sitting_out = FALSE
ORDER BY gs.session_id, gh.hand_num, ghp.end_stack_amt DESC;

-- ============================================================================
-- 렌더링 뷰: v_render_payout
-- Payouts 컴포지션용 데이터
-- ============================================================================

CREATE OR REPLACE VIEW v_render_payout AS
SELECT
    e.id AS event_id,
    (payout->>'place')::INTEGER AS slot_index,
    (payout->>'place')::TEXT AS rank,
    format_currency((payout->>'amount')::BIGINT) AS prize,
    (payout->>'amount')::BIGINT AS raw_amount
FROM wsop_events e
CROSS JOIN LATERAL jsonb_array_elements(e.payouts) AS payout
ORDER BY e.id, (payout->>'place')::INTEGER;

-- ============================================================================
-- 렌더링 뷰: v_render_payout_gfx
-- _Mini Payout 컴포지션용 데이터 (GFX 세션 기반)
-- ============================================================================

CREATE OR REPLACE VIEW v_render_payout_gfx AS
SELECT
    gs.session_id,
    idx AS slot_index,
    idx::TEXT AS rank,
    format_currency_from_int(payout_amount) AS prize,
    payout_amount AS raw_amount
FROM gfx_sessions gs
CROSS JOIN LATERAL unnest(gs.payouts) WITH ORDINALITY AS t(payout_amount, idx)
ORDER BY gs.session_id, idx;

-- ============================================================================
-- 렌더링 뷰: v_render_elimination
-- Elimination 컴포지션용 데이터
-- ============================================================================

CREATE OR REPLACE VIEW v_render_elimination AS
SELECT
    gs.session_id,
    gh.hand_num,
    -- 이름: manual_players 우선
    UPPER(COALESCE(mp.name_display, mp.name, ghp.player_name)) AS name,
    ghp.elimination_rank AS rank,
    COALESCE(
        format_currency_from_int(gs.payouts[ghp.elimination_rank]),
        '$0'
    ) AS prize,
    -- 국기: manual_players 우선
    get_flag_path(COALESCE(mp.country_code, 'XX')) AS flag
FROM gfx_hand_players ghp
JOIN gfx_hands gh ON ghp.hand_id = gh.id
JOIN gfx_sessions gs ON gh.session_id = gs.session_id
-- GFX 플레이어 → player_link_mapping → manual_players 조인
LEFT JOIN gfx_players gp ON ghp.player_id = gp.id
LEFT JOIN player_link_mapping plm ON plm.gfx_player_id = gp.id AND plm.is_verified = TRUE
LEFT JOIN manual_players mp ON plm.manual_player_id = mp.id
WHERE ghp.elimination_rank > 0
ORDER BY gs.session_id, gh.hand_num, ghp.elimination_rank DESC;

-- ============================================================================
-- 렌더링 함수: get_chip_display_data
-- 특정 세션/핸드의 칩 디스플레이 데이터를 JSON으로 반환
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
    -- 슬롯 데이터 조회
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

    -- 평균 스택 계산
    SELECT AVG(raw_chips), MAX(big_blind)
    INTO v_avg_stack, v_big_blind
    FROM v_render_chip_display
    WHERE session_id = p_session_id
      AND hand_num = p_hand_num;

    -- 결과 JSON 생성
    v_result := jsonb_build_object(
        '$schema', 'render_gfx_data_v2',
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
            'data_sources', ARRAY['gfx_hand_players', 'gfx_hands', 'gfx_sessions'],
            'generated_at', NOW()
        )
    );

    RETURN v_result;
END;
$$ LANGUAGE plpgsql STABLE;

-- ============================================================================
-- 렌더링 함수: get_payout_data
-- 특정 이벤트의 상금표 데이터를 JSON으로 반환
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

    -- 결과 JSON 생성
    v_result := jsonb_build_object(
        '$schema', 'render_gfx_data_v2',
        'comp_name', 'Payouts',
        'render_type', 'payout',
        'slots', COALESCE(v_slots, '[]'::JSONB),
        'single_fields', jsonb_build_object(
            'wsop_super_circuit_cyprus', '2025 WSOP SUPER CIRCUIT CYPRUS',
            'payouts', 'PAYOUTS',
            'total_prize', format_currency(v_total_prize)
        ),
        'metadata', jsonb_build_object(
            'event_id', p_event_id,
            'event_name', v_event_name,
            'data_sources', ARRAY['wsop_events'],
            'generated_at', NOW()
        )
    );

    RETURN v_result;
END;
$$ LANGUAGE plpgsql STABLE;

-- ============================================================================
-- Indexes (IF NOT EXISTS 패턴)
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_gfx_aep_mapping_comp ON gfx_aep_field_mappings(composition_name);
CREATE INDEX IF NOT EXISTS idx_gfx_aep_mapping_category ON gfx_aep_field_mappings(composition_category);
CREATE INDEX IF NOT EXISTS idx_gfx_aep_mapping_active ON gfx_aep_field_mappings(is_active) WHERE is_active = TRUE;
CREATE INDEX IF NOT EXISTS idx_gfx_aep_mapping_source ON gfx_aep_field_mappings(source_table);

CREATE INDEX IF NOT EXISTS idx_gfx_aep_comp_name ON gfx_aep_compositions(name);
CREATE INDEX IF NOT EXISTS idx_gfx_aep_comp_category ON gfx_aep_compositions(category);
CREATE INDEX IF NOT EXISTS idx_gfx_aep_comp_active ON gfx_aep_compositions(is_active) WHERE is_active = TRUE;

-- ============================================================================
-- Triggers (DROP IF EXISTS + CREATE 패턴)
-- ============================================================================

-- updated_at 자동 업데이트
DROP TRIGGER IF EXISTS trigger_gfx_aep_mapping_updated_at ON gfx_aep_field_mappings;
CREATE TRIGGER trigger_gfx_aep_mapping_updated_at
    BEFORE UPDATE ON gfx_aep_field_mappings
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS trigger_gfx_aep_comp_updated_at ON gfx_aep_compositions;
CREATE TRIGGER trigger_gfx_aep_comp_updated_at
    BEFORE UPDATE ON gfx_aep_compositions
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- RLS Policies (DROP IF EXISTS + CREATE 패턴)
-- ============================================================================

ALTER TABLE gfx_aep_field_mappings ENABLE ROW LEVEL SECURITY;
ALTER TABLE gfx_aep_compositions ENABLE ROW LEVEL SECURITY;

-- 읽기 권한 (authenticated)
DROP POLICY IF EXISTS "gfx_aep_mapping_select_authenticated" ON gfx_aep_field_mappings;
CREATE POLICY "gfx_aep_mapping_select_authenticated"
    ON gfx_aep_field_mappings FOR SELECT
    USING (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "gfx_aep_comp_select_authenticated" ON gfx_aep_compositions;
CREATE POLICY "gfx_aep_comp_select_authenticated"
    ON gfx_aep_compositions FOR SELECT
    USING (auth.role() = 'authenticated');

-- 전체 권한 (service_role)
DROP POLICY IF EXISTS "gfx_aep_mapping_all_service" ON gfx_aep_field_mappings;
CREATE POLICY "gfx_aep_mapping_all_service"
    ON gfx_aep_field_mappings FOR ALL
    USING (auth.role() = 'service_role');

DROP POLICY IF EXISTS "gfx_aep_comp_all_service" ON gfx_aep_compositions;
CREATE POLICY "gfx_aep_comp_all_service"
    ON gfx_aep_compositions FOR ALL
    USING (auth.role() = 'service_role');

-- ============================================================================
-- Initial Data: 26개 컴포지션 메타데이터 (ON CONFLICT DO NOTHING 패턴)
-- ============================================================================

INSERT INTO gfx_aep_compositions (name, category, display_name, slot_count, slot_field_keys, single_field_keys) VALUES
-- chip_display (7개)
('_MAIN Mini Chip Count', 'chip_display', 'Main Chip Count', 9, ARRAY['name', 'chips', 'bbs', 'rank', 'flag'], ARRAY['AVERAGE STACK']),
('_SUB_Mini Chip Count', 'chip_display', 'Sub Chip Count', 9, ARRAY['name', 'chips', 'bbs', 'rank', 'flag'], NULL),
('Chips In Play x3', 'chip_display', 'Chips In Play (3 Players)', 3, ARRAY['chips_in_play', 'fee'], ARRAY['level']),
('Chips In Play x4', 'chip_display', 'Chips In Play (4 Players)', 4, ARRAY['chips_in_play', 'fee'], ARRAY['level']),
('Chip Comparison', 'chip_display', 'Chip Comparison', 0, NULL, ARRAY['selected_player_percent', 'others_percent']),
('Chip Flow', 'chip_display', 'Chip Flow Graph', 0, NULL, ARRAY['player_name', 'max_label', 'min_label']),
('Chip VPIP', 'chip_display', 'Chip VPIP', 0, NULL, ARRAY['vpip', 'player_name']),

-- payout (3개)
('Payouts', 'payout', 'Payouts (9 Places)', 9, ARRAY['rank', 'prize'], ARRAY['wsop_super_circuit_cyprus', 'payouts', 'total_prize']),
('Payouts 등수 바꾸기 가능', 'payout', 'Payouts (11 Places)', 11, ARRAY['rank', 'prize'], ARRAY['wsop_super_circuit_cyprus', 'payouts']),
('_Mini Payout', 'payout', 'Mini Payout', 9, ARRAY['name', 'chips', 'rank', 'prize'], NULL),

-- event_info (5개)
('Block Transition INFO', 'event_info', 'Block Transition', 0, NULL, ARRAY['text_제목', 'text_내용_2줄']),
('Event info', 'event_info', 'Event Information', 0, NULL, ARRAY['event_info', 'wsop_super_circuit_cyprus', 'buy-in', 'total_prize_pool', 'entrants', 'places_paid']),
('Event name', 'event_info', 'Event Name', 0, NULL, ARRAY['main_event_final_day', 'wsop_super_circuit_cyprus']),
('Location', 'event_info', 'Location', 0, NULL, ARRAY['merit_royal_diamond_hotel']),
('Chips (Source Comp)', 'event_info', 'Chips Source', 0, NULL, ARRAY['chip']),

-- schedule (1개)
('Broadcast Schedule', 'schedule', 'Broadcast Schedule', 6, ARRAY['date', 'time', 'event_name'], ARRAY['broadcast_schedule', 'wsop_super_circuit_cyprus']),

-- staff (2개)
('Commentator', 'staff', 'Commentators', 2, ARRAY['name', 'sub'], ARRAY['commentary', 'text_제목']),
('Reporter', 'staff', 'Reporters', 2, ARRAY['name', 'sub'], ARRAY['text_제목']),

-- player_info (4개)
('NAME', 'player_info', 'Player Name (with Flag)', 0, NULL, ARRAY['name', 'text_내용']),
('NAME 1줄', 'player_info', 'Player Name (1 Line)', 0, NULL, ARRAY['player_name']),
('NAME 2줄 (국기 빼고)', 'player_info', 'Player Name (2 Lines)', 0, NULL, ARRAY['player_name']),
('NAME 3줄+', 'player_info', 'Player Name (3+ Lines)', 0, NULL, ARRAY['player_name']),

-- elimination (2개)
('Elimination', 'elimination', 'Elimination', 2, ARRAY['name', 'rank', 'prize', 'flag'], ARRAY['text_제목']),
('At Risk of Elimination', 'elimination', 'At Risk', 0, NULL, ARRAY['text_내용']),

-- transition (2개)
('1-NEXT STREAM STARTING SOON', 'transition', 'Stream Starting Soon', 0, NULL, ARRAY['wsop_vlogger_program']),
('Block Transition Level-Blinds', 'transition', 'Level/Blinds Transition', 0, NULL, ARRAY['level', 'blinds', 'duration'])
ON CONFLICT (name) DO NOTHING;

-- ============================================================================
-- Initial Data: 주요 컴포지션 필드 매핑 규칙 (ON CONFLICT DO NOTHING 패턴)
-- ============================================================================

-- _MAIN Mini Chip Count 매핑
INSERT INTO gfx_aep_field_mappings (composition_name, composition_category, target_field_key, slot_range_start, slot_range_end, source_table, source_column, transform, slot_order_by, source_filter, default_value) VALUES
('_MAIN Mini Chip Count', 'chip_display', 'name', 1, 9, 'gfx_hand_players', 'player_name', 'UPPER', 'end_stack_amt DESC', 'sitting_out = FALSE', ''),
('_MAIN Mini Chip Count', 'chip_display', 'chips', 1, 9, 'gfx_hand_players', 'end_stack_amt', 'format_chips', 'end_stack_amt DESC', 'sitting_out = FALSE', ''),
('_MAIN Mini Chip Count', 'chip_display', 'bbs', 1, 9, 'gfx_hand_players', 'end_stack_amt', 'format_bbs', 'end_stack_amt DESC', 'sitting_out = FALSE', ''),
('_MAIN Mini Chip Count', 'chip_display', 'rank', 1, 9, 'gfx_hand_players', 'ROW_NUMBER()', 'direct', 'end_stack_amt DESC', 'sitting_out = FALSE', ''),
('_MAIN Mini Chip Count', 'chip_display', 'flag', 1, 9, 'player_overrides', 'country_code', 'get_flag_path', 'end_stack_amt DESC', NULL, 'Flag/Unknown.png')
ON CONFLICT DO NOTHING;

-- Payouts 매핑
INSERT INTO gfx_aep_field_mappings (composition_name, composition_category, target_field_key, slot_range_start, slot_range_end, source_table, source_column, transform, slot_order_by, default_value) VALUES
('Payouts', 'payout', 'rank', 1, 9, 'wsop_events', 'payouts->place', 'direct', 'place ASC', '-'),
('Payouts', 'payout', 'prize', 1, 9, 'wsop_events', 'payouts->amount', 'format_currency', 'place ASC', '$0')
ON CONFLICT DO NOTHING;

-- Broadcast Schedule 매핑
INSERT INTO gfx_aep_field_mappings (composition_name, composition_category, target_field_key, slot_range_start, slot_range_end, source_table, source_column, transform, slot_order_by, default_value) VALUES
('Broadcast Schedule', 'schedule', 'date', 1, 6, 'broadcast_sessions', 'broadcast_date', 'format_date', 'broadcast_date ASC', ''),
('Broadcast Schedule', 'schedule', 'time', 1, 6, 'broadcast_sessions', 'scheduled_start', 'format_time', 'broadcast_date ASC', ''),
('Broadcast Schedule', 'schedule', 'event_name', 1, 6, 'broadcast_sessions', 'event_name', 'direct', 'broadcast_date ASC', '')
ON CONFLICT DO NOTHING;

-- Elimination 매핑
INSERT INTO gfx_aep_field_mappings (composition_name, composition_category, target_field_key, slot_range_start, slot_range_end, source_table, source_column, transform, slot_order_by, default_value) VALUES
('Elimination', 'elimination', 'name', 1, 2, 'gfx_hand_players', 'player_name', 'UPPER', 'elimination_rank DESC', ''),
('Elimination', 'elimination', 'rank', 1, 2, 'gfx_hand_players', 'elimination_rank', 'direct', 'elimination_rank DESC', ''),
('Elimination', 'elimination', 'prize', 1, 2, 'gfx_sessions', 'payouts[elimination_rank]', 'format_currency', 'elimination_rank DESC', '$0'),
('Elimination', 'elimination', 'flag', 1, 2, 'player_overrides', 'country_code', 'get_flag_path', 'elimination_rank DESC', 'Flag/Unknown.png')
ON CONFLICT DO NOTHING;

-- ============================================================================
-- Comments
-- ============================================================================

COMMENT ON TABLE gfx_aep_field_mappings IS 'GFX JSON DB → AEP 컴포지션 필드 매핑 규칙. GFX_AEP_FIELD_MAPPING.md 문서 기반.';
COMMENT ON TABLE gfx_aep_compositions IS '26개 AEP 컴포지션 메타데이터. 카테고리, 슬롯 수, 필드 키 정보.';

COMMENT ON FUNCTION format_chips IS '칩 포맷팅: 1500000 → "1,500,000"';
COMMENT ON FUNCTION format_bbs IS 'BB 포맷팅: (chips, bb) → "75.0"';
COMMENT ON FUNCTION format_currency IS '통화 포맷팅 (cents): 100000000 → "$1,000,000"';
COMMENT ON FUNCTION get_flag_path IS '국기 경로: "KR" → "Flag/Korea.png"';
COMMENT ON FUNCTION get_chip_display_data IS 'Chip Display 컴포지션용 gfx_data JSON 생성';
COMMENT ON FUNCTION get_payout_data IS 'Payout 컴포지션용 gfx_data JSON 생성';
