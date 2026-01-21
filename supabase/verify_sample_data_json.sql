-- ============================================================================
-- 검증 쿼리: json 스키마 샘플 데이터 확인
-- ============================================================================

-- ============================================================================
-- 1. json 스키마 데이터 확인
-- ============================================================================

\echo '===== json.gfx_sessions ====='
SELECT
    id,
    source_file,
    table_type,
    event_title,
    total_hands
FROM json.gfx_sessions
WHERE id = 638962967524560999;

\echo ''
\echo '===== json.hands ====='
SELECT
    hand_number,
    game_variant,
    duration_seconds,
    final_pot_size,
    player_count,
    grade,
    is_premium,
    is_showdown,
    board_cards
FROM json.hands
WHERE session_id = 638962967524560999
ORDER BY hand_number;

\echo ''
\echo '===== json.hand_players (Hand 1만) ====='
SELECT
    hand_number,
    seat_number,
    player_name,
    start_stack,
    end_stack,
    net_result,
    is_winner,
    hole_cards,
    has_shown_cards
FROM json.hand_players
WHERE session_id = 638962967524560999
  AND hand_number = 1
ORDER BY seat_number;

\echo ''
\echo '===== json.hand_actions 통계 ====='
SELECT
    hand_number,
    COUNT(*) as action_count,
    COUNT(DISTINCT street) as street_count
FROM json.hand_actions
WHERE session_id = 638962967524560999
GROUP BY hand_number
ORDER BY hand_number;

\echo ''
\echo '===== json.hand_cards 통계 ====='
SELECT
    hand_number,
    card_type,
    COUNT(*) as card_count
FROM json.hand_cards
WHERE session_id = 638962967524560999
GROUP BY hand_number, card_type
ORDER BY hand_number, card_type;

\echo ''
\echo '===== json.hand_results ====='
SELECT
    hand_number,
    seat_number,
    player_name,
    is_winner,
    won_amount,
    hand_rank,
    rank_value
FROM json.hand_results
WHERE session_id = 638962967524560999
ORDER BY hand_number, showdown_order;

-- ============================================================================
-- 2. public 스키마 동기화 확인 (트리거 동작 확인)
-- ============================================================================

\echo ''
\echo '===== public.gfx_sessions (트리거 동기화 확인) ====='
SELECT
    session_id,
    file_name,
    table_type,
    event_title,
    hand_count,
    sync_status
FROM public.gfx_sessions
WHERE session_id = 638962967524560999;

\echo ''
\echo '===== public.gfx_hands (트리거 동기화 확인) ====='
SELECT
    session_id,
    hand_num,
    game_variant,
    duration_seconds,
    pot_size,
    player_count,
    grade,
    is_premium,
    is_showdown,
    board_cards
FROM public.gfx_hands
WHERE session_id = 638962967524560999
ORDER BY hand_num;

\echo ''
\echo '===== public.gfx_hand_players 통계 ====='
SELECT
    h.hand_num,
    COUNT(*) as player_count,
    COUNT(CASE WHEN hp.is_winner THEN 1 END) as winner_count,
    SUM(hp.won_amount) as total_won
FROM public.gfx_hands h
JOIN public.gfx_hand_players hp ON h.id = hp.hand_id
WHERE h.session_id = 638962967524560999
GROUP BY h.hand_num
ORDER BY h.hand_num;

\echo ''
\echo '===== public.gfx_events 통계 ====='
SELECT
    h.hand_num,
    COUNT(*) as event_count,
    COUNT(DISTINCT e.street) as street_count
FROM public.gfx_hands h
JOIN public.gfx_events e ON h.id = e.hand_id
WHERE h.session_id = 638962967524560999
GROUP BY h.hand_num
ORDER BY h.hand_num;

\echo ''
\echo '===== public.gfx_hand_cards 통계 ====='
SELECT
    h.hand_num,
    c.card_type,
    COUNT(*) as card_count
FROM public.gfx_hands h
JOIN public.gfx_hand_cards c ON h.id = c.hand_id
WHERE h.session_id = 638962967524560999
GROUP BY h.hand_num, c.card_type
ORDER BY h.hand_num, c.card_type;

\echo ''
\echo '===== public.gfx_hand_results ====='
SELECT
    h.hand_num,
    r.seat_number,
    r.player_name,
    r.is_winner,
    r.won_amount,
    r.hand_rank,
    r.rank_value
FROM public.gfx_hands h
JOIN public.gfx_hand_results r ON h.id = r.hand_id
WHERE h.session_id = 638962967524560999
ORDER BY h.hand_num, r.showdown_order;

-- ============================================================================
-- 3. 데이터 무결성 검증
-- ============================================================================

\echo ''
\echo '===== 데이터 무결성 검증 ====='

-- 핸드 수 일치 확인
SELECT
    'hand_count_match' as check_name,
    CASE
        WHEN (SELECT total_hands FROM json.gfx_sessions WHERE id = 638962967524560999)
           = (SELECT COUNT(*) FROM json.hands WHERE session_id = 638962967524560999)
        THEN '✓ PASS'
        ELSE '✗ FAIL'
    END as result;

-- pot size 일치 확인 (Hand 1)
SELECT
    'pot_size_match_hand1' as check_name,
    CASE
        WHEN (SELECT final_pot_size FROM json.hands WHERE session_id = 638962967524560999 AND hand_number = 1)
           = (SELECT MAX(pot_after) FROM json.hand_actions WHERE session_id = 638962967524560999 AND hand_number = 1)
        THEN '✓ PASS'
        ELSE '✗ FAIL'
    END as result;

-- 승자 금액 일치 확인 (Hand 1)
SELECT
    'winner_amount_match_hand1' as check_name,
    CASE
        WHEN (SELECT won_amount FROM json.hand_results WHERE session_id = 638962967524560999 AND hand_number = 1 AND is_winner = TRUE)
           = (SELECT final_pot_size FROM json.hands WHERE session_id = 638962967524560999 AND hand_number = 1)
        THEN '✓ PASS'
        ELSE '✗ FAIL'
    END as result;

-- 카드 수 확인 (Hand 1 - 홀카드 4장 + 커뮤니티 5장)
SELECT
    'card_count_hand1' as check_name,
    CASE
        WHEN (SELECT COUNT(*) FROM json.hand_cards WHERE session_id = 638962967524560999 AND hand_number = 1) = 9
        THEN '✓ PASS'
        ELSE '✗ FAIL'
    END as result;

-- 트리거 동기화 확인 (json → public)
SELECT
    'sync_trigger_sessions' as check_name,
    CASE
        WHEN EXISTS (SELECT 1 FROM public.gfx_sessions WHERE session_id = 638962967524560999)
        THEN '✓ PASS (트리거 동작)'
        ELSE '✗ FAIL (트리거 미동작)'
    END as result;

SELECT
    'sync_trigger_hands' as check_name,
    CASE
        WHEN (SELECT COUNT(*) FROM public.gfx_hands WHERE session_id = 638962967524560999) = 3
        THEN '✓ PASS (3개 핸드 동기화)'
        ELSE '✗ FAIL'
    END as result;

\echo ''
\echo '===== 검증 완료 ====='
