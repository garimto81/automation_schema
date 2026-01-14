-- ============================================================================
-- Migration: 08_aep_mapping_functions
-- Description: GFX_AEP_FIELD_MAPPING.md 문서에 정의된 누락된 테이블 및 함수 추가
-- Author: Claude Opus 4.5
-- Date: 2026-01-14
-- ============================================================================

-- ============================================================================
-- 1. aep_media_sources 테이블: 국기/프로필 이미지 경로 관리
-- ============================================================================
CREATE TABLE IF NOT EXISTS aep_media_sources (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    category VARCHAR(50) NOT NULL,       -- 'Flag', 'Profile', 'Logo'
    country_code VARCHAR(10),            -- ISO 국가 코드 (2자리)
    name TEXT NOT NULL,                  -- 표시용 이름 (예: "Korea", "United States")
    file_path TEXT NOT NULL,             -- AEP 내부 경로 (예: "Flag/Korea.png")
    file_type VARCHAR(20) DEFAULT 'png', -- 파일 타입
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE aep_media_sources IS 'AEP 미디어 소스 경로 관리 (국기, 프로필 이미지 등)';
COMMENT ON COLUMN aep_media_sources.category IS 'Flag, Profile, Logo 등 미디어 카테고리';
COMMENT ON COLUMN aep_media_sources.country_code IS 'ISO 3166-1 alpha-2 국가 코드';
COMMENT ON COLUMN aep_media_sources.file_path IS 'AEP 프로젝트 내부 상대 경로';

-- 인덱스
CREATE INDEX IF NOT EXISTS idx_aep_media_sources_category ON aep_media_sources(category);
CREATE INDEX IF NOT EXISTS idx_aep_media_sources_country_code ON aep_media_sources(country_code);
CREATE UNIQUE INDEX IF NOT EXISTS idx_aep_media_sources_unique ON aep_media_sources(category, country_code)
    WHERE country_code IS NOT NULL;

-- ============================================================================
-- 2. gfx_aep_field_mappings 테이블: 컴포지션-필드 매핑 메타데이터
-- ============================================================================
CREATE TABLE IF NOT EXISTS gfx_aep_field_mappings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    composition_name VARCHAR(255) NOT NULL,
    composition_category VARCHAR(50) NOT NULL,  -- chip_display, payout, event_info 등
    target_field_key VARCHAR(100) NOT NULL,     -- AEP 텍스트 레이어 키 (예: "name", "chips")
    slot_range_start INTEGER,                   -- 슬롯 시작 번호 (NULL이면 단일 필드)
    slot_range_end INTEGER,                     -- 슬롯 끝 번호
    source_table VARCHAR(100) NOT NULL,         -- 소스 테이블 (예: "gfx_hand_players")
    source_column VARCHAR(100) NOT NULL,        -- 소스 컬럼 (예: "player_name")
    source_join TEXT,                           -- JOIN 절 (선택)
    transform VARCHAR(50),                       -- 변환 함수 (예: "UPPER", "format_chips")
    slot_order_by VARCHAR(100),                  -- 슬롯 정렬 기준 (예: "end_stack_amt DESC")
    slot_filter TEXT,                            -- 슬롯 필터 조건 (예: "sitting_out = FALSE")
    priority INTEGER DEFAULT 100,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(composition_name, target_field_key, COALESCE(slot_range_start, 0))
);

COMMENT ON TABLE gfx_aep_field_mappings IS 'AEP 컴포지션별 필드 매핑 메타데이터';
COMMENT ON COLUMN gfx_aep_field_mappings.composition_name IS 'AEP 컴포지션 이름 (예: "_MAIN Mini Chip Count")';
COMMENT ON COLUMN gfx_aep_field_mappings.transform IS '적용할 변환 함수 (UPPER, format_chips, format_bbs 등)';

-- 인덱스
CREATE INDEX IF NOT EXISTS idx_gfx_aep_field_mappings_comp ON gfx_aep_field_mappings(composition_name);
CREATE INDEX IF NOT EXISTS idx_gfx_aep_field_mappings_category ON gfx_aep_field_mappings(composition_category);

-- ============================================================================
-- 3. 변환 함수들
-- ============================================================================

-- 3.1 format_bbs: BB 단위 표시 (chips / big_blind)
-- 예: format_bbs(1500000, 20000) → "75.0"
CREATE OR REPLACE FUNCTION format_bbs(chips BIGINT, bb BIGINT)
RETURNS TEXT AS $$
    SELECT CASE
        WHEN bb IS NULL OR bb = 0 THEN ''
        WHEN chips IS NULL THEN ''
        ELSE TRIM(TO_CHAR(chips::NUMERIC / bb, 'FM999,999.9'))
    END
$$ LANGUAGE SQL IMMUTABLE;

COMMENT ON FUNCTION format_bbs(BIGINT, BIGINT) IS 'BB 단위로 변환: 1500000 / 20000 → "75.0"';

-- 3.2 format_date: 날짜 포맷팅
-- 예: format_date('2026-01-14') → "Jan 14"
CREATE OR REPLACE FUNCTION format_date(d DATE)
RETURNS TEXT AS $$
    SELECT CASE
        WHEN d IS NULL THEN ''
        ELSE TO_CHAR(d, 'Mon DD')
    END
$$ LANGUAGE SQL IMMUTABLE;

COMMENT ON FUNCTION format_date(DATE) IS '날짜를 "Mon DD" 형태로 변환: 2026-01-14 → "Jan 14"';

-- 3.3 format_time: 시간 포맷팅 (12시간제)
-- 예: format_time('17:30:00') → "05:30 PM"
CREATE OR REPLACE FUNCTION format_time(t TIME)
RETURNS TEXT AS $$
    SELECT CASE
        WHEN t IS NULL THEN ''
        ELSE TO_CHAR(t, 'HH:MI AM')
    END
$$ LANGUAGE SQL IMMUTABLE;

COMMENT ON FUNCTION format_time(TIME) IS '시간을 12시간제로 변환: 17:30 → "05:30 PM"';

-- 3.4 format_blinds: 블라인드 문자열 포맷팅
-- 예: format_blinds(10000, 20000, 20000) → "10K/20K (20K)"
CREATE OR REPLACE FUNCTION format_blinds(sb BIGINT, bb BIGINT, ante BIGINT DEFAULT 0)
RETURNS TEXT AS $$
    SELECT CASE
        WHEN sb IS NULL OR bb IS NULL THEN ''
        ELSE format_chips(sb) || '/' || format_chips(bb) ||
             CASE WHEN ante > 0 THEN ' (' || format_chips(ante) || ')' ELSE '' END
    END
$$ LANGUAGE SQL IMMUTABLE;

COMMENT ON FUNCTION format_blinds(BIGINT, BIGINT, BIGINT) IS '블라인드 포맷: 10000/20000 (20000) → "10K/20K (20K)"';

-- 3.5 format_chips_comma: 천단위 콤마 형태 (K/M 축약 없음)
-- 예: format_chips_comma(1500000) → "1,500,000"
CREATE OR REPLACE FUNCTION format_chips_comma(amount BIGINT)
RETURNS TEXT AS $$
    SELECT CASE
        WHEN amount IS NULL THEN ''
        ELSE TO_CHAR(amount, 'FM999,999,999,999')
    END
$$ LANGUAGE SQL IMMUTABLE;

COMMENT ON FUNCTION format_chips_comma(BIGINT) IS '천단위 콤마: 1500000 → "1,500,000"';

-- 3.6 get_flag_path: 국기 이미지 경로 조회
-- 예: get_flag_path('KR') → "Flag/Korea.png"
CREATE OR REPLACE FUNCTION get_flag_path(p_country_code VARCHAR)
RETURNS TEXT AS $$
    SELECT COALESCE(
        (SELECT file_path
         FROM aep_media_sources
         WHERE category = 'Flag'
           AND UPPER(country_code) = UPPER(p_country_code)
           AND is_active = TRUE
         LIMIT 1),
        'Flag/Unknown.png'
    )
$$ LANGUAGE SQL STABLE;

COMMENT ON FUNCTION get_flag_path(VARCHAR) IS '국가 코드로 국기 이미지 경로 조회: KR → "Flag/Korea.png"';

-- 3.7 format_currency_cents: cents → 달러 변환
-- 예: format_currency_cents(100000000) → "$1,000,000"
CREATE OR REPLACE FUNCTION format_currency_cents(amount BIGINT)
RETURNS TEXT AS $$
    SELECT CASE
        WHEN amount IS NULL THEN '$0'
        ELSE '$' || TO_CHAR(amount / 100, 'FM999,999,999,999')
    END
$$ LANGUAGE SQL IMMUTABLE;

COMMENT ON FUNCTION format_currency_cents(BIGINT) IS 'cents를 달러로 변환: 100000000 → "$1,000,000"';

-- ============================================================================
-- 4. 추가 유틸리티 함수
-- ============================================================================

-- 4.1 format_chips_safe: NULL 안전 버전 (기존 format_chips 보완)
CREATE OR REPLACE FUNCTION format_chips_safe(amount BIGINT)
RETURNS TEXT AS $$
BEGIN
    IF amount IS NULL OR amount < 0 THEN
        RETURN '';
    END IF;
    RETURN format_chips(amount);
EXCEPTION
    WHEN OTHERS THEN
        RETURN '';
END;
$$ LANGUAGE plpgsql IMMUTABLE;

COMMENT ON FUNCTION format_chips_safe(BIGINT) IS 'NULL 안전 버전의 format_chips';

-- 4.2 format_bbs_safe: NULL 안전 버전
CREATE OR REPLACE FUNCTION format_bbs_safe(chips BIGINT, bb BIGINT)
RETURNS TEXT AS $$
BEGIN
    IF chips IS NULL OR bb IS NULL OR bb = 0 THEN
        RETURN '';
    END IF;
    RETURN TRIM(TO_CHAR(chips::NUMERIC / bb, 'FM999,999.9'));
EXCEPTION
    WHEN OTHERS THEN
        RETURN '';
END;
$$ LANGUAGE plpgsql IMMUTABLE;

COMMENT ON FUNCTION format_bbs_safe(BIGINT, BIGINT) IS 'NULL 안전 버전의 format_bbs';

-- 4.3 format_currency_safe: NULL 안전 버전
CREATE OR REPLACE FUNCTION format_currency_safe(amount BIGINT)
RETURNS TEXT AS $$
BEGIN
    IF amount IS NULL THEN
        RETURN '$0';
    END IF;
    RETURN format_currency(amount);
EXCEPTION
    WHEN OTHERS THEN
        RETURN '$0';
END;
$$ LANGUAGE plpgsql IMMUTABLE;

COMMENT ON FUNCTION format_currency_safe(BIGINT) IS 'NULL 안전 버전의 format_currency';

-- ============================================================================
-- 5. 초기 데이터: 국기 이미지 경로
-- ============================================================================
INSERT INTO aep_media_sources (category, country_code, name, file_path) VALUES
-- 주요 국가
('Flag', 'US', 'United States', 'Flag/United States.png'),
('Flag', 'KR', 'Korea', 'Flag/Korea.png'),
('Flag', 'GB', 'United Kingdom', 'Flag/United Kingdom.png'),
('Flag', 'DE', 'Germany', 'Flag/Germany.png'),
('Flag', 'FR', 'France', 'Flag/France.png'),
('Flag', 'CA', 'Canada', 'Flag/Canada.png'),
('Flag', 'AU', 'Australia', 'Flag/Australia.png'),
('Flag', 'JP', 'Japan', 'Flag/Japan.png'),
('Flag', 'CN', 'China', 'Flag/China.png'),
('Flag', 'BR', 'Brazil', 'Flag/Brazil.png'),
-- 유럽
('Flag', 'ES', 'Spain', 'Flag/Spain.png'),
('Flag', 'IT', 'Italy', 'Flag/Italy.png'),
('Flag', 'NL', 'Netherlands', 'Flag/Netherlands.png'),
('Flag', 'PL', 'Poland', 'Flag/Poland.png'),
('Flag', 'SE', 'Sweden', 'Flag/Sweden.png'),
('Flag', 'NO', 'Norway', 'Flag/Norway.png'),
('Flag', 'DK', 'Denmark', 'Flag/Denmark.png'),
('Flag', 'FI', 'Finland', 'Flag/Finland.png'),
('Flag', 'AT', 'Austria', 'Flag/Austria.png'),
('Flag', 'CH', 'Switzerland', 'Flag/Switzerland.png'),
('Flag', 'BE', 'Belgium', 'Flag/Belgium.png'),
('Flag', 'PT', 'Portugal', 'Flag/Portugal.png'),
('Flag', 'IE', 'Ireland', 'Flag/Ireland.png'),
('Flag', 'GR', 'Greece', 'Flag/Greece.png'),
('Flag', 'CZ', 'Czech Republic', 'Flag/Czech Republic.png'),
('Flag', 'HU', 'Hungary', 'Flag/Hungary.png'),
('Flag', 'RO', 'Romania', 'Flag/Romania.png'),
('Flag', 'BG', 'Bulgaria', 'Flag/Bulgaria.png'),
('Flag', 'UA', 'Ukraine', 'Flag/Ukraine.png'),
('Flag', 'RU', 'Russia', 'Flag/Russia.png'),
-- 발트/동유럽
('Flag', 'LT', 'Lithuania', 'Flag/Lithuania.png'),
('Flag', 'LV', 'Latvia', 'Flag/Latvia.png'),
('Flag', 'EE', 'Estonia', 'Flag/Estonia.png'),
('Flag', 'BY', 'Belarus', 'Flag/Belarus.png'),
-- 아시아
('Flag', 'IN', 'India', 'Flag/India.png'),
('Flag', 'PH', 'Philippines', 'Flag/Philippines.png'),
('Flag', 'VN', 'Vietnam', 'Flag/Vietnam.png'),
('Flag', 'TH', 'Thailand', 'Flag/Thailand.png'),
('Flag', 'MY', 'Malaysia', 'Flag/Malaysia.png'),
('Flag', 'SG', 'Singapore', 'Flag/Singapore.png'),
('Flag', 'ID', 'Indonesia', 'Flag/Indonesia.png'),
('Flag', 'TW', 'Taiwan', 'Flag/Taiwan.png'),
('Flag', 'HK', 'Hong Kong', 'Flag/Hong Kong.png'),
-- 중동/지중해
('Flag', 'IL', 'Israel', 'Flag/Israel.png'),
('Flag', 'TR', 'Turkey', 'Flag/Turkey.png'),
('Flag', 'CY', 'Cyprus', 'Flag/Cyprus.png'),
('Flag', 'AE', 'United Arab Emirates', 'Flag/United Arab Emirates.png'),
-- 아메리카
('Flag', 'MX', 'Mexico', 'Flag/Mexico.png'),
('Flag', 'AR', 'Argentina', 'Flag/Argentina.png'),
('Flag', 'CL', 'Chile', 'Flag/Chile.png'),
('Flag', 'CO', 'Colombia', 'Flag/Colombia.png'),
-- 기타
('Flag', 'ZA', 'South Africa', 'Flag/South Africa.png'),
('Flag', 'NZ', 'New Zealand', 'Flag/New Zealand.png'),
-- Unknown (기본값)
('Flag', 'XX', 'Unknown', 'Flag/Unknown.png')
ON CONFLICT DO NOTHING;

-- ============================================================================
-- 6. 트리거: updated_at 자동 갱신
-- ============================================================================
CREATE OR REPLACE TRIGGER trigger_aep_media_sources_updated_at
    BEFORE UPDATE ON aep_media_sources
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE OR REPLACE TRIGGER trigger_gfx_aep_field_mappings_updated_at
    BEFORE UPDATE ON gfx_aep_field_mappings
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- 7. RLS 정책 (선택적)
-- ============================================================================
ALTER TABLE aep_media_sources ENABLE ROW LEVEL SECURITY;
ALTER TABLE gfx_aep_field_mappings ENABLE ROW LEVEL SECURITY;

-- 모든 인증된 사용자에게 읽기 권한
CREATE POLICY "Authenticated read on aep_media_sources" ON aep_media_sources
    FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Authenticated read on gfx_aep_field_mappings" ON gfx_aep_field_mappings
    FOR SELECT USING (auth.role() = 'authenticated');

-- Service role 전체 권한
CREATE POLICY "Service role full access on aep_media_sources" ON aep_media_sources
    USING (auth.role() = 'service_role')
    WITH CHECK (auth.role() = 'service_role');

CREATE POLICY "Service role full access on gfx_aep_field_mappings" ON gfx_aep_field_mappings
    USING (auth.role() = 'service_role')
    WITH CHECK (auth.role() = 'service_role');

-- ============================================================================
-- 완료
-- ============================================================================
