# 10. Internal Reference - ENUM, 트리거, 함수 목록

**Version**: 1.1.0
**Last Updated**: 2026-01-19

이 문서는 마이그레이션에 정의된 모든 ENUM 타입, 트리거, 함수를 정리한 내부 참조 문서입니다.

> ⚠️ **SSOT 주의**: 이 문서는 참조용이며, 실제 정의는 **마이그레이션 SQL 파일**(`supabase/migrations/*.sql`)이 SSOT입니다.
> 현재 마이그레이션 파일: **27개** (20260113 ~ 20260122)

---

## 1. ENUM 타입

### 1.1 GFX 스키마 (01_gfx_schema.sql)

| ENUM | 값 | 설명 |
|------|---|------|
| `table_type` | `cash`, `tournament`, `sit_n_go` | 테이블 유형 |
| `game_variant` | `holdem`, `omaha`, `omaha_hilo`, `stud`, `stud_hilo`, `razz`, `draw`, `mixed`, `other` | 게임 변형 |
| `game_class` | `nlhe`, `plo`, `plo8`, `limit_holdem`, `mixed_game` | 게임 클래스 |
| `bet_structure` | `no_limit`, `pot_limit`, `fixed_limit`, `spread_limit` | 베팅 구조 |
| `event_type` | `new_hand`, `action`, `card_dealt`, `showdown`, `pot_awarded`, `player_eliminated`, `blinds_posted`, `ante_posted`, `time_bank`, `chat`, `dealer_button`, `break`, `level_change`, `other` | 이벤트 타입 |
| `sync_status` | `synced`, `pending`, `conflict`, `error` | 동기화 상태 |
| `ante_type` | `none`, `standard`, `bb_ante` | 안테 타입 |

### 1.2 WSOP 스키마 (02_wsop_schema.sql)

| ENUM | 값 | 설명 |
|------|---|------|
| `wsop_event_type` | `freezeout`, `reentry`, `rebuy`, `shootout`, `bounty`, `turbo`, `super_turbo`, `deep_stack`, `six_max`, `heads_up`, `tag_team`, `ladies`, `seniors`, `colossus`, `other` | WSOP 이벤트 유형 |
| `wsop_event_status` | `announced`, `registering`, `running`, `paused`, `on_break`, `final_table`, `completed`, `cancelled` | 이벤트 진행 상태 |
| `wsop_player_status` | `active`, `eliminated`, `winner`, `final_table`, `itm` | 플레이어 상태 |
| `wsop_import_type` | `manual`, `csv`, `api`, `scrape` | 데이터 임포트 유형 |
| `wsop_import_status` | `pending`, `processing`, `completed`, `failed`, `partial` | 임포트 상태 |
| `wsop_chip_source` | `official`, `broadcast`, `estimated`, `manual` | 칩 카운트 소스 |

### 1.3 Manual Override 스키마 (03_manual_schema.sql)

| ENUM | 값 | 설명 |
|------|---|------|
| `manual_image_type` | `profile`, `full`, `action`, `celebration`, `casual`, `other` | 이미지 유형 |
| `manual_storage_type` | `supabase`, `nas`, `external` | 스토리지 유형 |
| `manual_match_method` | `exact`, `fuzzy`, `manual`, `verified` | 매칭 방법 |
| `manual_audit_action` | `create`, `update`, `delete`, `link`, `unlink`, `verify` | 감사 액션 |
| `manual_override_field` | `display_name`, `country`, `city`, `profile_image`, `twitter`, `instagram`, `hendon_id`, `wsop_id`, `gpi_id` | 오버라이드 가능 필드 |

### 1.4 Cuesheet 스키마 (04_cuesheet_schema.sql)

| ENUM | 값 | 설명 |
|------|---|------|
| `cue_broadcast_status` | `scheduled`, `pre_show`, `live`, `on_break`, `delayed`, `completed`, `cancelled` | 방송 상태 |
| `cue_sheet_type` | `pre_show`, `main`, `break`, `segment`, `finale`, `backup` | 큐시트 유형 |
| `cue_sheet_status` | `draft`, `ready`, `active`, `completed`, `archived` | 큐시트 상태 |
| `cue_content_type` | `gfx`, `video`, `audio`, `lower_third`, `full_screen`, `bug`, `animation`, `other` | 콘텐츠 유형 |
| `cue_item_type` | `chip_count`, `player_intro`, `hand_replay`, `elimination`, `payout`, `break_screen`, `standings`, `promo`, `ad_break`, `custom` | 큐 아이템 유형 |
| `cue_hand_rank` | `high_card`, `pair`, `two_pair`, `three_kind`, `straight`, `flush`, `full_house`, `four_kind`, `straight_flush`, `royal_flush` | 핸드 랭크 |
| `cue_item_status` | `pending`, `standby`, `on_air`, `completed`, `skipped`, `error` | 아이템 상태 |
| `cue_trigger_type` | `manual`, `scheduled`, `event`, `api` | 트리거 유형 |
| `cue_render_status` | `pending`, `rendering`, `completed`, `failed` | 렌더 상태 |
| `cue_template_type` | `chip_count`, `player_intro`, `elimination`, `payout`, `hand_replay`, `bug`, `lower_third`, `full_screen` | 템플릿 유형 |

### 1.5 Orchestration 스키마 (05_orch_schema.sql)

| ENUM | 값 | 설명 |
|------|---|------|
| `orch_data_source` | `gfx_json`, `wsop_plus`, `manual`, `external`, `system` | 데이터 소스 |
| `orch_job_type` | `sync`, `render`, `export`, `import`, `transform`, `validate`, `notify`, `cleanup`, `backup`, `restore`, `report`, `custom` | 작업 유형 |
| `orch_job_status` | `pending`, `queued`, `processing`, `completed`, `failed`, `cancelled`, `timeout`, `retry` | 작업 상태 |
| `orch_render_type` | `chip_count`, `player_intro`, `elimination`, `payout`, `hand_replay`, `standings`, `custom` | 렌더 유형 |
| `orch_render_status` | `pending`, `queued`, `rendering`, `encoding`, `completed`, `failed`, `cancelled` | 렌더 상태 |
| `orch_sync_status` | `idle`, `syncing`, `completed`, `failed`, `partial` | 동기화 상태 |
| `orch_sync_operation` | `create`, `update`, `delete`, `upsert` | 동기화 작업 |
| `orch_notification_type` | `sync_failure`, `render_complete`, `job_error`, `system`, `alert` | 알림 유형 |
| `orch_notification_level` | `info`, `warning`, `error`, `critical` | 알림 레벨 |
| `orch_actor_type` | `system`, `user`, `api`, `scheduler` | 액터 유형 |

### 1.6 AEP 매핑 스키마 (gfx_aep_render_mapping.sql)

| ENUM | 값 | 설명 |
|------|---|------|
| `aep_composition_category` | `chip_display`, `player_info`, `table_layout`, `hand_replay`, `elimination`, `payout`, `standings`, `utility` | AEP 컴포지션 카테고리 |
| `aep_transform_type` | `format_chips`, `format_bbs`, `format_currency`, `format_percent`, `format_date`, `format_time`, `flag_path`, `identity` | 데이터 변환 유형 |

---

## 2. 함수 목록

### 2.1 updated_at 자동 갱신 함수

| 함수명 | 스키마 | 설명 |
|--------|--------|------|
| `update_updated_at_column()` | GFX, Orch | 범용 updated_at 갱신 |
| `update_wsop_updated_at_column()` | WSOP | WSOP 테이블 updated_at 갱신 |
| `update_manual_updated_at_column()` | Manual | Manual 테이블 updated_at 갱신 |
| `update_cue_updated_at_column()` | Cuesheet | Cuesheet 테이블 updated_at 갱신 |

### 2.2 포맷 함수 (AEP 렌더링용)

| 함수명 | 입력 | 출력 | 설명 |
|--------|------|------|------|
| `format_chips(amount)` | BIGINT | TEXT | 칩 포맷 (예: 1,234,567) |
| `format_chips_safe(amount)` | BIGINT | TEXT | NULL-safe 칩 포맷 |
| `format_chips_short(amount)` | BIGINT | TEXT | 축약 칩 포맷 (예: 1.2M) |
| `format_chips_comma(amount)` | BIGINT | TEXT | 콤마 구분 칩 포맷 |
| `format_bbs(chips, bb)` | BIGINT, BIGINT | TEXT | BB 단위 포맷 |
| `format_bbs_safe(chips, bb)` | BIGINT, BIGINT | TEXT | NULL-safe BB 포맷 |
| `format_currency(amount)` | BIGINT | TEXT | 통화 포맷 (예: $1,234) |
| `format_currency_cents(amount)` | BIGINT | TEXT | 센트 단위 통화 포맷 |
| `format_currency_safe(amount)` | BIGINT | TEXT | NULL-safe 통화 포맷 |
| `format_currency_from_int(amount)` | BIGINT | TEXT | 정수→통화 포맷 |
| `format_date_short(d)` | DATE | TEXT | 날짜 단축 포맷 |
| `format_date(d)` | DATE | TEXT | 날짜 포맷 |
| `format_time_12h(t)` | TIME | TEXT | 12시간제 시간 포맷 |
| `format_time(t)` | TIME | TEXT | 시간 포맷 |
| `format_blinds(sb, bb, ante)` | BIGINT, BIGINT, BIGINT | TEXT | 블라인드 포맷 |
| `format_percent(value)` | NUMERIC | TEXT | 퍼센트 포맷 |
| `format_number(num)` | BIGINT | TEXT | 숫자 포맷 |

### 2.3 플레이어 관련 함수

| 함수명 | 설명 |
|--------|------|
| `normalize_player_name(p_name)` | 플레이어 이름 정규화 (소문자, 트림) |
| `normalize_manual_player_name(p_name)` | Manual 플레이어 이름 정규화 |
| `generate_player_hash(p_name, p_long_name)` | 플레이어 해시 생성 |
| `generate_player_code()` | 플레이어 코드 자동 생성 |
| `set_player_code()` | 플레이어 코드 설정 트리거 함수 |
| `set_normalized_name()` | 정규화 이름 설정 트리거 함수 |
| `set_manual_normalized_name()` | Manual 정규화 이름 설정 |
| `get_player_field_with_override(...)` | 오버라이드 적용된 플레이어 필드 조회 |
| `get_player_name_data(...)` | 플레이어 이름 렌더 데이터 조회 |
| `get_flag_path(country_code)` | 국기 이미지 경로 조회 |

### 2.4 렌더 데이터 함수

| 함수명 | 설명 |
|--------|------|
| `get_chip_display_data(...)` | 칩 표시 렌더 데이터 조회 |
| `get_chips_n_hands_ago(...)` | N핸드 전 칩 카운트 조회 |
| `get_chip_comparison_data(...)` | 칩 비교 데이터 조회 |
| `get_chip_flow_data(...)` | 칩 흐름 데이터 조회 |
| `get_player_history_data(...)` | 플레이어 히스토리 데이터 조회 |
| `get_payout_data(...)` | 상금 데이터 조회 |
| `get_elimination_data(...)` | 탈락 데이터 조회 |
| `get_at_risk_data(...)` | At Risk 데이터 조회 |

### 2.5 통계 갱신 함수

| 함수명 | 설명 |
|--------|------|
| `update_session_stats(p_session_id)` | GFX 세션 통계 갱신 |
| `update_cue_sheet_stats()` | 큐시트 통계 갱신 |
| `update_session_stats()` | Cuesheet 세션 통계 갱신 |
| `increment_template_usage()` | 템플릿 사용 카운트 증가 |
| `update_event_player_stats(p_event_id)` | WSOP 이벤트 플레이어 통계 갱신 |
| `update_event_rankings(p_event_id)` | WSOP 이벤트 순위 갱신 |

### 2.6 작업 큐 함수

| 함수명 | 설명 |
|--------|------|
| `claim_next_job(...)` | 다음 작업 할당 |
| `complete_job(...)` | 작업 완료 처리 |
| `update_sync_completion(...)` | 동기화 완료 처리 |
| `log_activity(...)` | 활동 로그 기록 |
| `get_config(...)` | 시스템 설정 조회 |

### 2.7 큐시트 함수

| 함수명 | 설명 |
|--------|------|
| `transition_cue_item_status(...)` | 큐 아이템 상태 전이 |
| `get_next_cue_item(p_sheet_id)` | 다음 큐 아이템 조회 |

### 2.8 검증 함수

| 함수명 | 설명 |
|--------|------|
| `validate_mapping_slot_range()` | 매핑 슬롯 범위 검증 |
| `validate_transform_params()` | 변환 파라미터 검증 |

### 2.9 동기화 함수

| 함수명 | 설명 |
|--------|------|
| `check_sync_health_and_notify()` | 동기화 건강 상태 확인 및 알림 |
| `retry_failed_syncs()` | 실패한 동기화 재시도 |
| `restore_gfx_from_external()` | External에서 GFX 데이터 복구 |
| `sync_json_gfx_sessions_to_public()` | JSON→Public 세션 동기화 |
| `sync_json_hands_to_public()` | JSON→Public 핸드 동기화 |
| `sync_json_hand_players_to_public()` | JSON→Public 핸드 플레이어 동기화 |
| `sync_json_hand_actions_to_public()` | JSON→Public 핸드 액션 동기화 |
| `sync_json_hand_cards_to_public()` | JSON→Public 핸드 카드 동기화 |
| `sync_json_hand_results_to_public()` | JSON→Public 핸드 결과 동기화 |
| `disable_json_sync_triggers()` | JSON 동기화 트리거 비활성화 |
| `enable_json_sync_triggers()` | JSON 동기화 트리거 활성화 |

### 2.10 유틸리티 함수

| 함수명 | 설명 |
|--------|------|
| `parse_iso8601_duration(duration)` | ISO8601 기간 파싱 |
| `log_manual_audit()` | Manual 감사 로그 기록 |

---

## 3. 트리거 목록

### 3.1 updated_at 자동 갱신 트리거

| 트리거명 | 테이블 | 함수 |
|----------|--------|------|
| `update_gfx_sessions_updated_at` | `gfx_sessions` | `update_updated_at_column()` |
| `update_gfx_hands_updated_at` | `gfx_hands` | `update_updated_at_column()` |
| `update_gfx_players_updated_at` | `gfx_players` | `update_updated_at_column()` |
| `update_wsop_players_updated_at` | `wsop_players` | `update_wsop_updated_at_column()` |
| `update_wsop_events_updated_at` | `wsop_events` | `update_wsop_updated_at_column()` |
| `update_wsop_event_players_updated_at` | `wsop_event_players` | `update_wsop_updated_at_column()` |
| `update_manual_players_updated_at` | `manual_players` | `update_manual_updated_at_column()` |
| `update_player_overrides_updated_at` | `player_overrides` | `update_manual_updated_at_column()` |
| `update_player_link_mapping_updated_at` | `player_link_mapping` | `update_manual_updated_at_column()` |
| `update_broadcast_sessions_updated_at` | `broadcast_sessions` | `update_cue_updated_at_column()` |
| `update_cue_sheets_updated_at` | `cue_sheets` | `update_cue_updated_at_column()` |
| `update_cue_items_updated_at` | `cue_items` | `update_cue_updated_at_column()` |
| `update_cue_templates_updated_at` | `cue_templates` | `update_cue_updated_at_column()` |
| `trigger_job_queue_updated_at` | `job_queue` | `update_updated_at_column()` |
| `trigger_render_queue_updated_at` | `render_queue` | `update_updated_at_column()` |
| `trigger_sync_status_updated_at` | `sync_status` | `update_updated_at_column()` |
| `trigger_system_config_updated_at` | `system_config` | `update_updated_at_column()` |
| `trigger_api_keys_updated_at` | `api_keys` | `update_updated_at_column()` |
| `trigger_gfx_aep_mapping_updated_at` | `gfx_aep_mapping` | `update_updated_at_column()` |
| `trigger_gfx_aep_comp_updated_at` | `gfx_aep_compositions` | `update_updated_at_column()` |

### 3.2 통계 자동 갱신 트리거

| 트리거명 | 테이블 | 함수 | 설명 |
|----------|--------|------|------|
| `update_sheet_stats_on_item_change` | `cue_items` | `update_cue_sheet_stats()` | 아이템 변경 시 시트 통계 갱신 |
| `update_session_stats_on_sheet_change` | `cue_sheets` | `update_session_stats()` | 시트 변경 시 세션 통계 갱신 |
| `increment_template_usage_on_item` | `cue_items` | `increment_template_usage()` | 템플릿 사용 시 카운트 증가 |

### 3.3 자동 설정 트리거

| 트리거명 | 테이블 | 함수 | 설명 |
|----------|--------|------|------|
| `auto_generate_player_code` | `manual_players` | `set_player_code()` | 플레이어 코드 자동 생성 |
| `normalize_manual_player_name` | `manual_players` | `set_manual_normalized_name()` | 이름 정규화 |
| `normalize_wsop_player_name` | `wsop_players` | `set_normalized_name()` | WSOP 이름 정규화 |

### 3.4 감사 로그 트리거

| 트리거명 | 테이블 | 함수 | 설명 |
|----------|--------|------|------|
| `audit_manual_players` | `manual_players` | `log_manual_audit()` | 플레이어 변경 감사 |
| `audit_player_overrides` | `player_overrides` | `log_manual_audit()` | 오버라이드 변경 감사 |
| `audit_player_link_mapping` | `player_link_mapping` | `log_manual_audit()` | 링크 매핑 변경 감사 |

### 3.5 검증 트리거

| 트리거명 | 테이블 | 함수 | 설명 |
|----------|--------|------|------|
| `trigger_validate_mapping_slot_range` | `gfx_aep_mapping` | `validate_mapping_slot_range()` | 슬롯 범위 검증 |
| `trigger_validate_transform_params` | `gfx_aep_field_transforms` | `validate_transform_params()` | 변환 파라미터 검증 |

### 3.6 JSON↔Public 동기화 트리거

| 트리거명 | 테이블 | 함수 | 설명 |
|----------|--------|------|------|
| `trg_sync_gfx_sessions_to_public` | `json.gfx_sessions` | `sync_json_gfx_sessions_to_public()` | 세션 동기화 |
| `trg_sync_hands_to_public` | `json.hands` | `sync_json_hands_to_public()` | 핸드 동기화 |
| `trg_sync_hand_players_to_public` | `json.hand_players` | `sync_json_hand_players_to_public()` | 핸드 플레이어 동기화 |
| `trg_sync_hand_actions_to_public` | `json.hand_actions` | `sync_json_hand_actions_to_public()` | 핸드 액션 동기화 |
| `trg_sync_hand_cards_to_public` | `json.hand_cards` | `sync_json_hand_cards_to_public()` | 핸드 카드 동기화 |
| `trg_sync_hand_results_to_public` | `json.hand_results` | `sync_json_hand_results_to_public()` | 핸드 결과 동기화 |

---

## 4. 인덱스 목록

주요 인덱스는 각 테이블 마이그레이션 파일에 정의되어 있습니다.
상세 목록은 다음 명령으로 확인:

```sql
SELECT indexname, tablename, indexdef
FROM pg_indexes
WHERE schemaname = 'public'
ORDER BY tablename, indexname;
```

---

## 5. 참조

| 문서 | 내용 |
|------|------|
| `docs/02-GFX-JSON-DB.md` | GFX 스키마 상세 |
| `docs/03-WSOP+-DB.md` | WSOP+ 스키마 상세 |
| `docs/04-Manual-DB.md` | Manual 스키마 상세 |
| `docs/05-Cuesheet-DB.md` | Cuesheet 스키마 상세 |
| `docs/07-Supabase-Orchestration.md` | Orchestration 스키마 상세 |
| `docs/08-GFX-AEP-Mapping.md` | AEP 매핑 상세 |
