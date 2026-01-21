# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 프로젝트 개요

**WSOP Poker Broadcast Automation System - Database Schema**

포커 방송 자동화를 위한 통합 데이터베이스 스키마 프로젝트. GFX JSON (실시간 포커 테이블 데이터), WSOP+ (토너먼트 데이터), Manual Override (수동 편집)를 Supabase에 통합하고, 26개 After Effects 컴포지션에 자동 매핑.

---

## 빌드/테스트 명령어

### Supabase 로컬 개발

```powershell
# Supabase 시작/중지
supabase start
supabase stop

# 스키마 덤프 (실제 DB 구조 확인 - 코드 작성 전 필수)
supabase db dump --schema public > schema_dump.sql

# 마이그레이션 상태 확인
supabase db diff

# 로컬 → 원격 푸시
supabase db push

# DB 리셋 (주의: 데이터 삭제)
supabase db reset
```

### Python 스크립트

```powershell
# GFX 스키마 분석
python C:\claude\automation_schema\analyze_schema.py

# GFX 스키마 검증
python C:\claude\automation_schema\scripts\validate_gfx_schema.py

# 문서-스키마 동기화 검증
python C:\claude\automation_schema\scripts\validate_docs_schema.py
```

---

## 아키텍처

### 데이터 흐름 (3계층)

```
INPUT LAYER              STORAGE LAYER              ORCHESTRATION LAYER
├─ NAS (JSON files)      ├─ GFX JSON DB             ├─ Unified Views
├─ WSOP+ (CSV/JSON)      ├─ WSOP+ DB                ├─ Job Queue
├─ Web UI                ├─ Manual Override DB      ├─ Render Queue
```

### 데이터베이스 스키마 구조

| 스키마 | 역할 | 핵심 테이블 |
|--------|------|-------------|
| **GFX JSON** | 실시간 포커 데이터 | `gfx_sessions`, `gfx_hands`, `gfx_players`, `gfx_events` |
| **WSOP+** | 토너먼트 메타데이터 | `wsop_events`, `wsop_players`, `wsop_chip_counts` |
| **Manual** | 수동 편집/보완 | `player_overrides`, `profile_images`, `player_link_mapping` |
| **Cuesheet** | 방송 진행 스크립트 | `cue_sheets`, `cue_items`, `broadcast_sessions` |
| **Orchestration** | 통합 관리 | `job_queue`, `render_queue`, `sync_status` |

### SSOT (Single Source of Truth) 전략

```
마이그레이션 SQL (SSOT)  →  문서 (설계/참조)  →  Python Models  →  Supabase DB
```

> **핵심 원칙**: 마이그레이션 SQL (`supabase/migrations/*.sql`)이 **진실의 소스(SSOT)**입니다.
> 문서와 마이그레이션이 다르면 **마이그레이션이 정답**입니다.

**주요 설계 문서** (참조용):
- `docs/02-GFX-JSON-DB.md` - GFX 스키마 설계
- `docs/07-Supabase-Orchestration.md` - 오케스트레이션 스키마 설계
- `docs/08-GFX-AEP-Mapping.md` - AEP 매핑 명세

---

## 핵심 규칙

### Supabase 작업 전 필수 확인

```powershell
# 코드 작성 전 반드시 실제 DB 스키마 확인
supabase db dump --schema public
supabase inspect db table-sizes
supabase inspect db policies
```

- TypeScript 타입이나 마이그레이션 파일만 보고 가정 금지
- 실제 DB 상태 확인 후 코드 작성

### 마이그레이션 멱등성

모든 마이그레이션은 반복 실행 가능해야 함:

```sql
CREATE TABLE IF NOT EXISTS table_name (...);
DROP TABLE IF EXISTS table_name CASCADE;
```

### 데이터 소스 우선순위

1. **Primary**: GFX JSON DB (실시간 데이터)
2. **Secondary**: WSOP+ DB (토너먼트 전체 데이터)
3. **Override**: Manual DB (수정/보완)

---

## 주요 파일

| 파일 | 설명 |
|------|------|
| `supabase/migrations/` | **27개** 마이그레이션 파일 (순차 적용, SSOT) |
| `src/gfx_normalizer.py` | GFX JSON → 정규화 구조 변환 |
| `scripts/validate_*.py` | 스키마 검증 도구 |
| `docs/01-DATA_FLOW.md` | 전체 데이터 흐름 아키텍처 |

---

## 로컬 개발 포트

| 서비스 | 포트 |
|--------|------|
| API | 54321 |
| DB (Postgres) | 54322 |
| Studio | 54323 |
| Inbucket (Email) | 54324 |
| Analytics | 54327 |
