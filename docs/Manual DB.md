# Manual Database Schema

수동 플레이어 프로필 관리를 위한 PostgreSQL/Supabase 데이터베이스 스키마 설계 문서

**Version**: 1.0.0
**Date**: 2026-01-13
**Project**: Automation DB Schema

---

## 1. 개요

### 1.1 목적

WSOP+ 데이터가 없거나 부정확할 때 수동으로 플레이어 프로필을 관리하여:
- 독립적인 플레이어 프로필 데이터베이스 구축
- WSOP+ 데이터 보정/오버라이드
- GFX, WSOP+ 플레이어와의 매핑/병합 지원
- 프로필 이미지 자산 관리

### 1.2 데이터 관계

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        Manual Schema 관계 다이어그램                         │
└─────────────────────────────────────────────────────────────────────────────┘

                    ┌─────────────────┐
                    │  GFX Players    │
                    │  (gfx_players)  │
                    └────────┬────────┘
                             │
                             │ FK
                             ▼
┌─────────────────┐   ┌─────────────────┐   ┌─────────────────┐
│  WSOP+ Players  │──▶│ Player Link     │◀──│  Manual Players │
│  (wsop_players) │   │ Mapping         │   │ (manual_players)│
└─────────────────┘   └────────┬────────┘   └────────┬────────┘
                               │                      │
                               │                      │ 1:N
                               │                      ▼
                               │            ┌─────────────────┐
                               │            │ Player Overrides│
                               │            └─────────────────┘
                               │
                               │ 1:N
                               ▼
                    ┌─────────────────┐
                    │ Profile Images  │
                    └─────────────────┘
```

### 1.3 핵심 기능

| 기능 | 설명 |
|------|------|
| **독립 관리** | WSOP+ 없이도 플레이어 프로필 관리 가능 |
| **병합 옵션** | 통합 뷰에서 WSOP+ 데이터와 병합 |
| **오버라이드** | 특정 필드만 수동 값으로 대체 |
| **이미지 관리** | 프로필 이미지 업로드 및 관리 |

---

## 2. ERD (Entity Relationship Diagram)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          Manual Database Schema                              │
└─────────────────────────────────────────────────────────────────────────────┘

┌──────────────────────┐       ┌──────────────────────┐
│   manual_players     │       │   player_overrides   │
│   (수동 플레이어)     │       │   (오버라이드 규칙)   │
├──────────────────────┤       ├──────────────────────┤
│ PK id: uuid          │       │ PK id: uuid          │
│ UK player_code: text │───┐   │ FK manual_player_id  │◄──┐
│    name: text        │   │   │ FK wsop_player_id    │   │
│    name_korean: text │   │   │    field_name: text  │   │
│    name_display: text│   │   │    override_value    │   │
│    country_code      │   │   │    original_value    │   │
│    country_name      │   │   │    reason: text      │   │
│    nationality       │   │   │    priority: int     │   │
│    birth_year: int   │   │   │    active: bool      │   │
│    profile_image_url │   │   │    created_by        │   │
│    profile_image_local│  │   │    approved_by       │   │
│    bio: text         │   │   │    created_at        │   │
│    notable_wins: jsonb│  │   │    updated_at        │   │
│    social_links: jsonb│  │   └──────────────────────┘   │
│    tags: text[]      │   │                              │
│    is_verified: bool │   │                              │
│    is_active: bool   │   │                              │
│    created_by: text  │   │   ┌──────────────────────┐   │
│    created_at        │   │   │   profile_images     │   │
│    updated_at        │   │   │   (이미지 저장소)     │   │
└──────────┬───────────┘   │   ├──────────────────────┤   │
           │               │   │ PK id: uuid          │   │
           │               └──▶│ FK player_id: uuid   │   │
           │                   │    image_type: enum  │   │
           │                   │    storage_type: enum│   │
           │                   │    file_path: text   │   │
           │                   │    file_name: text   │   │
           │                   │    file_size: int    │   │
           │                   │    mime_type: text   │   │
           │                   │    width: int        │   │
           │                   │    height: int       │   │
           │                   │    is_primary: bool  │   │
           │                   │    uploaded_by       │   │
           │                   │    uploaded_at       │   │
           │                   └──────────────────────┘   │
           │                                              │
           │                   ┌──────────────────────┐   │
           │                   │  player_link_mapping │   │
           │                   │  (플레이어 연결)      │   │
           │                   ├──────────────────────┤   │
           └──────────────────▶│ PK id: uuid          │   │
                               │ FK manual_player_id  │───┘
                               │ FK wsop_player_id    │
                               │ FK gfx_player_id     │
                               │    match_confidence  │
                               │    match_method: enum│
                               │    is_verified: bool │
                               │    verified_by       │
                               │    notes: text       │
                               │    created_at        │
                               │    updated_at        │
                               └──────────────────────┘

┌──────────────────────┐
│   manual_audit_log   │
│   (변경 이력)         │
├──────────────────────┤
│ PK id: uuid          │
│    table_name: text  │
│    record_id: uuid   │
│    action: enum      │
│    old_values: jsonb │
│    new_values: jsonb │
│    changed_by: text  │
│    changed_at: ts    │
│    ip_address: text  │
└──────────────────────┘
```

### 테이블 관계 요약

| 관계 | 설명 |
|------|------|
| `manual_players` 1:N `profile_images` | 플레이어당 여러 이미지 |
| `manual_players` 1:N `player_overrides` | 플레이어당 여러 오버라이드 규칙 |
| `manual_players` 1:1 `player_link_mapping` | 플레이어당 하나의 매핑 |
| `player_link_mapping` N:1 `wsop_players` | 여러 매뉴얼 → 하나의 WSOP |
| `player_link_mapping` N:1 `gfx_players` | 여러 매뉴얼 → 하나의 GFX |

---

## 3. Enum 타입 정의

```sql
-- ============================================================================
-- ENUM Types
-- ============================================================================

-- 이미지 타입
CREATE TYPE manual_image_type AS ENUM (
    'profile',          -- 프로필 메인 이미지
    'thumbnail',        -- 썸네일
    'broadcast',        -- 방송용 이미지 (고해상도)
    'headshot',         -- 얼굴 클로즈업
    'action',           -- 액션샷
    'flag_overlay'      -- 국기 오버레이용
);

-- 이미지 저장 타입
CREATE TYPE manual_storage_type AS ENUM (
    'local',            -- 로컬 파일 시스템
    'supabase',         -- Supabase Storage
    's3',               -- AWS S3
    'url'               -- 외부 URL
);

-- 플레이어 매칭 방법
CREATE TYPE manual_match_method AS ENUM (
    'exact_name',       -- 이름 완전 일치
    'fuzzy_name',       -- 유사 이름 매칭
    'manual',           -- 수동 연결
    'wsop_id',          -- WSOP ID 기반
    'hendon_mob_id',    -- Hendon Mob ID 기반
    'auto'              -- 자동 매칭 알고리즘
);

-- 감사 로그 액션
CREATE TYPE manual_audit_action AS ENUM (
    'INSERT',
    'UPDATE',
    'DELETE',
    'MERGE',
    'LINK',
    'UNLINK'
);

-- 오버라이드 필드 타입
CREATE TYPE manual_override_field AS ENUM (
    'name',
    'name_korean',
    'name_display',
    'country_code',
    'country_name',
    'profile_image_url',
    'bio',
    'notable_wins',
    'social_links'
);
```

---

## 4. 테이블 DDL

### 4.1 manual_players (수동 플레이어)

```sql
-- ============================================================================
-- manual_players: 수동 관리 플레이어 마스터 테이블
-- WSOP+ 데이터와 독립적으로 관리되는 플레이어 정보
-- ============================================================================

CREATE TABLE manual_players (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- 플레이어 식별
    player_code TEXT NOT NULL UNIQUE,  -- 내부 코드 (예: "MP-00001")

    -- 이름 정보
    name TEXT NOT NULL,
    name_korean TEXT,  -- 한글 이름
    name_display TEXT,  -- 표시용 이름 (nickname 포함 가능)
    name_normalized TEXT,  -- 검색용 정규화

    -- 국적
    country_code VARCHAR(10),  -- ISO 국가 코드 (KR, US 등)
    country_name VARCHAR(100),
    nationality TEXT,  -- 상세 국적 (예: "Korean-American")

    -- 기본 정보
    birth_year INTEGER,  -- 출생 연도만 (개인정보 보호)
    hometown TEXT,
    residence TEXT,

    -- 프로필 이미지
    profile_image_url TEXT,  -- 외부 URL
    profile_image_local TEXT,  -- 로컬 파일 경로
    profile_image_storage_id UUID,  -- profile_images FK

    -- 소개
    bio TEXT,
    short_bio VARCHAR(280),  -- 트위터 길이 제한

    -- 주요 성과 (JSONB)
    notable_wins JSONB DEFAULT '[]'::JSONB,
    /*
    [
        {
            "year": 2024,
            "event": "WSOP Main Event",
            "place": 1,
            "prize": 10000000,
            "notes": "First Korean winner"
        }
    ]
    */

    -- 소셜 링크 (JSONB)
    social_links JSONB DEFAULT '{}'::JSONB,
    /*
    {
        "twitter": "@player",
        "instagram": "@player",
        "youtube": "channel_id",
        "hendon_mob": "12345"
    }
    */

    -- 태그 (검색/필터용)
    tags TEXT[] DEFAULT ARRAY[]::TEXT[],

    -- 상태
    is_verified BOOLEAN DEFAULT FALSE,  -- 검증된 정보인지
    is_active BOOLEAN DEFAULT TRUE,  -- 활성 플레이어인지
    is_featured BOOLEAN DEFAULT FALSE,  -- 주요 플레이어인지

    -- 관리 정보
    created_by TEXT NOT NULL,
    verified_by TEXT,
    verified_at TIMESTAMPTZ,
    notes TEXT,

    -- 타임스탬프
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 인덱스
CREATE INDEX idx_manual_players_code ON manual_players(player_code);
CREATE INDEX idx_manual_players_name ON manual_players(name);
CREATE INDEX idx_manual_players_name_korean ON manual_players(name_korean) WHERE name_korean IS NOT NULL;
CREATE INDEX idx_manual_players_name_normalized ON manual_players(name_normalized);
CREATE INDEX idx_manual_players_country ON manual_players(country_code);
CREATE INDEX idx_manual_players_verified ON manual_players(is_verified) WHERE is_verified = TRUE;
CREATE INDEX idx_manual_players_featured ON manual_players(is_featured) WHERE is_featured = TRUE;
CREATE INDEX idx_manual_players_tags ON manual_players USING GIN (tags);
```

### 4.2 profile_images (프로필 이미지)

```sql
-- ============================================================================
-- profile_images: 플레이어 프로필 이미지 저장소
-- 다양한 용도의 이미지 관리 (프로필, 썸네일, 방송용 등)
-- ============================================================================

CREATE TABLE profile_images (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- 플레이어 참조
    player_id UUID NOT NULL REFERENCES manual_players(id) ON DELETE CASCADE,

    -- 이미지 타입
    image_type manual_image_type NOT NULL DEFAULT 'profile',

    -- 저장 정보
    storage_type manual_storage_type NOT NULL DEFAULT 'local',
    file_path TEXT NOT NULL,  -- 전체 경로 또는 URL
    file_name TEXT NOT NULL,  -- 원본 파일명
    file_extension VARCHAR(20),

    -- 파일 메타데이터
    file_size INTEGER,  -- bytes
    mime_type VARCHAR(100),
    width INTEGER,
    height INTEGER,
    aspect_ratio NUMERIC(5,2),

    -- 이미지 메타데이터
    original_url TEXT,  -- 원본 소스 URL (있는 경우)
    alt_text TEXT,  -- 접근성용 대체 텍스트
    caption TEXT,

    -- 상태
    is_primary BOOLEAN DEFAULT FALSE,  -- 대표 이미지 여부
    is_approved BOOLEAN DEFAULT TRUE,  -- 승인 여부
    processing_status VARCHAR(50) DEFAULT 'completed',

    -- 관리 정보
    uploaded_by TEXT NOT NULL,
    approved_by TEXT,
    notes TEXT,

    -- 타임스탬프
    uploaded_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 인덱스
CREATE INDEX idx_profile_images_player ON profile_images(player_id);
CREATE INDEX idx_profile_images_type ON profile_images(image_type);
CREATE INDEX idx_profile_images_primary ON profile_images(player_id, is_primary) WHERE is_primary = TRUE;
CREATE INDEX idx_profile_images_storage ON profile_images(storage_type);

-- 유니크 제약: 플레이어당 이미지 타입별 하나의 primary
CREATE UNIQUE INDEX idx_profile_images_unique_primary
    ON profile_images(player_id, image_type)
    WHERE is_primary = TRUE;
```

### 4.3 player_overrides (오버라이드 규칙)

```sql
-- ============================================================================
-- player_overrides: WSOP+ 데이터 오버라이드 규칙
-- 특정 필드만 수동 값으로 대체하는 규칙 정의
-- ============================================================================

CREATE TABLE player_overrides (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- 참조 (둘 중 하나는 반드시 있어야 함)
    manual_player_id UUID REFERENCES manual_players(id) ON DELETE CASCADE,
    wsop_player_id UUID,  -- wsop_players FK (다른 스키마)

    -- 오버라이드 대상
    field_name TEXT NOT NULL,  -- 오버라이드할 필드명
    field_type manual_override_field,  -- Enum 참조용

    -- 값
    override_value TEXT NOT NULL,  -- 새 값
    original_value TEXT,  -- 원래 값 (기록용)

    -- 메타데이터
    reason TEXT NOT NULL,  -- 오버라이드 이유
    priority INTEGER DEFAULT 100,  -- 우선순위 (낮을수록 높음)
    active BOOLEAN DEFAULT TRUE,  -- 활성 여부

    -- 유효 기간 (선택적)
    valid_from TIMESTAMPTZ,
    valid_until TIMESTAMPTZ,

    -- 관리 정보
    created_by TEXT NOT NULL,
    approved_by TEXT,
    approved_at TIMESTAMPTZ,
    notes TEXT,

    -- 타임스탬프
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    -- 제약: 최소 하나의 플레이어 참조 필요
    CONSTRAINT chk_player_reference CHECK (
        manual_player_id IS NOT NULL OR wsop_player_id IS NOT NULL
    )
);

-- 인덱스
CREATE INDEX idx_player_overrides_manual ON player_overrides(manual_player_id);
CREATE INDEX idx_player_overrides_wsop ON player_overrides(wsop_player_id);
CREATE INDEX idx_player_overrides_field ON player_overrides(field_name);
CREATE INDEX idx_player_overrides_active ON player_overrides(active) WHERE active = TRUE;
CREATE INDEX idx_player_overrides_priority ON player_overrides(priority);

-- 유니크 제약: 동일 플레이어/필드에 대한 활성 오버라이드는 하나
CREATE UNIQUE INDEX idx_player_overrides_unique_active
    ON player_overrides(COALESCE(manual_player_id, wsop_player_id), field_name)
    WHERE active = TRUE;
```

### 4.4 player_link_mapping (플레이어 연결)

```sql
-- ============================================================================
-- player_link_mapping: 플레이어 ID 매핑 테이블
-- Manual, WSOP+, GFX 플레이어 간의 연결 관리
-- ============================================================================

CREATE TABLE player_link_mapping (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- 플레이어 참조 (최소 하나 이상 필요)
    manual_player_id UUID REFERENCES manual_players(id) ON DELETE SET NULL,
    wsop_player_id UUID,  -- wsop_players FK (다른 스키마)
    gfx_player_id UUID,   -- gfx_players FK (다른 스키마)

    -- 매칭 정보
    match_confidence NUMERIC(5,2),  -- 매칭 신뢰도 (0-100%)
    match_method manual_match_method NOT NULL DEFAULT 'manual',
    match_score NUMERIC(5,2),  -- 알고리즘 점수

    -- 매칭 근거
    match_evidence JSONB DEFAULT '{}'::JSONB,
    /*
    {
        "name_similarity": 0.95,
        "country_match": true,
        "event_overlap": ["event1", "event2"],
        "manual_notes": "Same person confirmed via social media"
    }
    */

    -- 검증 상태
    is_verified BOOLEAN DEFAULT FALSE,
    verified_by TEXT,
    verified_at TIMESTAMPTZ,

    -- 메타데이터
    notes TEXT,
    merge_priority VARCHAR(20) DEFAULT 'manual',  -- 병합 시 우선순위 소스

    -- 타임스탬프
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    -- 제약: 최소 두 개의 플레이어 참조 필요 (매핑이므로)
    CONSTRAINT chk_link_minimum CHECK (
        (CASE WHEN manual_player_id IS NOT NULL THEN 1 ELSE 0 END +
         CASE WHEN wsop_player_id IS NOT NULL THEN 1 ELSE 0 END +
         CASE WHEN gfx_player_id IS NOT NULL THEN 1 ELSE 0 END) >= 2
    )
);

-- 인덱스
CREATE INDEX idx_player_link_manual ON player_link_mapping(manual_player_id);
CREATE INDEX idx_player_link_wsop ON player_link_mapping(wsop_player_id);
CREATE INDEX idx_player_link_gfx ON player_link_mapping(gfx_player_id);
CREATE INDEX idx_player_link_verified ON player_link_mapping(is_verified) WHERE is_verified = TRUE;
CREATE INDEX idx_player_link_method ON player_link_mapping(match_method);
CREATE INDEX idx_player_link_confidence ON player_link_mapping(match_confidence DESC);

-- 유니크 제약: 동일 소스 조합의 중복 매핑 방지
CREATE UNIQUE INDEX idx_player_link_unique
    ON player_link_mapping(
        COALESCE(manual_player_id, '00000000-0000-0000-0000-000000000000'::UUID),
        COALESCE(wsop_player_id, '00000000-0000-0000-0000-000000000000'::UUID),
        COALESCE(gfx_player_id, '00000000-0000-0000-0000-000000000000'::UUID)
    );
```

### 4.5 manual_audit_log (변경 이력)

```sql
-- ============================================================================
-- manual_audit_log: 모든 변경 사항 감사 로그
-- 데이터 변경 이력 추적 (규정 준수, 문제 추적용)
-- ============================================================================

CREATE TABLE manual_audit_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- 대상 테이블/레코드
    table_name TEXT NOT NULL,
    record_id UUID NOT NULL,

    -- 변경 내용
    action manual_audit_action NOT NULL,
    old_values JSONB,  -- 변경 전 값
    new_values JSONB,  -- 변경 후 값
    changed_fields TEXT[],  -- 변경된 필드 목록

    -- 변경 주체
    changed_by TEXT NOT NULL,
    changed_by_role TEXT,
    ip_address INET,
    user_agent TEXT,

    -- 컨텍스트
    reason TEXT,
    related_record_id UUID,  -- 관련 레코드 (예: merge 대상)

    -- 타임스탬프
    changed_at TIMESTAMPTZ DEFAULT NOW()
);

-- 인덱스
CREATE INDEX idx_manual_audit_table ON manual_audit_log(table_name);
CREATE INDEX idx_manual_audit_record ON manual_audit_log(record_id);
CREATE INDEX idx_manual_audit_action ON manual_audit_log(action);
CREATE INDEX idx_manual_audit_changed_by ON manual_audit_log(changed_by);
CREATE INDEX idx_manual_audit_changed_at ON manual_audit_log(changed_at DESC);
CREATE INDEX idx_manual_audit_table_record ON manual_audit_log(table_name, record_id);

-- 파티셔닝 고려 (대용량 로그 시)
-- PARTITION BY RANGE (changed_at);
```

---

## 5. 뷰 정의

### 5.1 v_manual_players_complete (완전한 플레이어 정보 뷰)

```sql
-- ============================================================================
-- v_manual_players_complete: 플레이어 + 대표 이미지 + 매핑 정보
-- ============================================================================

CREATE OR REPLACE VIEW v_manual_players_complete AS
SELECT
    mp.id,
    mp.player_code,
    mp.name,
    mp.name_korean,
    mp.name_display,
    mp.country_code,
    mp.country_name,
    mp.bio,
    mp.short_bio,
    mp.notable_wins,
    mp.social_links,
    mp.tags,
    mp.is_verified,
    mp.is_featured,

    -- 대표 이미지
    pi.file_path AS profile_image_path,
    pi.storage_type AS profile_image_storage,

    -- 매핑 정보
    plm.wsop_player_id,
    plm.gfx_player_id,
    plm.match_confidence,
    plm.is_verified AS link_verified,

    -- 활성 오버라이드 수
    (SELECT COUNT(*) FROM player_overrides po
     WHERE po.manual_player_id = mp.id AND po.active = TRUE) AS active_overrides_count,

    mp.created_at,
    mp.updated_at

FROM manual_players mp
LEFT JOIN profile_images pi ON mp.id = pi.player_id
    AND pi.image_type = 'profile' AND pi.is_primary = TRUE
LEFT JOIN player_link_mapping plm ON mp.id = plm.manual_player_id
WHERE mp.is_active = TRUE
ORDER BY mp.name;
```

### 5.2 v_player_images_all (플레이어별 전체 이미지 뷰)

```sql
-- ============================================================================
-- v_player_images_all: 플레이어별 모든 이미지 목록
-- ============================================================================

CREATE OR REPLACE VIEW v_player_images_all AS
SELECT
    mp.id AS player_id,
    mp.player_code,
    mp.name AS player_name,
    pi.id AS image_id,
    pi.image_type,
    pi.storage_type,
    pi.file_path,
    pi.file_name,
    pi.file_size,
    pi.width,
    pi.height,
    pi.is_primary,
    pi.is_approved,
    pi.uploaded_by,
    pi.uploaded_at

FROM manual_players mp
JOIN profile_images pi ON mp.id = pi.player_id
WHERE mp.is_active = TRUE
ORDER BY mp.name, pi.image_type, pi.is_primary DESC;
```

### 5.3 v_active_overrides (활성 오버라이드 뷰)

```sql
-- ============================================================================
-- v_active_overrides: 현재 활성화된 오버라이드 목록
-- ============================================================================

CREATE OR REPLACE VIEW v_active_overrides AS
SELECT
    po.id,
    mp.player_code,
    mp.name AS player_name,
    po.field_name,
    po.override_value,
    po.original_value,
    po.reason,
    po.priority,
    po.valid_from,
    po.valid_until,
    po.created_by,
    po.approved_by,
    po.created_at

FROM player_overrides po
LEFT JOIN manual_players mp ON po.manual_player_id = mp.id
WHERE po.active = TRUE
  AND (po.valid_from IS NULL OR po.valid_from <= NOW())
  AND (po.valid_until IS NULL OR po.valid_until > NOW())
ORDER BY po.priority, mp.name;
```

### 5.4 v_unlinked_players (미연결 플레이어 뷰)

```sql
-- ============================================================================
-- v_unlinked_players: 다른 소스와 연결되지 않은 플레이어
-- ============================================================================

CREATE OR REPLACE VIEW v_unlinked_players AS
SELECT
    mp.id,
    mp.player_code,
    mp.name,
    mp.name_korean,
    mp.country_code,
    mp.is_verified,
    mp.created_at

FROM manual_players mp
LEFT JOIN player_link_mapping plm ON mp.id = plm.manual_player_id
WHERE plm.id IS NULL
  AND mp.is_active = TRUE
ORDER BY mp.name;
```

### 5.5 v_recent_changes (최근 변경 사항 뷰)

```sql
-- ============================================================================
-- v_recent_changes: 최근 24시간 변경 이력
-- ============================================================================

CREATE OR REPLACE VIEW v_recent_changes AS
SELECT
    al.id,
    al.table_name,
    al.record_id,
    al.action,
    al.changed_fields,
    al.changed_by,
    al.reason,
    al.changed_at,

    -- 관련 플레이어 이름 (있는 경우)
    CASE
        WHEN al.table_name = 'manual_players' THEN
            (SELECT name FROM manual_players WHERE id = al.record_id)
        ELSE NULL
    END AS player_name

FROM manual_audit_log al
WHERE al.changed_at > NOW() - INTERVAL '24 hours'
ORDER BY al.changed_at DESC;
```

---

## 6. 함수 및 트리거

### 6.1 updated_at 자동 갱신

```sql
-- ============================================================================
-- 트리거 함수: updated_at 자동 갱신
-- ============================================================================

CREATE OR REPLACE FUNCTION update_manual_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 각 테이블에 트리거 적용
CREATE TRIGGER update_manual_players_updated_at
    BEFORE UPDATE ON manual_players
    FOR EACH ROW
    EXECUTE FUNCTION update_manual_updated_at_column();

CREATE TRIGGER update_player_overrides_updated_at
    BEFORE UPDATE ON player_overrides
    FOR EACH ROW
    EXECUTE FUNCTION update_manual_updated_at_column();

CREATE TRIGGER update_player_link_mapping_updated_at
    BEFORE UPDATE ON player_link_mapping
    FOR EACH ROW
    EXECUTE FUNCTION update_manual_updated_at_column();
```

### 6.2 플레이어 코드 자동 생성

```sql
-- ============================================================================
-- 함수: 플레이어 코드 자동 생성
-- ============================================================================

CREATE OR REPLACE FUNCTION generate_player_code()
RETURNS TEXT AS $$
DECLARE
    v_code TEXT;
    v_seq INTEGER;
BEGIN
    -- 현재 최대 번호 조회
    SELECT COALESCE(MAX(CAST(SUBSTRING(player_code FROM 4) AS INTEGER)), 0) + 1
    INTO v_seq
    FROM manual_players
    WHERE player_code LIKE 'MP-%';

    -- 코드 생성 (MP-00001 형식)
    v_code := 'MP-' || LPAD(v_seq::TEXT, 5, '0');

    RETURN v_code;
END;
$$ LANGUAGE plpgsql;

-- 삽입 시 자동 코드 생성 트리거
CREATE OR REPLACE FUNCTION set_player_code()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.player_code IS NULL OR NEW.player_code = '' THEN
        NEW.player_code = generate_player_code();
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER auto_generate_player_code
    BEFORE INSERT ON manual_players
    FOR EACH ROW
    EXECUTE FUNCTION set_player_code();
```

### 6.3 이름 정규화

```sql
-- ============================================================================
-- 함수: 플레이어 이름 정규화
-- ============================================================================

CREATE OR REPLACE FUNCTION normalize_manual_player_name(p_name TEXT)
RETURNS TEXT AS $$
BEGIN
    RETURN LOWER(
        REGEXP_REPLACE(
            TRIM(p_name),
            '[^a-zA-Z0-9가-힣\s]',
            '',
            'g'
        )
    );
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- 자동 정규화 트리거
CREATE OR REPLACE FUNCTION set_manual_normalized_name()
RETURNS TRIGGER AS $$
BEGIN
    NEW.name_normalized = normalize_manual_player_name(NEW.name);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER normalize_manual_player_name
    BEFORE INSERT OR UPDATE ON manual_players
    FOR EACH ROW
    EXECUTE FUNCTION set_manual_normalized_name();
```

### 6.4 감사 로그 자동 기록

```sql
-- ============================================================================
-- 함수: 변경 사항 자동 로깅
-- ============================================================================

CREATE OR REPLACE FUNCTION log_manual_audit()
RETURNS TRIGGER AS $$
DECLARE
    v_old_values JSONB;
    v_new_values JSONB;
    v_changed_fields TEXT[];
    v_action manual_audit_action;
BEGIN
    -- 액션 결정
    IF TG_OP = 'INSERT' THEN
        v_action := 'INSERT';
        v_new_values := to_jsonb(NEW);
        v_old_values := NULL;
    ELSIF TG_OP = 'UPDATE' THEN
        v_action := 'UPDATE';
        v_old_values := to_jsonb(OLD);
        v_new_values := to_jsonb(NEW);

        -- 변경된 필드 찾기
        SELECT ARRAY_AGG(key)
        INTO v_changed_fields
        FROM jsonb_each(v_old_values) old_kv
        JOIN jsonb_each(v_new_values) new_kv USING (key)
        WHERE old_kv.value IS DISTINCT FROM new_kv.value;
    ELSIF TG_OP = 'DELETE' THEN
        v_action := 'DELETE';
        v_old_values := to_jsonb(OLD);
        v_new_values := NULL;
    END IF;

    -- 로그 기록
    INSERT INTO manual_audit_log (
        table_name,
        record_id,
        action,
        old_values,
        new_values,
        changed_fields,
        changed_by,
        changed_at
    ) VALUES (
        TG_TABLE_NAME,
        COALESCE(NEW.id, OLD.id),
        v_action,
        v_old_values,
        v_new_values,
        v_changed_fields,
        COALESCE(current_setting('app.current_user', TRUE), 'system'),
        NOW()
    );

    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

-- 주요 테이블에 감사 트리거 적용
CREATE TRIGGER audit_manual_players
    AFTER INSERT OR UPDATE OR DELETE ON manual_players
    FOR EACH ROW
    EXECUTE FUNCTION log_manual_audit();

CREATE TRIGGER audit_player_overrides
    AFTER INSERT OR UPDATE OR DELETE ON player_overrides
    FOR EACH ROW
    EXECUTE FUNCTION log_manual_audit();

CREATE TRIGGER audit_player_link_mapping
    AFTER INSERT OR UPDATE OR DELETE ON player_link_mapping
    FOR EACH ROW
    EXECUTE FUNCTION log_manual_audit();
```

### 6.5 오버라이드 적용 함수

```sql
-- ============================================================================
-- 함수: 플레이어 필드에 오버라이드 적용
-- ============================================================================

CREATE OR REPLACE FUNCTION get_player_field_with_override(
    p_player_id UUID,
    p_field_name TEXT,
    p_default_value TEXT
)
RETURNS TEXT AS $$
DECLARE
    v_override_value TEXT;
BEGIN
    -- 활성 오버라이드 조회 (우선순위 순)
    SELECT override_value
    INTO v_override_value
    FROM player_overrides
    WHERE (manual_player_id = p_player_id OR wsop_player_id = p_player_id)
      AND field_name = p_field_name
      AND active = TRUE
      AND (valid_from IS NULL OR valid_from <= NOW())
      AND (valid_until IS NULL OR valid_until > NOW())
    ORDER BY priority ASC
    LIMIT 1;

    RETURN COALESCE(v_override_value, p_default_value);
END;
$$ LANGUAGE plpgsql STABLE;
```

---

## 7. 인덱스 전략 및 쿼리 패턴

### 7.1 주요 쿼리 패턴

| 쿼리 패턴 | 설명 | 최적화 인덱스 |
|-----------|------|---------------|
| 플레이어 검색 | `WHERE name_normalized LIKE ?` | `idx_manual_players_name_normalized` |
| 국가별 필터 | `WHERE country_code = ?` | `idx_manual_players_country` |
| 검증된 플레이어 | `WHERE is_verified = TRUE` | `idx_manual_players_verified` |
| 주요 플레이어 | `WHERE is_featured = TRUE` | `idx_manual_players_featured` |
| 태그 검색 | `WHERE ? = ANY(tags)` | `idx_manual_players_tags` (GIN) |
| 플레이어 이미지 | `WHERE player_id = ?` | `idx_profile_images_player` |
| 대표 이미지 | `WHERE is_primary = TRUE` | `idx_profile_images_primary` |
| 활성 오버라이드 | `WHERE active = TRUE` | `idx_player_overrides_active` |
| 플레이어 매핑 | `WHERE manual_player_id = ?` | `idx_player_link_manual` |

### 7.2 인덱스 요약

```sql
-- Primary Keys (자동 생성)
-- manual_players.id, profile_images.id, player_overrides.id, etc.

-- Unique Constraints
-- manual_players.player_code

-- B-tree Indexes (범위/정렬 쿼리)
-- manual_players: name, name_korean, country_code
-- profile_images: player_id, image_type
-- player_overrides: priority

-- GIN Indexes (배열/JSONB 검색)
-- manual_players.tags

-- Partial Indexes (조건부 최적화)
-- manual_players.is_verified WHERE TRUE
-- manual_players.is_featured WHERE TRUE
-- profile_images.is_primary WHERE TRUE
-- player_overrides.active WHERE TRUE
```

---

## 8. RLS 정책 (Row Level Security)

```sql
-- ============================================================================
-- RLS 정책 설정 (Supabase 환경)
-- ============================================================================

-- 모든 테이블 RLS 활성화
ALTER TABLE manual_players ENABLE ROW LEVEL SECURITY;
ALTER TABLE profile_images ENABLE ROW LEVEL SECURITY;
ALTER TABLE player_overrides ENABLE ROW LEVEL SECURITY;
ALTER TABLE player_link_mapping ENABLE ROW LEVEL SECURITY;
ALTER TABLE manual_audit_log ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- manual_players 정책
-- ============================================================================

-- 인증된 사용자는 읽기 가능
CREATE POLICY "manual_players_select_authenticated"
    ON manual_players FOR SELECT
    USING (auth.role() = 'authenticated');

-- 서비스 역할만 삽입 가능
CREATE POLICY "manual_players_insert_service"
    ON manual_players FOR INSERT
    WITH CHECK (auth.role() = 'service_role');

-- 서비스 역할만 수정 가능
CREATE POLICY "manual_players_update_service"
    ON manual_players FOR UPDATE
    USING (auth.role() = 'service_role');

-- 서비스 역할만 삭제 가능
CREATE POLICY "manual_players_delete_service"
    ON manual_players FOR DELETE
    USING (auth.role() = 'service_role');

-- ============================================================================
-- profile_images 정책
-- ============================================================================
CREATE POLICY "profile_images_select_authenticated"
    ON profile_images FOR SELECT
    USING (auth.role() = 'authenticated');

CREATE POLICY "profile_images_insert_service"
    ON profile_images FOR INSERT
    WITH CHECK (auth.role() = 'service_role');

CREATE POLICY "profile_images_update_service"
    ON profile_images FOR UPDATE
    USING (auth.role() = 'service_role');

CREATE POLICY "profile_images_delete_service"
    ON profile_images FOR DELETE
    USING (auth.role() = 'service_role');

-- ============================================================================
-- player_overrides 정책
-- ============================================================================
CREATE POLICY "player_overrides_select_authenticated"
    ON player_overrides FOR SELECT
    USING (auth.role() = 'authenticated');

CREATE POLICY "player_overrides_all_service"
    ON player_overrides FOR ALL
    USING (auth.role() = 'service_role');

-- ============================================================================
-- player_link_mapping 정책
-- ============================================================================
CREATE POLICY "player_link_mapping_select_authenticated"
    ON player_link_mapping FOR SELECT
    USING (auth.role() = 'authenticated');

CREATE POLICY "player_link_mapping_all_service"
    ON player_link_mapping FOR ALL
    USING (auth.role() = 'service_role');

-- ============================================================================
-- manual_audit_log 정책
-- ============================================================================
CREATE POLICY "manual_audit_log_select_authenticated"
    ON manual_audit_log FOR SELECT
    USING (auth.role() = 'authenticated');

CREATE POLICY "manual_audit_log_insert_service"
    ON manual_audit_log FOR INSERT
    WITH CHECK (auth.role() = 'service_role');
```

---

## 9. 마이그레이션 순서

### 실행 순서

```
1. ENUM 타입 생성 (CREATE TYPE)
2. manual_players 테이블 생성
3. profile_images 테이블 생성
4. player_overrides 테이블 생성
5. player_link_mapping 테이블 생성
6. manual_audit_log 테이블 생성
7. 뷰 생성 (CREATE VIEW)
8. 함수 생성 (CREATE FUNCTION)
9. 트리거 생성 (CREATE TRIGGER)
10. 인덱스 생성 (CREATE INDEX)
11. RLS 정책 적용 (ALTER TABLE, CREATE POLICY)
```

### Rollback 순서 (역순)

```
1. RLS 정책 삭제 (DROP POLICY)
2. 인덱스 삭제 (DROP INDEX)
3. 트리거 삭제 (DROP TRIGGER)
4. 함수 삭제 (DROP FUNCTION)
5. 뷰 삭제 (DROP VIEW)
6. 테이블 삭제 (역순)
7. ENUM 타입 삭제 (DROP TYPE)
```

---

## 10. 제약조건 요약

| 테이블 | 제약조건 | 설명 |
|--------|----------|------|
| `manual_players` | `player_code UNIQUE` | 플레이어 코드 중복 방지 |
| `profile_images` | `(player_id, image_type) UNIQUE WHERE is_primary` | 타입별 하나의 대표 이미지 |
| `player_overrides` | `chk_player_reference` | 최소 하나의 플레이어 참조 필요 |
| `player_overrides` | `UNIQUE (player, field) WHERE active` | 동일 필드 활성 오버라이드 하나 |
| `player_link_mapping` | `chk_link_minimum` | 최소 두 개 소스 연결 필요 |

---

## 11. 구현 연동 파일

| 파일 | 역할 | 연동 테이블 |
|------|------|-------------|
| `src/services/manual_player_service.py` | 플레이어 CRUD | manual_players |
| `src/services/image_upload_service.py` | 이미지 업로드 | profile_images |
| `src/services/player_link_service.py` | 플레이어 매핑 | player_link_mapping |
| `src/services/override_service.py` | 오버라이드 관리 | player_overrides |
| `src/utils/name_matcher.py` | 이름 매칭 알고리즘 | player_link_mapping |

---

## Appendix: 플레이어 코드 형식

| 형식 | 예시 | 설명 |
|------|------|------|
| `MP-NNNNN` | `MP-00001` | Manual Player 순번 |

자동 생성 규칙:
- 새 플레이어 생성 시 자동 할당
- 수동 지정 가능 (중복 불가)
- 삭제된 코드는 재사용하지 않음
