# 04. Player Override & Profile Schema

플레이어 오버라이드 및 프로필 이미지 관리를 위한 PostgreSQL/Supabase 데이터베이스 스키마 설계 문서

**Version**: 2.0.0
**Date**: 2026-01-16
**Project**: Automation DB Schema

---

> **스키마 변경 공지 (2026-01-16)**
>
> `manual_players` 테이블이 삭제되었습니다.
> 플레이어 정보는 `gfx_players`와 `wsop_players`에서 관리합니다.
>
> 변경 사항:
> - `manual_players` 테이블 삭제
> - `manual_audit_log` 테이블 삭제
> - `profile_images`: wsop_players/gfx_players 참조로 변경
> - `player_overrides`: gfx_player_id 추가
> - `player_link_mapping`: manual_player_id 제거

---

## 1. 개요

### 1.1 목적

WSOP+ 또는 GFX 데이터가 부정확할 때 오버라이드하고 프로필 이미지를 관리:
- **오버라이드**: WSOP+/GFX 플레이어 특정 필드 보정
- **이미지 관리**: 프로필 이미지 업로드 및 관리
- **플레이어 연결**: GFX ↔ WSOP+ 플레이어 교집합 매핑

### 1.2 데이터 관계

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                      Player Override Schema 관계 다이어그램                  │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────────┐                           ┌─────────────────┐
│  GFX Players    │                           │  WSOP+ Players  │
│  (gfx_players)  │                           │  (wsop_players) │
└────────┬────────┘                           └────────┬────────┘
         │                                             │
         │         ┌─────────────────┐                 │
         └────────▶│ Player Link     │◀────────────────┘
                   │ Mapping         │
                   │ (gfx↔wsop 연결)  │
                   └────────┬────────┘
                            │
         ┌──────────────────┼──────────────────┐
         │                  │                  │
         ▼                  ▼                  ▼
┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐
│ Profile Images  │  │ Player Overrides│  │   (삭제됨)      │
│ (wsop/gfx 참조) │  │ (wsop/gfx 참조) │  │ manual_players  │
└─────────────────┘  └─────────────────┘  └─────────────────┘
```

### 1.3 핵심 기능

| 기능 | 설명 |
|------|------|
| **오버라이드** | GFX/WSOP+ 플레이어 특정 필드만 수동 값으로 대체 |
| **이미지 관리** | 프로필 이미지 업로드 및 관리 (다양한 타입 지원) |
| **플레이어 연결** | GFX ↔ WSOP+ 교집합 플레이어 매핑 |

---

## 2. ERD (Entity Relationship Diagram)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    Player Override Schema v2.0                               │
│                    (manual_players 삭제됨)                                    │
└─────────────────────────────────────────────────────────────────────────────┘

┌──────────────────────┐                           ┌──────────────────────┐
│    gfx_players       │                           │    wsop_players      │
│    (GFX 플레이어)     │                           │   (WSOP+ 플레이어)    │
├──────────────────────┤                           ├──────────────────────┤
│ PK id: uuid          │                           │ PK id: uuid          │
│ UK player_hash: text │                           │ UK wsop_player_id    │
│    name: text        │                           │    name: text        │
│    long_name: text   │                           │    country_code      │
└──────────┬───────────┘                           └──────────┬───────────┘
           │                                                  │
           │                 ┌─────────────────┐              │
           │                 │ player_overrides│              │
           │                 │ (오버라이드 규칙)│              │
           │                 ├─────────────────┤              │
           │                 │ PK id: uuid     │              │
           ├────────────────▶│ FK gfx_player_id│◀─────────────┤
           │                 │ FK wsop_player_id              │
           │                 │    field_name   │              │
           │                 │    override_value              │
           │                 │    original_value              │
           │                 │    reason: text │              │
           │                 │    priority: int│              │
           │                 │    active: bool │              │
           │                 └─────────────────┘              │
           │                                                  │
           │                 ┌─────────────────┐              │
           │                 │ profile_images  │              │
           │                 │ (이미지 저장소)  │              │
           │                 ├─────────────────┤              │
           │                 │ PK id: uuid     │              │
           ├────────────────▶│ FK gfx_player_id│◀─────────────┤
           │                 │ FK wsop_player_id              │
           │                 │    image_type   │              │
           │                 │    storage_type │              │
           │                 │    file_path    │              │
           │                 │    is_primary   │              │
           │                 └─────────────────┘              │
           │                                                  │
           │                 ┌─────────────────┐              │
           │                 │player_link_mapping             │
           │                 │ (플레이어 연결)  │              │
           │                 ├─────────────────┤              │
           └────────────────▶│ PK id: uuid     │◀─────────────┘
                             │ FK gfx_player_id│
                             │ FK wsop_player_id
                             │    match_confidence
                             │    match_method │
                             │    is_verified  │
                             └─────────────────┘
```

### 테이블 관계 요약

| 관계 | 설명 |
|------|------|
| `gfx_players` 1:N `profile_images` | GFX 플레이어당 여러 이미지 |
| `wsop_players` 1:N `profile_images` | WSOP 플레이어당 여러 이미지 |
| `gfx_players` 1:N `player_overrides` | GFX 플레이어당 여러 오버라이드 |
| `wsop_players` 1:N `player_overrides` | WSOP 플레이어당 여러 오버라이드 |
| `player_link_mapping` N:1 `wsop_players` | 여러 매핑 → 하나의 WSOP |
| `player_link_mapping` N:1 `gfx_players` | 여러 매핑 → 하나의 GFX |

> ⚠️ **삭제된 테이블**: `manual_players`, `manual_audit_log`

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

> ⚠️ **삭제된 테이블**: `manual_players` (섹션 4.1 삭제됨)
> 플레이어 정보는 `gfx_players`와 `wsop_players`에서 관리합니다.

### 4.1 profile_images (프로필 이미지)

```sql
-- ============================================================================
-- profile_images: 플레이어 프로필 이미지 저장소
-- GFX 또는 WSOP 플레이어 참조 (둘 중 하나 필수)
-- ============================================================================

CREATE TABLE profile_images (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- 플레이어 참조 (Cross-Schema FK - 둘 중 하나 이상 필수)
    gfx_player_id UUID,   -- gfx_players FK (다른 스키마)
    wsop_player_id UUID,  -- wsop_players FK (다른 스키마)

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
    created_at TIMESTAMPTZ DEFAULT NOW(),

    -- 제약: 최소 하나의 플레이어 참조 필요
    CONSTRAINT chk_profile_images_player_ref CHECK (
        gfx_player_id IS NOT NULL OR wsop_player_id IS NOT NULL
    )
);

-- 인덱스
CREATE INDEX idx_profile_images_gfx_player ON profile_images(gfx_player_id);
CREATE INDEX idx_profile_images_wsop_player ON profile_images(wsop_player_id);
CREATE INDEX idx_profile_images_type ON profile_images(image_type);
CREATE INDEX idx_profile_images_storage ON profile_images(storage_type);

-- 유니크 제약: 플레이어(gfx/wsop)+이미지 타입별 하나의 primary
CREATE UNIQUE INDEX idx_profile_images_gfx_unique_primary
    ON profile_images(gfx_player_id, image_type)
    WHERE is_primary = TRUE AND gfx_player_id IS NOT NULL;

CREATE UNIQUE INDEX idx_profile_images_wsop_unique_primary
    ON profile_images(wsop_player_id, image_type)
    WHERE is_primary = TRUE AND wsop_player_id IS NOT NULL;
```

### 4.2 player_overrides (오버라이드 규칙)

```sql
-- ============================================================================
-- player_overrides: GFX/WSOP+ 데이터 오버라이드 규칙
-- 특정 필드만 수동 값으로 대체하는 규칙 정의
-- (manual_player_id 삭제됨 - gfx_player_id/wsop_player_id 사용)
-- ============================================================================

CREATE TABLE player_overrides (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- 참조 (Cross-Schema FK - 둘 중 하나 이상 필수)
    gfx_player_id UUID,   -- gfx_players FK (다른 스키마)
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
        gfx_player_id IS NOT NULL OR wsop_player_id IS NOT NULL
    )
);

-- 인덱스
CREATE INDEX idx_player_overrides_gfx ON player_overrides(gfx_player_id);
CREATE INDEX idx_player_overrides_wsop ON player_overrides(wsop_player_id);
CREATE INDEX idx_player_overrides_field ON player_overrides(field_name);
CREATE INDEX idx_player_overrides_active ON player_overrides(active) WHERE active = TRUE;
CREATE INDEX idx_player_overrides_priority ON player_overrides(priority);

-- 유니크 제약: 동일 플레이어/필드에 대한 활성 오버라이드는 하나
-- GFX 플레이어 기준
CREATE UNIQUE INDEX idx_player_overrides_gfx_unique_active
    ON player_overrides(gfx_player_id, field_name)
    WHERE active = TRUE AND gfx_player_id IS NOT NULL;

-- WSOP 플레이어 기준
CREATE UNIQUE INDEX idx_player_overrides_wsop_unique_active
    ON player_overrides(wsop_player_id, field_name)
    WHERE active = TRUE AND wsop_player_id IS NOT NULL;
```

### 4.3 player_link_mapping (플레이어 연결)

```sql
-- ============================================================================
-- player_link_mapping: GFX ↔ WSOP+ 플레이어 매핑
-- (manual_player_id 삭제됨)
-- ============================================================================

CREATE TABLE player_link_mapping (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- 플레이어 참조 (Cross-Schema FK - 둘 다 필수)
    gfx_player_id UUID NOT NULL,   -- gfx_players FK (다른 스키마)
    wsop_player_id UUID NOT NULL,  -- wsop_players FK (다른 스키마)

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
    merge_priority VARCHAR(20) DEFAULT 'wsop',  -- 병합 시 우선순위 소스

    -- 타임스탬프
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 인덱스
CREATE INDEX idx_player_link_wsop ON player_link_mapping(wsop_player_id);
CREATE INDEX idx_player_link_gfx ON player_link_mapping(gfx_player_id);
CREATE INDEX idx_player_link_verified ON player_link_mapping(is_verified) WHERE is_verified = TRUE;
CREATE INDEX idx_player_link_method ON player_link_mapping(match_method);
CREATE INDEX idx_player_link_confidence ON player_link_mapping(match_confidence DESC);

-- 유니크 제약: GFX-WSOP 조합의 중복 매핑 방지
CREATE UNIQUE INDEX idx_player_link_unique_gfx_wsop
    ON player_link_mapping(gfx_player_id, wsop_player_id);
```

> ⚠️ **삭제된 테이블**: `manual_audit_log` (섹션 4.4 삭제됨)
> 감사 로그는 `07-Supabase-Orchestration.md`의 `activity_log` 테이블 사용

---

## 5. 뷰 정의

> ⚠️ **삭제된 뷰**: `v_manual_players_complete`, `v_unlinked_players`, `v_recent_changes`
> (manual_players, manual_audit_log 테이블 삭제에 따라 제거됨)

### 5.1 v_player_images_all (플레이어별 전체 이미지 뷰)

```sql
-- ============================================================================
-- v_player_images_all: 플레이어별 모든 이미지 목록
-- GFX/WSOP 플레이어 기반 (manual_players 삭제됨)
-- ============================================================================

CREATE OR REPLACE VIEW v_player_images_all AS
-- GFX 플레이어 이미지
SELECT
    'gfx' AS source,
    gp.id AS player_id,
    gp.player_hash AS player_code,
    gp.name AS player_name,
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
FROM gfx_players gp
JOIN profile_images pi ON gp.id = pi.gfx_player_id

UNION ALL

-- WSOP 플레이어 이미지
SELECT
    'wsop' AS source,
    wp.id AS player_id,
    wp.wsop_player_id AS player_code,
    wp.name AS player_name,
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
FROM wsop_players wp
JOIN profile_images pi ON wp.id = pi.wsop_player_id

ORDER BY source, player_name, image_type, is_primary DESC;
```

### 5.2 v_active_overrides (활성 오버라이드 뷰)

```sql
-- ============================================================================
-- v_active_overrides: 현재 활성화된 오버라이드 목록
-- GFX/WSOP 플레이어 기반 (manual_player_id 삭제됨)
-- ============================================================================

CREATE OR REPLACE VIEW v_active_overrides AS
SELECT
    po.id,
    CASE
        WHEN po.gfx_player_id IS NOT NULL THEN 'gfx'
        ELSE 'wsop'
    END AS source,
    COALESCE(gp.name, wp.name) AS player_name,
    COALESCE(gp.player_hash, wp.wsop_player_id) AS player_code,
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
LEFT JOIN gfx_players gp ON po.gfx_player_id = gp.id
LEFT JOIN wsop_players wp ON po.wsop_player_id = wp.id
WHERE po.active = TRUE
  AND (po.valid_from IS NULL OR po.valid_from <= NOW())
  AND (po.valid_until IS NULL OR po.valid_until > NOW())
ORDER BY po.priority, player_name;
```

### 5.3 v_linked_players (연결된 플레이어 뷰)

```sql
-- ============================================================================
-- v_linked_players: GFX ↔ WSOP 연결된 플레이어 목록
-- ============================================================================

CREATE OR REPLACE VIEW v_linked_players AS
SELECT
    plm.id AS link_id,
    plm.gfx_player_id,
    plm.wsop_player_id,
    gp.name AS gfx_name,
    wp.name AS wsop_name,
    wp.country_code,
    plm.match_confidence,
    plm.match_method,
    plm.is_verified,
    plm.verified_by,
    plm.verified_at,
    plm.created_at
FROM player_link_mapping plm
JOIN gfx_players gp ON plm.gfx_player_id = gp.id
JOIN wsop_players wp ON plm.wsop_player_id = wp.id
ORDER BY plm.match_confidence DESC, gp.name;
```

---

## 6. 함수 및 트리거

> ⚠️ **삭제된 함수/트리거**:
> - `generate_player_code()`, `set_player_code()` (manual_players 삭제)
> - `normalize_manual_player_name()`, `set_manual_normalized_name()` (manual_players 삭제)
> - `log_manual_audit()` (manual_audit_log 삭제 → `activity_log` 사용)

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

-- 남은 테이블에 트리거 적용 (manual_players 트리거 삭제됨)
CREATE TRIGGER update_player_overrides_updated_at
    BEFORE UPDATE ON player_overrides
    FOR EACH ROW
    EXECUTE FUNCTION update_manual_updated_at_column();

CREATE TRIGGER update_player_link_mapping_updated_at
    BEFORE UPDATE ON player_link_mapping
    FOR EACH ROW
    EXECUTE FUNCTION update_manual_updated_at_column();
```

### 6.2 오버라이드 적용 함수

```sql
-- ============================================================================
-- 함수: 플레이어 필드에 오버라이드 적용
-- GFX/WSOP 플레이어 ID 기반 (manual_player_id 삭제됨)
-- ============================================================================

CREATE OR REPLACE FUNCTION get_player_field_with_override(
    p_gfx_player_id UUID,
    p_wsop_player_id UUID,
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
    WHERE (
            (p_gfx_player_id IS NOT NULL AND gfx_player_id = p_gfx_player_id)
            OR (p_wsop_player_id IS NOT NULL AND wsop_player_id = p_wsop_player_id)
          )
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
| GFX 플레이어 이미지 | `WHERE gfx_player_id = ?` | `idx_profile_images_gfx_player` |
| WSOP 플레이어 이미지 | `WHERE wsop_player_id = ?` | `idx_profile_images_wsop_player` |
| 이미지 타입별 조회 | `WHERE image_type = ?` | `idx_profile_images_type` |
| 활성 오버라이드 | `WHERE active = TRUE` | `idx_player_overrides_active` |
| GFX 플레이어 오버라이드 | `WHERE gfx_player_id = ?` | `idx_player_overrides_gfx` |
| WSOP 플레이어 오버라이드 | `WHERE wsop_player_id = ?` | `idx_player_overrides_wsop` |
| 검증된 매핑 | `WHERE is_verified = TRUE` | `idx_player_link_verified` |
| 매핑 신뢰도 순 | `ORDER BY match_confidence` | `idx_player_link_confidence` |

### 7.2 인덱스 요약

```sql
-- Primary Keys (자동 생성)
-- profile_images.id, player_overrides.id, player_link_mapping.id

-- B-tree Indexes (범위/정렬 쿼리)
-- profile_images: gfx_player_id, wsop_player_id, image_type
-- player_overrides: priority, field_name
-- player_link_mapping: match_confidence

-- Partial Indexes (조건부 최적화)
-- profile_images.is_primary WHERE TRUE (GFX/WSOP별)
-- player_overrides.active WHERE TRUE (GFX/WSOP별)
-- player_link_mapping.is_verified WHERE TRUE
```

---

## 8. RLS 정책 (Row Level Security)

```sql
-- ============================================================================
-- RLS 정책 설정 (Supabase 환경)
-- (manual_players, manual_audit_log 삭제됨)
-- ============================================================================

-- 남은 테이블 RLS 활성화
ALTER TABLE profile_images ENABLE ROW LEVEL SECURITY;
ALTER TABLE player_overrides ENABLE ROW LEVEL SECURITY;
ALTER TABLE player_link_mapping ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- profile_images 정책
-- ============================================================================
CREATE POLICY "profile_images_select_authenticated"
    ON profile_images FOR SELECT
    USING (auth.role() = 'authenticated');

CREATE POLICY "profile_images_all_service"
    ON profile_images FOR ALL
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
```

---

## 9. 마이그레이션 순서

### 실행 순서

```
1. ENUM 타입 생성 (CREATE TYPE)
2. profile_images 테이블 생성
3. player_overrides 테이블 생성
4. player_link_mapping 테이블 생성
5. 뷰 생성 (CREATE VIEW)
6. 함수 생성 (CREATE FUNCTION)
7. 트리거 생성 (CREATE TRIGGER)
8. 인덱스 생성 (CREATE INDEX)
9. RLS 정책 적용 (ALTER TABLE, CREATE POLICY)
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
