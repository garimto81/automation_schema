-- ============================================================================
-- Migration: gfx_aep_integrity_constraints
-- Description: GFX-AEP 매핑 테이블 데이터 무결성 제약조건 추가
-- Version: 1.0.0
-- Date: 2026-01-15
-- ============================================================================

-- ============================================================================
-- 1. FK 제약조건: composition_name → gfx_aep_compositions.name
-- ============================================================================

DO $$ BEGIN
    ALTER TABLE gfx_aep_field_mappings
    ADD CONSTRAINT fk_mapping_composition
    FOREIGN KEY (composition_name) REFERENCES gfx_aep_compositions(name)
    ON UPDATE CASCADE ON DELETE RESTRICT;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

COMMENT ON CONSTRAINT fk_mapping_composition ON gfx_aep_field_mappings IS
    '컴포지션 이름 참조 무결성: 존재하지 않는 컴포지션 참조 방지';

-- ============================================================================
-- 2. CHECK 제약조건: 슬롯 범위 유효성
-- ============================================================================

DO $$ BEGIN
    ALTER TABLE gfx_aep_field_mappings
    ADD CONSTRAINT chk_slot_range_valid
    CHECK (
        slot_range_start IS NULL OR slot_range_end IS NULL OR
        (slot_range_start >= 1 AND slot_range_end >= slot_range_start)
    );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

COMMENT ON CONSTRAINT chk_slot_range_valid ON gfx_aep_field_mappings IS
    '슬롯 범위 유효성: start >= 1, end >= start';

-- ============================================================================
-- 3. CHECK 제약조건: 정렬 방향 제한
-- ============================================================================

DO $$ BEGIN
    ALTER TABLE gfx_aep_field_mappings
    ADD CONSTRAINT chk_order_direction
    CHECK (slot_order_direction IS NULL OR slot_order_direction IN ('ASC', 'DESC'));
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

COMMENT ON CONSTRAINT chk_order_direction ON gfx_aep_field_mappings IS
    '정렬 방향 제한: ASC 또는 DESC만 허용';

-- ============================================================================
-- 4. CHECK 제약조건: 우선순위 범위
-- ============================================================================

DO $$ BEGIN
    ALTER TABLE gfx_aep_field_mappings
    ADD CONSTRAINT chk_priority_range
    CHECK (priority >= 0 AND priority <= 1000);
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

COMMENT ON CONSTRAINT chk_priority_range ON gfx_aep_field_mappings IS
    '우선순위 범위: 0-1000 (낮을수록 높은 우선순위)';

-- ============================================================================
-- 5. 트리거: 슬롯 범위 vs 컴포지션 slot_count 검증
-- ============================================================================

CREATE OR REPLACE FUNCTION validate_mapping_slot_range()
RETURNS TRIGGER AS $$
DECLARE
    v_slot_count INTEGER;
    v_slot_field_keys TEXT[];
    v_single_field_keys TEXT[];
BEGIN
    -- 컴포지션 정보 조회
    SELECT slot_count, slot_field_keys, single_field_keys
    INTO v_slot_count, v_slot_field_keys, v_single_field_keys
    FROM gfx_aep_compositions
    WHERE name = NEW.composition_name;

    -- 컴포지션이 없으면 FK에서 처리하므로 패스
    IF NOT FOUND THEN
        RETURN NEW;
    END IF;

    -- 슬롯 범위 검증 (slot_count > 0인 경우만)
    IF v_slot_count > 0 AND NEW.slot_range_end IS NOT NULL THEN
        IF NEW.slot_range_end > v_slot_count THEN
            RAISE EXCEPTION 'slot_range_end (%) exceeds composition slot_count (%) for composition "%"',
                NEW.slot_range_end, v_slot_count, NEW.composition_name;
        END IF;
    END IF;

    -- target_field_key 검증 (슬롯 필드인 경우)
    IF NEW.slot_range_start IS NOT NULL THEN
        -- 슬롯 필드인 경우 slot_field_keys에 있어야 함
        IF v_slot_field_keys IS NOT NULL AND array_length(v_slot_field_keys, 1) > 0 THEN
            IF NOT (NEW.target_field_key = ANY(v_slot_field_keys)) THEN
                RAISE EXCEPTION 'target_field_key "%" not in slot_field_keys for composition "%"',
                    NEW.target_field_key, NEW.composition_name;
            END IF;
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION validate_mapping_slot_range() IS
    '매핑 규칙의 슬롯 범위와 필드 키 유효성 검증';

DROP TRIGGER IF EXISTS trigger_validate_mapping_slot_range ON gfx_aep_field_mappings;
CREATE TRIGGER trigger_validate_mapping_slot_range
BEFORE INSERT OR UPDATE ON gfx_aep_field_mappings
FOR EACH ROW
EXECUTE FUNCTION validate_mapping_slot_range();

-- ============================================================================
-- 6. 트리거: transform 파라미터 검증
-- ============================================================================

CREATE OR REPLACE FUNCTION validate_transform_params()
RETURNS TRIGGER AS $$
BEGIN
    -- format_bbs는 big_blind 정보가 필요하지만,
    -- 현재 구조에서는 런타임에 결정되므로 여기서는 검증하지 않음

    -- 향후 필요시 transform_params JSON 스키마 검증 추가
    -- 예: format_bbs인 경우 bb_column 파라미터 필수 등

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION validate_transform_params() IS
    'transform 파라미터 유효성 검증 (향후 확장용)';

DROP TRIGGER IF EXISTS trigger_validate_transform_params ON gfx_aep_field_mappings;
CREATE TRIGGER trigger_validate_transform_params
BEFORE INSERT OR UPDATE ON gfx_aep_field_mappings
FOR EACH ROW
EXECUTE FUNCTION validate_transform_params();

-- ============================================================================
-- 7. 정합성 확인 쿼리 (참고용)
-- ============================================================================

-- 아래 쿼리로 기존 데이터 정합성 확인 가능:

-- 1. 존재하지 않는 composition_name 참조 확인
-- SELECT m.* FROM gfx_aep_field_mappings m
-- LEFT JOIN gfx_aep_compositions c ON m.composition_name = c.name
-- WHERE c.name IS NULL;

-- 2. slot_range_end > slot_count 확인
-- SELECT m.composition_name, m.slot_range_end, c.slot_count
-- FROM gfx_aep_field_mappings m
-- JOIN gfx_aep_compositions c ON m.composition_name = c.name
-- WHERE m.slot_range_end > c.slot_count;

-- 3. 유효하지 않은 target_field_key 확인
-- SELECT m.composition_name, m.target_field_key
-- FROM gfx_aep_field_mappings m
-- JOIN gfx_aep_compositions c ON m.composition_name = c.name
-- WHERE m.slot_range_start IS NOT NULL
--   AND c.slot_field_keys IS NOT NULL
--   AND NOT (m.target_field_key = ANY(c.slot_field_keys));

-- ============================================================================
-- 완료
-- ============================================================================
