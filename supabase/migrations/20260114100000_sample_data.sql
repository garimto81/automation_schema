-- ============================================================================
-- Migration: sample_data
-- Description: 샘플 DB 데이터 (GFX JSON + AE 템플릿 기반)
-- Source:
--   - GFX JSON: C:\claude\automation_feature_table\gfx_json
--   - AE Template: C:\claude\automation_ae\templates\CyprusDesign
-- Version: 1.0.0
-- Date: 2026-01-14
-- ============================================================================

-- ============================================================================
-- 1. GFX Players - 실제 플레이어 데이터 (table-pokercaster 기반)
-- ============================================================================

INSERT INTO gfx_players (id, player_hash, name, long_name, total_hands_played, total_sessions) VALUES
    -- 실제 포커 플레이어들 (WSOP Super Circuit Cyprus)
    (gen_random_uuid(), md5('korochenskiy:korochenskiy'), 'Korochenskiy', 'Korochenskiy', 42, 2),
    (gen_random_uuid(), md5('khordbin:khordbin'), 'Khordbin', 'Khordbin', 38, 2),
    (gen_random_uuid(), md5('haddad:haddad'), 'Haddad', 'Haddad', 45, 3),
    (gen_random_uuid(), md5('gadeikis:gadeikis'), 'Gadeikis', 'Gadeikis', 40, 2),
    (gen_random_uuid(), md5('ipekoglu:ipekoglu'), 'Ipekoglu', 'Ipekoglu', 35, 2),
    (gen_random_uuid(), md5('cucchiara:cucchiara'), 'Cucchiara', 'Cucchiara', 48, 3),
    (gen_random_uuid(), md5('artamonov:artamonov'), 'Artamonov', 'Artamonov', 30, 2),
    (gen_random_uuid(), md5('michalak:michalak'), 'Michalak', 'Michalak', 44, 2),
    (gen_random_uuid(), md5('herrmann:herrmann'), 'Herrmann', 'Herrmann', 25, 1),
    (gen_random_uuid(), md5('kolonias:kolonias'), 'Kolonias', 'Kolonias', 50, 3),
    (gen_random_uuid(), md5('klezys:klezys'), 'Klezys', 'Klezys', 28, 1),
    (gen_random_uuid(), md5('nikitina:nikitina'), 'Nikitina', 'Nikitina', 32, 2),
    (gen_random_uuid(), md5('bellande:bellande'), 'Bellande', 'Jean-Robert Bellande', 55, 4),
    (gen_random_uuid(), md5('mouawad:mouawad'), 'Mouawad', 'Mouawad', 20, 1),
    (gen_random_uuid(), md5('spasov:spasov'), 'Spasov', 'Spasov', 38, 2),
    (gen_random_uuid(), md5('neves:neves'), 'Neves', 'Neves', 42, 2)
ON CONFLICT (player_hash) DO NOTHING;

-- ============================================================================
-- 2. GFX Sessions - 세션 데이터 (실제 파일 기반)
-- ============================================================================

INSERT INTO gfx_sessions (
    id, session_id, file_name, file_hash, nas_path,
    table_type, event_title, software_version, payouts,
    hand_count, player_count, total_duration_seconds,
    session_created_at, raw_json, sync_status
) VALUES
    -- table-pokercaster/1017 세션
    (
        gen_random_uuid(),
        638962967524560670,
        'PGFX_live_data_export GameID=638962967524560670.json',
        md5('638962967524560670'),
        'C:\claude\automation_feature_table\gfx_json\table-pokercaster\1017\PGFX_live_data_export GameID=638962967524560670.json',
        'FEATURE_TABLE',
        'WSOP Super Circuit Cyprus - Main Event Day 2',
        'PokerGFX 3.2',
        ARRAY[0,0,0,0,0,0,0,0,0,0]::INTEGER[],
        144,
        9,
        7200,
        '2025-10-17T11:19:12.456Z'::TIMESTAMPTZ,
        '{"ID": 638962967524560670, "Type": "FEATURE_TABLE", "SoftwareVersion": "PokerGFX 3.2"}'::JSONB,
        'synced'
    ),
    -- table-GG/1015 세션
    (
        gen_random_uuid(),
        638961224831992165,
        'PGFX_live_data_export GameID=638961224831992165.json',
        md5('638961224831992165'),
        'C:\claude\automation_feature_table\gfx_json\table-GG\1015\PGFX_live_data_export GameID=638961224831992165.json',
        'FEATURE_TABLE',
        'WSOP Super Circuit Cyprus - Day 1A',
        'PokerGFX 3.2',
        ARRAY[0,0,0,0,0,0,0,0,0,0]::INTEGER[],
        3,
        9,
        3600,
        '2025-10-15T10:54:43.199Z'::TIMESTAMPTZ,
        '{"ID": 638961224831992165, "Type": "FEATURE_TABLE", "SoftwareVersion": "PokerGFX 3.2"}'::JSONB,
        'synced'
    )
ON CONFLICT (session_id) DO NOTHING;

-- ============================================================================
-- 3. GFX Hands - 핸드 데이터 (세션별 샘플)
-- ============================================================================

-- Session 638962967524560670의 핸드들
INSERT INTO gfx_hands (
    id, session_id, hand_num, game_variant, game_class, bet_structure,
    duration_seconds, start_time, ante_amt, num_boards, run_it_num_times,
    blinds, pot_size, player_count, board_cards, winner_name
) VALUES
    -- Hand 1: 프리플롭 폴드
    (
        gen_random_uuid(),
        638962967524560670,
        1,
        'HOLDEM',
        'FLOP',
        'NOLIMIT',
        74,  -- PT1M13.8126823S
        '2025-10-17T11:26:49.516Z'::TIMESTAMPTZ,
        500,
        1,
        1,
        '{"ante_type": "BB_ANTE_BB1ST", "big_blind_amt": 500, "big_blind_player_num": 5, "small_blind_amt": 300, "small_blind_player_num": 4, "button_player_num": 3}'::JSONB,
        1800,
        8,
        ARRAY[]::TEXT[],
        'Cucchiara'
    ),
    -- Hand 2: 플롭까지 진행
    (
        gen_random_uuid(),
        638962967524560670,
        2,
        'HOLDEM',
        'FLOP',
        'NOLIMIT',
        120,
        '2025-10-17T11:28:49.516Z'::TIMESTAMPTZ,
        500,
        1,
        1,
        '{"ante_type": "BB_ANTE_BB1ST", "big_blind_amt": 500, "big_blind_player_num": 6, "small_blind_amt": 300, "small_blind_player_num": 5, "button_player_num": 4}'::JSONB,
        15000,
        8,
        ARRAY['2h', '7c', 'kd']::TEXT[],
        'Khordbin'
    ),
    -- Hand 3: 쇼다운
    (
        gen_random_uuid(),
        638962967524560670,
        3,
        'HOLDEM',
        'FLOP',
        'NOLIMIT',
        180,
        '2025-10-17T11:32:49.516Z'::TIMESTAMPTZ,
        500,
        1,
        1,
        '{"ante_type": "BB_ANTE_BB1ST", "big_blind_amt": 500, "big_blind_player_num": 7, "small_blind_amt": 300, "small_blind_player_num": 6, "button_player_num": 5}'::JSONB,
        45000,
        8,
        ARRAY['as', 'kh', 'qd', 'jc', '10s']::TEXT[],
        'Ipekoglu'
    )
ON CONFLICT (session_id, hand_num) DO NOTHING;

-- ============================================================================
-- 4. GFX Hand Players - 핸드별 플레이어 상태 (칩 스택 기준 정렬)
-- ============================================================================

-- Hand 3의 플레이어들 (칩 스택 내림차순 - AEP 매핑 slot 순서)
WITH hand3 AS (
    SELECT id FROM gfx_hands WHERE session_id = 638962967524560670 AND hand_num = 3 LIMIT 1
)
INSERT INTO gfx_hand_players (
    id, hand_id, seat_num, player_name,
    start_stack_amt, end_stack_amt, cumulative_winnings_amt,
    hole_cards, has_shown, sitting_out, elimination_rank, is_winner,
    vpip_percent, preflop_raise_percent
)
SELECT
    gen_random_uuid(),
    hand3.id,
    seat_num,
    player_name,
    start_stack,
    end_stack,
    winnings,
    hole_cards,
    shown,
    FALSE,
    -1,
    is_winner,
    vpip,
    pfr
FROM hand3, (VALUES
    -- slot 1 (칩 리더) → slot 8 순서로 정렬됨
    (6, 'Ipekoglu',     79300, 124300, 45000, ARRAY['ah', 'kd']::TEXT[], TRUE, TRUE, 35.5, 28.0),
    (3, 'Khordbin',     77200, 77200, 0,     ARRAY[]::TEXT[], FALSE, FALSE, 22.0, 18.0),
    (7, 'Cucchiara',    52400, 52400, 0,     ARRAY['qs', 'jh']::TEXT[], TRUE, FALSE, 30.0, 25.0),
    (9, 'Michalak',     50000, 50000, 0,     ARRAY[]::TEXT[], FALSE, FALSE, 18.0, 12.0),
    (5, 'Gadeikis',     43800, 43300, -500,  ARRAY[]::TEXT[], FALSE, FALSE, 28.0, 22.0),
    (4, 'Haddad',       39700, 39200, -500,  ARRAY[]::TEXT[], FALSE, FALSE, 25.0, 20.0),
    (2, 'Korochenskiy', 37600, 37600, 0,     ARRAY[]::TEXT[], FALSE, FALSE, 20.0, 15.0),
    (8, 'Artamonov',    20000, 20000, 0,     ARRAY[]::TEXT[], FALSE, FALSE, 15.0, 10.0)
) AS t(seat_num, player_name, start_stack, end_stack, winnings, hole_cards, shown, is_winner, vpip, pfr)
ON CONFLICT (hand_id, seat_num) DO NOTHING;

-- ============================================================================
-- 5. Manual Players - 수동 관리 플레이어 (한글 이름 포함)
-- ============================================================================

INSERT INTO manual_players (
    id, player_code, name, name_korean, name_display,
    country_code, country_name, bio, is_verified, is_active, created_by
) VALUES
    (gen_random_uuid(), 'MP-001', 'Jean-Robert Bellande', '장-로버트 벨란드', 'Jean-Robert Bellande', 'US', 'United States',
     'Professional poker player and entrepreneur. Known for his aggressive playing style and TV appearances.',
     TRUE, TRUE, 'system'),
    (gen_random_uuid(), 'MP-002', 'Alexandros Kolonias', '알렉산드로스 콜로니아스', 'Alexandros Kolonias', 'GR', 'Greece',
     'WSOP bracelet winner. One of the most successful Greek poker players.',
     TRUE, TRUE, 'system'),
    (gen_random_uuid(), 'MP-003', 'Nikita Kuznetsov', '니키타 쿠즈네초프', 'Nikita Kuznetsov', 'RU', 'Russia',
     'High stakes tournament player.',
     FALSE, TRUE, 'system'),
    (gen_random_uuid(), 'MP-004', 'Sebastian Pauli', '세바스티안 파울리', 'Sebastian Pauli', 'DE', 'Germany',
     'German poker pro specializing in MTTs.',
     FALSE, TRUE, 'system')
ON CONFLICT DO NOTHING;

-- ============================================================================
-- 6. WSOP Events - 이벤트 데이터
-- ============================================================================

INSERT INTO wsop_events (
    id, event_id, event_name, event_number, event_type,
    start_date, end_date, buy_in, prize_pool, total_entries,
    status, venue
) VALUES
    (
        gen_random_uuid(),
        'WSOP-CYPRUS-2025-ME',
        'WSOP Super Circuit Cyprus - Main Event',
        1,
        'MAIN_EVENT',
        '2025-10-15',
        '2025-10-21',
        550000,  -- $5,500 in cents
        1500000000,  -- $15,000,000 prize pool in cents
        2750,
        'running',
        'Merit Royal Diamond Hotel, Cyprus'
    ),
    (
        gen_random_uuid(),
        'WSOP-CYPRUS-2025-12',
        'Event #12: $5,000 MEGA MYSTERY BOUNTY RAFFLE',
        12,
        'MYSTERY_BOUNTY',
        '2025-10-18',
        '2025-10-19',
        500000,  -- $5,000
        800000000,  -- $8,000,000
        1600,
        'completed',
        'Merit Royal Diamond Hotel, Cyprus'
    )
ON CONFLICT DO NOTHING;

-- ============================================================================
-- 7. WSOP Standings - 현재 순위 데이터 (Chip Display용)
-- ============================================================================

INSERT INTO wsop_standings (
    id, event_id, players_remaining, avg_stack, snapshot_at, standings
) VALUES
    (
        gen_random_uuid(),
        (SELECT id FROM wsop_events WHERE event_id = 'WSOP-CYPRUS-2025-ME' LIMIT 1),
        50,
        3000000,
        '2025-10-19T14:00:00Z'::TIMESTAMPTZ,
        '[
            {"rank": 1, "player_name": "Ipekoglu", "chip_count": 12430000, "stack_in_bbs": 124.3, "country_code": "TR"},
            {"rank": 2, "player_name": "Khordbin", "chip_count": 7720000, "stack_in_bbs": 77.2, "country_code": "IR"},
            {"rank": 3, "player_name": "Cucchiara", "chip_count": 5240000, "stack_in_bbs": 52.4, "country_code": "IT"},
            {"rank": 4, "player_name": "Michalak", "chip_count": 5000000, "stack_in_bbs": 50.0, "country_code": "PL"},
            {"rank": 5, "player_name": "Gadeikis", "chip_count": 4330000, "stack_in_bbs": 43.3, "country_code": "LV"},
            {"rank": 6, "player_name": "Haddad", "chip_count": 3920000, "stack_in_bbs": 39.2, "country_code": "LB"},
            {"rank": 7, "player_name": "Korochenskiy", "chip_count": 3760000, "stack_in_bbs": 37.6, "country_code": "RU"},
            {"rank": 8, "player_name": "Artamonov", "chip_count": 2000000, "stack_in_bbs": 20.0, "country_code": "RU"},
            {"rank": 9, "player_name": "Bellande", "chip_count": 1850000, "stack_in_bbs": 18.5, "country_code": "US"},
            {"rank": 10, "player_name": "Kolonias", "chip_count": 1720000, "stack_in_bbs": 17.2, "country_code": "GR"},
            {"rank": 11, "player_name": "Herrmann", "chip_count": 1650000, "stack_in_bbs": 16.5, "country_code": "DE"},
            {"rank": 12, "player_name": "Klezys", "chip_count": 1580000, "stack_in_bbs": 15.8, "country_code": "LT"},
            {"rank": 13, "player_name": "Nikitina", "chip_count": 1450000, "stack_in_bbs": 14.5, "country_code": "RU"},
            {"rank": 14, "player_name": "Mouawad", "chip_count": 1380000, "stack_in_bbs": 13.8, "country_code": "LB"},
            {"rank": 15, "player_name": "Spasov", "chip_count": 1250000, "stack_in_bbs": 12.5, "country_code": "BG"},
            {"rank": 16, "player_name": "Neves", "chip_count": 1180000, "stack_in_bbs": 11.8, "country_code": "BR"}
        ]'::JSONB
    )
ON CONFLICT DO NOTHING;

-- ============================================================================
-- 8-10. AEP 관련 테이블 (스키마에 미정의 - 생략)
-- aep_compositions, aep_field_keys, aep_media_sources는
-- 별도 스키마 추가 시 활성화
-- ============================================================================

-- ============================================================================
-- 11. Broadcast Sessions - 방송 스케줄 (Schedule 컴포지션용)
-- ============================================================================

INSERT INTO broadcast_sessions (
    id, session_code, event_name, broadcast_date, scheduled_start, status, created_by
) VALUES
    (gen_random_uuid(), 'BC-2025-1016', 'MAIN EVENT DAY 1A', '2025-10-16', '2025-10-16T17:10:00+03:00', 'completed', 'system'),
    (gen_random_uuid(), 'BC-2025-1017', 'MAIN EVENT DAY 1C', '2025-10-17', '2025-10-17T17:00:00+03:00', 'completed', 'system'),
    (gen_random_uuid(), 'BC-2025-1018', 'MAIN EVENT DAY 2', '2025-10-18', '2025-10-18T17:30:00+03:00', 'completed', 'system'),
    (gen_random_uuid(), 'BC-2025-1019', 'MAIN EVENT DAY 3', '2025-10-19', '2025-10-19T14:30:00+03:00', 'live', 'system'),
    (gen_random_uuid(), 'BC-2025-1020', 'MAIN EVENT DAY 4', '2025-10-20', '2025-10-20T14:00:00+03:00', 'scheduled', 'system'),
    (gen_random_uuid(), 'BC-2025-1021', 'MAIN EVENT FINAL DAY', '2025-10-21', '2025-10-21T13:30:00+03:00', 'scheduled', 'system')
ON CONFLICT DO NOTHING;

-- ============================================================================
-- 12. Render Queue 샘플 - Chip Display 렌더링 요청
-- ============================================================================

INSERT INTO render_queue (
    id, render_type, aep_project, aep_comp_name, priority, status,
    output_format, output_resolution, gfx_data
) VALUES
    (
        gen_random_uuid(),
        'chip_count',
        'CyprusDesign.aep',
        '_MAIN Mini Chip Count',
        100,
        'pending',
        'mp4',
        '1920x1080',
        '{
            "comp_name": "_MAIN Mini Chip Count",
            "render_type": "chip_count",
            "slots": [
                {"slot_index": 1, "fields": {"name": "Ipekoglu", "chips": "12,430,000", "rank": "1", "bbs": "124.3", "country_code": "TR", "flag_path": "Flag/Turkey.png"}},
                {"slot_index": 2, "fields": {"name": "Khordbin", "chips": "7,720,000", "rank": "2", "bbs": "77.2", "country_code": "IR", "flag_path": "Flag/Iran.png"}},
                {"slot_index": 3, "fields": {"name": "Cucchiara", "chips": "5,240,000", "rank": "3", "bbs": "52.4", "country_code": "IT", "flag_path": "Flag/Italy.png"}},
                {"slot_index": 4, "fields": {"name": "Michalak", "chips": "5,000,000", "rank": "4", "bbs": "50.0", "country_code": "PL", "flag_path": "Flag/Poland.png"}},
                {"slot_index": 5, "fields": {"name": "Gadeikis", "chips": "4,330,000", "rank": "5", "bbs": "43.3", "country_code": "LV", "flag_path": "Flag/Latvia.png"}},
                {"slot_index": 6, "fields": {"name": "Haddad", "chips": "3,920,000", "rank": "6", "bbs": "39.2", "country_code": "LB", "flag_path": "Flag/Lebanon.png"}},
                {"slot_index": 7, "fields": {"name": "Korochenskiy", "chips": "3,760,000", "rank": "7", "bbs": "37.6", "country_code": "RU", "flag_path": "Flag/Russia.png"}},
                {"slot_index": 8, "fields": {"name": "Artamonov", "chips": "2,000,000", "rank": "8", "bbs": "20.0", "country_code": "RU", "flag_path": "Flag/Russia.png"}}
            ],
            "metadata": {
                "event_id": "WSOP-CYPRUS-2025-ME",
                "event_name": "WSOP Super Circuit Cyprus - Main Event",
                "session_id": 638962967524560670,
                "hand_num": 3,
                "blind_level": "5K/10K (10K ante)",
                "players_remaining": 50,
                "timestamp": "2025-10-19T14:00:00Z"
            }
        }'::JSONB
    )
ON CONFLICT DO NOTHING;

-- ============================================================================
-- 통계 업데이트
-- ============================================================================

-- 세션 통계 업데이트
SELECT update_session_stats(638962967524560670);
SELECT update_session_stats(638961224831992165);

-- ============================================================================
-- 완료 메시지
-- ============================================================================
DO $$
BEGIN
    RAISE NOTICE '샘플 데이터 삽입 완료:';
    RAISE NOTICE '  - gfx_players: 16명';
    RAISE NOTICE '  - gfx_sessions: 2개';
    RAISE NOTICE '  - gfx_hands: 3개';
    RAISE NOTICE '  - gfx_hand_players: 8개';
    RAISE NOTICE '  - manual_players: 4명';
    RAISE NOTICE '  - wsop_events: 2개';
    RAISE NOTICE '  - wsop_standings: 1개 (16명 순위)';
    RAISE NOTICE '  - broadcast_sessions: 6개';
    RAISE NOTICE '  - render_queue: 1개';
END $$;
