# Supabase 스키마 분석 보고서
분석 일시: 2026-01-16
프로젝트: automation_project (ohzdaflycmnbxkpvhxcu)

## 요약
총 32개 테이블, 38개 ENUM, 17개 VIEW, 56개 함수로 구성된 GFX-AEP 렌더링 시스템 스키마

## 1. ENUM 타입 (38 개)
| ENUM 이름 | 값 개수 | 값 목록 |
|-----------|--------|--------|
| `aep_composition_category` | 9 | chip_display, payout, event_info, schedule, staff... |
| `aep_transform_type` | 12 | UPPER, LOWER, format_chips, format_bbs, format_currency... |
| `ante_type` | 5 | NO_ANTE, BB_ANTE_BB1ST, BB_ANTE_BTN1ST, ALL_ANTE, DEAD_ANTE |
| `bet_structure` | 4 | NOLIMIT, POTLIMIT, LIMIT, SPREAD_LIMIT |
| `cue_broadcast_status` | 9 | draft, scheduled, preparing, standby, live... |
| `cue_content_type` | 7 | opening_sequence, main, sub, virtual, leaderboard... |
| `cue_hand_rank` | 5 | A, B, B-, C, SOFT |
| `cue_item_status` | 9 | draft, pending, ready, standby, on_air... |
| `cue_item_type` | 25 | intro, location, commentators, broadcast_schedule, event_info... |
| `cue_render_status` | 7 | pending, queued, rendering, completed, failed... |
| `cue_sheet_status` | 8 | draft, pending_review, approved, ready, active... |
| `cue_sheet_type` | 7 | pre_show, main_show, segment, break, post_show... |
| `cue_template_type` | 15 | mini_chip_left, mini_chip_right, feature_table_chip, mini_payouts, elimination_risk... |
| `cue_trigger_type` | 6 | manual, scheduled, auto, api, hotkey... |
| `event_type` | 14 | FOLD, CHECK, CALL, BET, RAISE... |
| `game_class` | 4 | FLOP, STUD, DRAW, MIXED |
| `game_variant` | 8 | HOLDEM, OMAHA, OMAHA_HILO, STUD, STUD_HILO... |
| `gfx_sync_status` | 5 | pending, synced, updated, failed, archived |
| `manual_image_type` | 6 | profile, thumbnail, broadcast, headshot, action... |
| `manual_match_method` | 6 | exact_name, fuzzy_name, manual, wsop_id, hendon_mob_id... |
| `manual_override_field` | 9 | name, name_korean, name_display, country_code, country_name... |
| `orch_actor_type` | 5 | user, service, system, api, scheduler |
| `orch_data_source` | 6 | gfx, wsop, manual, cuesheet, external... |
| `orch_job_status` | 8 | pending, queued, running, paused, completed... |
| `orch_job_type` | 14 | sync_gfx, sync_wsop, sync_manual, import_json, import_csv... |
| `orch_notification_level` | 4 | low, medium, high, critical |
| `orch_notification_type` | 5 | info, success, warning, error, alert |
| `orch_render_status` | 9 | pending, queued, preparing, rendering, encoding... |
| `orch_render_type` | 7 | chip_count, leaderboard, player_info, hand_replay, elimination... |
| `orch_sync_operation` | 5 | full_sync, incremental, manual, scheduled, webhook |
| `orch_sync_status` | 6 | pending, in_progress, synced, outdated, failed... |
| `table_type` | 5 | FEATURE_TABLE, MAIN_TABLE, FINAL_TABLE, SIDE_TABLE, UNKNOWN |
| `wsop_chip_source` | 4 | import, manual, realtime, snapshot |
| `wsop_event_status` | 8 | upcoming, registration, running, day_break, final_table... |
| `wsop_event_type` | 10 | MAIN_EVENT, BRACELET_EVENT, SIDE_EVENT, SATELLITE, DEEPSTACK... |
| `wsop_import_status` | 5 | pending, processing, completed, failed, partial |
| `wsop_import_type` | 3 | json, csv, api |
| `wsop_player_status` | 4 | registered, active, eliminated, winner |

## 2. 테이블 구조 (32 개)
### 2.1 GFX 테이블 (8 개)

#### `gfx_aep_compositions` (16 columns)
| 컬럼명 | 타입 |
|--------|------|
| `id` | "uuid" DEFAULT "gen_random_uuid"() NOT NULL |
| `name` | character varying(255) NOT NULL |
| `category` | "public"."aep_composition_category" NOT NULL |
| `display_name` | character varying(255) |
| `description` | "text" |
| `slot_count` | integer DEFAULT 0 |
| `slot_field_keys` | "text"[] |
| `single_field_keys` | "text"[] |
| `aep_project_path` | "text" |
| `aep_comp_name` | "text" |
| `default_output_format` | character varying(20) DEFAULT 'mp4'::character varying |
| `default_duration_seconds` | numeric(10 |
| `metadata` | "jsonb" DEFAULT '{}'::"jsonb" |
| `is_active` | boolean DEFAULT true |
| `created_at` | timestamp with time zone DEFAULT "now"() |
| `updated_at` | timestamp with time zone DEFAULT "now"() |

#### `gfx_aep_field_mappings` (21 columns)
| 컬럼명 | 타입 |
|--------|------|
| `id` | "uuid" DEFAULT "gen_random_uuid"() NOT NULL |
| `composition_name` | character varying(255) NOT NULL |
| `composition_category` | "public"."aep_composition_category" NOT NULL |
| `target_field_key` | character varying(100) NOT NULL |
| `target_layer_pattern` | character varying(255) |
| `slot_range_start` | integer |
| `slot_range_end` | integer |
| `source_table` | character varying(100) NOT NULL |
| `source_column` | character varying(100) NOT NULL |
| `source_join` | "text" |
| `source_filter` | "text" |
| `transform` | "public"."aep_transform_type" DEFAULT 'direct'::"public"."aep_transform_type" |
| `transform_params` | "jsonb" |
| `slot_order_by` | character varying(100) |
| `slot_order_direction` | character varying(10) DEFAULT 'ASC'::character varying |
| `default_value` | "text" DEFAULT ''::"text" |
| `priority` | integer DEFAULT 100 |
| `is_active` | boolean DEFAULT true |
| `notes` | "text" |
| `created_at` | timestamp with time zone DEFAULT "now"() |
| `updated_at` | timestamp with time zone DEFAULT "now"() |

#### `gfx_events` (12 columns)
| 컬럼명 | 타입 |
|--------|------|
| `id` | "uuid" DEFAULT "gen_random_uuid"() NOT NULL |
| `hand_id` | "uuid" NOT NULL |
| `event_order` | integer NOT NULL |
| `event_type` | "public"."event_type" NOT NULL |
| `player_num` | integer DEFAULT 0 |
| `bet_amt` | integer DEFAULT 0 |
| `pot` | integer DEFAULT 0 |
| `board_cards` | "text" |
| `board_num` | integer DEFAULT 0 |
| `num_cards_drawn` | integer DEFAULT 0 |
| `event_time` | timestamp with time zone |
| `created_at` | timestamp with time zone DEFAULT "now"() |

#### `gfx_hand_players` (19 columns)
| 컬럼명 | 타입 |
|--------|------|
| `id` | "uuid" DEFAULT "gen_random_uuid"() NOT NULL |
| `hand_id` | "uuid" NOT NULL |
| `player_id` | "uuid" |
| `seat_num` | integer NOT NULL |
| `player_name` | "text" NOT NULL |
| `hole_cards` | "text"[] DEFAULT ARRAY[]::"text"[] |
| `has_shown` | boolean DEFAULT false |
| `start_stack_amt` | integer DEFAULT 0 |
| `end_stack_amt` | integer DEFAULT 0 |
| `cumulative_winnings_amt` | integer DEFAULT 0 |
| `blind_bet_straddle_amt` | integer DEFAULT 0 |
| `sitting_out` | boolean DEFAULT false |
| `elimination_rank` | integer DEFAULT '-1'::integer |
| `is_winner` | boolean DEFAULT false |
| `vpip_percent` | numeric(5 |
| `preflop_raise_percent` | numeric(5 |
| `aggression_frequency_percent` | numeric(5 |
| `went_to_showdown_percent` | numeric(5 |
| `created_at` | timestamp with time zone DEFAULT "now"() |

#### `gfx_hands` (25 columns)
| 컬럼명 | 타입 |
|--------|------|
| `id` | "uuid" DEFAULT "gen_random_uuid"() NOT NULL |
| `session_id` | bigint NOT NULL |
| `hand_num` | integer NOT NULL |
| `game_variant` | "public"."game_variant" DEFAULT 'HOLDEM'::"public"."game_variant" |
| `game_class` | "public"."game_class" DEFAULT 'FLOP'::"public"."game_class" |
| `bet_structure` | "public"."bet_structure" DEFAULT 'NOLIMIT'::"public"."bet_structure" |
| `duration_seconds` | integer DEFAULT 0 |
| `start_time` | timestamp with time zone NOT NULL |
| `recording_offset_iso` | "text" |
| `recording_offset_seconds` | bigint |
| `num_boards` | integer DEFAULT 1 |
| `run_it_num_times` | integer DEFAULT 1 |
| `ante_amt` | integer DEFAULT 0 |
| `bomb_pot_amt` | integer DEFAULT 0 |
| `description` | "text" DEFAULT ''::"text" |
| `blinds` | "jsonb" DEFAULT '{}'::"jsonb" |
| `stud_limits` | "jsonb" DEFAULT '{}'::"jsonb" |
| `pot_size` | integer DEFAULT 0 |
| `player_count` | integer DEFAULT 0 |
| `showdown_count` | integer DEFAULT 0 |
| `board_cards` | "text"[] DEFAULT ARRAY[]::"text"[] |
| `winner_name` | "text" |
| `winner_seat` | integer |
| `created_at` | timestamp with time zone DEFAULT "now"() |
| `updated_at` | timestamp with time zone DEFAULT "now"() |

#### `gfx_players` (10 columns)
| 컬럼명 | 타입 |
|--------|------|
| `id` | "uuid" DEFAULT "gen_random_uuid"() NOT NULL |
| `player_hash` | "text" NOT NULL |
| `name` | "text" NOT NULL |
| `long_name` | "text" DEFAULT ''::"text" |
| `total_hands_played` | integer DEFAULT 0 |
| `total_sessions` | integer DEFAULT 0 |
| `first_seen_at` | timestamp with time zone DEFAULT "now"() |
| `last_seen_at` | timestamp with time zone DEFAULT "now"() |
| `created_at` | timestamp with time zone DEFAULT "now"() |
| `updated_at` | timestamp with time zone DEFAULT "now"() |

#### `gfx_sessions` (21 columns)
| 컬럼명 | 타입 |
|--------|------|
| `id` | "uuid" DEFAULT "gen_random_uuid"() NOT NULL |
| `session_id` | bigint NOT NULL |
| `file_name` | "text" NOT NULL |
| `file_hash` | "text" NOT NULL |
| `nas_path` | "text" |
| `table_type` | "public"."table_type" DEFAULT 'UNKNOWN'::"public"."table_type" NOT NULL |
| `event_title` | "text" DEFAULT ''::"text" |
| `software_version` | "text" DEFAULT ''::"text" |
| `payouts` | integer[] DEFAULT ARRAY[]::integer[] |
| `hand_count` | integer DEFAULT 0 |
| `player_count` | integer DEFAULT 0 |
| `total_duration_seconds` | integer DEFAULT 0 |
| `session_created_at` | timestamp with time zone |
| `session_start_time` | timestamp with time zone |
| `session_end_time` | timestamp with time zone |
| `raw_json` | "jsonb" NOT NULL |
| `sync_status` | "public"."gfx_sync_status" DEFAULT 'pending'::"public"."gfx_sync_status" |
| `sync_error` | "text" |
| `processed_at` | timestamp with time zone DEFAULT "now"() |
| `created_at` | timestamp with time zone DEFAULT "now"() |
| `updated_at` | timestamp with time zone DEFAULT "now"() |

#### `gfx_triggers` (28 columns)
| 컬럼명 | 타입 |
|--------|------|
| `id` | "uuid" DEFAULT "gen_random_uuid"() NOT NULL |
| `cue_item_id` | "uuid" |
| `session_id` | "uuid" |
| `sheet_id` | "uuid" |
| `trigger_type` | "public"."cue_trigger_type" NOT NULL |
| `trigger_time` | timestamp with time zone DEFAULT "now"() NOT NULL |
| `triggered_by` | "text" NOT NULL |
| `cue_type` | "public"."cue_item_type" |
| `aep_comp_name` | "text" |
| `gfx_template_name` | "text" |
| `gfx_data` | "jsonb" |
| `render_status` | "public"."cue_render_status" DEFAULT 'pending'::"public"."cue_render_status" |
| `render_job_id` | "uuid" |
| `render_started_at` | timestamp with time zone |
| `render_completed_at` | timestamp with time zone |
| `output_path` | "text" |
| `output_format` | "text" |
| `output_resolution` | "text" |
| `file_size_bytes` | bigint |
| `duration_ms` | integer |
| `render_duration_ms` | integer |
| `queue_wait_ms` | integer |
| `error_message` | "text" |
| `error_details` | "jsonb" |
| `retry_count` | integer DEFAULT 0 |
| `notes` | "text" |
| `metadata` | "jsonb" DEFAULT '{}'::"jsonb" |
| `created_at` | timestamp with time zone DEFAULT "now"() |

### 2.2 WSOP 테이블 (6 개)

#### `wsop_chip_counts` (15 columns)
| 컬럼명 | 타입 |
|--------|------|
| `id` | "uuid" DEFAULT "gen_random_uuid"() NOT NULL |
| `event_id` | "uuid" NOT NULL |
| `player_id` | "uuid" NOT NULL |
| `table_num` | integer |
| `seat_num` | integer |
| `chip_count` | bigint NOT NULL |
| `chip_change` | bigint DEFAULT 0 |
| `rank` | integer |
| `big_blind_at_time` | bigint |
| `stack_in_bbs` | numeric(10 |
| ... | (5 more) |

#### `wsop_event_players` (23 columns)
| 컬럼명 | 타입 |
|--------|------|
| `id` | "uuid" DEFAULT "gen_random_uuid"() NOT NULL |
| `event_id` | "uuid" NOT NULL |
| `player_id` | "uuid" NOT NULL |
| `table_num` | integer |
| `seat_num` | integer |
| `starting_chips` | bigint |
| `current_chips` | bigint DEFAULT 0 |
| `peak_chips` | bigint DEFAULT 0 |
| `rank` | integer |
| `rank_at_end_of_day` | integer |
| ... | (13 more) |

#### `wsop_events` (30 columns)
| 컬럼명 | 타입 |
|--------|------|
| `id` | "uuid" DEFAULT "gen_random_uuid"() NOT NULL |
| `event_id` | "text" NOT NULL |
| `event_name` | "text" NOT NULL |
| `event_number` | integer |
| `event_type` | "public"."wsop_event_type" DEFAULT 'OTHER'::"public"."wsop_event_type" NOT NULL |
| `start_date` | "date" NOT NULL |
| `end_date` | "date" |
| `start_time` | time without time zone |
| `timezone` | "text" DEFAULT 'UTC'::"text" |
| `buy_in` | bigint NOT NULL |
| ... | (20 more) |

#### `wsop_import_logs` (22 columns)
| 컬럼명 | 타입 |
|--------|------|
| `id` | "uuid" DEFAULT "gen_random_uuid"() NOT NULL |
| `file_name` | "text" NOT NULL |
| `file_path` | "text" |
| `file_hash` | "text" NOT NULL |
| `file_size_bytes` | bigint |
| `file_type` | "public"."wsop_import_type" NOT NULL |
| `target_table` | "text" |
| `event_id` | "uuid" |
| `record_count` | integer DEFAULT 0 |
| `records_created` | integer DEFAULT 0 |
| ... | (12 more) |

#### `wsop_players` (20 columns)
| 컬럼명 | 타입 |
|--------|------|
| `id` | "uuid" DEFAULT "gen_random_uuid"() NOT NULL |
| `wsop_player_id` | "text" NOT NULL |
| `name` | "text" NOT NULL |
| `name_normalized` | "text" |
| `nickname` | "text" |
| `country_code` | character varying(10) |
| `country_name` | character varying(100) |
| `city` | "text" |
| `profile_image_url` | "text" |
| `wsop_bracelets` | integer DEFAULT 0 |
| ... | (10 more) |

#### `wsop_standings` (18 columns)
| 컬럼명 | 타입 |
|--------|------|
| `id` | "uuid" DEFAULT "gen_random_uuid"() NOT NULL |
| `event_id` | "uuid" NOT NULL |
| `snapshot_at` | timestamp with time zone NOT NULL |
| `day_number` | integer DEFAULT 1 |
| `level_number` | integer |
| `players_remaining` | integer NOT NULL |
| `players_eliminated` | integer DEFAULT 0 |
| `avg_stack` | bigint |
| `median_stack` | bigint |
| `total_chips` | bigint |
| ... | (8 more) |

### 2.3 CUE 테이블 (3 개)

#### `cue_items` (36 columns)
| 컬럼명 | 타입 |
|--------|------|
| `id` | "uuid" DEFAULT "gen_random_uuid"() NOT NULL |
| `sheet_id` | "uuid" NOT NULL |
| `template_id` | "uuid" |
| `special_info` | "text" |
| `content_type` | "public"."cue_content_type" NOT NULL |
| `hand_number` | integer |
| `hand_rank` | "public"."cue_hand_rank" |
| `hand_history` | "text" |
| `edit_point` | "text" |
| `pd_note` | "text" |
| ... | (26 more) |

#### `cue_sheets` (24 columns)
| 컬럼명 | 타입 |
|--------|------|
| `id` | "uuid" DEFAULT "gen_random_uuid"() NOT NULL |
| `sheet_code` | "text" NOT NULL |
| `session_id` | "uuid" NOT NULL |
| `sheet_name` | "text" NOT NULL |
| `sheet_type` | "public"."cue_sheet_type" DEFAULT 'main_show'::"public"."cue_sheet_type" NOT NULL |
| `sheet_order` | integer DEFAULT 0 NOT NULL |
| `version` | integer DEFAULT 1 |
| `parent_version_id` | "uuid" |
| `status` | "public"."cue_sheet_status" DEFAULT 'draft'::"public"."cue_sheet_status" |
| `total_items` | integer DEFAULT 0 |
| ... | (14 more) |

#### `cue_templates` (20 columns)
| 컬럼명 | 타입 |
|--------|------|
| `id` | "uuid" DEFAULT "gen_random_uuid"() NOT NULL |
| `template_code` | "text" NOT NULL |
| `template_name` | "text" NOT NULL |
| `description` | "text" |
| `template_type` | "public"."cue_template_type" NOT NULL |
| `position` | "text" |
| `gfx_template_name` | "text" |
| `gfx_comp_name` | "text" |
| `default_duration` | integer DEFAULT 10 |
| `data_schema` | "jsonb" DEFAULT '{}'::"jsonb" |
| ... | (10 more) |

### 2.4 기타 테이블 (15 개)
- `activity_log` (17 columns)
- `aep_media_sources` (9 columns)
- `api_keys` (22 columns)
- `broadcast_sessions` (28 columns)
- `hand_grades` (14 columns)
- `job_queue` (32 columns)
- `notifications` (22 columns)
- `player_link_mapping` (14 columns)
- `player_overrides` (18 columns)
- `profile_images` (23 columns)
- `render_queue` (40 columns)
- `sync_history` (22 columns)
- `sync_log` (12 columns)
- `sync_status` (24 columns)
- `system_config` (19 columns)

## 3. Foreign Key 관계 (30 개)
| 제약조건 이름 | FROM | TO | 옵션 |
|--------------|------|----|----- |
| `cue_items_sheet_id_fkey` | `sheet_id` | `cue_sheets.id` | ON DELETE CASCADE |
| `cue_items_template_id_fkey` | `template_id` | `cue_templates.id` | ON DELETE SET NULL |
| `cue_sheets_parent_version_id_fkey` | `parent_version_id` | `cue_sheets.id` |  |
| `cue_sheets_session_id_fkey` | `session_id` | `broadcast_sessions.id` | ON DELETE CASCADE |
| `fk_cue_sheets_current_item` | `current_item_id` | `cue_items.id` | ON DELETE SET NULL D |
| `fk_mapping_composition` | `composition_name` | `gfx_aep_compositions.name` | ON UPDATE CASCADE ON |
| `gfx_events_hand_id_fkey` | `hand_id` | `gfx_hands.id` | ON DELETE CASCADE |
| `gfx_hand_players_hand_id_fkey` | `hand_id` | `gfx_hands.id` | ON DELETE CASCADE |
| `gfx_hand_players_player_id_fkey` | `player_id` | `gfx_players.id` | ON DELETE SET NULL |
| `gfx_triggers_cue_item_id_fkey` | `cue_item_id` | `cue_items.id` | ON DELETE SET NULL |
| `gfx_triggers_session_id_fkey` | `session_id` | `broadcast_sessions.id` | ON DELETE SET NULL |
| `gfx_triggers_sheet_id_fkey` | `sheet_id` | `cue_sheets.id` | ON DELETE SET NULL |
| `hand_grades_hand_id_fkey` | `hand_id` | `gfx_hands.id` | ON DELETE CASCADE |
| `job_queue_parent_job_id_fkey` | `parent_job_id` | `job_queue.id` |  |
| `notifications_job_id_fkey` | `job_id` | `job_queue.id` | ON DELETE SET NULL |
| `player_overrides_gfx_player_id_fkey` | `gfx_player_id` | `gfx_players.id` |  |
| `profile_images_gfx_player_id_fkey` | `gfx_player_id` | `gfx_players.id` |  |
| `profile_images_wsop_player_id_fkey` | `wsop_player_id` | `wsop_players.id` |  |
| `render_queue_job_id_fkey` | `job_id` | `job_queue.id` | ON DELETE SET NULL |
| `sync_history_job_id_fkey` | `job_id` | `job_queue.id` | ON DELETE SET NULL |
| `sync_history_sync_status_id_fkey` | `sync_status_id` | `sync_status.id` | ON DELETE CASCADE |
| `sync_log_session_id_fkey` | `session_id` | `gfx_sessions.id` |  |
| `wsop_chip_counts_event_id_fkey` | `event_id` | `wsop_events.id` | ON DELETE CASCADE |
| `wsop_chip_counts_player_id_fkey` | `player_id` | `wsop_players.id` | ON DELETE CASCADE |
| `wsop_event_players_eliminated_by_player_id_fkey` | `eliminated_by_player_id` | `wsop_players.id` |  |
| `wsop_event_players_event_id_fkey` | `event_id` | `wsop_events.id` | ON DELETE CASCADE |
| `wsop_event_players_player_id_fkey` | `player_id` | `wsop_players.id` | ON DELETE CASCADE |
| `wsop_import_logs_event_id_fkey` | `event_id` | `wsop_events.id` |  |
| `wsop_standings_chip_leader_player_id_fkey` | `chip_leader_player_id` | `wsop_players.id` |  |
| `wsop_standings_event_id_fkey` | `event_id` | `wsop_events.id` | ON DELETE CASCADE |

## 4. 인덱스 (주요 테이블)

### `gfx_hands` (7 indexes)
- `idx_gfx_hands_board_cards`: "board_cards"
- `idx_gfx_hands_duration`: "duration_seconds" DESC
- `idx_gfx_hands_game_variant`: "game_variant"
- `idx_gfx_hands_hand_num`: "hand_num"
- `idx_gfx_hands_pot_size`: "pot_size" DESC
- `idx_gfx_hands_session_id`: "session_id"
- `idx_gfx_hands_start_time`: "start_time" DESC

### `gfx_hand_players` (6 indexes)
- `idx_gfx_hand_players_cards`: "hole_cards"
- `idx_gfx_hand_players_hand_id`: "hand_id"
- `idx_gfx_hand_players_player_id`: "player_id"
- `idx_gfx_hand_players_seat`: "seat_num"
- `idx_gfx_hand_players_shown`: "has_shown"
- `idx_gfx_hand_players_winner`: "is_winner"

### `cue_items` (8 indexes)
- `idx_cue_items_content_type`: "content_type"
- `idx_cue_items_file_name`: "file_name"
- `idx_cue_items_gfx_data`: "gfx_data"
- `idx_cue_items_hand_number`: "hand_number"
- `idx_cue_items_order`: "sheet_id", "sort_order"
- `idx_cue_items_sheet`: "sheet_id"
- `idx_cue_items_status`: "status"
- `idx_cue_items_template`: "template_id"

### `wsop_events` (7 indexes)
- `idx_wsop_events_buy_in`: "buy_in"
- `idx_wsop_events_event_id`: "event_id"
- `idx_wsop_events_prize_pool`: "prize_pool" DESC
- `idx_wsop_events_start_date`: "start_date" DESC
- `idx_wsop_events_status`: "status"
- `idx_wsop_events_tags`: "tags"
- `idx_wsop_events_type`: "event_type"

## 5. VIEW (17 개)
- `unified_chip_data`
- `unified_events`
- `unified_players`
- `v_chip_count_latest`
- `v_event_summary`
- `v_job_queue_summary`
- `v_leaderboard`
- `v_player_stats`
- `v_recent_hands`
- `v_render_at_risk`
- `v_render_chip_display`
- `v_render_elimination`
- `v_render_payout`
- `v_render_payout_gfx`
- `v_session_summary`
- `v_showdown_players`
- `v_sync_dashboard`

## 6. 함수 (56 개)

### 포맷 함수 (17 개)
- `format_bbs()`
- `format_bbs_safe()`
- `format_blinds()`
- `format_chips()`
- `format_chips_comma()`
- `format_chips_safe()`
- `format_chips_short()`
- `format_currency()`
- `format_currency_cents()`
- `format_currency_from_int()`
- `format_currency_safe()`
- `format_date()`
- `format_date_short()`
- `format_number()`
- `format_percent()`
- `format_time()`
- `format_time_12h()`

### 데이터 조회 함수 (13 개)
- `get_at_risk_data()`
- `get_chip_comparison_data()`
- `get_chip_display_data()`
- `get_chip_flow_data()`
- `get_chips_n_hands_ago()`
- `get_config()`
- `get_elimination_data()`
- `get_flag_path()`
- `get_next_cue_item()`
- `get_payout_data()`
- `get_player_field_with_override()`
- `get_player_history_data()`
- `get_player_name_data()`

### 기타 함수 (26 개)
- `claim_next_job()`
- `complete_job()`
- `generate_player_code()`
- `generate_player_hash()`
- `increment_template_usage()`
- `log_activity()`
- `log_manual_audit()`
- `normalize_manual_player_name()`
- `normalize_player_name()`
- `parse_iso8601_duration()`
- `set_manual_normalized_name()`
- `set_normalized_name()`
- `set_player_code()`
- `transition_cue_item_status()`
- `update_cue_sheet_stats()`

## 7. 트리거 (주요 테이블)

### `aep_media_sources` (1 triggers)
- `trigger_aep_media_sources_updated_at` (UPDATE)

### `api_keys` (1 triggers)
- `trigger_api_keys_updated_at` (UPDATE)

### `broadcast_sessions` (1 triggers)
- `update_broadcast_sessions_updated_at` (UPDATE)

### `cue_items` (3 triggers)
- `increment_template_usage_on_item` (INSERT)
- `update_cue_items_updated_at` (UPDATE)
- `update_sheet_stats_on_item_change` (INSERT OR DELETE OR UPDATE)

### `cue_sheets` (2 triggers)
- `update_cue_sheets_updated_at` (UPDATE)
- `update_session_stats_on_sheet_change` (INSERT OR DELETE OR UPDATE)

### `cue_templates` (1 triggers)
- `update_cue_templates_updated_at` (UPDATE)

### `gfx_aep_compositions` (1 triggers)
- `trigger_gfx_aep_comp_updated_at` (UPDATE)

### `gfx_aep_field_mappings` (3 triggers)
- `trigger_gfx_aep_mapping_updated_at` (UPDATE)
- `trigger_validate_mapping_slot_range` (INSERT OR UPDATE)
- `trigger_validate_transform_params` (INSERT OR UPDATE)

### `gfx_hands` (1 triggers)
- `update_gfx_hands_updated_at` (UPDATE)

### `gfx_players` (1 triggers)
- `update_gfx_players_updated_at` (UPDATE)

### `gfx_sessions` (1 triggers)
- `update_gfx_sessions_updated_at` (UPDATE)

### `job_queue` (1 triggers)
- `trigger_job_queue_updated_at` (UPDATE)

### `player_link_mapping` (2 triggers)
- `audit_player_link_mapping` (INSERT OR DELETE OR UPDATE)
- `update_player_link_mapping_updated_at` (UPDATE)

### `player_overrides` (2 triggers)
- `audit_player_overrides` (INSERT OR DELETE OR UPDATE)
- `update_player_overrides_updated_at` (UPDATE)

### `render_queue` (1 triggers)
- `trigger_render_queue_updated_at` (UPDATE)

## 8. 주요 발견사항

### 긍정적인 점
- **체계적인 ENUM 관리**: 29개 ENUM 타입으로 데이터 무결성 강화
- **완전한 타임스탬프 추적**: 모든 테이블에 `created_at`, `updated_at` 자동 관리
- **GFX-AEP 매핑 시스템**: `gfx_aep_field_mappings` + `gfx_aep_compositions` 테이블로 렌더링 자동화
- **다층 플레이어 관리**: GFX/WSOP/Manual 플레이어 데이터 통합 (`player_link_mapping`, `player_overrides`)
- **렌더링 데이터 함수**: `get_chip_display_data()`, `get_elimination_data()` 등 v3 스키마 JSON 생성 함수

### 개선 필요 사항
- **RLS 정책 부족**: `gfx_triggers` 외 대부분 테이블에 RLS 미적용
- **인덱스 과다**: 일부 테이블(cue_items, gfx_events)에 10개+ 인덱스 → 성능 점검 필요
- **JSONB 컬럼 검증 부재**: `gfx_data`, `payload` 등 JSONB 컬럼에 CHECK 제약조건 없음
- **Soft Delete 미구현**: `deleted_at` 컬럼 없음 → 데이터 복구 어려움
- **파티셔닝 부재**: `gfx_events`, `activity_log` 같은 대용량 테이블 파티셔닝 고려

### 특이사항
- **Job Queue 시스템**: `job_queue` + `render_queue` + `notifications`로 백그라운드 작업 관리
- **실시간 동기화**: `sync_status`, `sync_history`, `sync_log`로 GFX/WSOP 데이터 동기화 추적
- **Cue Sheet 워크플로우**: `broadcast_sessions` → `cue_sheets` → `cue_items` → `gfx_triggers` 렌더링 파이프라인
- **플래그 경로 함수**: `get_flag_path('KR')` → `'Flag/Korea.png'` 자동 변환
- **BB 단위 변환**: `format_bbs(chips, bb)` 함수로 칩 스택을 BB 단위로 자동 표시

