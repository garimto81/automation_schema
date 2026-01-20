# GFX → DB → AEP 통합 3계층 매핑

**Version**: 2.0.0
**Last Updated**: 2026-01-20

GFX JSON 원본 필드에서 After Effects 컴포지션 출력까지 **하나의 연속된 흐름**으로 시각화한 통합 매핑 문서입니다.

---

## 범례

| 기호 | 의미 |
|------|------|
| `✅` | GFX 전체 경로 (GFX JSON → DB → AE) |
| `❌` | WSOP+/Manual 필요 (N/A → DB → AE) |
| `⚠️` | 혼합 (일부 GFX + 일부 WSOP+/Manual) |
| `──►` | 매핑 방향 |
| `[함수명]` | 변환 함수 |
| `(계산)` | DB에서 계산/집계 |

### 표기법

```
[GFX JSON Field] ──[변환1]──► [Supabase DB Column] ──[변환2]──► [AE Field]
```

---

## 컴포지션별 통합 매핑 (26개)

```
┌─────────────────────────────────────────────────────────────────────────────────────────────────┐
│                    GFX JSON → SUPABASE DB → AFTER EFFECTS 통합 매핑                              │
│                    ✅ GFX 전체 경로  |  ❌ WSOP+/Manual 필요                                     │
└─────────────────────────────────────────────────────────────────────────────────────────────────┘
```

---

### [chip_display] _MAIN Mini Chip Count (9 slots) ⚠️ 혼합

| GFX JSON | 변환1 | Supabase DB | 변환2 | AE Field |
|----------|-------|-------------|-------|----------|
| ✅ `Players[].Name` | - | `gfx_hand_players.player_name` | `UPPER` | `name` |
| ✅ `Players[].EndStackAmt` | - | `gfx_hand_players.end_stack_amt` | `format_chips` | `chips` |
| ✅ `FlopDrawBlinds.big_blind_amt` | - | `gfx_hands.blinds.big_blind_amt` | `(÷ + format_bbs)` | `bbs` |
| ✅ (계산) | `ROW_NUMBER` | (ORDER BY end_stack_amt DESC) | - | `rank` |
| ❌ N/A | - | `player_overrides.country_code` | `get_flag_path` | `flag` |

```
✅ Players[].Name ──────────────► gfx_hand_players.player_name ──[UPPER]────────────► AE:name
✅ Players[].EndStackAmt ───────► gfx_hand_players.end_stack_amt ──[format_chips]──► AE:chips
✅ FlopDrawBlinds ──────────────► gfx_hands.blinds ─────────────[÷ + format_bbs]───► AE:bbs
✅ (계산) ──────────────────────► (ROW_NUMBER) ────────────────────────────────────► AE:rank
❌ N/A ─────────────────────────► player_overrides.country_code ──[get_flag_path]──► AE:flag
```

---

### [chip_display] _SUB_Mini Chip Count (9 slots) ⚠️ 혼합

| GFX JSON | 변환1 | Supabase DB | 변환2 | AE Field |
|----------|-------|-------------|-------|----------|
| ✅ `Players[].Name` | - | `gfx_hand_players.player_name` | `UPPER` | `name` |
| ✅ `Players[].EndStackAmt` | - | `gfx_hand_players.end_stack_amt` | `format_chips` | `chips` |
| ✅ `FlopDrawBlinds.big_blind_amt` | - | `gfx_hands.blinds.big_blind_amt` | `(÷ + format_bbs)` | `bbs` |
| ✅ (계산) | `ROW_NUMBER` | (ORDER BY end_stack_amt DESC) | - | `rank` |
| ❌ N/A | - | `player_overrides.country_code` | `get_flag_path` | `flag` |

```
(동일 구조: _MAIN Mini Chip Count)
```

---

### [chip_display] Chips In Play x3 (3 slots) ✅ GFX 전용

| GFX JSON | 변환1 | Supabase DB | 변환2 | AE Field |
|----------|-------|-------------|-------|----------|
| ✅ `Players[].EndStackAmt` | `SUM` | `gfx_hand_players.end_stack_amt` | `format_chips` | `chips_in_play` |
| ✅ `FlopDrawBlinds` | - | `gfx_hands.blinds` | `calc_level` | `level` |

```
✅ Players[].EndStackAmt ───────► SUM(gfx_hand_players.end_stack_amt) ──[format_chips]──► AE:chips_in_play
✅ FlopDrawBlinds ──────────────► gfx_hands.blinds ────────────────────[calc_level]────► AE:level
```

---

### [chip_display] Chips In Play x4 (4 slots) ✅ GFX 전용

| GFX JSON | 변환1 | Supabase DB | 변환2 | AE Field |
|----------|-------|-------------|-------|----------|
| ✅ `Players[].EndStackAmt` | `SUM` | `gfx_hand_players.end_stack_amt` | `format_chips` | `chips_in_play` |
| ✅ `FlopDrawBlinds` | - | `gfx_hands.blinds` | `calc_level` | `level` |

```
(동일 구조: Chips In Play x3)
```

---

### [chip_display] Chip Comparison (v2.0) ✅ GFX 전용

| GFX JSON | 변환1 | Supabase DB | 변환2 | AE Field |
|----------|-------|-------------|-------|----------|
| ✅ `Players[selected].EndStackAmt` | `÷ SUM(all)` | `gfx_hand_players.end_stack_amt` | `format_percent` | `selected_player_%` |
| ✅ `Players[others].EndStackAmt` | `SUM - selected` | `gfx_hand_players.end_stack_amt` | `format_percent` | `others_%` |

```
✅ Players[selected].EndStackAmt ► (선택 ÷ SUM) ──────────────[format_percent]───► AE:selected_player_%
✅ Players[others].EndStackAmt ──► (SUM - 선택) ÷ SUM ────────[format_percent]───► AE:others_%
```

---

### [chip_display] Chip Flow (v2.0) ✅ GFX 전용

| GFX JSON | 변환1 | Supabase DB | 변환2 | AE Field |
|----------|-------|-------------|-------|----------|
| ✅ `Players[].Name` | - | `gfx_hand_players.player_name` | `UPPER` | `player_name` |
| ✅ `Players[].EndStackAmt` (history) | `MAX` | `gfx_hand_players.end_stack_amt` | `format_chips` | `max_label` |
| ✅ `Players[].EndStackAmt` (history) | `MIN` | `gfx_hand_players.end_stack_amt` | `format_chips` | `min_label` |
| ✅ `Players[].EndStackAmt` (10핸드) | `ARRAY_AGG` | (최근 10핸드 히스토리) | - | `chips_10h[]` |
| ✅ `Players[].EndStackAmt` (20핸드) | `ARRAY_AGG` | (최근 20핸드 히스토리) | - | `chips_20h[]` |
| ✅ `Players[].EndStackAmt` (30핸드) | `ARRAY_AGG` | (최근 30핸드 히스토리) | - | `chips_30h[]` |

```
✅ Players[].Name ──────────────► gfx_hand_players.player_name ──[UPPER]────────────► AE:player_name
✅ Players[].EndStackAmt ───────► MAX(history.end_stack_amt) ───[format_chips]─────► AE:max_label
✅ Players[].EndStackAmt ───────► MIN(history.end_stack_amt) ───[format_chips]─────► AE:min_label
✅ Players[].EndStackAmt ───────► (최근 10핸드 히스토리) ───────────────────────────► AE:chips_10h[]
✅ Players[].EndStackAmt ───────► (최근 20핸드 히스토리) ───────────────────────────► AE:chips_20h[]
✅ Players[].EndStackAmt ───────► (최근 30핸드 히스토리) ───────────────────────────► AE:chips_30h[]
```

---

### [payout] Payouts (9 slots) ❌ WSOP+ 전용

| GFX JSON | 변환1 | Supabase DB | 변환2 | AE Field |
|----------|-------|-------------|-------|----------|
| ❌ N/A | - | `wsop_events.payouts[].place` | - | `rank` |
| ❌ N/A | - | `wsop_events.payouts[].amount` | `format_currency` | `prize` |
| ❌ N/A | - | `wsop_events.event_name` | - | `event_name` |

```
❌ N/A ─────────────────────────► wsop_events.payouts[].place ──────────────────────► AE:rank
❌ N/A ─────────────────────────► wsop_events.payouts[].amount ──[format_currency]─► AE:prize
❌ N/A ─────────────────────────► wsop_events.event_name ───────────────────────────► AE:event_name
```

---

### [payout] Payouts 등수 바꾸기 가능 (11 slots) ❌ WSOP+ 전용

| GFX JSON | 변환1 | Supabase DB | 변환2 | AE Field |
|----------|-------|-------------|-------|----------|
| ❌ N/A | - | `wsop_events.payouts[start:start+9].place` | - | `rank` |
| ❌ N/A | - | `wsop_events.payouts[start:start+9].amount` | `format_currency` | `prize` |
| ❌ N/A | - | `wsop_events.event_name` | - | `event_name` |
| ❌ N/A (파라미터) | - | - | - | `start_rank` |

```
❌ N/A ─────────────────────────► wsop_events.payouts[start:+9].place ──────────────► AE:rank
❌ N/A ─────────────────────────► wsop_events.payouts[start:+9].amount ─[format_$]─► AE:prize
❌ N/A ─────────────────────────► wsop_events.event_name ───────────────────────────► AE:event_name
❌ (파라미터) ──────────────────────────────────────────────────────────────────────► AE:start_rank
```

---

### [payout] _Mini Payout (9 slots) ⚠️ 혼합 (GFX name/chips/rank + WSOP+ prize)

| GFX JSON | 변환1 | Supabase DB | 변환2 | AE Field |
|----------|-------|-------------|-------|----------|
| ✅ `Players[].Name` | - | `gfx_hand_players.player_name` | `UPPER` | `name` |
| ✅ `Players[].EndStackAmt` | - | `gfx_hand_players.end_stack_amt` | `format_chips` | `chips` |
| ✅ `Players[].EliminationRank` | - | `gfx_hand_players.elimination_rank` | - | `rank` |
| ❌ N/A | - | `wsop_events.payouts[rank].amount` | `format_currency` | `prize` |

```
✅ Players[].Name ──────────────► gfx_hand_players.player_name ──[UPPER]────────────► AE:name
✅ Players[].EndStackAmt ───────► gfx_hand_players.end_stack_amt ──[format_chips]──► AE:chips
✅ Players[].EliminationRank ───► gfx_hand_players.elimination_rank ────────────────► AE:rank
❌ N/A ─────────────────────────► wsop_events.payouts[rank].amount ─[format_$]─────► AE:prize
```

---

### [event_info] Event info ❌ WSOP+ 전용

| GFX JSON | 변환1 | Supabase DB | 변환2 | AE Field |
|----------|-------|-------------|-------|----------|
| ❌ N/A | - | `wsop_events.buy_in` | `format_currency` | `buy_in` |
| ❌ N/A | - | `wsop_events.total_prize_pool` | `format_currency` | `total_prize_pool` |
| ❌ N/A | - | `wsop_events.entrants` | `format_number` | `entrants` |
| ❌ N/A | - | `wsop_events.places_paid` | `format_number` | `places_paid` |

```
❌ N/A ─────────────────────────► wsop_events.buy_in ──────────[format_currency]───► AE:buy_in
❌ N/A ─────────────────────────► wsop_events.total_prize_pool ─[format_currency]──► AE:total_prize_pool
❌ N/A ─────────────────────────► wsop_events.entrants ────────[format_number]─────► AE:entrants
❌ N/A ─────────────────────────► wsop_events.places_paid ─────[format_number]─────► AE:places_paid
```

---

### [event_info] Event name ❌ WSOP+ 전용

| GFX JSON | 변환1 | Supabase DB | 변환2 | AE Field |
|----------|-------|-------------|-------|----------|
| ❌ N/A | - | `wsop_events.event_name` | - | `main_event_final_day` |
| ❌ N/A | - | `wsop_events.series_name` | - | `wsop_super_circuit_cyprus` |

```
❌ N/A ─────────────────────────► wsop_events.event_name ───────────────────────────► AE:main_event_final_day
❌ N/A ─────────────────────────► wsop_events.series_name ──────────────────────────► AE:wsop_super_circuit_cyprus
```

---

### [event_info] Block Transition INFO ❌ WSOP+ 전용

| GFX JSON | 변환1 | Supabase DB | 변환2 | AE Field |
|----------|-------|-------------|-------|----------|
| ❌ N/A | - | `wsop_events + (계산)` | - | `text_제목` |
| ❌ N/A | - | `wsop_events + (계산)` | - | `text_내용_2줄` |

```
❌ N/A ─────────────────────────► wsop_events + (계산) ─────────────────────────────► AE:text_제목
❌ N/A ─────────────────────────► wsop_events + (계산) ─────────────────────────────► AE:text_내용_2줄
```

---

### [event_info] Location ❌ Manual 전용

| GFX JSON | 변환1 | Supabase DB | 변환2 | AE Field |
|----------|-------|-------------|-------|----------|
| ❌ N/A (정적) | - | (정적 값) | - | `merit_royal_diamond_hotel` |

```
❌ (정적 값) ───────────────────────────────────────────────────────────────────────► AE:merit_royal_diamond_hotel
```

---

### [schedule] Broadcast Schedule (6 slots) ❌ WSOP+/Manual 전용

| GFX JSON | 변환1 | Supabase DB | 변환2 | AE Field |
|----------|-------|-------------|-------|----------|
| ❌ N/A | - | `broadcast_sessions.broadcast_date` | `format_date_short` | `date` |
| ❌ N/A | - | `broadcast_sessions.scheduled_start` | `format_time_12h` | `time` |
| ❌ N/A | - | `wsop_events.event_name` | - | `event_name` |

```
❌ N/A ─────────────────────────► broadcast_sessions.broadcast_date ─[format_date]─► AE:date
❌ N/A ─────────────────────────► broadcast_sessions.scheduled_start ─[format_12h]─► AE:time
❌ N/A ─────────────────────────► wsop_events.event_name ───────────────────────────► AE:event_name
```

---

### [staff] Commentator (2 slots) ❌ Manual 전용

| GFX JSON | 변환1 | Supabase DB | 변환2 | AE Field |
|----------|-------|-------------|-------|----------|
| ❌ N/A | - | `broadcast_staff.name` | - | `name` |
| ❌ N/A | - | `broadcast_staff.sub` | - | `sub` |
| ❌ N/A (정적) | - | (정적 값) | - | `text_제목` |

```
❌ N/A ─────────────────────────► broadcast_staff.name ──────────────────────────────► AE:name
❌ N/A ─────────────────────────► broadcast_staff.sub ───────────────────────────────► AE:sub
❌ (정적 값) ───────────────────────────────────────────────────────────────────────► AE:text_제목
```

---

### [staff] Reporter (2 slots) ❌ Manual 전용

| GFX JSON | 변환1 | Supabase DB | 변환2 | AE Field |
|----------|-------|-------------|-------|----------|
| ❌ N/A | - | `broadcast_staff.name` | - | `name` |
| ❌ N/A | - | `broadcast_staff.sub` | - | `sub` |

```
❌ N/A ─────────────────────────► broadcast_staff.name ──────────────────────────────► AE:name
❌ N/A ─────────────────────────► broadcast_staff.sub ───────────────────────────────► AE:sub
```

---

### [player_info] NAME ⚠️ 혼합 (GFX + Manual 국기)

| GFX JSON | 변환1 | Supabase DB | 변환2 | AE Field |
|----------|-------|-------------|-------|----------|
| ✅ `Players[].Name` | - | `gfx_hand_players.player_name` | `UPPER` | `name` |
| ✅ `Players[].EndStackAmt` | - | `gfx_hand_players.end_stack_amt` | `format_chips` | `chips` |
| ✅ `FlopDrawBlinds.big_blind_amt` | - | `gfx_hands.blinds.big_blind_amt` | `(÷ + format_bbs)` | `bbs` |
| ❌ N/A | - | `player_overrides.country_code` | `get_flag_path` | `국기` |

```
✅ Players[].Name ──────────────► gfx_hand_players.player_name ──[UPPER]────────────► AE:name
✅ Players[].EndStackAmt ───────► gfx_hand_players.end_stack_amt ──[format_chips]──► AE:chips
✅ FlopDrawBlinds ──────────────► gfx_hands.blinds ─────────────[÷ + format_bbs]───► AE:bbs
❌ N/A ─────────────────────────► player_overrides.country_code ──[get_flag_path]──► AE:국기
```

---

### [player_info] NAME 1줄 ⚠️ 혼합 (GFX + Manual 국기)

| GFX JSON | 변환1 | Supabase DB | 변환2 | AE Field |
|----------|-------|-------------|-------|----------|
| ✅ `Players[].Name` | - | `gfx_hand_players.player_name` | `UPPER` | `player_name` |
| ❌ N/A | - | `player_overrides.country_code` | `get_flag_path` | `국기` |

```
✅ Players[].Name ──────────────► gfx_hand_players.player_name ──[UPPER]────────────► AE:player_name
❌ N/A ─────────────────────────► player_overrides.country_code ──[get_flag_path]──► AE:국기
```

---

### [player_info] NAME 2줄 (국기 빼고) ✅ GFX 전용

| GFX JSON | 변환1 | Supabase DB | 변환2 | AE Field |
|----------|-------|-------------|-------|----------|
| ✅ `Players[].Name` | - | `gfx_hand_players.player_name` | `UPPER` | `player_name` |
| ✅ `Players[].EndStackAmt` | - | `gfx_hand_players.end_stack_amt` | `format_chips` | `chips` |
| ✅ `FlopDrawBlinds.big_blind_amt` | - | `gfx_hands.blinds.big_blind_amt` | `(÷ + format_bbs)` | `bbs` |

```
✅ Players[].Name ──────────────► gfx_hand_players.player_name ──[UPPER]────────────► AE:player_name
✅ Players[].EndStackAmt ───────► gfx_hand_players.end_stack_amt ──[format_chips]──► AE:chips
✅ FlopDrawBlinds ──────────────► gfx_hands.blinds ─────────────[÷ + format_bbs]───► AE:bbs
```

---

### [player_info] NAME 3줄+ ✅ GFX 전용

| GFX JSON | 변환1 | Supabase DB | 변환2 | AE Field |
|----------|-------|-------------|-------|----------|
| ✅ `Players[].Name` | - | `gfx_hand_players.player_name` | `UPPER` | `player_name` |
| ✅ `Players[].EndStackAmt` | - | `gfx_hand_players.end_stack_amt` | `format_chips` | `chips` |
| ✅ `FlopDrawBlinds.big_blind_amt` | - | `gfx_hands.blinds.big_blind_amt` | `(÷ + format_bbs)` | `bbs` |
| ✅ `Players[].EndStackAmt` (10핸드 전) | - | (history) | `format_chips` | `chips_10_hands_ago` |
| ✅ `Players[].VPIPPercent` | - | `gfx_hand_players.vpip_percent` | `format_percent` | `vpip` |

```
✅ Players[].Name ──────────────► gfx_hand_players.player_name ──[UPPER]────────────► AE:player_name
✅ Players[].EndStackAmt ───────► gfx_hand_players.end_stack_amt ──[format_chips]──► AE:chips
✅ FlopDrawBlinds ──────────────► gfx_hands.blinds ─────────────[÷ + format_bbs]───► AE:bbs
✅ Players[].EndStackAmt ───────► (10핸드 전 히스토리) ─────────[format_chips]─────► AE:chips_10_hands_ago
✅ Players[].VPIPPercent ───────► gfx_hand_players.vpip_percent ─[format_percent]──► AE:vpip
```

---

### [elimination] Elimination (2 slots) ⚠️ 혼합 (GFX + WSOP+/Manual)

| GFX JSON | 변환1 | Supabase DB | 변환2 | AE Field |
|----------|-------|-------------|-------|----------|
| ✅ `Players[].Name` | - | `gfx_hand_players.player_name` | `UPPER` | `name` |
| ✅ `Players[].EliminationRank` | - | `gfx_hand_players.elimination_rank` | - | `rank` |
| ❌ N/A | - | `wsop_events.payouts[rank].amount` | `format_currency` | `prize` |
| ❌ N/A | - | `player_overrides.country_code` | `get_flag_path` | `flag` |

```
✅ Players[].Name ──────────────► gfx_hand_players.player_name ──[UPPER]────────────► AE:name
✅ Players[].EliminationRank ───► gfx_hand_players.elimination_rank ────────────────► AE:rank
❌ N/A ─────────────────────────► wsop_events.payouts[rank].amount ─[format_$]─────► AE:prize
❌ N/A ─────────────────────────► player_overrides.country_code ──[get_flag_path]──► AE:flag
```

---

### [elimination] At Risk of Elimination (v2.0) ⚠️ 혼합 (GFX + WSOP+/Manual)

| GFX JSON | 변환1 | Supabase DB | 변환2 | AE Field |
|----------|-------|-------------|-------|----------|
| ✅ `Players[].Name` (최소 스택) | - | `gfx_hand_players.player_name` | `UPPER` | `player_name` |
| ❌ N/A | - | (남은 인원 기반 계산) | - | `rank` |
| ❌ N/A | - | `wsop_events.payouts[rank].amount` | `format_currency` | `prize` |
| ❌ N/A | - | `player_overrides.country_code` | `get_flag_path` | `flag` |

```
✅ Players[].Name (최소 스택) ──► gfx_hand_players.player_name ──[UPPER]────────────► AE:player_name
❌ N/A ─────────────────────────► (남은 인원 기반 예상 순위) ───────────────────────► AE:rank
❌ N/A ─────────────────────────► wsop_events.payouts[rank].amount ─[format_$]─────► AE:prize
❌ N/A ─────────────────────────► player_overrides.country_code ──[get_flag_path]──► AE:flag
```

---

### [transition] Block Transition Level-Blinds ✅ GFX 전용

| GFX JSON | 변환1 | Supabase DB | 변환2 | AE Field |
|----------|-------|-------------|-------|----------|
| ✅ `FlopDrawBlinds` | - | `gfx_hands.blinds` | `calc_level` | `level` |
| ✅ `FlopDrawBlinds` | - | `gfx_hands.blinds` | `format_blinds` | `blinds` |
| ✅ `Duration` | `parse_iso8601` | `gfx_hands.duration_seconds` | `format_duration` | `duration` |

```
✅ FlopDrawBlinds ──────────────► gfx_hands.blinds ────────────────[calc_level]────► AE:level
✅ FlopDrawBlinds ──────────────► gfx_hands.blinds ────────────────[format_blinds]─► AE:blinds
✅ Duration ────────────────────► gfx_hands.duration_seconds ──────[format_duration]► AE:duration
```

---

### [transition] NEXT STREAM STARTING SOON ❌ Manual 전용

| GFX JSON | 변환1 | Supabase DB | 변환2 | AE Field |
|----------|-------|-------------|-------|----------|
| ❌ N/A (정적) | - | (정적 값) | - | `wsop_vlogger_program` |

```
❌ (정적 값) ───────────────────────────────────────────────────────────────────────► AE:wsop_vlogger_program
```

---

## GFX JSON → DB 필드 레퍼런스

### SESSION LEVEL

```
✅ ID ─────────────────────────────────────────────────────────────────► gfx_sessions.session_id
✅ CreatedDateTimeUTC ─────────────────────────────────────────────────► gfx_sessions.session_created_at
✅ SoftwareVersion ────────────────────────────────────────────────────► gfx_sessions.software_version
✅ Type ───────────────────────────────────────────────────────────────► gfx_sessions.table_type
❌ EventTitle ─────────────────────────────────────────────────────────X (미사용, wsop_events.event_name 대체)
❌ Payouts[10] ────────────────────────────────────────────────────────X (미사용, wsop_events.payouts 대체)
```

### HAND LEVEL

```
✅ HandNum ────────────────────────────────────────────────────────────► gfx_hands.hand_num
✅ Duration ───────────────────── [parse_iso8601] ────────────────────► gfx_hands.duration_seconds
✅ StartDateTimeUTC ───────────────────────────────────────────────────► gfx_hands.start_time
✅ RecordingOffsetStart ───────── [parse_iso8601] ────────────────────► gfx_hands.recording_offset_seconds
✅ GameVariant ────────────────────────────────────────────────────────► gfx_hands.game_variant
✅ BetStructure ───────────────────────────────────────────────────────► gfx_hands.bet_structure
✅ FlopDrawBlinds ─────────────────────────────────────────────────────► gfx_hands.blinds (JSONB)
✅ NumBoards ──────────────────────────────────────────────────────────► gfx_hands.num_boards
✅ Description ────────────────────────────────────────────────────────► gfx_hands.description
   (계산) ─────────────────────── [MAX(Events.Pot)] ──────────────────► gfx_hands.pot_size
   (계산) ─────────────────────── [extract_board] ────────────────────► gfx_hands.board_cards
```

### PLAYER LEVEL (Hands[].Players[])

```
✅ PlayerNum ──────────────────────────────────────────────────────────► gfx_hand_players.seat_num
✅ Name ───────────────────────────────────────────────────────────────► gfx_hand_players.player_name
✅ LongName ───────────────────────────────────────────────────────────► gfx_players.long_name (마스터)
✅ HoleCards ──────────────────── [split(' ')] ───────────────────────► gfx_hand_players.hole_cards (TEXT[])
✅ StartStackAmt ──────────────────────────────────────────────────────► gfx_hand_players.start_stack_amt
✅ EndStackAmt ────────────────────────────────────────────────────────► gfx_hand_players.end_stack_amt
✅ CumulativeWinningsAmt ──────────────────────────────────────────────► gfx_hand_players.cumulative_winnings_amt
✅ VPIPPercent ────────────────────────────────────────────────────────► gfx_hand_players.vpip_percent
✅ PreFlopRaisePercent ────────────────────────────────────────────────► gfx_hand_players.preflop_raise_percent
✅ AggressionFrequencyPercent ─────────────────────────────────────────► gfx_hand_players.aggression_frequency_percent
✅ WentToShowDownPercent ──────────────────────────────────────────────► gfx_hand_players.went_to_showdown_percent
✅ SittingOut ─────────────────────────────────────────────────────────► gfx_hand_players.sitting_out
✅ EliminationRank ────────────────────────────────────────────────────► gfx_hand_players.elimination_rank
✅ BlindBetStraddleAmt ────────────────────────────────────────────────► gfx_hand_players.blind_bet_straddle_amt
   (계산) ─────────────────────── [end > start] ──────────────────────► gfx_hand_players.is_winner
```

### EVENT LEVEL (Hands[].Events[])

```
✅ EventType ──────────────────── ['ALL IN'→'ALL_IN'] ────────────────► gfx_events.event_type (ENUM)
✅ PlayerNum ──────────────────────────────────────────────────────────► gfx_events.player_num
✅ BetAmt ─────────────────────────────────────────────────────────────► gfx_events.bet_amt
✅ Pot ────────────────────────────────────────────────────────────────► gfx_events.pot
✅ BoardCards ─────────────────────────────────────────────────────────► gfx_events.board_cards
✅ DateTimeUTC ────────────────────────────────────────────────────────► gfx_events.event_time
```

---

## 26개 AEP 컴포지션 요약 (데이터 소스별)

### ✅ GFX 전용 (9개) - 즉시 사용 가능

| # | 컴포지션 | 카테고리 |
|---|----------|----------|
| 1 | _MAIN Mini Chip Count (flag 제외) | chip_display |
| 2 | _SUB_Mini Chip Count (flag 제외) | chip_display |
| 3 | Chips In Play x3 | chip_display |
| 4 | Chips In Play x4 | chip_display |
| 5 | Chip Comparison | chip_display |
| 6 | Chip Flow | chip_display |
| 7 | NAME 2줄 (국기 빼고) | player_info |
| 8 | NAME 3줄+ | player_info |
| 9 | Block Transition Level-Blinds | transition |

### ⚠️ GFX + WSOP+/Manual 혼합 (8개)

| # | 컴포지션 | GFX 필드 | 추가 필요 |
|---|----------|----------|----------|
| 1 | _MAIN Mini Chip Count | name, chips, bbs, rank | **flag** |
| 2 | _SUB_Mini Chip Count | name, chips, bbs, rank | **flag** |
| 3 | NAME | name, chips, bbs | **국기** |
| 4 | NAME 1줄 | player_name | **국기** |
| 5 | Elimination | name, rank | **prize, flag** |
| 6 | At Risk of Elimination | player_name | **rank, prize, flag** |
| 7 | _Mini Payout | name, chips, rank | **prize** |
| 8 | Broadcast Schedule | - | **date, time, event_name** |

### ❌ WSOP+ 전용 (5개)

| # | 컴포지션 | 필드 |
|---|----------|------|
| 1 | Payouts | rank, prize, event_name |
| 2 | Payouts 등수 바꾸기 가능 | rank, prize, event_name, start_rank |
| 3 | Event info | buy_in, prize_pool, entrants, places_paid |
| 4 | Event name | event_name, series_name |
| 5 | Block Transition INFO | text_제목, text_내용 |

### ❌ Manual 전용 (4개)

| # | 컴포지션 | 입력 방식 |
|---|----------|----------|
| 1 | Commentator | broadcast_staff |
| 2 | Reporter | broadcast_staff |
| 3 | Location | 정적 값 |
| 4 | NEXT STREAM STARTING SOON | 정적 값 |

---

## 변환 함수 목록

| 함수 | 입력 | 출력 | 예시 |
|------|------|------|------|
| `UPPER` | 'Phil Ivey' | 'PHIL IVEY' | 이름 대문자 |
| `format_chips` | 1500000 | '1,500,000' | 칩 포맷 |
| `format_bbs` | (150000, 2000) | '75.0' | BB 비율 |
| `format_currency` | 100000000 | '$1,000,000' | 통화 (cents→dollars) |
| `format_percent` | 0.455 | '45.5%' | 백분율 |
| `format_number` | 1234 | '1,234' | 숫자 포맷 |
| `format_date_short` | 2026-01-14 | 'Jan 14' | 날짜 단축 |
| `format_time_12h` | 17:30 | '05:30 PM' | 12시간제 |
| `format_blinds` | (10000, 20000, 20000) | '10K/20K (20K)' | 블라인드 |
| `format_duration` | 2137 | '35:37' | 시간 포맷 |
| `calc_level` | blinds JSONB | 15 | 블라인드→레벨 계산 |
| `get_flag_path` | 'KR' | 'Flag/Korea.png' | 국기 경로 |
| `parse_iso8601` | 'PT35M37S' | 2137 | ISO → 초 |
| `split(' ')` | '10d 9d' | ['10d', '9d'] | 홀카드 분리 |
| `extract_board` | Events[] | ['Ah', 'Kd', '5c', '2s', '9h'] | 보드 추출 |

---

## 미사용 GFX 필드

| 테이블 | 컬럼 | 대체 |
|--------|------|------|
| gfx_sessions | event_title | wsop_events.event_name |
| gfx_sessions | payouts | wsop_events.payouts |

---

## 관련 문서

- `docs/02-GFX-JSON-DB.md` - GFX 스키마 설계
- `docs/07-Supabase-Orchestration.md` - 오케스트레이션 스키마 설계
- `docs/08-GFX-AEP-Mapping.md` - AEP 매핑 명세
- `docs/GFX_SUPABASE_CUESHEET_MAPPING.md` - 3계층 매핑 통합
