-- Migration: 미사용 인덱스 정리 (Phase 1)
-- Issue: #3 - 미사용 인덱스 330개 정리로 약 4.4MB 절약
-- Date: 2026-01-24
--
-- 주의: 이 마이그레이션은 30일 이상 모니터링 후 사용되지 않은 인덱스만 삭제합니다.
-- 현재 통계 기간: 12일 → 추가 모니터링 권장
--
-- 삭제 기준:
-- - Index scans = 0
-- - Unused = true
-- - 크기 >= 16 KB (작은 인덱스는 영향 미미)

-- ============================================================
-- Phase 1: public 스키마 미사용 인덱스 (가장 영향이 큰 것들)
-- ============================================================

-- GIN 인덱스 (JSONB 필드) - 사용되지 않음
DROP INDEX IF EXISTS public.idx_gfx_hands_board_cards;
DROP INDEX IF EXISTS public.idx_broadcast_sessions_tags;
DROP INDEX IF EXISTS public.idx_wsop_standings_data;
DROP INDEX IF EXISTS public.idx_system_config_tags;
DROP INDEX IF EXISTS public.idx_gfx_hand_players_cards;
DROP INDEX IF EXISTS public.idx_wsop_events_tags;
DROP INDEX IF EXISTS public.idx_gfx_sessions_raw_json_type;
DROP INDEX IF EXISTS public.idx_job_queue_tags;
DROP INDEX IF EXISTS public.idx_cue_templates_tags;

-- 일반 B-tree 인덱스 (미사용)
DROP INDEX IF EXISTS public.idx_gfx_sessions_file_hash;
DROP INDEX IF EXISTS public.idx_render_queue_type;
DROP INDEX IF EXISTS public.idx_render_queue_pending;
DROP INDEX IF EXISTS public.idx_gfx_players_name;
DROP INDEX IF EXISTS public.idx_broadcast_sessions_date;
DROP INDEX IF EXISTS public.idx_wsop_standings_remaining;
DROP INDEX IF EXISTS public.idx_gfx_sessions_sync_status;
DROP INDEX IF EXISTS public.idx_render_queue_job;
DROP INDEX IF EXISTS public.idx_wsop_events_buy_in;
DROP INDEX IF EXISTS public.idx_gfx_sessions_processed_at;
DROP INDEX IF EXISTS public.idx_broadcast_sessions_code;
DROP INDEX IF EXISTS public.idx_wsop_events_type;
DROP INDEX IF EXISTS public.idx_wsop_standings_event_day;
DROP INDEX IF EXISTS public.idx_wsop_events_status;
DROP INDEX IF EXISTS public.idx_wsop_events_start_date;
DROP INDEX IF EXISTS public.idx_gfx_hands_start_time;
DROP INDEX IF EXISTS public.idx_gfx_hands_pot_size;
DROP INDEX IF EXISTS public.idx_gfx_hand_players_player_id;
DROP INDEX IF EXISTS public.idx_gfx_sessions_table_type;
DROP INDEX IF EXISTS public.idx_gfx_hands_game_variant;
DROP INDEX IF EXISTS public.idx_broadcast_sessions_scheduled;
DROP INDEX IF EXISTS public.idx_sync_status_next_sync;
DROP INDEX IF EXISTS public.idx_render_queue_priority;
DROP INDEX IF EXISTS public.idx_wsop_events_prize_pool;
DROP INDEX IF EXISTS public.idx_gfx_sessions_created_at;
DROP INDEX IF EXISTS public.idx_sync_status_status;
DROP INDEX IF EXISTS public.idx_sync_status_last_synced;
DROP INDEX IF EXISTS public.idx_aep_media_sources_category;
DROP INDEX IF EXISTS public.idx_wsop_standings_event;
DROP INDEX IF EXISTS public.idx_gfx_aep_comp_active;
DROP INDEX IF EXISTS public.idx_render_queue_cue_item;
DROP INDEX IF EXISTS public.idx_broadcast_sessions_status;
DROP INDEX IF EXISTS public.idx_gfx_aep_mapping_category;
DROP INDEX IF EXISTS public.idx_gfx_hand_players_winner;
DROP INDEX IF EXISTS public.idx_aep_media_sources_country_code;
DROP INDEX IF EXISTS public.idx_render_queue_data_hash;
DROP INDEX IF EXISTS public.idx_gfx_hand_players_shown;
DROP INDEX IF EXISTS public.idx_gfx_players_hash;
DROP INDEX IF EXISTS public.idx_gfx_hands_duration;
DROP INDEX IF EXISTS public.idx_sync_status_source;

-- ============================================================
-- Phase 2: json 스키마 미사용 인덱스
-- ============================================================

DROP INDEX IF EXISTS json.idx_json_hands_number;
DROP INDEX IF EXISTS json.idx_json_hand_players_stack_delta;
DROP INDEX IF EXISTS json.idx_json_hands_started;
DROP INDEX IF EXISTS json.idx_json_hands_level;
DROP INDEX IF EXISTS json.idx_json_hand_players_winner;
DROP INDEX IF EXISTS json.idx_json_hand_players_name;
DROP INDEX IF EXISTS json.idx_json_sessions_gfx_created;
DROP INDEX IF EXISTS json.idx_json_sessions_created;
DROP INDEX IF EXISTS json.idx_json_hand_actions_player;
DROP INDEX IF EXISTS json.idx_json_hands_showdown;
DROP INDEX IF EXISTS json.idx_json_hands_session;
DROP INDEX IF EXISTS json.idx_json_hand_players_hand;
DROP INDEX IF EXISTS json.idx_json_sessions_tournament;
DROP INDEX IF EXISTS json.idx_json_sessions_feature_table;
DROP INDEX IF EXISTS json.idx_json_sessions_status;
DROP INDEX IF EXISTS json.idx_json_hand_results_hand;
DROP INDEX IF EXISTS json.idx_json_hand_results_rank;
DROP INDEX IF EXISTS json.idx_json_hand_actions_action;
DROP INDEX IF EXISTS json.idx_json_hand_actions_type;
DROP INDEX IF EXISTS json.idx_json_hand_actions_order;
DROP INDEX IF EXISTS json.idx_json_sessions_gfx_id;
DROP INDEX IF EXISTS json.idx_json_hand_actions_hand;
DROP INDEX IF EXISTS json.idx_json_hand_results_winner;
DROP INDEX IF EXISTS json.idx_json_hands_premium;
DROP INDEX IF EXISTS json.idx_json_hands_winner;
DROP INDEX IF EXISTS json.idx_json_hand_players_eliminated;
DROP INDEX IF EXISTS json.idx_json_hand_cards_seat;
DROP INDEX IF EXISTS json.idx_json_hand_cards_type;
DROP INDEX IF EXISTS json.idx_json_hand_cards_hand;
DROP INDEX IF EXISTS json.idx_json_hands_grade;
DROP INDEX IF EXISTS json.idx_json_hand_players_master;

-- ============================================================
-- Phase 3: ae 스키마 미사용 인덱스
-- ============================================================

DROP INDEX IF EXISTS ae.idx_ae_render_jobs_composition;
DROP INDEX IF EXISTS ae.idx_ae_mappings_data_type;
DROP INDEX IF EXISTS ae.idx_ae_render_outputs_type;
DROP INDEX IF EXISTS ae.idx_ae_compositions_type;
DROP INDEX IF EXISTS ae.idx_ae_compositions_name;
DROP INDEX IF EXISTS ae.idx_ae_templates_updated;
DROP INDEX IF EXISTS ae.idx_ae_data_types_active;
DROP INDEX IF EXISTS ae.idx_ae_render_outputs_job;
DROP INDEX IF EXISTS ae.idx_ae_compositions_renderable;
DROP INDEX IF EXISTS ae.idx_ae_mappings_layer;
DROP INDEX IF EXISTS ae.idx_ae_mappings_source;
DROP INDEX IF EXISTS ae.idx_ae_render_jobs_status;
DROP INDEX IF EXISTS ae.idx_ae_layers_data_field;
DROP INDEX IF EXISTS ae.idx_ae_templates_active;
DROP INDEX IF EXISTS ae.idx_ae_render_jobs_created;
DROP INDEX IF EXISTS ae.idx_ae_templates_name;
DROP INDEX IF EXISTS ae.idx_ae_data_types_category;
DROP INDEX IF EXISTS ae.idx_ae_layers_dynamic;
DROP INDEX IF EXISTS ae.idx_ae_layers_slot;
DROP INDEX IF EXISTS ae.idx_ae_render_jobs_pending;
DROP INDEX IF EXISTS ae.idx_ae_render_jobs_worker;

-- ============================================================
-- Phase 4: manual 스키마 미사용 인덱스
-- ============================================================

DROP INDEX IF EXISTS manual.idx_manual_players_search;
DROP INDEX IF EXISTS manual.idx_manual_players_display_name;
DROP INDEX IF EXISTS manual.idx_manual_players_active;
DROP INDEX IF EXISTS manual.idx_manual_events_venue;
DROP INDEX IF EXISTS manual.idx_manual_venues_active;
DROP INDEX IF EXISTS manual.idx_manual_players_nationality;
DROP INDEX IF EXISTS manual.idx_manual_commentators_active;
DROP INDEX IF EXISTS manual.idx_manual_venues_city;
DROP INDEX IF EXISTS manual.idx_manual_venues_country;
DROP INDEX IF EXISTS manual.idx_manual_events_status;
DROP INDEX IF EXISTS manual.idx_manual_events_dates;
DROP INDEX IF EXISTS manual.idx_manual_venues_name;
DROP INDEX IF EXISTS manual.idx_manual_players_bracelets;
DROP INDEX IF EXISTS manual.idx_manual_feature_tables_active;
DROP INDEX IF EXISTS manual.idx_manual_events_code;
DROP INDEX IF EXISTS manual.idx_manual_players_name;
DROP INDEX IF EXISTS manual.idx_manual_events_active;
DROP INDEX IF EXISTS manual.idx_manual_feature_tables_main;
DROP INDEX IF EXISTS manual.idx_manual_feature_tables_rfid;
DROP INDEX IF EXISTS manual.idx_manual_profiles_style;
DROP INDEX IF EXISTS manual.idx_manual_commentators_player;
DROP INDEX IF EXISTS manual.idx_manual_commentators_primary;
DROP INDEX IF EXISTS manual.idx_manual_seating_current;
DROP INDEX IF EXISTS manual.idx_manual_seating_table;
DROP INDEX IF EXISTS manual.idx_manual_seating_player;
DROP INDEX IF EXISTS manual.idx_manual_seating_seat;
DROP INDEX IF EXISTS manual.idx_manual_seating_assigned;
DROP INDEX IF EXISTS manual.idx_manual_events_series;
DROP INDEX IF EXISTS manual.idx_manual_venues_location;
DROP INDEX IF EXISTS manual.idx_manual_profiles_player;
DROP INDEX IF EXISTS manual.idx_manual_players_key;
DROP INDEX IF EXISTS manual.idx_manual_players_hendon;
DROP INDEX IF EXISTS manual.idx_manual_feature_tables_tournament;
DROP INDEX IF EXISTS manual.idx_manual_feature_tables_streaming;

-- ============================================================
-- Phase 5: wsop_plus 스키마 미사용 인덱스
-- ============================================================

DROP INDEX IF EXISTS wsop_plus.idx_wsop_payouts_place;
DROP INDEX IF EXISTS wsop_plus.idx_wsop_tournaments_running;
DROP INDEX IF EXISTS wsop_plus.idx_wsop_payouts_tournament;
DROP INDEX IF EXISTS wsop_plus.idx_wsop_tournaments_status;
DROP INDEX IF EXISTS wsop_plus.idx_wsop_player_instances_name;
DROP INDEX IF EXISTS wsop_plus.idx_wsop_player_instances_master;
DROP INDEX IF EXISTS wsop_plus.idx_wsop_blind_levels_current;
DROP INDEX IF EXISTS wsop_plus.idx_wsop_payouts_bubble;
DROP INDEX IF EXISTS wsop_plus.idx_wsop_payouts_amount;
DROP INDEX IF EXISTS wsop_plus.idx_wsop_tournaments_event;
DROP INDEX IF EXISTS wsop_plus.idx_wsop_blind_levels_level;
DROP INDEX IF EXISTS wsop_plus.idx_wsop_tournaments_venue;
DROP INDEX IF EXISTS wsop_plus.idx_wsop_player_instances_tournament;
DROP INDEX IF EXISTS wsop_plus.idx_wsop_player_instances_feature;
DROP INDEX IF EXISTS wsop_plus.idx_wsop_player_instances_rank;
DROP INDEX IF EXISTS wsop_plus.idx_wsop_tournaments_scheduled;
DROP INDEX IF EXISTS wsop_plus.idx_wsop_blind_levels_tournament;
DROP INDEX IF EXISTS wsop_plus.idx_wsop_tournaments_code;
DROP INDEX IF EXISTS wsop_plus.idx_wsop_blind_levels_break;
DROP INDEX IF EXISTS wsop_plus.idx_wsop_schedules_tournament;
DROP INDEX IF EXISTS wsop_plus.idx_wsop_schedules_date;
DROP INDEX IF EXISTS wsop_plus.idx_wsop_schedules_live;
DROP INDEX IF EXISTS wsop_plus.idx_wsop_schedules_event;
DROP INDEX IF EXISTS wsop_plus.idx_wsop_schedules_start;
DROP INDEX IF EXISTS wsop_plus.idx_wsop_player_instances_eliminated;
DROP INDEX IF EXISTS wsop_plus.idx_wsop_player_instances_chips;

-- ============================================================
-- 완료 메시지
-- ============================================================

DO $$
DECLARE
    v_count INTEGER;
BEGIN
    -- 남은 인덱스 수 계산
    SELECT COUNT(*) INTO v_count
    FROM pg_indexes
    WHERE schemaname IN ('public', 'json', 'ae', 'manual', 'wsop_plus');

    RAISE NOTICE '미사용 인덱스 정리 완료!';
    RAISE NOTICE '남은 인덱스 수: %', v_count;
    RAISE NOTICE '';
    RAISE NOTICE '예상 절약: ~4.4 MB 스토리지';
    RAISE NOTICE 'INSERT/UPDATE/DELETE 성능 향상';
END $$;
