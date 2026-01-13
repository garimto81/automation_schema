# 05. Cuesheet Database Schema

방송 진행 큐시트 관리를 위한 PostgreSQL/Supabase 데이터베이스 스키마 설계 문서

**Version**: 2.0.0
**Date**: 2026-01-13
**Project**: Automation DB Schema
**Source**: [Google Sheets - WSOP SC Cyprus ME Day1A](https://docs.google.com/spreadsheets/d/1XiZqoZ3DggHdafWGEzN3PTbCNmTRSt8Ab1Ofclsoc34/edit)

---

## 1. 개요

### 1.1 목적

포커 방송의 진행 순서 및 GFX 출력을 관리하여:
- 방송 세션 및 큐시트 관리
- 개별 큐 아이템 (GFX 요소) 순서 제어
- **핸드 히스토리 및 편집 포인트 관리**
- **칩카운트/리더보드 데이터 연동**
- 큐 템플릿으로 재사용 가능한 구성 저장
- GFX 트리거 및 렌더링 상태 추적
- 실시간 방송 진행 모니터링

### 1.2 Google Sheets 원본 구조

실제 운영 중인 큐시트 스프레드시트 구조:

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  CUE SHEET [1016 WSOP SC Cyprus Main Event Day 1A]                          │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  시트 목록 (17개):                                                          │
│  ├── INFO          : 이벤트 요약 (블록별 핸드 수, 런타임)                   │
│  ├── LIVE          : 방송 진행용 메인 큐시트 ⭐                             │
│  ├── FRONT         : 타임라인 기반 전체 큐 (MAIN/SUB/VIRTUAL)              │
│  ├── PD            : PD용 타임라인 (편집 지시)                              │
│  ├── SUBTITLE      : 자막팀용 타임라인                                      │
│  ├── main          : MAIN 테이블 핸드 타임라인                              │
│  ├── sub           : SUB 테이블 핸드 타임라인                               │
│  ├── virtual       : 버추얼 GFX 타임라인                                    │
│  ├── chipcount     : 실시간 칩카운트 (포커캐스터 연동)                      │
│  ├── leaderboard   : 전체 리더보드                                          │
│  ├── payout        : 상금 구조                                              │
│  ├── template      : GFX 템플릿 정의                                        │
│  ├── for ZED       : ZED(외주 편집) 전달용                                  │
│  └── ati-*         : ATI 시스템 연동용                                      │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 1.3 LIVE 시트 컬럼 구조 (핵심)

| 컬럼 | 필드명 | 설명 | 예시 |
|------|--------|------|------|
| A | special_info | 특별 정보 | "2-TIME BRACELET WINNER" |
| B | content_type | 콘텐츠 타입 | OPENING SEQUENCE, MAIN, SUB, VIRTUAL |
| C | hand_number | 핸드 번호 | 1, 2, 3... (최대 176) |
| D | rank | 핸드 등급 | A, B, B-, C |
| E | hand_history | 핸드 히스토리 | "Pre: AK RAISE\\nFlop: ..." |
| F | edit_point | 편집 시작점 | "프리플랍부터" |
| G | pd_note | PD 노트 | "WINNER: COHEN" |
| H | time | 촬영 시간 | "14:36" |
| I | subtitle_flag | 자막 필요 여부 | TRUE/FALSE |
| J | blind_level | 블라인드 | "300 / 500" |
| K | subtitle_confirm | 자막 (컨펌용) | 자막 텍스트 |
| L | subtitle_team | 자막 (자막팀) | 자막팀 버전 |
| M | post_flag | 사후 제작 여부 | TRUE/FALSE |
| N | copy_status | 복사 상태 | "복사완료" |
| O | file_name | 파일명 | "A_0003", "B_0004" |
| P | transition | 전환 효과 | - |
| Q | timecode_in | 시작 타임코드 | "00:01:25" |
| R | timecode_out | 종료 타임코드 | "00:01:55" |

### 1.4 큐시트 흐름

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           Cuesheet Workflow                                  │
└─────────────────────────────────────────────────────────────────────────────┘

┌───────────────┐     ┌───────────────┐     ┌───────────────┐
│   방송 세션    │────▶│   큐시트      │────▶│   큐 아이템    │
│   (Session)   │  1:N│   (Sheet)     │  1:N│   (Item)      │
└───────────────┘     └───────────────┘     └───────┬───────┘
        │                                          │
        │                                          │ trigger
        │                                          ▼
        │            ┌───────────────┐     ┌───────────────┐
        │            │   큐 템플릿    │     │  GFX 트리거   │
        │            │   (Template)  │────▶│   (Trigger)   │
        │            └───────────────┘     └───────┬───────┘
        │                                          │
        │   1:N                                    │ render
        ▼                                          ▼
┌───────────────┐                          ┌───────────────┐
│   칩카운트    │                          │   AEP 렌더    │
│ (ChipSnapshot)│                          │   (Output)    │
└───────────────┘                          └───────────────┘
```

### 1.5 핵심 기능

| 기능 | 설명 |
|------|------|
| **세션 관리** | 방송 일정, 블록별 통계, 런타임 관리 |
| **큐시트 관리** | 방송 구간별 큐시트 구성 |
| **큐 아이템** | 개별 GFX 요소 순서/타이밍 제어 |
| **핸드 히스토리** | Pre/Flop/Turn/River 액션 기록 |
| **칩카운트 스냅샷** | 실시간 칩 현황 스냅샷 저장 |
| **템플릿** | 재사용 가능한 큐 구성 저장 |
| **트리거 로그** | GFX 송출 이력 추적 |

---

## 2. ERD (Entity Relationship Diagram)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    Cuesheet Database Schema v2.0                             │
│                  (Based on Google Sheets Analysis)                           │
└─────────────────────────────────────────────────────────────────────────────┘

┌──────────────────────┐
│  broadcast_sessions  │
│  (방송 세션)          │
├──────────────────────┤
│ PK id: uuid          │
│ UK session_code: text│───┐     예: "1016-WSOP-SC-ME-D1A"
│    event_name: text  │   │
│    event_id: uuid    │   │  FK to wsop_events (optional)
│    broadcast_date    │   │
│    scheduled_start   │   │     예: 13:00 (Cyprus)
│    scheduled_end     │   │
│    actual_start      │   │
│    actual_end        │   │
│    total_runtime     │   │     예: "06:49:19"
│    status: enum      │   │
│    director: text    │   │
│    commentators: jsonb│  │
│    block_stats: jsonb│   │     블록별 핸드 수, 런타임
│    settings: jsonb   │   │
│    created_at        │   │
│    updated_at        │   │
└──────────┬───────────┘   │
           │               │
           │ 1:N           │
           ▼               │
┌──────────────────────┐   │   ┌──────────────────────┐
│     cue_sheets       │   │   │  chip_snapshots      │
│     (큐시트)         │   │   │  (칩카운트 스냅샷)   │
├──────────────────────┤   │   ├──────────────────────┤
│ PK id: uuid          │   │   │ PK id: uuid          │
│ UK sheet_code: text  │   │   │ FK session_id: uuid  │◄─┐
│ FK session_id: uuid  │◄──┘   │    snapshot_time     │  │
│    sheet_name: text  │       │    blind_level: text │  │
│    sheet_type: enum  │       │    players_remaining │  │
│    sheet_order: int  │       │    avg_stack: int    │  │
│    status: enum      │       │    total_chips: bigint│ │
│    total_items: int  │       │    data: jsonb       │  │
│    current_item_id   │───┐   │    created_at        │  │
│    created_at        │   │   └──────────────────────┘  │
│    updated_at        │   │                             │
└──────────┬───────────┘   │                             │
           │               │                             │
           │ 1:N           │                             │
           ▼               │                             │
┌──────────────────────┐   │                             │
│     cue_items        │◄──┘                             │
│   (큐 아이템)        │                                 │
├──────────────────────┤     ⭐ LIVE 시트 매핑          │
│ PK id: uuid          │                                 │
│ FK sheet_id: uuid    │                                 │
│ FK template_id: uuid │◄─────────────────────┐         │
│ FK snapshot_id: uuid │─────────────────────────────────┘
│    content_type: enum│     MAIN, SUB, VIRTUAL, OPENING
│    hand_number: int  │     핸드 번호 (1-176)
│    hand_rank: text   │     A, B, B-, C
│    hand_history: text│     Pre/Flop/Turn/River 액션
│    edit_point: text  │     "프리플랍부터"
│    pd_note: text     │     "WINNER: COHEN"
│    recording_time    │     촬영 시간 (14:36)
│    subtitle_flag     │     자막 필요 여부
│    blind_level: text │     "300 / 500"
│    subtitle_confirm  │     자막 (컨펌용)
│    subtitle_team     │     자막 (자막팀용)
│    post_flag: bool   │     사후 제작 여부
│    copy_status: text │     "복사완료"
│    file_name: text   │     "A_0003", "B_0004"
│    timecode_in: text │     "00:01:25"
│    timecode_out: text│     "00:01:55"
│    transition: text  │     전환 효과
│    special_info: text│     "2-TIME BRACELET WINNER"
│    gfx_data: jsonb   │     GFX 바인딩 데이터
│    status: enum      │     pending, on_air, completed
│    sort_order: int   │
│    created_at        │
│    updated_at        │
└──────────┬───────────┘                   │
           │                               │
           │ 1:N                           │
           ▼                               │
┌──────────────────────┐   ┌──────────────────────┐
│    gfx_triggers      │   │   cue_templates      │
│   (GFX 트리거 로그)   │   │   (큐 템플릿)        │
├──────────────────────┤   ├──────────────────────┤
│ PK id: uuid          │   │ PK id: uuid          │
│ FK cue_item_id: uuid │   │ UK template_code     │───┘
│ FK session_id: uuid  │   │    template_name     │
│    trigger_type: enum│   │    template_type     │  MINI_CHIP, PAYOUT, etc.
│    trigger_time: ts  │   │    gfx_template_name │
│    triggered_by: text│   │    default_duration  │
│    gfx_data: jsonb   │   │    data_schema: jsonb│
│    render_status:enum│   │    sample_data: jsonb│
│    output_path: text │   │    is_active: bool   │
│    duration_ms: int  │   │    created_at        │
│    created_at        │   │    updated_at        │
└──────────────────────┘   └──────────────────────┘
```

### 테이블 관계 요약

| 관계 | 설명 |
|------|------|
| `broadcast_sessions` 1:N `cue_sheets` | 세션당 여러 큐시트 |
| `broadcast_sessions` 1:N `chip_snapshots` | 세션당 여러 칩 스냅샷 |
| `cue_sheets` 1:N `cue_items` | 큐시트당 여러 아이템 |
| `cue_items` 1:N `gfx_triggers` | 아이템당 여러 트리거 |
| `cue_items` N:1 `chip_snapshots` | 아이템이 특정 스냅샷 참조 |
| `cue_templates` 1:N `cue_items` | 템플릿 → 아이템 참조 |
| `cue_sheets.current_item_id` → `cue_items` | 현재 진행 중 아이템 |

---

## 3. Enum 타입 정의

```sql
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
-- Google Sheets 원본: OPENING SEQUENCE, Leaderboard, MAIN, SUB, VIRTUAL
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
```

---

## 4. 테이블 DDL

### 4.1 broadcast_sessions (방송 세션)

```sql
-- ============================================================================
-- broadcast_sessions: 방송 세션 정보
-- 하나의 방송 날짜/이벤트에 대한 전체 정보
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
    /*
    [
        {"name": "홍길동", "role": "main", "language": "ko"},
        {"name": "John Doe", "role": "color", "language": "en"}
    ]
    */

    reporters JSONB DEFAULT '[]'::JSONB,

    -- 방송 설정
    settings JSONB DEFAULT '{}'::JSONB,
    /*
    {
        "default_gfx_duration": 10,
        "auto_advance": true,
        "language": "ko",
        "resolution": "1080p"
    }
    */

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

-- 인덱스
CREATE INDEX idx_broadcast_sessions_code ON broadcast_sessions(session_code);
CREATE INDEX idx_broadcast_sessions_date ON broadcast_sessions(broadcast_date DESC);
CREATE INDEX idx_broadcast_sessions_status ON broadcast_sessions(status);
CREATE INDEX idx_broadcast_sessions_event ON broadcast_sessions(event_id);
CREATE INDEX idx_broadcast_sessions_scheduled ON broadcast_sessions(scheduled_start DESC);
CREATE INDEX idx_broadcast_sessions_tags ON broadcast_sessions USING GIN (tags);
```

### 4.2 cue_sheets (큐시트)

```sql
-- ============================================================================
-- cue_sheets: 방송 큐시트
-- 방송 세션 내의 구간별 큐 목록
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
    current_item_id UUID,  -- 현재 진행 중인 아이템
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

-- 인덱스
CREATE INDEX idx_cue_sheets_code ON cue_sheets(sheet_code);
CREATE INDEX idx_cue_sheets_session ON cue_sheets(session_id);
CREATE INDEX idx_cue_sheets_type ON cue_sheets(sheet_type);
CREATE INDEX idx_cue_sheets_status ON cue_sheets(status);
CREATE INDEX idx_cue_sheets_order ON cue_sheets(session_id, sheet_order);

-- FK 추가 (순환 참조 방지를 위해 별도 추가)
ALTER TABLE cue_sheets
    ADD CONSTRAINT fk_cue_sheets_current_item
    FOREIGN KEY (current_item_id)
    REFERENCES cue_items(id)
    ON DELETE SET NULL
    DEFERRABLE INITIALLY DEFERRED;
```

### 4.3 cue_items (큐 아이템) - LIVE 시트 매핑

```sql
-- ============================================================================
-- cue_items: 개별 큐 아이템
-- Google Sheets LIVE 시트의 각 행에 대응
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
    /*
    예시:
    "Pre: SOKRUTA AK RAISE, GABDULLIN 44 CALL
    Flop: 44 CHECK, AK BET, 44 RAISE, AK CALL
    Turn: 44 BET, AK CALL
    River: 44 BET, AK CALL"
    */

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
    /*
    예시:
    "[LEFT]MINI_CHIP_TABLE 24
    GLOSHKIN / 86,500
    ASMOLOVA / 75,200
    ...
    BLINDS 300/500 - 500 (BB)"
    */

    -- L열: 자막 (자막팀용)
    subtitle_team TEXT,

    -- M열: 사후 제작 여부
    post_flag BOOLEAN DEFAULT FALSE,

    -- N열: 복사 상태
    copy_status TEXT,  -- "복사완료"

    -- O열: 파일명
    file_name TEXT,  -- "A_0003", "B_0004", "1809_SC001_Georgios_Tsouloftas_L3_Profile"

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

-- 인덱스
CREATE INDEX idx_cue_items_sheet ON cue_items(sheet_id);
CREATE INDEX idx_cue_items_content_type ON cue_items(content_type);
CREATE INDEX idx_cue_items_hand_number ON cue_items(hand_number) WHERE hand_number IS NOT NULL;
CREATE INDEX idx_cue_items_status ON cue_items(status);
CREATE INDEX idx_cue_items_order ON cue_items(sheet_id, sort_order);
CREATE INDEX idx_cue_items_template ON cue_items(template_id);
CREATE INDEX idx_cue_items_snapshot ON cue_items(snapshot_id);
CREATE INDEX idx_cue_items_file_name ON cue_items(file_name) WHERE file_name IS NOT NULL;
CREATE INDEX idx_cue_items_gfx_data ON cue_items USING GIN (gfx_data);
```

### 4.3.1 chip_snapshots (칩카운트 스냅샷)

```sql
-- ============================================================================
-- chip_snapshots: 칩카운트 스냅샷
-- Google Sheets chipcount/leaderboard 시트 데이터
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
    /*
    [
        {
            "rank": 1,
            "poker_room": "Main",
            "table_name": "Red",
            "table_id": 43748,
            "table_no": 24,
            "seat_id": 435388,
            "seat_no": 3,
            "player_id": 101437,
            "player_name": "Oscar Romero Cobos",
            "player_name_display": "OSCAR COBOS",
            "nationality": "ES",
            "chipcount": 154500,
            "bb_stack": 103
        },
        ...
    ]
    */

    -- 메타데이터
    source TEXT DEFAULT 'pokercaster',  -- 데이터 소스
    notes TEXT,

    -- 타임스탬프
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 인덱스
CREATE INDEX idx_chip_snapshots_session ON chip_snapshots(session_id);
CREATE INDEX idx_chip_snapshots_time ON chip_snapshots(snapshot_time DESC);
CREATE INDEX idx_chip_snapshots_players ON chip_snapshots USING GIN (players_data);
```

### 4.4 cue_templates (큐 템플릿) - template 시트 매핑

```sql
-- ============================================================================
-- cue_templates: 재사용 가능한 큐 템플릿
-- Google Sheets template 시트의 GFX 템플릿 정의
-- ============================================================================

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

    -- 샘플 데이터 (미리보기용) - Google Sheets template 시트의 예시
    sample_data JSONB DEFAULT '{}'::JSONB,
    /*
    Mini Chip Table 예시:
    {
        "table_no": 24,
        "players": [
            {"name": "GLOSHKIN", "chips": 114800, "is_winner": true},
            {"name": "ASMOLOVA", "chips": 75200},
            ...
        ],
        "blinds": "300/500 - 500 (BB)"
    }

    VPIP 예시:
    {
        "player_name": "BAGIROV",
        "country": "RUSSIA",
        "vpip_percent": 72
    }

    Chip Flow 예시:
    {
        "player_name": "BAGIROV",
        "country": "RUSSIA",
        "chip_history": [685000, 785000, 1785000, 2785000, 3785000],
        "period": "LAST 20 HANDS"
    }
    */

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

-- 인덱스
CREATE INDEX idx_cue_templates_code ON cue_templates(template_code);
CREATE INDEX idx_cue_templates_type ON cue_templates(template_type);
CREATE INDEX idx_cue_templates_category ON cue_templates(category);
CREATE INDEX idx_cue_templates_active ON cue_templates(is_active) WHERE is_active = TRUE;
CREATE INDEX idx_cue_templates_tags ON cue_templates USING GIN (tags);
CREATE INDEX idx_cue_templates_usage ON cue_templates(usage_count DESC);
```

### 4.5 gfx_triggers (GFX 트리거 로그)

```sql
-- ============================================================================
-- gfx_triggers: GFX 송출 트리거 로그
-- 모든 GFX 송출 이력 기록
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

-- 인덱스
CREATE INDEX idx_gfx_triggers_cue_item ON gfx_triggers(cue_item_id);
CREATE INDEX idx_gfx_triggers_session ON gfx_triggers(session_id);
CREATE INDEX idx_gfx_triggers_sheet ON gfx_triggers(sheet_id);
CREATE INDEX idx_gfx_triggers_type ON gfx_triggers(trigger_type);
CREATE INDEX idx_gfx_triggers_time ON gfx_triggers(trigger_time DESC);
CREATE INDEX idx_gfx_triggers_status ON gfx_triggers(render_status);
CREATE INDEX idx_gfx_triggers_cue_type ON gfx_triggers(cue_type);
CREATE INDEX idx_gfx_triggers_triggered_by ON gfx_triggers(triggered_by);

-- 최근 트리거 빠른 조회용
CREATE INDEX idx_gfx_triggers_recent ON gfx_triggers(session_id, trigger_time DESC);
```

---

## 5. 뷰 정의

### 5.1 v_session_overview (세션 개요 뷰)

```sql
-- ============================================================================
-- v_session_overview: 방송 세션 개요 및 진행 상황
-- ============================================================================

CREATE OR REPLACE VIEW v_session_overview AS
SELECT
    bs.id,
    bs.session_code,
    bs.event_name,
    bs.broadcast_date,
    bs.scheduled_start,
    bs.actual_start,
    bs.status,
    bs.director,

    -- 큐시트 통계
    COUNT(cs.id) AS total_sheets,
    COUNT(CASE WHEN cs.status = 'completed' THEN 1 END) AS completed_sheets,
    COUNT(CASE WHEN cs.status = 'active' THEN 1 END) AS active_sheets,

    -- 큐 아이템 통계
    SUM(cs.total_items) AS total_items,
    SUM(cs.completed_items) AS completed_items,

    -- 진행률
    CASE
        WHEN SUM(cs.total_items) > 0
        THEN ROUND(SUM(cs.completed_items)::NUMERIC / SUM(cs.total_items) * 100, 1)
        ELSE 0
    END AS progress_percent,

    bs.updated_at

FROM broadcast_sessions bs
LEFT JOIN cue_sheets cs ON bs.id = cs.session_id
GROUP BY bs.id
ORDER BY bs.broadcast_date DESC, bs.scheduled_start DESC;
```

### 5.2 v_cue_sheet_items (큐시트 아이템 목록 뷰)

```sql
-- ============================================================================
-- v_cue_sheet_items: 큐시트별 아이템 목록
-- ============================================================================

CREATE OR REPLACE VIEW v_cue_sheet_items AS
SELECT
    ci.id,
    ci.cue_number,
    ci.title,
    ci.cue_type,
    ci.status,
    ci.duration_seconds,
    ci.sort_order,
    ci.gfx_template_name,
    ci.scheduled_time,
    ci.actual_time,

    -- 큐시트 정보
    cs.id AS sheet_id,
    cs.sheet_code,
    cs.sheet_name,
    cs.sheet_type,

    -- 세션 정보
    bs.id AS session_id,
    bs.session_code,
    bs.event_name,

    -- 현재 진행 여부
    (cs.current_item_id = ci.id) AS is_current,

    -- 템플릿 정보
    ct.template_name,
    ct.preview_image_url,

    ci.updated_at

FROM cue_items ci
JOIN cue_sheets cs ON ci.sheet_id = cs.id
JOIN broadcast_sessions bs ON cs.session_id = bs.id
LEFT JOIN cue_templates ct ON ci.template_id = ct.id
ORDER BY cs.session_id, cs.sheet_order, ci.sort_order;
```

### 5.3 v_active_cues (현재 활성 큐 뷰)

```sql
-- ============================================================================
-- v_active_cues: 현재 진행 중인 세션의 활성 큐
-- ============================================================================

CREATE OR REPLACE VIEW v_active_cues AS
SELECT
    ci.id,
    ci.cue_number,
    ci.title,
    ci.cue_type,
    ci.status,
    ci.gfx_data,
    ci.duration_seconds,

    cs.sheet_name,
    bs.session_code,
    bs.event_name,

    -- 다음 큐 정보
    (
        SELECT ci2.title
        FROM cue_items ci2
        WHERE ci2.sheet_id = ci.sheet_id
          AND ci2.sort_order > ci.sort_order
        ORDER BY ci2.sort_order
        LIMIT 1
    ) AS next_cue_title

FROM cue_items ci
JOIN cue_sheets cs ON ci.sheet_id = cs.id
JOIN broadcast_sessions bs ON cs.session_id = bs.id
WHERE bs.status = 'live'
  AND cs.status = 'active'
  AND ci.status IN ('standby', 'on_air')
ORDER BY ci.sort_order;
```

### 5.4 v_trigger_history (트리거 이력 뷰)

```sql
-- ============================================================================
-- v_trigger_history: GFX 트리거 이력
-- ============================================================================

CREATE OR REPLACE VIEW v_trigger_history AS
SELECT
    gt.id,
    gt.trigger_type,
    gt.trigger_time,
    gt.triggered_by,
    gt.cue_type,
    gt.aep_comp_name,
    gt.render_status,
    gt.duration_ms,
    gt.error_message,

    ci.cue_number,
    ci.title AS cue_title,

    cs.sheet_name,
    bs.session_code,
    bs.event_name

FROM gfx_triggers gt
LEFT JOIN cue_items ci ON gt.cue_item_id = ci.id
LEFT JOIN cue_sheets cs ON gt.sheet_id = cs.id
LEFT JOIN broadcast_sessions bs ON gt.session_id = bs.id
ORDER BY gt.trigger_time DESC;
```

### 5.5 v_template_usage (템플릿 사용 현황 뷰)

```sql
-- ============================================================================
-- v_template_usage: 템플릿 사용 현황
-- ============================================================================

CREATE OR REPLACE VIEW v_template_usage AS
SELECT
    ct.id,
    ct.template_code,
    ct.template_name,
    ct.cue_type,
    ct.category,
    ct.is_active,
    ct.usage_count,
    ct.last_used_at,

    -- 최근 30일 사용 횟수
    (
        SELECT COUNT(*)
        FROM cue_items ci
        WHERE ci.template_id = ct.id
          AND ci.created_at > NOW() - INTERVAL '30 days'
    ) AS usage_last_30_days,

    -- 현재 사용 중인 아이템 수
    (
        SELECT COUNT(*)
        FROM cue_items ci
        JOIN cue_sheets cs ON ci.sheet_id = cs.id
        JOIN broadcast_sessions bs ON cs.session_id = bs.id
        WHERE ci.template_id = ct.id
          AND bs.status = 'live'
    ) AS active_usage_count

FROM cue_templates ct
WHERE ct.is_active = TRUE
ORDER BY ct.usage_count DESC;
```

---

## 6. 함수 및 트리거

### 6.1 updated_at 자동 갱신

```sql
-- ============================================================================
-- 트리거 함수: updated_at 자동 갱신
-- ============================================================================

CREATE OR REPLACE FUNCTION update_cue_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 각 테이블에 트리거 적용
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
```

### 6.2 큐시트 통계 자동 업데이트

```sql
-- ============================================================================
-- 함수: 큐시트 아이템 통계 업데이트
-- ============================================================================

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
```

### 6.3 세션 통계 자동 업데이트

```sql
-- ============================================================================
-- 함수: 세션 통계 업데이트
-- ============================================================================

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
```

### 6.4 템플릿 사용 횟수 업데이트

```sql
-- ============================================================================
-- 함수: 템플릿 사용 횟수 증가
-- ============================================================================

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
```

### 6.5 큐 아이템 상태 전환

```sql
-- ============================================================================
-- 함수: 큐 아이템 상태 전환 및 로그 기록
-- ============================================================================

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
```

### 6.6 다음 큐 아이템 조회

```sql
-- ============================================================================
-- 함수: 다음 큐 아이템 조회
-- ============================================================================

CREATE OR REPLACE FUNCTION get_next_cue_item(p_sheet_id UUID)
RETURNS TABLE (
    id UUID,
    cue_number TEXT,
    title TEXT,
    cue_type cue_item_type,
    gfx_data JSONB,
    duration_seconds INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        ci.id,
        ci.cue_number,
        ci.title,
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
```

---

## 7. 인덱스 전략 및 쿼리 패턴

### 7.1 주요 쿼리 패턴

| 쿼리 패턴 | 설명 | 최적화 인덱스 |
|-----------|------|---------------|
| 오늘 방송 세션 | `WHERE broadcast_date = CURRENT_DATE` | `idx_broadcast_sessions_date` |
| 진행 중 세션 | `WHERE status = 'live'` | `idx_broadcast_sessions_status` |
| 세션별 큐시트 | `WHERE session_id = ?` | `idx_cue_sheets_session` |
| 큐시트별 아이템 | `WHERE sheet_id = ? ORDER BY sort_order` | `idx_cue_items_order` |
| 대기 중 아이템 | `WHERE status = 'standby'` | `idx_cue_items_status` |
| 최근 트리거 | `WHERE trigger_time > ? ORDER BY trigger_time DESC` | `idx_gfx_triggers_time` |
| 템플릿 검색 | `WHERE category = ?` | `idx_cue_templates_category` |

### 7.2 인덱스 요약

```sql
-- Primary Keys (자동 생성)
-- broadcast_sessions.id, cue_sheets.id, cue_items.id, etc.

-- Unique Constraints
-- broadcast_sessions.session_code
-- cue_sheets.sheet_code
-- cue_templates.template_code
-- (session_id, sheet_order), (sheet_id, sort_order)

-- B-tree Indexes (범위/정렬 쿼리)
-- broadcast_sessions: broadcast_date DESC, scheduled_start DESC
-- cue_sheets: session_id, sheet_order
-- cue_items: sheet_id, sort_order
-- gfx_triggers: trigger_time DESC

-- GIN Indexes (배열/JSONB 검색)
-- broadcast_sessions.tags
-- cue_templates.tags
-- cue_items.gfx_data

-- Partial Indexes (조건부 최적화)
-- cue_templates.is_active WHERE TRUE
-- cue_items.scheduled_time WHERE NOT NULL
```

---

## 8. RLS 정책 (Row Level Security)

```sql
-- ============================================================================
-- RLS 정책 설정 (Supabase 환경)
-- ============================================================================

-- 모든 테이블 RLS 활성화
ALTER TABLE broadcast_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE cue_sheets ENABLE ROW LEVEL SECURITY;
ALTER TABLE cue_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE cue_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE gfx_triggers ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- broadcast_sessions 정책
-- ============================================================================
CREATE POLICY "broadcast_sessions_select_authenticated"
    ON broadcast_sessions FOR SELECT
    USING (auth.role() = 'authenticated');

CREATE POLICY "broadcast_sessions_insert_service"
    ON broadcast_sessions FOR INSERT
    WITH CHECK (auth.role() = 'service_role');

CREATE POLICY "broadcast_sessions_update_service"
    ON broadcast_sessions FOR UPDATE
    USING (auth.role() = 'service_role');

-- ============================================================================
-- cue_sheets 정책
-- ============================================================================
CREATE POLICY "cue_sheets_select_authenticated"
    ON cue_sheets FOR SELECT
    USING (auth.role() = 'authenticated');

CREATE POLICY "cue_sheets_all_service"
    ON cue_sheets FOR ALL
    USING (auth.role() = 'service_role');

-- ============================================================================
-- cue_items 정책
-- ============================================================================
CREATE POLICY "cue_items_select_authenticated"
    ON cue_items FOR SELECT
    USING (auth.role() = 'authenticated');

CREATE POLICY "cue_items_all_service"
    ON cue_items FOR ALL
    USING (auth.role() = 'service_role');

-- ============================================================================
-- cue_templates 정책
-- ============================================================================
CREATE POLICY "cue_templates_select_authenticated"
    ON cue_templates FOR SELECT
    USING (auth.role() = 'authenticated');

CREATE POLICY "cue_templates_all_service"
    ON cue_templates FOR ALL
    USING (auth.role() = 'service_role');

-- ============================================================================
-- gfx_triggers 정책
-- ============================================================================
CREATE POLICY "gfx_triggers_select_authenticated"
    ON gfx_triggers FOR SELECT
    USING (auth.role() = 'authenticated');

CREATE POLICY "gfx_triggers_insert_service"
    ON gfx_triggers FOR INSERT
    WITH CHECK (auth.role() = 'service_role');
```

---

## 9. 마이그레이션 순서

### 실행 순서

```
1. ENUM 타입 생성 (CREATE TYPE)
2. broadcast_sessions 테이블 생성
3. cue_templates 테이블 생성
4. cue_sheets 테이블 생성 (current_item_id FK 제외)
5. cue_items 테이블 생성
6. cue_sheets에 current_item_id FK 추가 (ALTER TABLE)
7. gfx_triggers 테이블 생성
8. 뷰 생성 (CREATE VIEW)
9. 함수 생성 (CREATE FUNCTION)
10. 트리거 생성 (CREATE TRIGGER)
11. 인덱스 생성 (CREATE INDEX)
12. RLS 정책 적용 (ALTER TABLE, CREATE POLICY)
```

### Rollback 순서 (역순)

```
1. RLS 정책 삭제 (DROP POLICY)
2. 인덱스 삭제 (DROP INDEX)
3. 트리거 삭제 (DROP TRIGGER)
4. 함수 삭제 (DROP FUNCTION)
5. 뷰 삭제 (DROP VIEW)
6. cue_sheets.current_item_id FK 삭제
7. 테이블 삭제 (역순)
8. ENUM 타입 삭제 (DROP TYPE)
```

---

## 10. 제약조건 요약

| 테이블 | 제약조건 | 설명 |
|--------|----------|------|
| `broadcast_sessions` | `session_code UNIQUE` | 세션 코드 중복 방지 |
| `cue_sheets` | `sheet_code UNIQUE` | 큐시트 코드 중복 방지 |
| `cue_sheets` | `(session_id, sheet_order) UNIQUE` | 세션 내 순서 중복 방지 |
| `cue_items` | `(sheet_id, sort_order) UNIQUE` | 큐시트 내 순서 중복 방지 |
| `cue_templates` | `template_code UNIQUE` | 템플릿 코드 중복 방지 |

---

## 11. 구현 연동 파일

| 파일 | 역할 | 연동 테이블 |
|------|------|-------------|
| `src/services/broadcast_service.py` | 방송 세션 관리 | broadcast_sessions |
| `src/services/cuesheet_service.py` | 큐시트 CRUD | cue_sheets, cue_items |
| `src/services/template_service.py` | 템플릿 관리 | cue_templates |
| `src/services/trigger_service.py` | GFX 트리거 | gfx_triggers |
| `src/api/cuesheet_api.py` | REST API | 전체 |
| `src/websocket/live_cue_handler.py` | 실시간 업데이트 | cue_items, gfx_triggers |

---

## Appendix: 큐 아이템 GFX 데이터 예시

### 칩 카운트 (chip_count)

```json
{
  "players": [
    {
      "rank": 1,
      "name": "홍길동",
      "country_code": "KR",
      "chips": 1500000,
      "stack_bbs": 75
    },
    {
      "rank": 2,
      "name": "John Doe",
      "country_code": "US",
      "chips": 1200000,
      "stack_bbs": 60
    }
  ],
  "event_name": "WSOP Main Event",
  "players_remaining": 100,
  "avg_stack": 500000
}
```

### 선수 정보 (player_info)

```json
{
  "name": "홍길동",
  "name_display": "Gil-Dong Hong",
  "country_code": "KR",
  "country_name": "South Korea",
  "profile_image": "/images/players/hong.jpg",
  "chips": 1500000,
  "rank": 1,
  "wsop_bracelets": 2,
  "notable_wins": ["2023 WSOP Asia Main Event"]
}
```

### 탈락 정보 (elimination)

```json
{
  "eliminated_player": {
    "name": "Jane Doe",
    "country_code": "UK",
    "chips_at_elimination": 0,
    "final_rank": 50
  },
  "eliminator": {
    "name": "홍길동",
    "country_code": "KR"
  },
  "prize_won": 25000,
  "elimination_hand": "AA vs KK"
}
```

---

## Appendix B: Google Sheets 원본 데이터 매핑

### B.1 스프레드시트 정보

| 항목 | 값 |
|------|-----|
| **URL** | [Google Sheets](https://docs.google.com/spreadsheets/d/1XiZqoZ3DggHdafWGEzN3PTbCNmTRSt8Ab1Ofclsoc34/edit) |
| **제목** | CUE SHEET [1016 WSOP SC Cyprus Main Event Day 1A] |
| **시트 수** | 17개 |

### B.2 시트별 매핑

| 시트 | GID | DB 테이블 | 설명 |
|------|-----|-----------|------|
| INFO | 1451613436 | `broadcast_sessions.block_stats` | 블록별 통계 |
| **LIVE** | 390049308 | `cue_items` | 메인 큐시트 ⭐ |
| FRONT | 1427920466 | (참조용) | 타임라인 기반 전체 뷰 |
| PD | 481406284 | (참조용) | PD용 타임라인 |
| SUBTITLE | 1333911885 | (참조용) | 자막팀용 타임라인 |
| main | 495054819 | (참조용) | MAIN 테이블 타임라인 |
| sub | 360071413 | (참조용) | SUB 테이블 타임라인 |
| virtual | 561799849 | (참조용) | VIRTUAL GFX 타임라인 |
| **chipcount** | 863418569 | `chip_snapshots` | 실시간 칩카운트 |
| leaderboard | 369994611 | `chip_snapshots` | 전체 리더보드 |
| **payout** | 1594013979 | (별도 스키마) | 상금 구조 |
| **template** | 487939277 | `cue_templates` | GFX 템플릿 정의 |
| for ZED | 1519464196 | (외부 연동) | ZED 전달용 |
| ati-* | - | (외부 연동) | ATI 시스템 연동 |

### B.3 LIVE 시트 컬럼 → cue_items 필드 매핑

| 컬럼 | 시트 헤더 | DB 필드 | 타입 |
|------|----------|---------|------|
| A | (특별 정보) | `special_info` | TEXT |
| B | Content | `content_type` | ENUM |
| C | # (핸드 번호) | `hand_number` | INTEGER |
| D | Rank | `hand_rank` | ENUM |
| E | Hand History | `hand_history` | TEXT |
| F | Edit Point | `edit_point` | TEXT |
| G | PD Note | `pd_note` | TEXT |
| H | Time | `recording_time` | TIME |
| I | SUBTITLE (플래그) | `subtitle_flag` | BOOLEAN |
| J | Blind | `blind_level` | TEXT |
| K | Subtitle (컨펌용) | `subtitle_confirm` | TEXT |
| L | Subtitle (자막팀) | `subtitle_team` | TEXT |
| M | POST | `post_flag` | BOOLEAN |
| N | 📋 (복사상태) | `copy_status` | TEXT |
| O | File Name | `file_name` | TEXT |
| P | Transition | `transition` | TEXT |
| Q | In | `timecode_in` | TEXT |
| R | Out | `timecode_out` | TEXT |

### B.4 chipcount 시트 컬럼 → chip_snapshots.players_data 매핑

| 컬럼 | 시트 헤더 | JSON 필드 |
|------|----------|-----------|
| A | Rank | `rank` |
| B | PokerRoom | `poker_room` |
| C | TableName | `table_name` |
| D | TableId | `table_id` |
| E | TableNo | `table_no` |
| F | SeatId | `seat_id` |
| G | SeatNo | `seat_no` |
| H | PlayerId | `player_id` |
| I | PlayerName | `player_name` |
| J | Nationality | `nationality` |
| K | Chipcount | `chipcount` |
| L | BB | `bb_stack` |
| P | (OUTPUT용) | `player_name_display` |

### B.5 실제 데이터 예시 (LIVE 시트)

```json
{
  "content_type": "main",
  "hand_number": 1,
  "hand_rank": "A",
  "hand_history": "Pre: SOKRUTA AK RAISE, GABDULLIN 44 CALL\nFlop: 44 CHECK, AK BET, 44 RAISE, AK CALL\nTurn: 44 BET, AK CALL\nRiver: 44 BET, AK CALL",
  "edit_point": "처음부터 모두 써주세요.",
  "pd_note": "GABDULLIN 44 WIN",
  "recording_time": "14:36",
  "subtitle_flag": false,
  "blind_level": "300 / 500",
  "copy_status": "복사완료",
  "file_name": "A_0003"
}
```

### B.6 실제 데이터 예시 (VIRTUAL/플레이어 소개)

```json
{
  "content_type": "virtual",
  "hand_number": 1,
  "hand_rank": "SOFT",
  "pd_note": "소프트 콘텐츠\n'플레이어 소개'",
  "recording_time": "13:11",
  "subtitle_flag": true,
  "subtitle_confirm": "플레이어 소개\nGEORGIOS TSOULOFTAS / CYPRUS\n2ND ON CYPRUS ALL TIME MONEY LIST ($2,084,179)",
  "copy_status": "복사완료",
  "file_name": "1809_SC001_Georgios_Tsouloftas_L3_Profile"
}
```

### B.7 실제 데이터 예시 (Mini Chip Table 자막)

```json
{
  "subtitle_confirm": "[LEFT]MINI_CHIP_TABLE 24\nGLOSHKIN / 86,500\nASMOLOVA / 75,200\nCOBOS / 62,500\nGARCIA / 49,000\nISTOMIN / 46,500 (WINNER)\nKORENEV / 46,000\nCOHEN / 43,800\nCHUDAPAL / 40,500\nBLINDS 300/500 - 500 (BB)"
}
```
