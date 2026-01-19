# 01. Automation DB Schema - Data Flow Document

전체 시스템 데이터 흐름 및 통합 아키텍처 설계 문서

**Version**: 2.0.0
**Date**: 2026-01-16

> ⚠️ **스키마 변경 안내 (2026-01-16)**
> - `manual_players` 테이블 삭제 → `gfx_players`/`wsop_players` 직접 사용
> - `chip_snapshots` 테이블 삭제 → `wsop_chip_counts`/`gfx_hand_players` 사용
> - `profile_images` → `wsop_player_id`/`gfx_player_id` 참조로 변경
**Project**: Automation DB Schema

---

## 1. 시스템 전체 개요

### 1.1 아키텍처 레이어

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    WSOP Poker Broadcast Automation System                    │
│                        전체 데이터 흐름 아키텍처                              │
└─────────────────────────────────────────────────────────────────────────────┘

═══════════════════════════════════════════════════════════════════════════════
                              INPUT LAYER (입력 계층)
═══════════════════════════════════════════════════════════════════════════════

    ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
    │   NAS       │     │   WSOP+     │     │   Web UI    │
    │   Storage   │     │   Platform  │     │   Admin     │
    └──────┬──────┘     └──────┬──────┘     └──────┬──────┘
           │                   │                   │
           │ JSON files        │ JSON/CSV          │ Forms
           │                   │ files             │
           ▼                   ▼                   ▼
    ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
    │ GFX JSON    │     │   WSOP+     │     │   Manual    │
    │ Parser      │     │  Importer   │     │   Editor    │
    └──────┬──────┘     └──────┬──────┘     └──────┬──────┘
           │                   │                   │
           ▼                   ▼                   ▼
═══════════════════════════════════════════════════════════════════════════════
                            STORAGE LAYER (저장 계층)
═══════════════════════════════════════════════════════════════════════════════

    ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
    │  GFX JSON   │     │   WSOP+     │     │   Override  │
    │    DB       │     │    DB       │     │    DB       │
    ├─────────────┤     ├─────────────┤     ├─────────────┤
    │ gfx_sessions│     │ wsop_events │     │profile_image│
    │ gfx_hands   │     │ wsop_players│     │player_override│
    │ gfx_events  │     │ wsop_chips  │     │player_link  │
    │ gfx_players │     │ wsop_standings│   │             │
    │ hand_grades │     │ import_logs │     │             │
    └──────┬──────┘     └──────┬──────┘     └──────┬──────┘
           │                   │                   │
           └───────────────────┼───────────────────┘
                               │
                               ▼
═══════════════════════════════════════════════════════════════════════════════
                         ORCHESTRATION LAYER (오케스트레이션 계층)
═══════════════════════════════════════════════════════════════════════════════

                    ┌─────────────────────────────┐
                    │        Supabase             │
                    │   Orchestration Schema      │
                    ├─────────────────────────────┤
                    │ ┌─────────────────────────┐ │
                    │ │    Unified Views        │ │
                    │ │  - unified_players      │ │
                    │ │  - unified_events       │ │
                    │ │  - unified_chip_data    │ │
                    │ └─────────────────────────┘ │
                    │ ┌─────────────────────────┐ │
                    │ │    Job Management       │ │
                    │ │  - job_queue            │ │
                    │ │  - render_queue         │ │
                    │ │  - sync_status          │ │
                    │ └─────────────────────────┘ │
                    │ ┌─────────────────────────┐ │
                    │ │    System Control       │ │
                    │ │  - system_config        │ │
                    │ │  - notifications        │ │
                    │ │  - activity_log         │ │
                    │ └─────────────────────────┘ │
                    └──────────────┬──────────────┘
                                   │
                                   ▼
═══════════════════════════════════════════════════════════════════════════════
                          DASHBOARD LAYER (대시보드 계층)
═══════════════════════════════════════════════════════════════════════════════

                    ┌─────────────────────────────┐
                    │       Cuesheet Schema       │
                    │       (방송 진행 관리)        │
                    ├─────────────────────────────┤
                    │ broadcast_sessions          │
                    │ cue_sheets                  │
                    │ cue_items                   │
                    │ cue_templates               │
                    │ gfx_triggers                │
                    └──────────────┬──────────────┘
                                   │
                                   │ Trigger
                                   ▼
═══════════════════════════════════════════════════════════════════════════════
                            OUTPUT LAYER (출력 계층)
═══════════════════════════════════════════════════════════════════════════════

                    ┌─────────────────────────────┐
                    │     AEP Analysis DB         │
                    │   (After Effects 분석)       │
                    ├─────────────────────────────┤
                    │ aep_compositions            │
                    │ aep_layers                  │
                    │ aep_field_keys              │
                    │ aep_media_sources           │
                    └──────────────┬──────────────┘
                                   │
                                   │ Render
                                   ▼
                    ┌─────────────────────────────┐
                    │      Final Output           │
                    │   (비디오/이미지 출력)        │
                    ├─────────────────────────────┤
                    │  MP4, MOV, PNG              │
                    │  Broadcast Ready            │
                    └─────────────────────────────┘
```

### 1.2 스키마별 역할

| 스키마 | 계층 | 역할 | 주요 테이블 |
|--------|------|------|-------------|
| **GFX JSON DB** | Input | PokerGFX JSON 파일 정규화 | gfx_sessions, gfx_hands |
| **WSOP+ DB** | Input | WSOP+ 데이터 임포트 | wsop_events, wsop_players |
| **Override DB** | Input | 플레이어 오버라이드/이미지 | profile_images, player_overrides |
| **Supabase Orchestration** | Orchestration | 통합 뷰, 작업 큐 | unified_players, job_queue |
| **Cuesheet DB** | Dashboard | 방송 진행 관리 | cue_sheets, cue_items |
| **AEP Analysis DB** | Output | AE 컴포지션 분석 | aep_compositions, aep_layers |

---

## 2. 데이터 흐름 상세

### 2.1 GFX JSON 데이터 흐름

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         GFX JSON Data Flow                                   │
└─────────────────────────────────────────────────────────────────────────────┘

[NAS Storage]
     │
     │ File Watcher / Scheduled Sync
     ▼
┌─────────────────┐
│ JSON File       │  PGFX_live_data_export GameID={id}.json
│ Detection       │
└────────┬────────┘
         │
         │ file_hash 체크 (중복 방지)
         ▼
┌─────────────────┐
│ JSON Parser     │
│                 │
│ - Validate      │
│ - Normalize     │
│ - Transform     │
└────────┬────────┘
         │
         │ Transaction
         ▼
┌─────────────────────────────────────────────────────────────────┐
│                         GFX JSON DB                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐      │
│  │ gfx_sessions │───▶│  gfx_hands   │───▶│  gfx_events  │      │
│  └──────────────┘    └──────┬───────┘    └──────────────┘      │
│                             │                                    │
│                             ▼                                    │
│                      ┌──────────────┐    ┌──────────────┐      │
│                      │gfx_hand_     │    │  hand_grades │      │
│                      │players       │    │  (Grading)   │      │
│                      └──────┬───────┘    └──────────────┘      │
│                             │                                    │
│                             ▼                                    │
│                      ┌──────────────┐                           │
│                      │ gfx_players  │  (Master, Deduplicated)   │
│                      └──────────────┘                           │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
         │
         │ sync_log 기록
         ▼
┌─────────────────┐
│ Supabase        │
│ sync_status     │  status: 'synced'
│ sync_history    │  records_created: N
└─────────────────┘
```

### 2.2 WSOP+ 데이터 흐름

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          WSOP+ Data Flow                                     │
└─────────────────────────────────────────────────────────────────────────────┘

[WSOP+ Platform]
     │
     │ Export JSON/CSV
     ▼
┌─────────────────┐     ┌─────────────────┐
│  Events.json    │     │ ChipCounts.csv  │
│  Players.json   │     │ Standings.csv   │
└────────┬────────┘     └────────┬────────┘
         │                       │
         └───────────┬───────────┘
                     │
                     │ file_hash 체크
                     ▼
              ┌─────────────────┐
              │ WSOP+ Importer  │
              │                 │
              │ - Parse JSON    │
              │ - Parse CSV     │
              │ - Validate      │
              │ - Upsert        │
              └────────┬────────┘
                       │
                       │ Transaction
                       ▼
┌─────────────────────────────────────────────────────────────────┐
│                          WSOP+ DB                                │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐      │
│  │ wsop_events  │───▶│wsop_event_   │◀───│ wsop_players │      │
│  │              │    │players       │    │              │      │
│  └──────────────┘    └──────────────┘    └──────────────┘      │
│         │                                       │                │
│         │                                       │                │
│         ▼                                       ▼                │
│  ┌──────────────┐                      ┌──────────────┐        │
│  │wsop_standings│                      │wsop_chip_    │        │
│  │ (snapshots)  │                      │counts        │        │
│  └──────────────┘                      └──────────────┘        │
│                                                                  │
│  ┌──────────────┐                                               │
│  │wsop_import_  │  (Import tracking)                            │
│  │logs          │                                               │
│  └──────────────┘                                               │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### 2.3 Override 데이터 흐름

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         Override Data Flow                                   │
└─────────────────────────────────────────────────────────────────────────────┘

[Admin Web UI]
     │
     │ User Input / Image Upload
     ▼
┌─────────────────┐
│ Override Editor │
│                 │
│ - Image Upload  │
│ - Link Mapping  │
│ - Override      │
└────────┬────────┘
         │
         │ Validation & Processing
         ▼
┌─────────────────────────────────────────────────────────────────┐
│                         Override DB                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐      │
│  │profile_images│    │player_       │    │player_link_  │      │
│  │              │    │overrides     │    │mapping       │      │
│  │ wsop_player  │    │              │    │              │      │
│  │ gfx_player   │    │ wsop_player  │    │ wsop_player  │      │
│  │ (FK)         │    │ gfx_player   │    │ gfx_player   │      │
│  └──────────────┘    └──────────────┘    └──────────────┘      │
│                                                                  │
│  ※ wsop_players / gfx_players를 직접 참조                       │
│  ※ manual_players 삭제됨 (2026-01-16)                           │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### 2.4 통합 데이터 흐름 (Unified View)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                      Unified Data Flow (Supabase)                            │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────┐   ┌─────────────┐   ┌─────────────┐
│  GFX JSON   │   │   WSOP+     │   │  Override   │
│     DB      │   │     DB      │   │     DB      │
└──────┬──────┘   └──────┬──────┘   └──────┬──────┘
       │                 │                 │
       │ gfx_players     │ wsop_players    │ player_overrides
       │                 │                 │ profile_images
       └─────────────────┼─────────────────┘
                         │
                         │ player_link_mapping (gfx↔wsop 교집합)
                         ▼
              ┌─────────────────────┐
              │                     │
              │   unified_players   │  VIEW
              │                     │
              │  - source           │
              │  - name             │  (gfx/wsop만 UNION)
              │  - country_code     │
              │  - profile_image    │
              │                     │
              └──────────┬──────────┘
                         │
                         │ Priority: WSOP+ > GFX
                         │ + Override Rules 적용
                         ▼
              ┌─────────────────────┐
              │                     │
              │  Final Player Data  │  API Response
              │                     │
              │  with overrides     │
              │  applied            │
              │                     │
              └─────────────────────┘
```

### 2.5 큐시트 → 렌더 데이터 흐름

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                      Cuesheet to Render Flow                                 │
└─────────────────────────────────────────────────────────────────────────────┘

[Broadcast Director]
         │
         │ Create/Manage Cuesheet
         ▼
┌─────────────────────────────────────────────────────────────────┐
│                        Cuesheet Schema                           │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌──────────────┐    ┌──────────────┐                           │
│  │broadcast_    │───▶│  cue_sheets  │                           │
│  │sessions      │    │              │                           │
│  └──────────────┘    └──────┬───────┘                           │
│                             │                                    │
│                             │ 1:N                                │
│                             ▼                                    │
│                      ┌──────────────┐    ┌──────────────┐      │
│                      │  cue_items   │◀───│cue_templates │      │
│                      │              │    │              │      │
│                      └──────┬───────┘    └──────────────┘      │
│                             │                                    │
└─────────────────────────────┼────────────────────────────────────┘
                              │
                              │ Trigger (Manual/Auto)
                              ▼
              ┌───────────────────────────┐
              │     GFX Trigger Event     │
              │                           │
              │  cue_type: 'chip_count'   │
              │  gfx_data: {players: [...]}│
              │  aep_comp_name: 'Leaderboard'│
              └─────────────┬─────────────┘
                            │
                            │ Job Creation
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Supabase Orchestration                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌──────────────┐    ┌──────────────┐                           │
│  │  job_queue   │───▶│ render_queue │                           │
│  │              │    │              │                           │
│  │ type: render │    │ aep_project  │                           │
│  │ priority: 1  │    │ aep_comp     │                           │
│  │ payload: {}  │    │ gfx_data     │                           │
│  └──────────────┘    └──────┬───────┘                           │
│                             │                                    │
└─────────────────────────────┼────────────────────────────────────┘
                              │
                              │ Render Worker
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                     AEP Analysis DB                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌──────────────┐    ┌──────────────┐                           │
│  │aep_          │───▶│ aep_layers   │                           │
│  │compositions  │    │              │                           │
│  │              │    │ - Text       │  Data Binding             │
│  │              │    │ - Images     │  (gfx_data → layers)      │
│  └──────────────┘    └──────────────┘                           │
│                                                                  │
│  ┌──────────────┐    ┌──────────────┐                           │
│  │aep_field_keys│    │aep_media_    │                           │
│  │              │    │sources       │  Flag images, etc.        │
│  └──────────────┘    └──────────────┘                           │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │ After Effects Render
                              ▼
              ┌───────────────────────────┐
              │      Output File          │
              │                           │
              │  /output/chip_count.mp4   │
              │  1920x1080, 30fps         │
              └───────────────────────────┘
```

---

## 3. 동기화 전략

### 3.1 동기화 주기

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         Sync Schedule Matrix                                 │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────┬─────────────┬─────────────┬─────────────┬─────────────┐
│   Source    │   Entity    │  Interval   │   Method    │  Priority   │
├─────────────┼─────────────┼─────────────┼─────────────┼─────────────┤
│ GFX JSON    │ sessions    │ 60 min      │ File Watch  │ High        │
│ GFX JSON    │ hands       │ 60 min      │ Incremental │ High        │
│ GFX JSON    │ players     │ 60 min      │ Upsert      │ Medium      │
├─────────────┼─────────────┼─────────────┼─────────────┼─────────────┤
│ WSOP+       │ events      │ 30 min      │ Full Sync   │ High        │
│ WSOP+       │ players     │ 30 min      │ Upsert      │ High        │
│ WSOP+       │ chip_counts │ 15 min      │ Incremental │ Critical    │
│ WSOP+       │ standings   │ 15 min      │ Snapshot    │ Critical    │
├─────────────┼─────────────┼─────────────┼─────────────┼─────────────┤
│ Manual      │ players     │ Real-time   │ Event       │ High        │
│ Manual      │ overrides   │ Real-time   │ Event       │ High        │
└─────────────┴─────────────┴─────────────┴─────────────┴─────────────┘
```

### 3.2 동기화 상태 흐름

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                       Sync State Machine                                     │
└─────────────────────────────────────────────────────────────────────────────┘

                         ┌─────────────┐
                         │   pending   │  Initial state
                         └──────┬──────┘
                                │
                                │ Scheduled time reached
                                ▼
                         ┌─────────────┐
            ┌────────────│ in_progress │────────────┐
            │            └─────────────┘            │
            │                   │                   │
            │ Error             │ Success           │ Timeout
            ▼                   ▼                   ▼
     ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
     │   failed    │     │   synced    │     │   failed    │
     └──────┬──────┘     └──────┬──────┘     └──────┬──────┘
            │                   │                   │
            │ Retry             │ Time passes       │ Retry
            │ (max 3)           │                   │ (max 3)
            ▼                   ▼                   ▼
     ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
     │   pending   │     │   outdated  │     │   pending   │
     └─────────────┘     └──────┬──────┘     └─────────────┘
                                │
                                │ Next sync interval
                                ▼
                         ┌─────────────┐
                         │   pending   │
                         └─────────────┘
```

---

## 4. 플레이어 데이터 병합 전략

### 4.1 우선순위 규칙

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    Player Data Merge Priority                                │
└─────────────────────────────────────────────────────────────────────────────┘

Priority Order: Manual > WSOP+ > GFX

┌────────────────┬──────────┬──────────┬──────────┬────────────────────────┐
│     Field      │  Manual  │  WSOP+   │   GFX    │        Notes           │
├────────────────┼──────────┼──────────┼──────────┼────────────────────────┤
│ name           │    1     │    2     │    3     │ Display name           │
│ name_korean    │    1     │    -     │    -     │ Manual only            │
│ country_code   │    1     │    2     │    -     │ GFX has no country     │
│ profile_image  │    1     │    2     │    -     │ Manual preferred       │
│ bio            │    1     │    -     │    -     │ Manual only            │
│ notable_wins   │    1     │    -     │    -     │ Manual curated         │
│ chip_count     │    -     │    1     │    2     │ WSOP+ is realtime      │
│ hand_data      │    -     │    -     │    1     │ GFX only               │
└────────────────┴──────────┴──────────┴──────────┴────────────────────────┘
```

### 4.2 오버라이드 적용 흐름

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                     Override Application Flow                                │
└─────────────────────────────────────────────────────────────────────────────┘

[API Request for Player Data]
            │
            ▼
┌───────────────────────────┐
│ 1. Get Base Data          │
│                           │
│ SELECT from source table  │
│ (wsop_players, etc.)      │
└─────────────┬─────────────┘
              │
              ▼
┌───────────────────────────┐
│ 2. Check for Overrides    │
│                           │
│ SELECT from player_       │
│ overrides WHERE active    │
│ AND valid_from <= NOW     │
│ AND valid_until > NOW     │
└─────────────┬─────────────┘
              │
              │ Has override?
              │
     ┌────────┴────────┐
     │ Yes             │ No
     ▼                 ▼
┌─────────────┐  ┌─────────────┐
│ Apply       │  │ Use Base    │
│ Override    │  │ Value       │
│ Value       │  │             │
└──────┬──────┘  └──────┬──────┘
       │                │
       └────────┬───────┘
                │
                ▼
┌───────────────────────────┐
│ 3. Return Merged Data     │
│                           │
│ {                         │
│   "name": "홍길동",        │  ← Override
│   "country": "KR",        │  ← Base
│   "chips": 1500000        │  ← Base
│ }                         │
└───────────────────────────┘
```

---

## 5. 렌더링 파이프라인

### 5.1 렌더 큐 처리 흐름

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        Render Queue Pipeline                                 │
└─────────────────────────────────────────────────────────────────────────────┘

[Trigger Event]
      │
      │ Create Job
      ▼
┌─────────────────┐
│   job_queue     │  status: 'pending'
│                 │  type: 'render_gfx'
│   payload: {    │
│     cue_id,     │
│     gfx_data    │
│   }             │
└────────┬────────┘
         │
         │ Worker claims job
         ▼
┌─────────────────┐
│  render_queue   │  status: 'pending'
│                 │
│  aep_project    │
│  aep_comp_name  │
│  gfx_data       │
│  output_format  │
└────────┬────────┘
         │
         │ Pre-render checks
         │ - Check cache (data_hash)
         │ - Validate AEP project
         ▼
     ┌───┴───┐
     │ Cache │
     │ Hit?  │
     └───┬───┘
    Yes  │  No
    ┌────┴────┐
    │         │
    ▼         ▼
┌────────┐  ┌────────────────────────────────────────┐
│ Return │  │           Render Process               │
│ Cached │  ├────────────────────────────────────────┤
│ Output │  │ 1. Open AEP Project                    │
└────────┘  │ 2. Find Composition                    │
            │ 3. Bind GFX Data to Layers             │
            │    - Text layers: name, chips, etc.    │
            │    - Image layers: flag, profile       │
            │ 4. Set Output Module                   │
            │ 5. Add to Render Queue                 │
            │ 6. Execute aerender                    │
            │ 7. Monitor Progress                    │
            └─────────────┬──────────────────────────┘
                          │
                          │ Render complete
                          ▼
            ┌─────────────────────────────┐
            │ Update render_queue         │
            │                             │
            │ status: 'completed'         │
            │ output_path: '/output/...'  │
            │ render_duration_ms: 5000    │
            └─────────────────────────────┘
```

### 5.2 GFX 데이터 바인딩

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         GFX Data Binding                                     │
└─────────────────────────────────────────────────────────────────────────────┘

Input GFX Data:
┌─────────────────────────────────────────────┐
│ {                                           │
│   "players": [                              │
│     {                                       │
│       "rank": 1,                            │
│       "name": "홍길동",                      │
│       "country_code": "KR",                 │
│       "chips": 1500000                      │
│     },                                      │
│     ...                                     │
│   ]                                         │
│ }                                           │
└────────────────────┬────────────────────────┘
                     │
                     │ Mapping
                     ▼
AEP Composition Layers:
┌─────────────────────────────────────────────┐
│ Layer: "Name 1"     ─────▶  "홍길동"        │
│ Layer: "Chips 1"    ─────▶  "1,500,000"     │
│ Layer: "Rank 1"     ─────▶  "1"             │
│ Layer: "Flag 1"     ─────▶  [KR.png]        │
│                                             │
│ Layer: "Name 2"     ─────▶  "John Doe"      │
│ Layer: "Chips 2"    ─────▶  "1,200,000"     │
│ ...                                         │
└─────────────────────────────────────────────┘

Binding Rules (from aep_field_keys):
┌─────────────────┬─────────────────┬──────────────┐
│   field_key     │   pattern_type  │  slot_count  │
├─────────────────┼─────────────────┼──────────────┤
│ name            │ slot            │ 30           │
│ chips           │ slot            │ 19           │
│ rank            │ slot            │ 25           │
│ flag            │ slot (image)    │ 30           │
└─────────────────┴─────────────────┴──────────────┘
```

---

## 6. 실시간 업데이트 (Supabase Realtime)

### 6.1 실시간 구독 채널

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                      Supabase Realtime Channels                              │
└─────────────────────────────────────────────────────────────────────────────┘

Channel: broadcast-{session_id}
┌─────────────────────────────────────────────────────────────────┐
│ Events:                                                          │
│   - cue_item:update     → 큐 아이템 상태 변경                     │
│   - cue_sheet:update    → 큐시트 상태 변경                        │
│   - session:update      → 세션 상태 변경                          │
└─────────────────────────────────────────────────────────────────┘

Channel: render-progress
┌─────────────────────────────────────────────────────────────────┐
│ Events:                                                          │
│   - render:started      → 렌더링 시작                            │
│   - render:progress     → 진행률 업데이트 (frame_number)         │
│   - render:completed    → 렌더링 완료                            │
│   - render:failed       → 렌더링 실패                            │
└─────────────────────────────────────────────────────────────────┘

Channel: sync-status
┌─────────────────────────────────────────────────────────────────┐
│ Events:                                                          │
│   - sync:started        → 동기화 시작                            │
│   - sync:completed      → 동기화 완료                            │
│   - sync:failed         → 동기화 실패                            │
└─────────────────────────────────────────────────────────────────┘

Channel: notifications
┌─────────────────────────────────────────────────────────────────┐
│ Events:                                                          │
│   - notification:new    → 새 알림                                │
│   - notification:read   → 알림 읽음 처리                         │
└─────────────────────────────────────────────────────────────────┘
```

### 6.2 이벤트 트리거 설정

```sql
-- ============================================================================
-- Supabase Realtime Triggers
-- ============================================================================

-- cue_items 변경 시 broadcast 알림
CREATE OR REPLACE FUNCTION notify_cue_item_change()
RETURNS TRIGGER AS $$
DECLARE
    v_session_id UUID;
BEGIN
    -- 세션 ID 조회
    SELECT cs.session_id INTO v_session_id
    FROM cue_sheets cs
    WHERE cs.id = NEW.sheet_id;

    -- Realtime 채널로 알림
    PERFORM pg_notify(
        'broadcast-' || v_session_id::TEXT,
        json_build_object(
            'event', 'cue_item:update',
            'payload', json_build_object(
                'id', NEW.id,
                'cue_number', NEW.cue_number,
                'status', NEW.status,
                'sheet_id', NEW.sheet_id
            )
        )::TEXT
    );

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER cue_item_realtime_trigger
    AFTER INSERT OR UPDATE ON cue_items
    FOR EACH ROW
    EXECUTE FUNCTION notify_cue_item_change();
```

---

## 7. 에러 처리 및 복구

### 7.1 에러 유형별 처리

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        Error Handling Strategy                               │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────────┬─────────────────┬─────────────────┬───────────────────────┐
│   Error Type    │    Severity     │     Action      │       Recovery        │
├─────────────────┼─────────────────┼─────────────────┼───────────────────────┤
│ File not found  │ Warning         │ Skip + Log      │ Manual intervention   │
│ Parse error     │ Error           │ Skip record     │ Fix file + re-sync    │
│ DB constraint   │ Error           │ Rollback txn    │ Check data integrity  │
│ Network timeout │ Transient       │ Retry (3x)      │ Auto-retry            │
│ Render failure  │ Error           │ Log + Notify    │ Re-queue with flags   │
│ Auth failure    │ Critical        │ Alert + Stop    │ Check credentials     │
└─────────────────┴─────────────────┴─────────────────┴───────────────────────┘
```

### 7.2 재시도 로직

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          Retry Logic Flow                                    │
└─────────────────────────────────────────────────────────────────────────────┘

[Job Execution]
      │
      │ Error occurs
      ▼
┌─────────────────┐
│ Check retry     │
│ count < max     │
└────────┬────────┘
         │
    Yes  │  No
    ┌────┴────┐
    │         │
    ▼         ▼
┌────────┐  ┌────────────────────┐
│ Retry  │  │ Mark as failed     │
│ with   │  │                    │
│ delay  │  │ - Log error        │
└───┬────┘  │ - Send notification│
    │       │ - Create alert     │
    │       └────────────────────┘
    │
    │ Exponential backoff
    │ delay = base * 2^retry_count
    │
    │ retry_count: 0 → delay: 60s
    │ retry_count: 1 → delay: 120s
    │ retry_count: 2 → delay: 240s
    │
    ▼
┌─────────────────┐
│ Update job      │
│                 │
│ retry_count++   │
│ status: pending │
│ scheduled_at += │
│   delay         │
└─────────────────┘
```

---

## 8. 모니터링 및 알림

### 8.1 시스템 헬스 체크

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        System Health Dashboard                               │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│ SYNC STATUS                                                                  │
├─────────────┬───────────┬───────────┬───────────┬──────────────────────────┤
│   Source    │  Status   │ Last Sync │ Next Sync │         Health           │
├─────────────┼───────────┼───────────┼───────────┼──────────────────────────┤
│ GFX JSON    │  ● synced │ 10m ago   │ in 50m    │ ████████████░░ 85% OK    │
│ WSOP+       │  ● synced │ 5m ago    │ in 25m    │ ████████████████ 100% OK │
│ Manual      │  ● active │ realtime  │ -         │ ████████████████ 100% OK │
└─────────────┴───────────┴───────────┴───────────┴──────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│ JOB QUEUE                                                                    │
├─────────────┬───────────┬───────────┬───────────┬──────────────────────────┤
│  Job Type   │  Pending  │  Running  │  Failed   │      Avg Duration        │
├─────────────┼───────────┼───────────┼───────────┼──────────────────────────┤
│ sync_gfx    │     2     │     1     │     0     │         45s              │
│ sync_wsop   │     0     │     0     │     0     │         30s              │
│ render_gfx  │     5     │     2     │     1     │         8s               │
└─────────────┴───────────┴───────────┴───────────┴──────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│ RENDER QUEUE                                                                 │
├─────────────┬───────────┬───────────┬───────────┬──────────────────────────┤
│ Render Type │  Pending  │ Rendering │ Completed │      Queue Time          │
├─────────────┼───────────┼───────────┼───────────┼──────────────────────────┤
│ chip_count  │     3     │     1     │    15     │         2s               │
│ leaderboard │     2     │     1     │    10     │         3s               │
│ player_info │     0     │     0     │     5     │         1s               │
└─────────────┴───────────┴───────────┴───────────┴──────────────────────────┘
```

### 8.2 알림 규칙

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        Notification Rules                                    │
└─────────────────────────────────────────────────────────────────────────────┘

┌──────────────────────────┬───────────┬───────────────────────────────────────┐
│        Condition         │   Level   │              Action                   │
├──────────────────────────┼───────────┼───────────────────────────────────────┤
│ Sync failed 3+ times     │ Critical  │ Email + Slack + Dashboard alert       │
│ Render queue > 10        │ Warning   │ Dashboard alert                       │
│ Job failed               │ Error     │ Log + Dashboard notification          │
│ Sync completed           │ Info      │ Dashboard update only                 │
│ New player added         │ Info      │ Activity log only                     │
│ Broadcast session start  │ Info      │ Slack notification                    │
└──────────────────────────┴───────────┴───────────────────────────────────────┘
```

---

## 9. API 엔드포인트 요약

### 9.1 통합 API

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           Unified API Endpoints                              │
└─────────────────────────────────────────────────────────────────────────────┘

Players API:
  GET    /api/v1/players                 → List all unified players
  GET    /api/v1/players/:id             → Get player by ID
  GET    /api/v1/players/search?q=name   → Search players
  POST   /api/v1/players                 → Create manual player
  PATCH  /api/v1/players/:id             → Update player
  POST   /api/v1/players/:id/override    → Add override

Events API:
  GET    /api/v1/events                  → List all events
  GET    /api/v1/events/:id              → Get event details
  GET    /api/v1/events/:id/players      → Get event players
  GET    /api/v1/events/:id/standings    → Get current standings

Cuesheet API:
  GET    /api/v1/sessions                → List broadcast sessions
  GET    /api/v1/sessions/:id/sheets     → Get session cuesheets
  GET    /api/v1/sheets/:id/items        → Get cue items
  POST   /api/v1/items/:id/trigger       → Trigger cue item
  PATCH  /api/v1/items/:id/status        → Update item status

Render API:
  POST   /api/v1/render                  → Submit render job
  GET    /api/v1/render/:id/status       → Get render status
  GET    /api/v1/render/:id/output       → Get render output

Sync API:
  GET    /api/v1/sync/status             → Get all sync status
  POST   /api/v1/sync/:source/trigger    → Trigger manual sync
  GET    /api/v1/sync/:source/history    → Get sync history
```

---

## 10. 배포 및 확장

### 10.1 배포 아키텍처

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        Deployment Architecture                               │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│                             Cloud (Supabase)                                 │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌─────────────────────┐  ┌─────────────────────┐                          │
│  │     PostgreSQL      │  │   Supabase Auth     │                          │
│  │     Database        │  │   & API Gateway     │                          │
│  └─────────────────────┘  └─────────────────────┘                          │
│                                                                             │
│  ┌─────────────────────┐  ┌─────────────────────┐                          │
│  │  Supabase Storage   │  │  Supabase Realtime  │                          │
│  │  (Images, Outputs)  │  │  (WebSocket)        │                          │
│  └─────────────────────┘  └─────────────────────┘                          │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    │ HTTPS/WSS
                                    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                            On-Premise                                        │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌─────────────────────┐  ┌─────────────────────┐  ┌─────────────────────┐ │
│  │   Sync Worker       │  │   Render Worker     │  │   Admin Dashboard   │ │
│  │   (Python)          │  │   (AE + Python)     │  │   (React)           │ │
│  └──────────┬──────────┘  └──────────┬──────────┘  └─────────────────────┘ │
│             │                        │                                      │
│             │                        │                                      │
│             ▼                        ▼                                      │
│  ┌─────────────────────┐  ┌─────────────────────┐                          │
│  │   NAS Storage       │  │   After Effects     │                          │
│  │   (GFX JSON)        │  │   (Render Engine)   │                          │
│  └─────────────────────┘  └─────────────────────┘                          │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 10.2 확장 고려사항

| 영역 | 현재 | 확장 방안 |
|------|------|----------|
| **Database** | Supabase Free/Pro | Supabase Enterprise, Read Replicas |
| **Render Workers** | 1대 | 다중 워커, 로드 밸런싱 |
| **Storage** | Local NAS | Cloud Storage (S3, GCS) |
| **Real-time** | Supabase Realtime | Redis Pub/Sub 추가 |
| **Caching** | PostgreSQL | Redis Cache Layer |

---

## 11. 문서 참조

### 11.1 관련 스키마 문서

| 문서 | 경로 | 설명 |
|------|------|------|
| GFX JSON DB | `docs/02-GFX-JSON-DB.md` | PokerGFX JSON 스키마 |
| WSOP+ DB | `docs/03-WSOP+-DB.md` | WSOP+ 데이터 스키마 |
| Manual DB | `docs/04-Manual-DB.md` | 수동 플레이어 스키마 |
| Cuesheet DB | `docs/05-Cuesheet-DB.md` | 큐시트 스키마 |
| Supabase Orchestration | `docs/07-Supabase-Orchestration.md` | 통합 오케스트레이션 |
| AEP Analysis DB | `docs/06-AEP-Analysis-DB.md` | After Effects 분석 |

### 11.2 구현 참조

| 모듈 | 경로 | 설명 |
|------|------|------|
| GFX Parser | `src/primary/pokergfx_file_parser.py` | JSON 파싱 |
| WSOP Importer | `src/importers/wsop_json_importer.py` | WSOP+ 임포트 |
| Sync Worker | `src/workers/sync_worker.py` | 동기화 워커 |
| Render Worker | `src/workers/render_worker.py` | 렌더링 워커 |
| Unified API | `src/api/unified_api.py` | 통합 API |

---

## 12. 문서 그룹 및 인덱스

> **그룹 B**: 데이터 흐름 및 오케스트레이션 (Master: 01-DATA_FLOW)

### 12.1 문서 계층

```
01-DATA_FLOW.md (본 문서 - Master)
└── 07-Supabase-Orchestration.md (오케스트레이션 DDL 상세)
```

### 12.2 관련 문서

| 문서 | 역할 | 관계 |
|------|------|------|
| **00-DOCUMENT-INDEX.md** | 전체 문서 인덱스 | 그룹/SSOT 정의 |
| **07-Supabase-Orchestration.md** | 오케스트레이션 스키마 DDL | 본 문서 종속 |
| 02-GFX-JSON-DB.md | GFX JSON 스키마 | 데이터 소스 |
| 03-WSOP+-DB.md | WSOP+ 스키마 | 데이터 소스 |
| 04-Manual-DB.md | Manual Override 스키마 | 데이터 소스 |
| 05-Cuesheet-DB.md | 큐시트 스키마 | Dashboard 계층 |
| 06-AEP-Analysis-DB.md | AEP 분석 스키마 | Output 계층 |

> **SSOT 정책**: 마이그레이션 SQL (`supabase/migrations/*.sql`)이 진실의 소스. 본 문서와 마이그레이션이 다르면 마이그레이션이 정답.
