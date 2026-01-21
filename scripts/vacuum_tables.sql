-- VACUUM ANALYZE 스크립트
-- Issue: #2 - DB 최적화
--
-- 실행 방법:
-- 1. Supabase Dashboard → SQL Editor에서 직접 실행
-- 2. 또는: psql -h <host> -U postgres -d postgres -f vacuum_tables.sql
--
-- 주의: 마이그레이션에서는 VACUUM 실행 불가 (트랜잭션 내 실행 제한)

-- ============================================================
-- Dead rows가 누적된 주요 테이블
-- ============================================================

VACUUM ANALYZE public.gfx_aep_compositions;
VACUUM ANALYZE public.gfx_sessions;
VACUUM ANALYZE json.hands;
VACUUM ANALYZE ae.compositions;
VACUUM ANALYZE ae.templates;
VACUUM ANALYZE wsop_plus.tournaments;

-- ============================================================
-- 추가 테이블 (선택적)
-- ============================================================

-- public 스키마
VACUUM ANALYZE public.gfx_hands;
VACUUM ANALYZE public.gfx_hand_players;
VACUUM ANALYZE public.gfx_players;
VACUUM ANALYZE public.sync_status;

-- json 스키마
VACUUM ANALYZE json.gfx_sessions;
VACUUM ANALYZE json.hand_players;
VACUUM ANALYZE json.hand_actions;
VACUUM ANALYZE json.hand_results;

-- ae 스키마
VACUUM ANALYZE ae.composition_layers;
VACUUM ANALYZE ae.render_jobs;

-- manual 스키마
VACUUM ANALYZE manual.players_master;
