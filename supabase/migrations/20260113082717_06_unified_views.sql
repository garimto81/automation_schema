-- ============================================================================
-- 06. Unified Views Migration
-- ============================================================================
-- 통합 뷰 정의 - 모든 데이터 소스를 병합하여 조회
-- 의존성: 01_gfx, 02_wsop, 03_manual, 04_cuesheet 마이그레이션 완료 필요
-- ============================================================================

-- ============================================================================
-- 5.1 unified_players: 모든 소스의 플레이어 통합 뷰
-- GFX, WSOP+, Manual 데이터를 병합
-- ============================================================================

CREATE OR REPLACE VIEW unified_players AS
WITH player_sources AS (
    -- Manual Players (최우선)
    SELECT
        'manual' AS source,
        mp.id AS source_id,
        mp.player_code AS source_code,
        mp.name,
        mp.name_korean,
        COALESCE(mp.name_display, mp.name) AS display_name,
        mp.country_code,
        mp.country_name,
        COALESCE(mp.profile_image_url, mp.profile_image_local) AS profile_image,
        mp.bio,
        mp.notable_wins,
        mp.is_verified,
        mp.created_at,
        mp.updated_at,
        1 AS priority
    FROM manual_players mp
    WHERE mp.is_active = TRUE

    UNION ALL

    -- WSOP+ Players
    SELECT
        'wsop' AS source,
        wp.id AS source_id,
        wp.wsop_player_id AS source_code,
        wp.name,
        NULL AS name_korean,
        wp.name AS display_name,
        wp.country_code,
        wp.country_name,
        wp.profile_image_url AS profile_image,
        NULL AS bio,
        NULL AS notable_wins,
        FALSE AS is_verified,
        wp.created_at,
        wp.updated_at,
        2 AS priority
    FROM wsop_players wp

    UNION ALL

    -- GFX Players
    SELECT
        'gfx' AS source,
        gp.id AS source_id,
        gp.player_hash AS source_code,
        gp.name,
        NULL AS name_korean,
        COALESCE(gp.long_name, gp.name) AS display_name,
        NULL AS country_code,
        NULL AS country_name,
        NULL AS profile_image,
        NULL AS bio,
        NULL AS notable_wins,
        FALSE AS is_verified,
        gp.created_at,
        gp.updated_at,
        3 AS priority
    FROM gfx_players gp
),
linked_players AS (
    -- 연결된 플레이어 정보
    SELECT
        plm.manual_player_id,
        plm.wsop_player_id,
        plm.gfx_player_id,
        plm.match_confidence,
        plm.is_verified AS link_verified
    FROM player_link_mapping plm
)
SELECT
    COALESCE(ps.source_id, gen_random_uuid()) AS id,
    ps.source AS primary_source,
    ps.source_id,
    ps.source_code,
    ps.name,
    ps.name_korean,
    ps.display_name,
    ps.country_code,
    ps.country_name,
    ps.profile_image,
    ps.bio,
    ps.notable_wins,
    ps.is_verified,

    -- 연결 정보
    lp.manual_player_id,
    lp.wsop_player_id,
    lp.gfx_player_id,
    lp.match_confidence,
    lp.link_verified,

    -- 소스 개수
    (CASE WHEN lp.manual_player_id IS NOT NULL THEN 1 ELSE 0 END +
     CASE WHEN lp.wsop_player_id IS NOT NULL THEN 1 ELSE 0 END +
     CASE WHEN lp.gfx_player_id IS NOT NULL THEN 1 ELSE 0 END) AS linked_sources_count,

    ps.created_at,
    GREATEST(ps.updated_at, NOW()) AS last_updated

FROM player_sources ps
LEFT JOIN linked_players lp ON
    (ps.source = 'manual' AND ps.source_id = lp.manual_player_id) OR
    (ps.source = 'wsop' AND ps.source_id = lp.wsop_player_id) OR
    (ps.source = 'gfx' AND ps.source_id = lp.gfx_player_id)
ORDER BY ps.priority, ps.name;

COMMENT ON VIEW unified_players IS '모든 소스(GFX, WSOP+, Manual)의 플레이어 데이터 통합 뷰';

-- ============================================================================
-- 5.2 unified_events: 통합 이벤트 뷰
-- WSOP+, GFX, Cuesheet 이벤트 병합
-- ============================================================================

CREATE OR REPLACE VIEW unified_events AS
SELECT
    'wsop' AS source,
    we.id AS source_id,
    we.event_id AS source_code,
    we.event_name AS name,
    we.event_type::TEXT AS event_type,
    we.start_date,
    we.end_date,
    we.buy_in,
    we.prize_pool,
    we.total_entries,
    we.status::TEXT AS status,
    we.venue,
    we.created_at,
    we.updated_at

FROM wsop_events we

UNION ALL

SELECT
    'gfx' AS source,
    gs.id AS source_id,
    gs.session_id::TEXT AS source_code,
    gs.event_title AS name,
    gs.table_type::TEXT AS event_type,
    gs.session_created_at::DATE AS start_date,
    gs.session_created_at::DATE AS end_date,
    NULL AS buy_in,
    NULL AS prize_pool,
    gs.player_count AS total_entries,
    gs.sync_status::TEXT AS status,
    NULL AS venue,
    gs.created_at,
    gs.updated_at

FROM gfx_sessions gs

UNION ALL

SELECT
    'cuesheet' AS source,
    bs.id AS source_id,
    bs.session_code AS source_code,
    bs.event_name AS name,
    'broadcast' AS event_type,
    bs.broadcast_date AS start_date,
    bs.broadcast_date AS end_date,
    NULL AS buy_in,
    NULL AS prize_pool,
    bs.total_cue_items AS total_entries,
    bs.status::TEXT AS status,
    NULL AS venue,
    bs.created_at,
    bs.updated_at

FROM broadcast_sessions bs

ORDER BY start_date DESC;

COMMENT ON VIEW unified_events IS '모든 소스(WSOP+, GFX, Cuesheet)의 이벤트 데이터 통합 뷰';

-- ============================================================================
-- 5.3 unified_chip_data: 통합 칩 데이터 뷰
-- WSOP+, GFX 칩 데이터 병합
-- ============================================================================

CREATE OR REPLACE VIEW unified_chip_data AS
SELECT
    'wsop' AS source,
    wcc.id,
    wcc.event_id,
    wcc.player_id,
    wp.name AS player_name,
    wp.country_code,
    wcc.chip_count,
    wcc.rank,
    wcc.table_num,
    wcc.seat_num,
    wcc.recorded_at,
    wcc.source::TEXT AS data_source

FROM wsop_chip_counts wcc
JOIN wsop_players wp ON wcc.player_id = wp.id

UNION ALL

SELECT
    'gfx' AS source,
    ghp.id,
    gs.id AS event_id,
    ghp.player_id,
    ghp.player_name,
    NULL AS country_code,
    ghp.end_stack_amt AS chip_count,
    NULL AS rank,
    NULL AS table_num,
    ghp.seat_num,
    gh.start_time AS recorded_at,
    'gfx' AS data_source

FROM gfx_hand_players ghp
JOIN gfx_hands gh ON ghp.hand_id = gh.id
JOIN gfx_sessions gs ON gh.session_id = gs.session_id

UNION ALL

SELECT
    'cuesheet' AS source,
    cs.id,
    cs.session_id AS event_id,
    NULL AS player_id,
    (pd.value->>'player_name')::TEXT AS player_name,
    (pd.value->>'nationality')::TEXT AS country_code,
    (pd.value->>'chipcount')::BIGINT AS chip_count,
    (pd.value->>'rank')::INTEGER AS rank,
    (pd.value->>'table_no')::INTEGER AS table_num,
    (pd.value->>'seat_no')::INTEGER AS seat_num,
    cs.snapshot_time AS recorded_at,
    'cuesheet' AS data_source

FROM chip_snapshots cs
CROSS JOIN LATERAL jsonb_array_elements(cs.players_data) AS pd(value)

ORDER BY recorded_at DESC;

COMMENT ON VIEW unified_chip_data IS '모든 소스(WSOP+, GFX, Cuesheet)의 칩 데이터 통합 뷰';

-- ============================================================================
-- 5.4 v_job_queue_summary: 작업 큐 상태 요약
-- ============================================================================

CREATE OR REPLACE VIEW v_job_queue_summary AS
SELECT
    job_type,
    status,
    COUNT(*) AS count,
    AVG(EXTRACT(EPOCH FROM (completed_at - started_at))) AS avg_duration_seconds,
    MAX(created_at) AS last_created,
    MAX(completed_at) AS last_completed

FROM job_queue
WHERE created_at > NOW() - INTERVAL '24 hours'
GROUP BY job_type, status
ORDER BY job_type, status;

COMMENT ON VIEW v_job_queue_summary IS '작업 큐 상태 요약 (최근 24시간)';

-- ============================================================================
-- 5.5 v_sync_dashboard: 동기화 상태 대시보드
-- ============================================================================

CREATE OR REPLACE VIEW v_sync_dashboard AS
SELECT
    ss.id,
    ss.source,
    ss.entity_type,
    ss.status,
    ss.last_synced_at,
    ss.next_sync_at,
    ss.consecutive_failures,
    ss.total_records,
    ss.sync_enabled,

    -- 마지막 동기화 결과
    sh.records_processed AS last_records_processed,
    sh.records_created AS last_records_created,
    sh.records_failed AS last_records_failed,
    sh.duration_ms AS last_duration_ms,

    -- 상태 계산
    CASE
        WHEN ss.status = 'failed' OR ss.consecutive_failures > 3 THEN 'error'
        WHEN ss.status = 'in_progress' THEN 'syncing'
        WHEN ss.last_synced_at < NOW() - (ss.sync_interval_minutes * INTERVAL '2 minutes') THEN 'stale'
        ELSE 'healthy'
    END AS health_status,

    ss.updated_at

FROM sync_status ss
LEFT JOIN LATERAL (
    SELECT * FROM sync_history
    WHERE sync_status_id = ss.id
    ORDER BY created_at DESC
    LIMIT 1
) sh ON TRUE
ORDER BY ss.source, ss.entity_type;

COMMENT ON VIEW v_sync_dashboard IS '동기화 상태 대시보드 (전체 소스 모니터링)';

-- ============================================================================
-- END OF MIGRATION
-- ============================================================================
