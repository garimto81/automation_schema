# 00. 문서 인덱스 및 그룹 관리

**Version**: 2.4.0
**Last Updated**: 2026-01-20
**Status**: Active
**Project**: Automation DB Schema

---

## 1. 폴더 구조

```
docs/
├── 00-DOCUMENT-INDEX.md        # 이 문서 (마스터 인덱스)
├── 01-DATA_FLOW.md             # 전체 데이터 흐름 개요
├── 10-Internal-Reference.md    # 내부 참조 문서
├── 11-LARGE-FILE-CHUNKING-STRATEGY.md  # 대용량 파일 청킹 전략
├── GFX_SUPABASE_CUESHEET_MAPPING.md    # 3계층 통합 매핑
├── MAPPING_DIAGRAM.md          # ⭐ GFX→DB→AEP 시각화 다이어그램 (NEW)
│
├── gfx-json/                   # GFX JSON 관련 문서
│   ├── 02-GFX-JSON-DB.md
│   ├── GFX_JSON_COMPREHENSIVE_ANALYSIS.md
│   ├── GFX_FIELD_EXTRACTION_GUIDE.md
│   └── GFX_FIELD_OPTIMIZATION_STRATEGY.md
│
├── wsop-plus/                  # WSOP+ 데이터 관련 문서
│   └── 03-WSOP+-DB.md
│
├── manual/                     # Manual Override 관련 문서
│   └── 04-Manual-DB.md
│
├── cuesheet/                   # 큐시트 관련 문서
│   ├── 05-Cuesheet-DB.md
│   ├── CUESHEET_FIELD_ANALYSIS.md
│   └── CUESHEET_JSON_MAPPING.md
│
├── ae/                         # After Effects 관련 문서
│   ├── 06-AEP-Analysis-DB.md
│   ├── 08-GFX-AEP-Mapping.md
│   ├── images/
│   │   └── gfx-aep-mapping-diagram.png
│   └── mockups/
│       └── gfx-aep-mapping-diagram.html
│
└── supabase/                   # Supabase 인프라 관련 문서
    ├── 07-Supabase-Orchestration.md
    ├── 09-DB-Sync-Guidelines.md
    ├── DOCUMENT_SYNC_STRATEGY.md
    ├── current_schema_dump.sql
    └── erd/
        ├── 01_gfx_schema.mmd/.png
        ├── 02_wsop_schema.mmd/.png
        ├── 03_manual_schema.mmd/.png
        ├── 04_cuesheet_schema.mmd/.png
        ├── 05_orchestration_schema.mmd/.png
        └── 06_unified_schema.mmd/.png
```

---

## 2. 폴더별 개요

### 2.1 gfx-json/ - GFX JSON 스키마

| 문서 | 역할 | 상태 |
|------|------|------|
| **02-GFX-JSON-DB.md** | GFX JSON 파싱 스키마 DDL | Active |
| **GFX_JSON_COMPREHENSIVE_ANALYSIS.md** | 두 소스 통합 분석 (60개 필드) | Active |
| **GFX_FIELD_EXTRACTION_GUIDE.md** | 필드별 추출 로직 가이드 | Active |
| **GFX_FIELD_OPTIMIZATION_STRATEGY.md** | DB 스키마 최적화 전략 | Active |

**핵심 테이블**: `gfx_sessions`, `gfx_hands`, `gfx_hand_players`, `gfx_players`, `gfx_events`

### 2.2 wsop-plus/ - WSOP+ 데이터

| 문서 | 역할 | 상태 |
|------|------|------|
| **03-WSOP+-DB.md** | WSOP+ 데이터 임포트 스키마 | Active |

**핵심 테이블**: `wsop_events`, `wsop_players`, `wsop_chip_counts`, `wsop_standings`

### 2.3 manual/ - Manual Override

| 문서 | 역할 | 상태 |
|------|------|------|
| **04-Manual-DB.md** | 플레이어 오버라이드/이미지 스키마 | Active |

**핵심 테이블**: `profile_images`, `player_overrides`, `player_link_mapping`

### 2.4 cuesheet/ - 큐시트 (방송 진행)

| 문서 | 역할 | 상태 |
|------|------|------|
| **05-Cuesheet-DB.md** | 큐시트 스키마 DDL | Active |
| **CUESHEET_FIELD_ANALYSIS.md** | Google Sheets 정밀 분석 | Active |
| **CUESHEET_JSON_MAPPING.md** | JSON 필드 매핑 정의서 | Active |

**핵심 테이블**: `broadcast_sessions`, `cue_sheets`, `cue_items`, `cue_templates`, `gfx_triggers`

### 2.5 ae/ - After Effects 연동

| 문서 | 역할 | 상태 |
|------|------|------|
| **06-AEP-Analysis-DB.md** | AEP 컴포지션 분석 스키마 | Active |
| **08-GFX-AEP-Mapping.md** | GFX DB → AEP 매핑 전략 | Active |

**핵심 테이블**: `aep_compositions`, `aep_layers`, `aep_field_keys`
**26개 AEP 컴포지션**: L3_Profile, ChipCount_Leaderboard, VPIP 등

### 2.6 supabase/ - 인프라 및 오케스트레이션

| 문서 | 역할 | 상태 |
|------|------|------|
| **07-Supabase-Orchestration.md** | 오케스트레이션 스키마 DDL | Active |
| **09-DB-Sync-Guidelines.md** | External PostgreSQL ↔ Supabase 동기화 | Active |
| **DOCUMENT_SYNC_STRATEGY.md** | 문서-마이그레이션 동기화 전략 | Active |
| **current_schema_dump.sql** | 현재 스키마 덤프 | Reference |
| **erd/** | ERD 다이어그램 (mermaid + PNG) | Reference |

**핵심 테이블**: `unified_players`, `unified_events`, `job_queue`, `render_queue`, `sync_status`

---

## 3. 문서 그룹 아키텍처

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         문서 그룹 아키텍처 v2.0                               │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│  LAYER 1: 메인 문서 (docs/)                                                  │
├─────────────────────────────────────────────────────────────────────────────┤
│   00-DOCUMENT-INDEX.md     ─── 이 문서 (마스터 인덱스)                       │
│   01-DATA_FLOW.md          ─── 전체 데이터 흐름 개요                         │
│   10-Internal-Reference.md ─── 내부 참조                                    │
│   11-LARGE-FILE-CHUNKING.md ── 대용량 파일 청킹 전략                         │
│   GFX_SUPABASE_CUESHEET_MAPPING.md ── 3계층 통합 매핑 (JSON→DB→방송)        │
│   MAPPING_DIAGRAM.md ──────── ⭐ GFX→DB→AEP 시각화 다이어그램 (26 AEP)       │
└─────────────────────────────────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│  LAYER 2: 도메인별 폴더                                                      │
├────────────────┬────────────────┬────────────────┬────────────────┬─────────┤
│   gfx-json/    │   wsop-plus/   │    manual/     │   cuesheet/    │   ae/   │
│   (4 files)    │   (1 file)     │   (1 file)     │   (3 files)    │(2+imgs) │
└────────────────┴────────────────┴────────────────┴────────────────┴─────────┘
         │
         ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│  LAYER 3: 인프라 (supabase/)                                                 │
├─────────────────────────────────────────────────────────────────────────────┤
│   07-Supabase-Orchestration.md ─── 오케스트레이션 스키마                     │
│   09-DB-Sync-Guidelines.md ─────── DB 동기화 가이드                          │
│   DOCUMENT_SYNC_STRATEGY.md ────── 문서-코드 동기화                          │
│   erd/ ─────────────────────────── ERD 다이어그램                            │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 4. SSOT (Single Source of Truth) 정책

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         SSOT 계층 구조                                        │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  Layer 1: 설계 문서 (docs/**/*.md)                                          │
│  ┌─────────────────────────────────────────────────────────────┐            │
│  │  비즈니스 요구사항, 설계 의도, 예시                           │            │
│  │  → 변경 시 Layer 2 반영 필요                                 │            │
│  └─────────────────────────────────────────────────────────────┘            │
│                              │                                              │
│                              ▼                                              │
│  Layer 2: 스키마 정의 (SSOT) ★                                              │
│  ┌─────────────────────────────────────────────────────────────┐            │
│  │  supabase/migrations/*.sql (번호순 정렬)                     │            │
│  │  ※ 이것이 진실의 소스 (SSOT)                                 │            │
│  │  → 문서와 마이그레이션이 다르면 마이그레이션이 정답           │            │
│  └─────────────────────────────────────────────────────────────┘            │
│                              │                                              │
│                              ▼                                              │
│  Layer 3: 실제 DB (Supabase PostgreSQL)                                     │
│  ┌─────────────────────────────────────────────────────────────┐            │
│  │  supabase db push 결과                                       │            │
│  └─────────────────────────────────────────────────────────────┘            │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 5. 문서-마이그레이션 매핑

| 문서 | 마이그레이션 |
|------|-------------|
| gfx-json/02-GFX-JSON-DB.md | `20260113082406_01_gfx_schema.sql` |
| wsop-plus/03-WSOP+-DB.md | `20260113082703_02_wsop_schema.sql` |
| manual/04-Manual-DB.md | `20260113082705_03_manual_schema.sql` |
| cuesheet/05-Cuesheet-DB.md | `20260113082707_04_cuesheet_schema.sql` |
| ae/06-AEP-Analysis-DB.md | `20260114120000_gfx_aep_render_mapping.sql` |
| supabase/07-Supabase-Orchestration.md | `20260113082715_05_orch_schema.sql` |
| ae/08-GFX-AEP-Mapping.md | `20260114130000_08_aep_mapping_functions.sql` |
| supabase/09-DB-Sync-Guidelines.md | `20260119000000_json_public_schema_integration.sql` |

---

## 5.5 문서별 버전 현황

| 문서 경로 | 버전 | 업데이트 | 상태 |
|-----------|:----:|:--------:|:----:|
| **Layer 1: 메인 문서** ||||
| `00-DOCUMENT-INDEX.md` | 2.2.0 | 2026-01-19 | ✅ Active |
| `01-DATA_FLOW.md` | 2.0.0 | 2026-01-16 | ✅ Active |
| `10-Internal-Reference.md` | - | - | Reference |
| `11-LARGE-FILE-CHUNKING-STRATEGY.md` | - | 2026-01-19 | ✅ Active |
| `GFX_SUPABASE_CUESHEET_MAPPING.md` | 1.0.0 | 2026-01-19 | ✅ Active |
| `MAPPING_DIAGRAM.md` | 1.0.0 | 2026-01-20 | ✅ **NEW** |
| **gfx-json/** ||||
| `02-GFX-JSON-DB.md` | 1.1.0 | 2026-01-16 | ✅ Active |
| `GFX_JSON_COMPREHENSIVE_ANALYSIS.md` | 1.0.0 | 2026-01-19 | ✅ Active |
| `GFX_FIELD_EXTRACTION_GUIDE.md` | 1.0.0 | 2026-01-19 | ✅ Active |
| `GFX_FIELD_OPTIMIZATION_STRATEGY.md` | 2.0.0 | 2026-01-19 | ✅ Active |
| **wsop-plus/** ||||
| `03-WSOP+-DB.md` | 1.0.0 | 2026-01-13 | ✅ Active |
| **manual/** ||||
| `04-Manual-DB.md` | 2.0.0 | 2026-01-16 | ✅ Active |
| **cuesheet/** ||||
| `05-Cuesheet-DB.md` | 2.2.0 | 2026-01-19 | ✅ Active |
| `CUESHEET_FIELD_ANALYSIS.md` | 2.0.0 | 2026-01-19 | ✅ Active |
| `CUESHEET_JSON_MAPPING.md` | 1.0.0 | 2026-01-19 | ✅ Active |
| **ae/** ||||
| `06-AEP-Analysis-DB.md` | 1.0.0 | 2026-01-13 | ✅ Active |
| `08-GFX-AEP-Mapping.md` | 2.1.0 | 2026-01-16 | ✅ Active |
| **supabase/** ||||
| `07-Supabase-Orchestration.md` | 2.0.0 | 2026-01-16 | ✅ Active |
| `09-DB-Sync-Guidelines.md` | 1.0.0 | 2026-01-17 | ✅ Active |
| `DOCUMENT_SYNC_STRATEGY.md` | 1.0.0 | 2026-01-19 | ✅ Active |

---

## 6. 빠른 참조

### 6.1 스키마별 핵심 테이블

| 스키마 | 핵심 테이블 | 문서 경로 |
|--------|-------------|-----------|
| GFX JSON | gfx_sessions, gfx_hands, gfx_hand_players | gfx-json/02-GFX-JSON-DB.md |
| WSOP+ | wsop_events, wsop_players, wsop_chip_counts | wsop-plus/03-WSOP+-DB.md |
| Manual | profile_images, player_overrides | manual/04-Manual-DB.md |
| Cuesheet | broadcast_sessions, cue_items | cuesheet/05-Cuesheet-DB.md |
| AEP | aep_compositions, aep_layers | ae/06-AEP-Analysis-DB.md |
| Orchestration | unified_players, job_queue | supabase/07-Supabase-Orchestration.md |

### 6.2 ERD 다이어그램 위치

| 스키마 | ERD 파일 |
|--------|----------|
| GFX JSON | supabase/erd/01_gfx_schema.png |
| WSOP+ | supabase/erd/02_wsop_schema.png |
| Manual | supabase/erd/03_manual_schema.png |
| Cuesheet | supabase/erd/04_cuesheet_schema.png |
| Orchestration | supabase/erd/05_orchestration_schema.png |
| 통합 | supabase/erd/06_unified_schema.png |

### 6.3 JSON 매핑 문서

| 도메인 | JSON 매핑 문서 |
|--------|----------------|
| GFX JSON | gfx-json/GFX_JSON_COMPREHENSIVE_ANALYSIS.md |
| Cuesheet | cuesheet/CUESHEET_JSON_MAPPING.md |
| 3계층 통합 | GFX_SUPABASE_CUESHEET_MAPPING.md |
| **GFX→DB→AEP 시각화** | MAPPING_DIAGRAM.md |

---

## 7. 검증 스크립트

```powershell
# 문서-스키마 동기화 검증
python scripts/validate_docs_schema.py

# GFX 스키마 검증
python scripts/validate_gfx_schema.py

# 전체 스키마 덤프
supabase db dump --schema public > docs/supabase/current_schema_dump.sql
```

---

## 8. 스키마 변경 이력 (주요)

### 8.1 삭제된 테이블

| 테이블 | 삭제일 | 마이그레이션 | 대체 | 사유 |
|--------|--------|--------------|------|------|
| `chip_snapshots` | 2026-01-16 | `20260116000000_schema_simplification.sql` | `unified_chip_data` VIEW | 스키마 단순화 - WSOP + GFX 통합 뷰로 대체 |
| `manual_players` | 2026-01-16 | `20260116000000_schema_simplification.sql` | `gfx_players`, `wsop_players` | 중복 제거 - 각 소스별 플레이어 테이블로 통합 |

### 8.2 타입 변경 이력

| 테이블.컬럼 | 변경일 | 이전 | 이후 | 사유 |
|------------|--------|------|------|------|
| `gfx_hand_players.*_amt` | 2026-01-25 | INTEGER | BIGINT | 21억 칩 초과 데이터 손실 방지 |
| `gfx_events.bet_amount` | 2026-01-25 | INTEGER | BIGINT | 대규모 팟 지원 |
| `gfx_hands.pot_size` | 2026-01-25 | INTEGER | BIGINT | 대규모 팟 지원 |

---

## 9. 변경 이력

| 버전 | 날짜 | 변경 내용 |
|------|------|----------|
| 2.4.0 | 2026-01-20 | MAPPING_DIAGRAM.md 추가 (GFX→DB→AEP 시각화 다이어그램) |
| 2.3.0 | 2026-01-25 | 스키마 변경 이력 섹션 추가, BIGINT 마이그레이션 반영 |
| 2.2.0 | 2026-01-19 | GFX→Supabase→Cuesheet 3계층 통합 매핑 문서 추가 |
| 2.1.0 | 2026-01-19 | Cuesheet Day 1A~5 전체 분석 통합 (CUESHEET_FIELD_ANALYSIS.md v2.0) |
| 2.0.0 | 2026-01-19 | 폴더 구조 재편: 6개 도메인 폴더 생성 |
| 1.2.0 | 2026-01-19 | 대용량 파일 청킹 전략 문서 추가 (그룹 E) |
| 1.1.0 | 2026-01-19 | GFX JSON 분석 문서 추가 (그룹 D) |
| 1.0.0 | 2026-01-16 | 초기 작성: 그룹 A/B/C 정의, SSOT 정책 |

---

## 9. 문서 수정 체크리스트

### 신규 문서 추가 시

- [ ] 적절한 폴더에 배치
- [ ] 00-DOCUMENT-INDEX.md 업데이트
- [ ] 관련 마이그레이션 파일 확인/생성
- [ ] ERD 업데이트 (필요 시)

### 기존 문서 수정 시

- [ ] 종속 문서 영향 확인
- [ ] 마이그레이션 파일 업데이트 필요 여부 확인
- [ ] `python scripts/validate_docs_schema.py` 실행
