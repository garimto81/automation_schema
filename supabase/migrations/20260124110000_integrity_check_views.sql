-- Migration: 무결성 검증 결과 뷰
-- Date: 2026-01-24
-- Purpose: 실시간 무결성 상태 모니터링 뷰

-- ============================================================
-- 1. FK 무결성 상태 뷰
-- ============================================================

CREATE OR REPLACE VIEW v_integrity_fk_status AS
SELECT * FROM validate_fk_integrity();

COMMENT ON VIEW v_integrity_fk_status IS 'FK 참조 무결성 현재 상태';

-- ============================================================
-- 2. 데이터 일관성 상태 뷰
-- ============================================================

CREATE OR REPLACE VIEW v_integrity_data_status AS
SELECT * FROM validate_data_consistency();

COMMENT ON VIEW v_integrity_data_status IS '데이터 일관성 현재 상태';

-- ============================================================
-- 3. 스키마 간 참조 상태 뷰
-- ============================================================

CREATE OR REPLACE VIEW v_integrity_cross_schema_status AS
SELECT * FROM validate_cross_schema_integrity();

COMMENT ON VIEW v_integrity_cross_schema_status IS '스키마 간 참조 무결성 현재 상태';

-- ============================================================
-- 4. 전체 무결성 요약 뷰
-- ============================================================

CREATE OR REPLACE VIEW v_integrity_summary AS
SELECT
    'FK_INTEGRITY' AS category,
    COUNT(*) FILTER (WHERE status = 'OK') AS passed,
    COUNT(*) FILTER (WHERE status != 'OK') AS failed,
    SUM(orphan_count) AS total_issues
FROM validate_fk_integrity()
UNION ALL
SELECT
    'DATA_CONSISTENCY' AS category,
    COUNT(*) FILTER (WHERE status = 'OK') AS passed,
    COUNT(*) FILTER (WHERE status != 'OK') AS failed,
    SUM(issue_count) AS total_issues
FROM validate_data_consistency()
UNION ALL
SELECT
    'CROSS_SCHEMA' AS category,
    COUNT(*) FILTER (WHERE status = 'OK') AS passed,
    COUNT(*) FILTER (WHERE status != 'OK') AS failed,
    SUM(orphan_count) AS total_issues
FROM validate_cross_schema_integrity();

COMMENT ON VIEW v_integrity_summary IS '전체 무결성 검증 요약';

-- ============================================================
-- 5. 완료 메시지
-- ============================================================

DO $$
BEGIN
    RAISE NOTICE '무결성 모니터링 뷰 생성 완료!';
    RAISE NOTICE '';
    RAISE NOTICE '조회 방법:';
    RAISE NOTICE '  SELECT * FROM v_integrity_summary;';
    RAISE NOTICE '  SELECT * FROM v_integrity_fk_status;';
    RAISE NOTICE '  SELECT * FROM v_integrity_data_status;';
    RAISE NOTICE '  SELECT * FROM v_integrity_cross_schema_status;';
END $$;
