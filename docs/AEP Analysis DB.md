# AEP Analysis Database Schema

CyprusDesign.aep After Effects 프로젝트 분석 데이터를 위한 PostgreSQL 데이터베이스 스키마 설계 문서

**Version**: 1.0.0
**Date**: 2026-01-13
**Project**: AEP Composition Analysis (automation_aep)

---

## 1. 개요

### 1.1 목적

CyprusDesign.aep After Effects 프로젝트의 **comp 폴더 내 콤포지션 요소**를 분석하여:
- 컴포지션별 폴더 계층 구조 저장
- 레이어 정보 및 패턴 분석
- 동적 텍스트/이미지 바인딩을 위한 매핑 규칙 정의
- 미디어 소스 (국기 이미지 등) 관리

### 1.2 AEP 프로젝트 구조 요약

```
CyprusDesign.aep
├── Comp/ (2개)                    # 메인 렌더링 컴포지션
│   ├── Feature Table Leaderboard MAIN
│   └── Feature Table Leaderboard SUB
│
├── 방송 전or후 뽑기/ (11개)         # Pre/Post 방송용
│   ├── Broadcast Schedule
│   ├── Commentator
│   ├── Reporter
│   ├── Event info
│   └── Payouts ...
│
├── 방송 중 뽑기/ (16개)             # On-Air 방송용
│   ├── _MAIN Mini Chip Count
│   ├── _SUB_Mini Chip Count
│   ├── Chip Comparison
│   └── Chip Flow ...
│
├── Source comp/ (30개)             # 재사용 요소 (Element)
│   ├── Flag (141개 레이어)
│   ├── Chips
│   ├── BG 1~4
│   └── Pointer ...
│
├── Flag/ (270개)                   # 국기 이미지 Footage
├── Solids/ (11개)                  # 솔리드 레이어
└── Source Image/ (12개)            # 소스 이미지 Footage
```

### 1.3 분석 데이터 요약

| 항목 | 수량 |
|------|------|
| 총 컴포지션 | 58개 |
| 총 레이어 | 1,122개 |
| 텍스트 레이어 | 279개 |
| AV 레이어 (이미지/비디오) | 270개 |
| 고유 필드 키 | 84개 |
| 최대 슬롯 수 | 32개 |
| 프로젝트 폴더 | 7개 |

---

## 2. ERD (Entity Relationship Diagram)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          AEP Analysis Database Schema                        │
└─────────────────────────────────────────────────────────────────────────────┘

    ┌────────────────────────────┐
    │  aep_folders               │◄────────┐ (self-reference: parent_id)
    │  (프로젝트 폴더)            │─────────┘
    ├────────────────────────────┤
    │ PK id: int                 │
    │    name: varchar(255)      │
    │ FK parent_id: int          │
    │    item_count: int         │
    │    folder_type: enum       │
    │    aep_id: int             │
    │    created_at: timestamptz │
    └──────────┬─────────────────┘
               │
               │ 1:N
               ▼
    ┌────────────────────────────┐
    │  aep_compositions          │◄────────┐ (self-reference: precomp_parent_id)
    │  (컴포지션)                 │─────────┘
    ├────────────────────────────┤
    │ PK id: int                 │
    │ UK name: varchar(255)      │
    │ FK folder_id: int          │──────┐
    │    width: int              │      │
    │    height: int             │      │
    │    duration: float         │      │
    │    frame_rate: float       │      │
    │    num_layers: int         │      │
    │    category: enum          │      │
    │    slot_count: int         │      │
    │ FK precomp_parent_id: int  │      │
    │    text_layer_count: int   │      │
    │    av_layer_count: int     │      │
    │    created_at: timestamptz │      │
    │    updated_at: timestamptz │      │
    └──────────┬─────────────────┘      │
               │                        │
               │ 1:N                    │
    ┌──────────┴──────────┐             │
    │                     │             │
    ▼                     ▼             │
┌──────────────────────┐  ┌──────────────────────┐
│  aep_layers          │  │  aep_field_keys      │
│  (레이어)             │  │  (필드 키)           │
├──────────────────────┤  ├──────────────────────┤
│ PK id: int           │  │ PK id: int           │
│ FK composition_id    │  │ FK composition_id    │◄──┘
│    layer_index: int  │  │    field_key: varchar│
│    layer_name: varchar│  │    occurrence_count  │
│    layer_type: enum  │  │    created_at        │
│    enabled: bool     │  └──────────────────────┘
│    text_content: text│
│    source_path: varchar│
│ FK source_id: int    │──────┐
│    in_point: float   │      │
│    out_point: float  │      │
│    created_at        │      │
└──────────┬───────────┘      │
           │                  │
           │ 1:1              │
           ▼                  │
┌──────────────────────┐      │
│  aep_layer_patterns  │      │
│  (패턴 정보)          │      │
├──────────────────────┤      │
│ PK id: int           │      │
│ FK layer_id: int (UQ)│      │
│    pattern_type: enum│      │
│    field_key: varchar│      │
│    slot_index: int   │      │
│    field_type: enum  │      │
└──────────────────────┘      │
                              │
    ┌────────────────────────────┐
    │  aep_media_sources         │◄──┘
    │  (미디어 소스)              │
    ├────────────────────────────┤
    │ PK id: int                 │
    │    file_name: varchar(255) │
    │ UK file_path: varchar(500) │
    │    file_extension: varchar │
    │    media_type: enum        │
    │ FK folder_id: int          │
    │    category: varchar       │
    │    width: int              │
    │    height: int             │
    │    duration: float         │
    │    country_code: varchar   │
    │    country_name: varchar   │
    │    aep_id: int             │
    │    extra_metadata: jsonb   │
    │    created_at: timestamptz │
    └────────────────────────────┘
```

### 테이블 관계 요약

| 관계 | 설명 |
|------|------|
| `aep_folders` 1:N `aep_folders` | 폴더 계층 구조 (자기 참조) |
| `aep_folders` 1:N `aep_compositions` | 폴더당 여러 컴포지션 |
| `aep_compositions` 1:N `aep_layers` | 컴포지션당 여러 레이어 |
| `aep_layers` 1:1 `aep_layer_patterns` | 레이어당 1개 패턴 (선택적) |
| `aep_compositions` 1:N `aep_field_keys` | 컴포지션당 여러 필드 키 |
| `aep_folders` 1:N `aep_media_sources` | 폴더당 여러 미디어 소스 |

---

## 3. Enum 타입 정의

```sql
-- ============================================================================
-- ENUM Types
-- ============================================================================

-- 폴더 타입
CREATE TYPE aep_folder_type AS ENUM (
    'comp',       -- 컴포지션 폴더
    'footage',    -- Footage 폴더
    'solid',      -- Solids 폴더
    'root'        -- 루트 레벨
);

-- 컴포지션 카테고리
CREATE TYPE aep_category AS ENUM (
    'chip_display',   -- 칩 표시 (16개)
    'element',        -- 재사용 요소 (14개)
    'player_info',    -- 선수 정보 (6개)
    'event_info',     -- 이벤트 정보 (5개)
    'other',          -- 기타 (4개)
    'leaderboard',    -- 순위표 (3개)
    'payout',         -- 상금 정보 (3개)
    'elimination',    -- 탈락 정보 (2개)
    'staff',          -- 스태프 정보 (2개)
    'transition',     -- 전환 화면 (2개)
    'schedule'        -- 방송 스케줄 (1개)
);

-- 레이어 타입
CREATE TYPE aep_layer_type AS ENUM (
    'text',              -- 텍스트 레이어 (279개)
    'AVLayer',           -- 이미지/비디오 레이어 (270개)
    'ShapeLayer',        -- 도형 레이어
    'AdjustmentLayer',   -- 조정 레이어
    'NullLayer',         -- 널 레이어
    'Camera',            -- 카메라 레이어
    'Light'              -- 라이트 레이어
);

-- 패턴 타입
CREATE TYPE aep_pattern_type AS ENUM (
    'single',   -- 단일 필드 (예: wsop_super_circuit_cyprus)
    'slot'      -- 슬롯 기반 반복 (예: Date 1, Date 2)
);

-- 필드 타입
CREATE TYPE aep_field_type AS ENUM (
    'text',       -- 일반 텍스트
    'date',       -- 날짜 (Oct 16)
    'time',       -- 시간 (05:10 PM)
    'number',     -- 숫자
    'currency',   -- 통화 ($1,000,000)
    'image'       -- 이미지 참조
);

-- 미디어 타입
CREATE TYPE aep_media_type AS ENUM (
    'image',   -- PNG, JPG, PSD
    'video',   -- MP4, MOV
    'audio'    -- MP3, WAV
);
```

---

## 4. 테이블 DDL

### 4.1 aep_folders (프로젝트 폴더)

```sql
-- ============================================================================
-- aep_folders: AEP 프로젝트 패널 폴더 구조
-- 7개 폴더: Comp, 방송 전or후 뽑기, 방송 중 뽑기, Source comp, Flag, Solids, Source Image
-- ============================================================================

CREATE TABLE aep_folders (
    id SERIAL PRIMARY KEY,

    -- 폴더 정보
    name VARCHAR(255) NOT NULL,

    -- 폴더 계층 구조 (자기 참조)
    parent_id INTEGER REFERENCES aep_folders(id) ON DELETE CASCADE,

    -- 메타데이터
    item_count INTEGER DEFAULT 0,
    folder_type aep_folder_type NOT NULL,

    -- AEP 내부 ID (ExtendScript에서 추출)
    aep_id INTEGER,

    -- 타임스탬프
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 인덱스
CREATE INDEX idx_aep_folders_name ON aep_folders(name);
CREATE INDEX idx_aep_folders_type ON aep_folders(folder_type);
CREATE INDEX idx_aep_folders_parent ON aep_folders(parent_id);
```

### 4.2 aep_compositions (컴포지션)

```sql
-- ============================================================================
-- aep_compositions: AEP 컴포지션 분석 데이터
-- 58개 컴포지션, 11개 카테고리
-- ============================================================================

CREATE TABLE aep_compositions (
    id SERIAL PRIMARY KEY,

    -- 컴포지션 식별
    name VARCHAR(255) NOT NULL UNIQUE,

    -- 폴더 연결
    folder_id INTEGER REFERENCES aep_folders(id) ON DELETE SET NULL,

    -- 컴포지션 메타데이터
    width INTEGER NOT NULL,
    height INTEGER NOT NULL,
    duration REAL NOT NULL,
    frame_rate REAL NOT NULL,
    num_layers INTEGER NOT NULL,

    -- 분류
    category aep_category NOT NULL,
    slot_count INTEGER DEFAULT 0,

    -- 레이어 통계
    text_layer_count INTEGER DEFAULT 0,
    av_layer_count INTEGER DEFAULT 0,
    slot_field_count INTEGER DEFAULT 0,
    single_field_count INTEGER DEFAULT 0,

    -- 중첩 컴포지션 참조
    precomp_parent_id INTEGER REFERENCES aep_compositions(id) ON DELETE SET NULL,

    -- AEP 내부 ID
    aep_id INTEGER,

    -- 타임스탬프
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 인덱스
CREATE INDEX idx_aep_compositions_name ON aep_compositions(name);
CREATE INDEX idx_aep_compositions_folder ON aep_compositions(folder_id);
CREATE INDEX idx_aep_compositions_category ON aep_compositions(category);
CREATE INDEX idx_aep_compositions_precomp ON aep_compositions(precomp_parent_id);
```

### 4.3 aep_layers (레이어)

```sql
-- ============================================================================
-- aep_layers: 컴포지션별 레이어 정보
-- 1,122개 레이어 (텍스트 279개, AV 270개)
-- ============================================================================

CREATE TABLE aep_layers (
    id SERIAL PRIMARY KEY,

    -- 컴포지션 참조
    composition_id INTEGER NOT NULL REFERENCES aep_compositions(id) ON DELETE CASCADE,

    -- 레이어 기본 정보
    layer_index INTEGER NOT NULL,
    layer_name VARCHAR(255) NOT NULL,
    layer_type aep_layer_type NOT NULL,
    enabled BOOLEAN DEFAULT TRUE,

    -- 타임라인 정보
    in_point REAL,
    out_point REAL,

    -- 텍스트 레이어 전용
    text_content TEXT,

    -- AV 레이어 전용
    source_path VARCHAR(500),
    source_id INTEGER REFERENCES aep_media_sources(id) ON DELETE SET NULL,

    -- 타임스탬프
    created_at TIMESTAMPTZ DEFAULT NOW(),

    -- 복합 유니크 제약
    CONSTRAINT uq_aep_comp_layer_idx UNIQUE (composition_id, layer_index)
);

-- 인덱스
CREATE INDEX idx_aep_layers_composition ON aep_layers(composition_id);
CREATE INDEX idx_aep_layers_type ON aep_layers(layer_type);
CREATE INDEX idx_aep_layers_name ON aep_layers(layer_name);
CREATE INDEX idx_aep_layers_enabled ON aep_layers(enabled) WHERE enabled = TRUE;
```

### 4.4 aep_layer_patterns (패턴 정보)

```sql
-- ============================================================================
-- aep_layer_patterns: 레이어 이름 패턴 분석
-- 84개 고유 패턴 (single/slot)
-- ============================================================================

CREATE TABLE aep_layer_patterns (
    id SERIAL PRIMARY KEY,

    -- 레이어 참조 (1:1 관계)
    layer_id INTEGER NOT NULL UNIQUE REFERENCES aep_layers(id) ON DELETE CASCADE,

    -- 패턴 정보
    pattern_type aep_pattern_type NOT NULL,
    field_key VARCHAR(100) NOT NULL,
    slot_index INTEGER,  -- slot 패턴일 경우
    field_type aep_field_type DEFAULT 'text'
);

-- 인덱스
CREATE INDEX idx_aep_layer_patterns_field_key ON aep_layer_patterns(field_key);
CREATE INDEX idx_aep_layer_patterns_type ON aep_layer_patterns(pattern_type);
CREATE INDEX idx_aep_layer_patterns_slot ON aep_layer_patterns(slot_index) WHERE slot_index IS NOT NULL;
```

### 4.5 aep_field_keys (필드 키)

```sql
-- ============================================================================
-- aep_field_keys: 컴포지션별 필드 키 목록
-- 84개 고유 필드 키 (name, chips, rank, prize, date, time 등)
-- ============================================================================

CREATE TABLE aep_field_keys (
    id SERIAL PRIMARY KEY,

    -- 컴포지션 참조
    composition_id INTEGER NOT NULL REFERENCES aep_compositions(id) ON DELETE CASCADE,

    -- 필드 키 정보
    field_key VARCHAR(100) NOT NULL,
    occurrence_count INTEGER DEFAULT 1,

    -- 타임스탬프
    created_at TIMESTAMPTZ DEFAULT NOW(),

    -- 복합 유니크 제약
    CONSTRAINT uq_aep_comp_field_key UNIQUE (composition_id, field_key)
);

-- 인덱스
CREATE INDEX idx_aep_field_keys_composition ON aep_field_keys(composition_id);
CREATE INDEX idx_aep_field_keys_key ON aep_field_keys(field_key);
```

### 4.6 aep_media_sources (미디어 소스)

```sql
-- ============================================================================
-- aep_media_sources: Footage 아이템 정보
-- 270개 미디어 소스 (PNG 212개, JPG 40개, MP4 12개 등)
-- 국기 이미지 200+ 포함
-- ============================================================================

CREATE TABLE aep_media_sources (
    id SERIAL PRIMARY KEY,

    -- 파일 정보
    file_name VARCHAR(255) NOT NULL,
    file_path VARCHAR(500) NOT NULL UNIQUE,
    file_extension VARCHAR(20) NOT NULL,
    media_type aep_media_type NOT NULL,

    -- 폴더 연결
    folder_id INTEGER REFERENCES aep_folders(id) ON DELETE SET NULL,

    -- 분류
    category VARCHAR(100),  -- Flag, Source Image 등

    -- 미디어 메타데이터
    width INTEGER,
    height INTEGER,
    duration REAL,
    frame_rate REAL,

    -- 국기 전용 필드
    country_code VARCHAR(10),   -- ISO 국가 코드 (KR, US 등)
    country_name VARCHAR(100),  -- 국가명 (Korea, United States 등)

    -- AEP 내부 ID
    aep_id INTEGER,

    -- 추가 메타데이터 (JSON)
    extra_metadata JSONB,

    -- 타임스탬프
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 인덱스
CREATE INDEX idx_aep_media_sources_name ON aep_media_sources(file_name);
CREATE INDEX idx_aep_media_sources_type ON aep_media_sources(media_type);
CREATE INDEX idx_aep_media_sources_folder ON aep_media_sources(folder_id);
CREATE INDEX idx_aep_media_sources_category ON aep_media_sources(category);
CREATE INDEX idx_aep_media_sources_country ON aep_media_sources(country_code);
```

---

## 5. 뷰 정의

### 5.1 v_compositions_by_folder (폴더별 컴포지션 뷰)

```sql
-- ============================================================================
-- v_compositions_by_folder: 폴더별 컴포지션 목록
-- ============================================================================

CREATE OR REPLACE VIEW v_compositions_by_folder AS
SELECT
    c.id,
    c.name,
    c.category,
    c.width,
    c.height,
    c.duration,
    c.num_layers,
    c.slot_count,
    c.text_layer_count,
    f.name AS folder_name,
    f.folder_type
FROM aep_compositions c
LEFT JOIN aep_folders f ON c.folder_id = f.id
ORDER BY f.name, c.name;
```

### 5.2 v_text_layers_with_patterns (패턴 포함 텍스트 레이어 뷰)

```sql
-- ============================================================================
-- v_text_layers_with_patterns: 패턴 정보가 포함된 텍스트 레이어
-- ============================================================================

CREATE OR REPLACE VIEW v_text_layers_with_patterns AS
SELECT
    l.id,
    l.layer_index,
    l.layer_name,
    l.text_content,
    l.enabled,
    p.pattern_type,
    p.field_key,
    p.slot_index,
    p.field_type,
    c.name AS composition_name,
    c.category AS composition_category,
    f.name AS folder_name
FROM aep_layers l
LEFT JOIN aep_layer_patterns p ON l.id = p.layer_id
LEFT JOIN aep_compositions c ON l.composition_id = c.id
LEFT JOIN aep_folders f ON c.folder_id = f.id
WHERE l.layer_type = 'text'
ORDER BY c.name, l.layer_index;
```

### 5.3 v_flag_images (국기 이미지 뷰)

```sql
-- ============================================================================
-- v_flag_images: 국기 이미지 목록 (country_code 기반 매핑용)
-- ============================================================================

CREATE OR REPLACE VIEW v_flag_images AS
SELECT
    id,
    file_name,
    file_path,
    country_code,
    country_name,
    width,
    height
FROM aep_media_sources
WHERE category = 'Flag'
ORDER BY country_code;
```

### 5.4 v_folder_summary (폴더 요약 뷰)

```sql
-- ============================================================================
-- v_folder_summary: 폴더별 요약 통계
-- ============================================================================

CREATE OR REPLACE VIEW v_folder_summary AS
SELECT
    f.id,
    f.name,
    f.folder_type,
    f.item_count,
    COUNT(DISTINCT c.id) AS composition_count,
    COUNT(DISTINCT m.id) AS media_source_count,
    SUM(c.num_layers) AS total_layers
FROM aep_folders f
LEFT JOIN aep_compositions c ON f.id = c.folder_id
LEFT JOIN aep_media_sources m ON f.id = m.folder_id
GROUP BY f.id, f.name, f.folder_type, f.item_count
ORDER BY f.name;
```

---

## 6. 함수 및 트리거

### 6.1 updated_at 자동 갱신

```sql
-- ============================================================================
-- 트리거 함수: updated_at 자동 갱신
-- ============================================================================

CREATE OR REPLACE FUNCTION update_aep_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- aep_compositions 테이블에 트리거 적용
CREATE TRIGGER update_aep_compositions_updated_at
    BEFORE UPDATE ON aep_compositions
    FOR EACH ROW
    EXECUTE FUNCTION update_aep_updated_at_column();
```

### 6.2 레이어 통계 업데이트

```sql
-- ============================================================================
-- 함수: 컴포지션 레이어 통계 업데이트
-- ============================================================================

CREATE OR REPLACE FUNCTION update_composition_layer_stats(p_composition_id INTEGER)
RETURNS VOID AS $$
BEGIN
    UPDATE aep_compositions
    SET
        text_layer_count = (
            SELECT COUNT(*) FROM aep_layers
            WHERE composition_id = p_composition_id AND layer_type = 'text'
        ),
        av_layer_count = (
            SELECT COUNT(*) FROM aep_layers
            WHERE composition_id = p_composition_id AND layer_type = 'AVLayer'
        ),
        slot_field_count = (
            SELECT COUNT(*) FROM aep_layer_patterns lp
            JOIN aep_layers l ON lp.layer_id = l.id
            WHERE l.composition_id = p_composition_id AND lp.pattern_type = 'slot'
        ),
        single_field_count = (
            SELECT COUNT(*) FROM aep_layer_patterns lp
            JOIN aep_layers l ON lp.layer_id = l.id
            WHERE l.composition_id = p_composition_id AND lp.pattern_type = 'single'
        ),
        updated_at = NOW()
    WHERE id = p_composition_id;
END;
$$ LANGUAGE plpgsql;
```

---

## 7. 인덱스 전략 및 쿼리 패턴

### 7.1 주요 쿼리 패턴

| 쿼리 패턴 | 설명 | 최적화 인덱스 |
|-----------|------|---------------|
| 폴더별 컴포지션 | `WHERE folder_id = ?` | `idx_aep_compositions_folder` |
| 카테고리별 조회 | `WHERE category = ?` | `idx_aep_compositions_category` |
| 컴포지션별 레이어 | `WHERE composition_id = ?` | `idx_aep_layers_composition` |
| 텍스트 레이어 | `WHERE layer_type = 'text'` | `idx_aep_layers_type` |
| 필드 키 검색 | `WHERE field_key = ?` | `idx_aep_field_keys_key` |
| 국기 코드 검색 | `WHERE country_code = ?` | `idx_aep_media_sources_country` |
| 활성 레이어만 | `WHERE enabled = TRUE` | `idx_aep_layers_enabled` (partial) |

### 7.2 인덱스 요약

```sql
-- Primary Keys (자동 생성)
-- aep_folders.id, aep_compositions.id, aep_layers.id, etc.

-- Unique Constraints
-- aep_compositions.name
-- aep_media_sources.file_path
-- (composition_id, layer_index), (composition_id, field_key)
-- aep_layer_patterns.layer_id (1:1 관계)

-- B-tree Indexes (범위/정렬 쿼리)
-- aep_compositions: folder_id, category
-- aep_layers: composition_id, layer_type

-- Partial Indexes (조건부 최적화)
-- aep_layers.enabled WHERE TRUE
-- aep_layer_patterns.slot_index WHERE NOT NULL
```

---

## 8. 초기 데이터

### 8.1 폴더 초기 데이터

```sql
-- ============================================================================
-- 7개 폴더 초기 데이터
-- ============================================================================

INSERT INTO aep_folders (name, item_count, folder_type) VALUES
('Comp', 2, 'comp'),
('방송 전or후 뽑기', 11, 'comp'),
('방송 중 뽑기', 16, 'comp'),
('Source comp', 30, 'comp'),
('Flag', 270, 'footage'),
('Solids', 11, 'solid'),
('Source Image', 12, 'footage');
```

### 8.2 카테고리별 분포

| 카테고리 | 컴포지션 수 | 설명 |
|----------|------------|------|
| chip_display | 16 | 칩 표시 (Mini Chip Count 등) |
| element | 14 | 재사용 요소 (BG, Flag, Chips) |
| player_info | 6 | 선수 정보 (NAME 등) |
| event_info | 5 | 이벤트 정보 (Event info 등) |
| other | 4 | 기타 (Location 등) |
| leaderboard | 3 | 순위표 (Feature Table) |
| payout | 3 | 상금 정보 (Payouts) |
| elimination | 2 | 탈락 정보 (Elimination) |
| staff | 2 | 스태프 정보 (Commentator, Reporter) |
| transition | 2 | 전환 화면 |
| schedule | 1 | 방송 스케줄 (Broadcast Schedule) |

---

## 9. 마이그레이션 순서

### 실행 순서

```
1. ENUM 타입 생성 (CREATE TYPE)
2. aep_folders 테이블 생성
3. aep_media_sources 테이블 생성
4. aep_compositions 테이블 생성
5. aep_layers 테이블 생성
6. aep_layer_patterns 테이블 생성
7. aep_field_keys 테이블 생성
8. 뷰 생성 (CREATE VIEW)
9. 함수 생성 (CREATE FUNCTION)
10. 트리거 생성 (CREATE TRIGGER)
11. 인덱스 생성 (CREATE INDEX)
12. 초기 데이터 삽입 (INSERT)
```

### Rollback 순서 (역순)

```
1. 초기 데이터 삭제 (DELETE)
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
| `aep_compositions` | `name UNIQUE` | 컴포지션 이름 중복 방지 |
| `aep_media_sources` | `file_path UNIQUE` | 파일 경로 중복 방지 |
| `aep_layers` | `(composition_id, layer_index) UNIQUE` | 레이어 인덱스 중복 방지 |
| `aep_layer_patterns` | `layer_id UNIQUE` | 1:1 관계 보장 |
| `aep_field_keys` | `(composition_id, field_key) UNIQUE` | 필드 키 중복 방지 |

---

## 11. 구현 연동 파일

| 파일 | 역할 | 연동 테이블 |
|------|------|-------------|
| `backend/app/models/aep_folder.py` | SQLAlchemy 모델 | aep_folders |
| `backend/app/models/aep_composition.py` | SQLAlchemy 모델 | aep_compositions |
| `backend/app/models/aep_layer.py` | SQLAlchemy 모델 | aep_layers, aep_layer_patterns |
| `backend/app/models/aep_field_key.py` | SQLAlchemy 모델 | aep_field_keys |
| `backend/app/models/aep_media_source.py` | SQLAlchemy 모델 | aep_media_sources |
| `automation_aep/scripts/extract_folder_mapping.jsx` | ExtendScript | 폴더 매핑 추출 |
| `automation_aep/CyprusDesign/comp_folder_detailed.json` | 분석 데이터 | 임포트 소스 |

---

## Appendix: 주요 필드 키

### 패턴별 분류

| 패턴 타입 | 필드 키 | 슬롯 수 | 예시 |
|-----------|---------|--------|------|
| slot | name | 30 | Name 1, Name 2 ... |
| slot | chips | 19 | Chips 1, Chips 2 ... |
| slot | rank | 25 | Rank 1, Rank 2 ... |
| slot | prize | 24 | prize 1, prize 2 ... |
| slot | bbs | 14 | BBs 1, BBs 2 ... |
| slot | date | 20 | Date 1, Date 2 ... |
| slot | event_name | 6 | Event Name 1 ... |
| slot | time | 6 | time 1, time 2 ... |
| single | wsop_super_circuit_cyprus | - | 고정 텍스트 |
| single | broadcast_schedule | - | 고정 텍스트 |
| single | payouts | - | 고정 텍스트 |
