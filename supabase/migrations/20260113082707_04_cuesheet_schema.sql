-- ============================================================================
-- Migration: 04_cuesheet_schema.sql
-- Description: Cuesheet Database Schema (방송 큐시트 관리)
-- Version: 2.0.0
-- Date: 2026-01-13
-- ============================================================================

-- ============================================================================
-- ENUM Types
-- ============================================================================

-- 방송 세션 상태
CREATE TYPE cue_broadcast_status AS ENUM (
    'draft',            -- 초안
    'scheduled',        -- 예정됨
    'preparing',        -- 준비 중
    'standby',          -- 대기
    'live',             -- 생방송 중
    'break',            -- 휴식
    'completed',        -- 완료
    'cancelled',        -- 취소
    'postponed'         -- 연기
);

-- 큐시트 타입
CREATE TYPE cue_sheet_type AS ENUM (
    'pre_show',         -- 방송 전 (오프닝)
    'main_show',        -- 메인 방송
    'segment',          -- 세그먼트 (중간 구간)
    'break',            -- 휴식 시간
    'post_show',        -- 방송 후 (클로징)
    'highlight',        -- 하이라이트
    'emergency'         -- 긴급 (기술 문제 등)
);

-- 큐시트 상태
CREATE TYPE cue_sheet_status AS ENUM (
    'draft',            -- 초안
    'pending_review',   -- 검토 대기
    'approved',         -- 승인됨
    'ready',            -- 준비 완료
    'active',           -- 진행 중
    'paused',           -- 일시 정지
    'completed',        -- 완료
    'archived'          -- 아카이브
);

-- 큐 콘텐츠 타입 (LIVE 시트의 Content 컬럼)
CREATE TYPE cue_content_type AS ENUM (
    'opening_sequence',     -- 오프닝 시퀀스 (Intro, Location, Commentators 등)
    'main',                 -- 메인 테이블 핸드
    'sub',                  -- 서브 테이블 핸드
    'virtual',              -- 버추얼 GFX (플레이어 소개 등)
    'leaderboard',          -- 리더보드/칩카운트
    'break',                -- 휴식
    'closing'               -- 클로징
);

-- 큐 아이템 타입 (GFX 요소 분류)
CREATE TYPE cue_item_type AS ENUM (
    -- 오프닝/클로징 관련
    'intro',                -- 인트로
    'location',             -- 장소 소개
    'commentators',         -- 해설자 소개
    'broadcast_schedule',   -- 방송 일정
    'event_info',           -- 이벤트 정보
    'payouts',              -- 상금 구조

    -- 칩/순위 관련
    'chip_count',           -- 칩 카운트
    'mini_chip_table',      -- 미니 칩 테이블 (좌/우)
    'leaderboard',          -- 순위표
    'chip_flow',            -- 칩 변동 그래프
    'chip_comparison',      -- 칩 비교
    'chips_in_play',        -- 칩 인 플레이

    -- 플레이어 관련
    'player_profile',       -- 선수 프로필 (L3_Profile)
    'player_info',          -- 선수 정보
    'elimination',          -- 탈락 정보
    'elimination_risk',     -- 탈락 위험
    'money_list',           -- 역대 상금 순위

    -- 핸드 관련
    'hand_main',            -- 메인 테이블 핸드
    'hand_sub',             -- 서브 테이블 핸드

    -- 통계
    'vpip',                 -- VPIP 통계
    'blinds_info',          -- 블라인드 정보

    -- 전환/기타
    'transition',           -- 전환 화면
    'bumper',               -- 범퍼
    'sponsor',              -- 스폰서
    'custom'                -- 커스텀
);

-- 핸드 등급 (A, B, B-, C)
CREATE TYPE cue_hand_rank AS ENUM (
    'A',      -- A급 (하이라이트)
    'B',      -- B급 (중요)
    'B-',     -- B-급 (보통)
    'C',      -- C급 (필러)
    'SOFT'    -- 소프트 콘텐츠 (버추얼 GFX 등)
);

-- 큐 아이템 상태
CREATE TYPE cue_item_status AS ENUM (
    'draft',            -- 초안
    'pending',          -- 대기
    'ready',            -- 준비됨
    'standby',          -- 송출 대기
    'on_air',           -- 송출 중
    'completed',        -- 완료
    'skipped',          -- 건너뜀
    'failed',           -- 실패
    'cancelled'         -- 취소
);

-- GFX 트리거 타입
CREATE TYPE cue_trigger_type AS ENUM (
    'manual',           -- 수동 트리거
    'scheduled',        -- 예약 트리거
    'auto',             -- 자동 트리거
    'api',              -- API 호출
    'hotkey',           -- 단축키
    'external'          -- 외부 시스템
);

-- 렌더 상태
CREATE TYPE cue_render_status AS ENUM (
    'pending',          -- 대기
    'queued',           -- 큐에 등록됨
    'rendering',        -- 렌더링 중
    'completed',        -- 완료
    'failed',           -- 실패
    'cancelled',        -- 취소
    'cached'            -- 캐시됨 (이전 렌더 사용)
);

-- 템플릿 타입 (Google Sheets template 시트 기반)
CREATE TYPE cue_template_type AS ENUM (
    -- 칩카운트 관련
    'mini_chip_left',       -- [LEFT]MINI_CHIP_TABLE
    'mini_chip_right',      -- [RIGHT]MINI_CHIP_TABLE
    'feature_table_chip',   -- Feature Table Chipcounts

    -- Payout 관련
    'mini_payouts',         -- [LEFT]MINI_PAYOUTS_TABLE

    -- 플레이어 상태
    'elimination_risk',     -- [ELIMINATION AT RISK]
    'current_stack',        -- CURRENT STACK
    'eliminated',           -- ELIMINATED IN Xth PLACE
    'money_list',           -- MONEY LIST (All Time)

    -- 게임 정보
    'chips_in_play',        -- [CHIPS IN PLAY]
    'vpip',                 -- [VPIP]
    'chip_flow',            -- [CHIP FLOW]
    'chip_comparison',      -- [CHIP COMPARISON]
    'blinds',               -- [BLINDS_좌하단]

    -- 기타
    'player_profile',       -- L3_Profile
    'custom'                -- 커스텀
);

-- ============================================================================
-- TABLES
-- ============================================================================

-- ============================================================================
-- broadcast_sessions: 방송 세션 정보
-- ============================================================================

CREATE TABLE broadcast_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- 세션 식별
    session_code TEXT NOT NULL UNIQUE,  -- 예: "WSOP-2024-ME-D1"

    -- 이벤트 연결 (선택적)
    event_id UUID,  -- wsop_events FK (다른 스키마)
    event_name TEXT NOT NULL,
    event_description TEXT,

    -- 방송 일정
    broadcast_date DATE NOT NULL,
    scheduled_start TIMESTAMPTZ NOT NULL,
    scheduled_end TIMESTAMPTZ,
    actual_start TIMESTAMPTZ,
    actual_end TIMESTAMPTZ,

    -- 상태
    status cue_broadcast_status DEFAULT 'draft',
    current_sheet_id UUID,  -- 현재 진행 중인 큐시트

    -- 스태프 정보
    director TEXT,
    technical_director TEXT,
    producer TEXT,

    -- 해설자/리포터 (JSONB)
    commentators JSONB DEFAULT '[]'::JSONB,
    reporters JSONB DEFAULT '[]'::JSONB,

    -- 방송 설정
    settings JSONB DEFAULT '{}'::JSONB,

    -- 통계
    total_cue_items INTEGER DEFAULT 0,
    completed_cue_items INTEGER DEFAULT 0,
    total_duration_minutes INTEGER DEFAULT 0,

    -- 메타데이터
    notes TEXT,
    tags TEXT[] DEFAULT ARRAY[]::TEXT[],

    -- 관리 정보
    created_by TEXT NOT NULL,
    approved_by TEXT,
    approved_at TIMESTAMPTZ,

    -- 타임스탬프
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE broadcast_sessions IS '방송 세션 정보';
COMMENT ON COLUMN broadcast_sessions.commentators IS '[{"name": "홍길동", "role": "main", "language": "ko"}]';
COMMENT ON COLUMN broadcast_sessions.settings IS '{"default_gfx_duration": 10, "auto_advance": true}';

-- ============================================================================
-- cue_templates: 재사용 가능한 큐 템플릿
-- ============================================================================

CREATE TABLE cue_templates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- 템플릿 식별
    template_code TEXT NOT NULL UNIQUE,  -- 예: "TPL-MINI-CHIP-LEFT"

    -- 기본 정보
    template_name TEXT NOT NULL,
    description TEXT,
    template_type cue_template_type NOT NULL,

    -- 위치 설정
    position TEXT,  -- 'LEFT', 'RIGHT', 'CENTER'

    -- GFX 정보
    gfx_template_name TEXT,
    gfx_comp_name TEXT,

    -- 기본 설정
    default_duration INTEGER DEFAULT 10,

    -- 데이터 스키마 (필수 필드 정의)
    data_schema JSONB DEFAULT '{}'::JSONB,

    -- 샘플 데이터 (미리보기용)
    sample_data JSONB DEFAULT '{}'::JSONB,

    -- 미리보기 이미지
    preview_image_url TEXT,

    -- 분류
    category TEXT,
    tags TEXT[] DEFAULT ARRAY[]::TEXT[],

    -- 상태
    is_active BOOLEAN DEFAULT TRUE,

    -- 사용 통계
    usage_count INTEGER DEFAULT 0,
    last_used_at TIMESTAMPTZ,

    -- 관리 정보
    created_by TEXT,

    -- 타임스탬프
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE cue_templates IS '재사용 가능한 큐 템플릿 (Google Sheets template 시트)';

-- ============================================================================
-- cue_sheets: 방송 큐시트
-- ============================================================================

CREATE TABLE cue_sheets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- 큐시트 식별
    sheet_code TEXT NOT NULL UNIQUE,  -- 예: "WSOP-2024-ME-D1-MAIN"

    -- 세션 참조
    session_id UUID NOT NULL REFERENCES broadcast_sessions(id) ON DELETE CASCADE,

    -- 기본 정보
    sheet_name TEXT NOT NULL,
    sheet_type cue_sheet_type NOT NULL DEFAULT 'main_show',
    sheet_order INTEGER NOT NULL DEFAULT 0,  -- 세션 내 순서

    -- 버전 관리
    version INTEGER DEFAULT 1,
    parent_version_id UUID REFERENCES cue_sheets(id),  -- 이전 버전

    -- 상태
    status cue_sheet_status DEFAULT 'draft',

    -- 진행 상황
    total_items INTEGER DEFAULT 0,
    completed_items INTEGER DEFAULT 0,
    current_item_id UUID,  -- 현재 진행 중인 아이템 (FK는 나중에 추가)
    current_item_index INTEGER DEFAULT 0,

    -- 예상 시간
    estimated_duration_minutes INTEGER,
    actual_duration_minutes INTEGER,

    -- 설정 (세션 설정 오버라이드)
    settings_override JSONB DEFAULT '{}'::JSONB,

    -- 메타데이터
    description TEXT,
    notes TEXT,

    -- 관리 정보
    created_by TEXT NOT NULL,
    last_modified_by TEXT,

    -- 타임스탬프
    started_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    -- 복합 유니크 제약
    CONSTRAINT uq_cue_sheets_session_order UNIQUE (session_id, sheet_order)
);

COMMENT ON TABLE cue_sheets IS '방송 큐시트 (방송 세션 내의 구간별 큐 목록)';

-- ============================================================================
-- chip_snapshots: 칩카운트 스냅샷
-- ============================================================================

CREATE TABLE chip_snapshots (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- 세션 참조
    session_id UUID NOT NULL REFERENCES broadcast_sessions(id) ON DELETE CASCADE,

    -- 스냅샷 시점
    snapshot_time TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- 블라인드 정보
    blind_level TEXT,  -- "300 / 500"
    blind_bb INTEGER,  -- 500

    -- 전체 통계
    players_remaining INTEGER,
    total_chips BIGINT,
    avg_stack INTEGER,

    -- 플레이어별 칩카운트 (JSONB)
    players_data JSONB NOT NULL DEFAULT '[]'::JSONB,

    -- 메타데이터
    source TEXT DEFAULT 'pokercaster',  -- 데이터 소스
    notes TEXT,

    -- 타임스탬프
    created_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE chip_snapshots IS '칩카운트 스냅샷 (Google Sheets chipcount/leaderboard 시트)';
COMMENT ON COLUMN chip_snapshots.players_data IS '[{"rank": 1, "player_name": "Oscar Romero Cobos", "chipcount": 154500, "bb_stack": 103}]';

-- ============================================================================
-- cue_items: 개별 큐 아이템 (LIVE 시트 매핑)
-- ============================================================================

CREATE TABLE cue_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- 큐시트 참조
    sheet_id UUID NOT NULL REFERENCES cue_sheets(id) ON DELETE CASCADE,

    -- 템플릿 참조 (선택적)
    template_id UUID REFERENCES cue_templates(id) ON DELETE SET NULL,

    -- 칩 스냅샷 참조 (해당 시점의 칩카운트)
    snapshot_id UUID REFERENCES chip_snapshots(id) ON DELETE SET NULL,

    -- =========================================================================
    -- LIVE 시트 컬럼 매핑 (A-R)
    -- =========================================================================

    -- A열: 특별 정보 (2-TIME BRACELET WINNER 등)
    special_info TEXT,

    -- B열: 콘텐츠 타입
    content_type cue_content_type NOT NULL,  -- OPENING SEQUENCE, MAIN, SUB, VIRTUAL

    -- C열: 핸드 번호 (1-176)
    hand_number INTEGER,

    -- D열: 핸드 등급
    hand_rank cue_hand_rank,  -- A, B, B-, C, SOFT

    -- E열: 핸드 히스토리
    hand_history TEXT,

    -- F열: 편집 포인트 (시작점)
    edit_point TEXT,  -- "프리플랍부터", "플랍부터"

    -- G열: PD 노트
    pd_note TEXT,  -- "WINNER: COHEN", "GABDULLIN 44 WIN"

    -- H열: 촬영 시간
    recording_time TIME,  -- 14:36

    -- I열: 자막 필요 여부
    subtitle_flag BOOLEAN DEFAULT FALSE,

    -- J열: 블라인드 레벨
    blind_level TEXT,  -- "300 / 500"

    -- K열: 자막 (컨펌용)
    subtitle_confirm TEXT,

    -- L열: 자막 (자막팀용)
    subtitle_team TEXT,

    -- M열: 사후 제작 여부
    post_flag BOOLEAN DEFAULT FALSE,

    -- N열: 복사 상태
    copy_status TEXT,  -- "복사완료"

    -- O열: 파일명
    file_name TEXT,  -- "A_0003", "B_0004"

    -- P열: 전환 효과
    transition TEXT,

    -- Q열: 시작 타임코드
    timecode_in TEXT,  -- "00:01:25"

    -- R열: 종료 타임코드
    timecode_out TEXT,  -- "00:01:55"

    -- =========================================================================
    -- 기존 필드 (유지)
    -- =========================================================================

    -- 큐 식별
    cue_number TEXT,  -- 자동 생성: "Q001", "Q002"
    cue_type cue_item_type,  -- GFX 요소 타입

    -- GFX 정보
    gfx_template_name TEXT,  -- AEP 템플릿명
    gfx_comp_name TEXT,      -- After Effects 컴포지션명

    -- GFX 데이터 (동적 바인딩)
    gfx_data JSONB DEFAULT '{}'::JSONB,

    -- 타이밍
    duration_seconds INTEGER DEFAULT 10,
    scheduled_time TIMESTAMPTZ,
    actual_time TIMESTAMPTZ,

    -- 순서
    sort_order INTEGER NOT NULL DEFAULT 0,

    -- 상태
    status cue_item_status DEFAULT 'pending',

    -- 관리 정보
    created_by TEXT,
    last_triggered_by TEXT,

    -- 타임스탬프
    last_triggered_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    -- 복합 유니크 제약
    CONSTRAINT uq_cue_items_sheet_order UNIQUE (sheet_id, sort_order)
);

COMMENT ON TABLE cue_items IS '개별 큐 아이템 (Google Sheets LIVE 시트 매핑)';
COMMENT ON COLUMN cue_items.hand_history IS 'Pre: AK RAISE\nFlop: 44 CHECK, AK BET\nTurn: 44 BET, AK CALL';

-- ============================================================================
-- gfx_triggers: GFX 트리거 로그
-- ============================================================================

CREATE TABLE gfx_triggers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- 참조
    cue_item_id UUID REFERENCES cue_items(id) ON DELETE SET NULL,
    session_id UUID REFERENCES broadcast_sessions(id) ON DELETE SET NULL,
    sheet_id UUID REFERENCES cue_sheets(id) ON DELETE SET NULL,

    -- 트리거 정보
    trigger_type cue_trigger_type NOT NULL,
    trigger_time TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    triggered_by TEXT NOT NULL,

    -- GFX 정보
    cue_type cue_item_type,
    aep_comp_name TEXT,
    gfx_template_name TEXT,
    gfx_data JSONB,

    -- 렌더링 정보
    render_status cue_render_status DEFAULT 'pending',
    render_job_id UUID,  -- 렌더 큐 작업 ID
    render_started_at TIMESTAMPTZ,
    render_completed_at TIMESTAMPTZ,

    -- 출력 정보
    output_path TEXT,
    output_format TEXT,  -- mp4, mov, png 등
    output_resolution TEXT,  -- 1920x1080 등
    file_size_bytes BIGINT,

    -- 성능 메트릭
    duration_ms INTEGER,  -- 전체 처리 시간
    render_duration_ms INTEGER,
    queue_wait_ms INTEGER,

    -- 에러 정보
    error_message TEXT,
    error_details JSONB,
    retry_count INTEGER DEFAULT 0,

    -- 메타데이터
    notes TEXT,
    metadata JSONB DEFAULT '{}'::JSONB,

    -- 타임스탬프
    created_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE gfx_triggers IS 'GFX 송출 트리거 로그 (모든 GFX 송출 이력)';

-- ============================================================================
-- INDEXES
-- ============================================================================

-- broadcast_sessions 인덱스
CREATE INDEX idx_broadcast_sessions_code ON broadcast_sessions(session_code);
CREATE INDEX idx_broadcast_sessions_date ON broadcast_sessions(broadcast_date DESC);
CREATE INDEX idx_broadcast_sessions_status ON broadcast_sessions(status);
CREATE INDEX idx_broadcast_sessions_event ON broadcast_sessions(event_id);
CREATE INDEX idx_broadcast_sessions_scheduled ON broadcast_sessions(scheduled_start DESC);
CREATE INDEX idx_broadcast_sessions_tags ON broadcast_sessions USING GIN (tags);

-- cue_sheets 인덱스
CREATE INDEX idx_cue_sheets_code ON cue_sheets(sheet_code);
CREATE INDEX idx_cue_sheets_session ON cue_sheets(session_id);
CREATE INDEX idx_cue_sheets_type ON cue_sheets(sheet_type);
CREATE INDEX idx_cue_sheets_status ON cue_sheets(status);
CREATE INDEX idx_cue_sheets_order ON cue_sheets(session_id, sheet_order);

-- chip_snapshots 인덱스
CREATE INDEX idx_chip_snapshots_session ON chip_snapshots(session_id);
CREATE INDEX idx_chip_snapshots_time ON chip_snapshots(snapshot_time DESC);
CREATE INDEX idx_chip_snapshots_players ON chip_snapshots USING GIN (players_data);

-- cue_items 인덱스
CREATE INDEX idx_cue_items_sheet ON cue_items(sheet_id);
CREATE INDEX idx_cue_items_content_type ON cue_items(content_type);
CREATE INDEX idx_cue_items_hand_number ON cue_items(hand_number) WHERE hand_number IS NOT NULL;
CREATE INDEX idx_cue_items_status ON cue_items(status);
CREATE INDEX idx_cue_items_order ON cue_items(sheet_id, sort_order);
CREATE INDEX idx_cue_items_template ON cue_items(template_id);
CREATE INDEX idx_cue_items_snapshot ON cue_items(snapshot_id);
CREATE INDEX idx_cue_items_file_name ON cue_items(file_name) WHERE file_name IS NOT NULL;
CREATE INDEX idx_cue_items_gfx_data ON cue_items USING GIN (gfx_data);

-- cue_templates 인덱스
CREATE INDEX idx_cue_templates_code ON cue_templates(template_code);
CREATE INDEX idx_cue_templates_type ON cue_templates(template_type);
CREATE INDEX idx_cue_templates_category ON cue_templates(category);
CREATE INDEX idx_cue_templates_active ON cue_templates(is_active) WHERE is_active = TRUE;
CREATE INDEX idx_cue_templates_tags ON cue_templates USING GIN (tags);
CREATE INDEX idx_cue_templates_usage ON cue_templates(usage_count DESC);

-- gfx_triggers 인덱스
CREATE INDEX idx_gfx_triggers_cue_item ON gfx_triggers(cue_item_id);
CREATE INDEX idx_gfx_triggers_session ON gfx_triggers(session_id);
CREATE INDEX idx_gfx_triggers_sheet ON gfx_triggers(sheet_id);
CREATE INDEX idx_gfx_triggers_type ON gfx_triggers(trigger_type);
CREATE INDEX idx_gfx_triggers_time ON gfx_triggers(trigger_time DESC);
CREATE INDEX idx_gfx_triggers_status ON gfx_triggers(render_status);
CREATE INDEX idx_gfx_triggers_cue_type ON gfx_triggers(cue_type);
CREATE INDEX idx_gfx_triggers_triggered_by ON gfx_triggers(triggered_by);
CREATE INDEX idx_gfx_triggers_recent ON gfx_triggers(session_id, trigger_time DESC);

-- ============================================================================
-- FOREIGN KEY 추가 (순환 참조 방지를 위해 별도 추가)
-- ============================================================================

ALTER TABLE cue_sheets
    ADD CONSTRAINT fk_cue_sheets_current_item
    FOREIGN KEY (current_item_id)
    REFERENCES cue_items(id)
    ON DELETE SET NULL
    DEFERRABLE INITIALLY DEFERRED;

-- ============================================================================
-- FUNCTIONS AND TRIGGERS
-- ============================================================================

-- updated_at 자동 갱신 함수
CREATE OR REPLACE FUNCTION update_cue_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 각 테이블에 updated_at 트리거 적용
CREATE TRIGGER update_broadcast_sessions_updated_at
    BEFORE UPDATE ON broadcast_sessions
    FOR EACH ROW
    EXECUTE FUNCTION update_cue_updated_at_column();

CREATE TRIGGER update_cue_sheets_updated_at
    BEFORE UPDATE ON cue_sheets
    FOR EACH ROW
    EXECUTE FUNCTION update_cue_updated_at_column();

CREATE TRIGGER update_cue_items_updated_at
    BEFORE UPDATE ON cue_items
    FOR EACH ROW
    EXECUTE FUNCTION update_cue_updated_at_column();

CREATE TRIGGER update_cue_templates_updated_at
    BEFORE UPDATE ON cue_templates
    FOR EACH ROW
    EXECUTE FUNCTION update_cue_updated_at_column();

-- 큐시트 통계 자동 업데이트
CREATE OR REPLACE FUNCTION update_cue_sheet_stats()
RETURNS TRIGGER AS $$
BEGIN
    -- 큐시트 통계 업데이트
    UPDATE cue_sheets
    SET
        total_items = (
            SELECT COUNT(*) FROM cue_items WHERE sheet_id = COALESCE(NEW.sheet_id, OLD.sheet_id)
        ),
        completed_items = (
            SELECT COUNT(*) FROM cue_items
            WHERE sheet_id = COALESCE(NEW.sheet_id, OLD.sheet_id)
              AND status = 'completed'
        ),
        updated_at = NOW()
    WHERE id = COALESCE(NEW.sheet_id, OLD.sheet_id);

    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_sheet_stats_on_item_change
    AFTER INSERT OR UPDATE OR DELETE ON cue_items
    FOR EACH ROW
    EXECUTE FUNCTION update_cue_sheet_stats();

-- 세션 통계 자동 업데이트
CREATE OR REPLACE FUNCTION update_session_stats()
RETURNS TRIGGER AS $$
BEGIN
    -- 세션 통계 업데이트
    UPDATE broadcast_sessions
    SET
        total_cue_items = (
            SELECT COALESCE(SUM(total_items), 0)
            FROM cue_sheets
            WHERE session_id = COALESCE(NEW.session_id, OLD.session_id)
        ),
        completed_cue_items = (
            SELECT COALESCE(SUM(completed_items), 0)
            FROM cue_sheets
            WHERE session_id = COALESCE(NEW.session_id, OLD.session_id)
        ),
        updated_at = NOW()
    WHERE id = COALESCE(NEW.session_id, OLD.session_id);

    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_session_stats_on_sheet_change
    AFTER INSERT OR UPDATE OR DELETE ON cue_sheets
    FOR EACH ROW
    EXECUTE FUNCTION update_session_stats();

-- 템플릿 사용 횟수 증가
CREATE OR REPLACE FUNCTION increment_template_usage()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.template_id IS NOT NULL THEN
        UPDATE cue_templates
        SET
            usage_count = usage_count + 1,
            last_used_at = NOW()
        WHERE id = NEW.template_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER increment_template_usage_on_item
    AFTER INSERT ON cue_items
    FOR EACH ROW
    EXECUTE FUNCTION increment_template_usage();

-- 큐 아이템 상태 전환 함수
CREATE OR REPLACE FUNCTION transition_cue_item_status(
    p_item_id UUID,
    p_new_status cue_item_status,
    p_triggered_by TEXT DEFAULT 'system'
)
RETURNS VOID AS $$
DECLARE
    v_item RECORD;
BEGIN
    -- 아이템 조회
    SELECT * INTO v_item FROM cue_items WHERE id = p_item_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Cue item not found: %', p_item_id;
    END IF;

    -- 상태 업데이트
    UPDATE cue_items
    SET
        status = p_new_status,
        actual_time = CASE WHEN p_new_status = 'on_air' THEN NOW() ELSE actual_time END,
        last_triggered_by = p_triggered_by,
        last_triggered_at = NOW()
    WHERE id = p_item_id;

    -- on_air 상태로 전환 시 트리거 로그 기록
    IF p_new_status = 'on_air' THEN
        INSERT INTO gfx_triggers (
            cue_item_id,
            session_id,
            sheet_id,
            trigger_type,
            triggered_by,
            cue_type,
            aep_comp_name,
            gfx_template_name,
            gfx_data
        )
        SELECT
            ci.id,
            cs.session_id,
            ci.sheet_id,
            'manual',
            p_triggered_by,
            ci.cue_type,
            ci.gfx_comp_name,
            ci.gfx_template_name,
            ci.gfx_data
        FROM cue_items ci
        JOIN cue_sheets cs ON ci.sheet_id = cs.id
        WHERE ci.id = p_item_id;

        -- 큐시트의 현재 아이템 업데이트
        UPDATE cue_sheets
        SET current_item_id = p_item_id
        WHERE id = v_item.sheet_id;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- 다음 큐 아이템 조회 함수
CREATE OR REPLACE FUNCTION get_next_cue_item(p_sheet_id UUID)
RETURNS TABLE (
    id UUID,
    cue_number TEXT,
    cue_type cue_item_type,
    gfx_data JSONB,
    duration_seconds INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        ci.id,
        ci.cue_number,
        ci.cue_type,
        ci.gfx_data,
        ci.duration_seconds
    FROM cue_items ci
    JOIN cue_sheets cs ON ci.sheet_id = cs.id
    WHERE ci.sheet_id = p_sheet_id
      AND ci.status IN ('pending', 'ready', 'standby')
      AND ci.sort_order > COALESCE(
          (SELECT sort_order FROM cue_items WHERE id = cs.current_item_id),
          -1
      )
    ORDER BY ci.sort_order
    LIMIT 1;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- RLS (Row Level Security)
-- ============================================================================

-- 모든 테이블 RLS 활성화
ALTER TABLE broadcast_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE cue_sheets ENABLE ROW LEVEL SECURITY;
ALTER TABLE cue_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE chip_snapshots ENABLE ROW LEVEL SECURITY;
ALTER TABLE cue_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE gfx_triggers ENABLE ROW LEVEL SECURITY;

-- broadcast_sessions 정책
CREATE POLICY "broadcast_sessions_select_authenticated"
    ON broadcast_sessions FOR SELECT
    USING (auth.role() = 'authenticated');

CREATE POLICY "broadcast_sessions_insert_service"
    ON broadcast_sessions FOR INSERT
    WITH CHECK (auth.role() = 'service_role');

CREATE POLICY "broadcast_sessions_update_service"
    ON broadcast_sessions FOR UPDATE
    USING (auth.role() = 'service_role');

-- cue_sheets 정책
CREATE POLICY "cue_sheets_select_authenticated"
    ON cue_sheets FOR SELECT
    USING (auth.role() = 'authenticated');

CREATE POLICY "cue_sheets_all_service"
    ON cue_sheets FOR ALL
    USING (auth.role() = 'service_role');

-- cue_items 정책
CREATE POLICY "cue_items_select_authenticated"
    ON cue_items FOR SELECT
    USING (auth.role() = 'authenticated');

CREATE POLICY "cue_items_all_service"
    ON cue_items FOR ALL
    USING (auth.role() = 'service_role');

-- chip_snapshots 정책
CREATE POLICY "chip_snapshots_select_authenticated"
    ON chip_snapshots FOR SELECT
    USING (auth.role() = 'authenticated');

CREATE POLICY "chip_snapshots_all_service"
    ON chip_snapshots FOR ALL
    USING (auth.role() = 'service_role');

-- cue_templates 정책
CREATE POLICY "cue_templates_select_authenticated"
    ON cue_templates FOR SELECT
    USING (auth.role() = 'authenticated');

CREATE POLICY "cue_templates_all_service"
    ON cue_templates FOR ALL
    USING (auth.role() = 'service_role');

-- gfx_triggers 정책
CREATE POLICY "gfx_triggers_select_authenticated"
    ON gfx_triggers FOR SELECT
    USING (auth.role() = 'authenticated');

CREATE POLICY "gfx_triggers_insert_service"
    ON gfx_triggers FOR INSERT
    WITH CHECK (auth.role() = 'service_role');
