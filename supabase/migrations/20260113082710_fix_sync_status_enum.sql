-- ============================================================================
-- Fix: sync_status ENUM 이름 충돌 해결
-- sync_status ENUM -> gfx_sync_status로 변경
-- (Orchestration의 sync_status 테이블과 이름 충돌 방지)
-- ============================================================================

-- ENUM 이름 변경
ALTER TYPE sync_status RENAME TO gfx_sync_status;

-- gfx_sessions 테이블의 컬럼 타입 업데이트는 자동으로 처리됨
-- (PostgreSQL은 ENUM 타입 이름 변경 시 참조하는 컬럼도 자동 업데이트)
