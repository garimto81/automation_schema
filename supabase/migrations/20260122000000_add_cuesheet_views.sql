-- ============================================================================
-- Migration: 20260122000000_add_cuesheet_views.sql
-- Description: Cuesheet 관련 뷰 추가 (문서 정의 기반)
-- Source: docs/05-Cuesheet-DB.md Section 5
-- ============================================================================

-- ============================================================================
-- v_session_overview: 방송 세션 개요 및 진행 상황
-- ============================================================================

CREATE OR REPLACE VIEW v_session_overview AS
SELECT
    bs.id,
    bs.session_code,
    bs.event_name,
    bs.broadcast_date,
    bs.scheduled_start,
    bs.actual_start,
    bs.status,
    bs.director,

    -- 큐시트 통계
    COUNT(cs.id) AS total_sheets,
    COUNT(CASE WHEN cs.status = 'completed' THEN 1 END) AS completed_sheets,
    COUNT(CASE WHEN cs.status = 'active' THEN 1 END) AS active_sheets,

    -- 큐 아이템 통계
    SUM(cs.total_items) AS total_items,
    SUM(cs.completed_items) AS completed_items,

    -- 진행률
    CASE
        WHEN SUM(cs.total_items) > 0
        THEN ROUND(SUM(cs.completed_items)::NUMERIC / SUM(cs.total_items) * 100, 1)
        ELSE 0
    END AS progress_percent,

    bs.updated_at

FROM broadcast_sessions bs
LEFT JOIN cue_sheets cs ON bs.id = cs.session_id
GROUP BY bs.id
ORDER BY bs.broadcast_date DESC, bs.scheduled_start DESC;

-- ============================================================================
-- v_cue_sheet_items: 큐시트별 아이템 목록
-- ============================================================================

CREATE OR REPLACE VIEW v_cue_sheet_items AS
SELECT
    ci.id,
    ci.cue_number,
    ci.title,
    ci.cue_type,
    ci.status,
    ci.duration_seconds,
    ci.sort_order,
    ci.gfx_template_name,
    ci.scheduled_time,
    ci.actual_time,

    -- 큐시트 정보
    cs.id AS sheet_id,
    cs.sheet_code,
    cs.sheet_name,
    cs.sheet_type,

    -- 세션 정보
    bs.id AS session_id,
    bs.session_code,
    bs.event_name,

    -- 현재 진행 여부
    (cs.current_item_id = ci.id) AS is_current,

    -- 템플릿 정보
    ct.template_name,
    ct.preview_image_url,

    ci.updated_at

FROM cue_items ci
JOIN cue_sheets cs ON ci.sheet_id = cs.id
JOIN broadcast_sessions bs ON cs.session_id = bs.id
LEFT JOIN cue_templates ct ON ci.template_id = ct.id
ORDER BY cs.session_id, cs.sheet_order, ci.sort_order;

-- ============================================================================
-- v_active_cues: 현재 진행 중인 세션의 활성 큐
-- ============================================================================

CREATE OR REPLACE VIEW v_active_cues AS
SELECT
    ci.id,
    ci.cue_number,
    ci.title,
    ci.cue_type,
    ci.status,
    ci.gfx_data,
    ci.duration_seconds,

    cs.sheet_name,
    bs.session_code,
    bs.event_name,

    -- 다음 큐 정보
    (
        SELECT ci2.title
        FROM cue_items ci2
        WHERE ci2.sheet_id = ci.sheet_id
          AND ci2.sort_order > ci.sort_order
        ORDER BY ci2.sort_order
        LIMIT 1
    ) AS next_cue_title

FROM cue_items ci
JOIN cue_sheets cs ON ci.sheet_id = cs.id
JOIN broadcast_sessions bs ON cs.session_id = bs.id
WHERE bs.status = 'live'
  AND cs.status = 'active'
  AND ci.status IN ('standby', 'on_air')
ORDER BY ci.sort_order;

-- ============================================================================
-- v_trigger_history: GFX 트리거 이력
-- ============================================================================

CREATE OR REPLACE VIEW v_trigger_history AS
SELECT
    gt.id,
    gt.trigger_type,
    gt.trigger_time,
    gt.triggered_by,
    gt.cue_type,
    gt.aep_comp_name,
    gt.render_status,
    gt.duration_ms,
    gt.error_message,

    ci.cue_number,
    ci.title AS cue_title,

    cs.sheet_name,
    bs.session_code,
    bs.event_name

FROM gfx_triggers gt
LEFT JOIN cue_items ci ON gt.cue_item_id = ci.id
LEFT JOIN cue_sheets cs ON gt.sheet_id = cs.id
LEFT JOIN broadcast_sessions bs ON gt.session_id = bs.id
ORDER BY gt.trigger_time DESC;

-- ============================================================================
-- v_template_usage: 템플릿 사용 현황
-- ============================================================================

CREATE OR REPLACE VIEW v_template_usage AS
SELECT
    ct.id,
    ct.template_code,
    ct.template_name,
    ct.cue_type,
    ct.category,
    ct.is_active,
    ct.usage_count,
    ct.last_used_at,

    -- 최근 30일 사용 횟수
    (
        SELECT COUNT(*)
        FROM cue_items ci
        WHERE ci.template_id = ct.id
          AND ci.created_at > NOW() - INTERVAL '30 days'
    ) AS usage_last_30_days,

    -- 현재 사용 중인 아이템 수
    (
        SELECT COUNT(*)
        FROM cue_items ci
        JOIN cue_sheets cs ON ci.sheet_id = cs.id
        JOIN broadcast_sessions bs ON cs.session_id = bs.id
        WHERE ci.template_id = ct.id
          AND bs.status = 'live'
    ) AS active_usage_count

FROM cue_templates ct
WHERE ct.is_active = TRUE
ORDER BY ct.usage_count DESC;
