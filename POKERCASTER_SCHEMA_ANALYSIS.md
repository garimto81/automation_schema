# table-pokercaster JSON 스키마 분석 최종 리포트

**분석 일시**: 2026-01-19
**분석 대상**: `C:\claude\automation_schema\gfx_json_data\table-pokercaster`
**분석 파일**: 7개 (폴더: 1016, 1017, 1018, 1019, 1021)
**총 필드 수**: 58개

---

## 핵심 발견사항

1. **table-pokercaster와 table-GG의 스키마가 100% 동일함** (58개 필드 일치)
2. **전용 필드 없음** - 두 소스 모두 동일한 PokerGFX 3.2 형식 사용
3. **통합 스키마 설계 가능** - 별도 정규화 없이 단일 테이블 구조로 통합 가능

---

## 스키마 구조 요약

### Root Level (6개 필드)

| 필드 | 타입 | 설명 | 예시 |
|------|------|------|------|
| `CreatedDateTimeUTC` | string (ISO 8601) | 세션 생성 시각 | `"2025-10-19T08:25:23.8678697Z"` |
| `EventTitle` | string | 이벤트 제목 | `""` (비어있음) |
| `Hands` | array | 핸드 배열 (113-144개) | `[{...}, {...}]` |
| `ID` | integer | 세션 고유 ID | `638964591238678697` |
| `Payouts` | array | 순위별 상금 배열 | `[0,0,0,0,0,0,0,0,0,0]` |
| `SoftwareVersion` | string | GFX 소프트웨어 버전 | `"PokerGFX 3.2"` |
| `Type` | string | 테이블 유형 | `"FEATURE_TABLE"` / `"FINAL_TABLE"` |

### Hands[] (14개 필드)

| 필드 | 타입 | 설명 | 예시 |
|------|------|------|------|
| `AnteAmt` | integer | Ante 금액 | `15000`, `200000`, `3000` |
| `BetStructure` | string | 베팅 구조 | `"NOLIMIT"` |
| `BombPotAmt` | integer | Bomb Pot 금액 | `0` |
| `Description` | string | 핸드 설명 | `""` |
| `Duration` | string (ISO 8601) | 핸드 지속 시간 | `"PT19.0628118S"` (19초) |
| `Events` | array | 이벤트 배열 | `[{...}, {...}]` |
| `GameClass` | string | 게임 클래스 | `"FLOP"` |
| `GameVariant` | string | 게임 변형 | `"HOLDEM"` |
| `HandNum` | integer | 핸드 번호 (1부터 시작) | `1`, `2`, `3` |
| `NumBoards` | integer | 보드 개수 | `1` |
| `Players` | array | 플레이어 배열 | `[{...}, {...}]` |
| `RecordingOffsetStart` | string (ISO 8601) | 녹화 시작 오프셋 | `"P739542DT11H36M21.8331582S"` |
| `RunItNumTimes` | integer | Run It 횟수 | `1` |
| `StartDateTimeUTC` | string (ISO 8601) | 핸드 시작 시각 | `"2025-10-19T08:36:21.8331582Z"` |

### Hands[].Events[] (8개 필드)

| 필드 | 타입 | 설명 | 예시 |
|------|------|------|------|
| `BetAmt` | integer | 베팅 금액 | `0`, `1000`, `6500` |
| `BoardCards` | null / array | 보드 카드 (null 가능) | `null` |
| `BoardNum` | integer | 보드 번호 | `0` |
| `DateTimeUTC` | null / string | 이벤트 시각 (null 가능) | `null` |
| `EventType` | string | 이벤트 타입 | `"BET"`, `"FOLD"` |
| `NumCardsDrawn` | integer | 드로우 카드 수 | `0` |
| `PlayerNum` | integer | 플레이어 번호 | `2`, `6`, `7` |
| `Pot` | integer | 팟 금액 | `0`, `1300`, `7500` |

### Hands[].Players[] (14개 필드)

| 필드 | 타입 | 설명 | 예시 |
|------|------|------|------|
| `AggressionFrequencyPercent` | integer | 공격 빈도 (%) | `0`, `40`, `66` |
| `BlindBetStraddleAmt` | integer | Blind/Straddle 금액 | `0` |
| `CumulativeWinningsAmt` | integer | 누적 상금 | `-19000`, `0`, `40000` |
| `EliminationRank` | integer | 탈락 순위 (-1=생존) | `-1` |
| `EndStackAmt` | integer | 핸드 종료 스택 | `1220000`, `23000` |
| `HoleCards` | array | 홀카드 배열 | `[""]` (비공개 시) |
| `LongName` | string | 플레이어 풀네임 | `"Konstantin Voronin"` |
| `Name` | string | 플레이어 이름 (대문자) | `"VORONIN"`, `"Demirkol"` |
| `PlayerNum` | integer | 플레이어 번호 (1-10) | `2`, `3`, `4` |
| `PreFlopRaisePercent` | integer | 프리플랍 레이즈 비율 (%) | `0`, `100` |
| `SittingOut` | boolean | 자리 비움 여부 | `false` |
| `StartStackAmt` | integer | 핸드 시작 스택 | `1220000`, `109500` |
| `VPIPPercent` | integer | VPIP (%) | `0`, `100` |
| `WentToShowDownPercent` | integer | 쇼다운 비율 (%) | `0`, `100` |

### Hands[].FlopDrawBlinds (9개 필드)

| 필드 | 타입 | 설명 | 예시 |
|------|------|------|------|
| `AnteType` | string | Ante 타입 | `"BB_ANTE_BB1ST"` |
| `BigBlindAmt` | integer | 빅 블라인드 금액 | `15000`, `200000`, `3000` |
| `BigBlindPlayerNum` | integer | 빅 블라인드 플레이어 번호 | `2`, `5`, `6` |
| `BlindLevel` | integer | 블라인드 레벨 | `0` |
| `ButtonPlayerNum` | integer | 버튼 플레이어 번호 | `10`, `3`, `4` |
| `SmallBlindAmt` | integer | 스몰 블라인드 금액 | `10000`, `100000`, `1500` |
| `SmallBlindPlayerNum` | integer | 스몰 블라인드 플레이어 번호 | `1`, `4`, `5` |
| `ThirdBlindAmt` | integer | 서드 블라인드 금액 | `0` |
| `ThirdBlindPlayerNum` | integer | 서드 블라인드 플레이어 번호 | `0` |

### Hands[].StudLimits (4개 필드)

| 필드 | 타입 | 설명 | 예시 |
|------|------|------|------|
| `BringInAmt` | integer | Bring-In 금액 | `0` |
| `BringInPlayerNum` | integer | Bring-In 플레이어 번호 | `1` |
| `HighLimitAmt` | integer | 하이 리미트 금액 | `0` |
| `LowLimitAmt` | integer | 로우 리미트 금액 | `0` |

---

## DB 스키마 매핑 (기존 `docs/02-GFX-JSON-DB.md` 기준)

### 1. gfx_sessions (Root Level)

```sql
CREATE TABLE gfx_sessions (
    id BIGINT PRIMARY KEY,                    -- ID
    created_at TIMESTAMPTZ NOT NULL,          -- CreatedDateTimeUTC
    event_title TEXT,                         -- EventTitle
    software_version TEXT,                    -- SoftwareVersion
    session_type TEXT,                        -- Type (FEATURE_TABLE / FINAL_TABLE)
    -- Payouts는 별도 테이블로 분리 필요 시 정규화
);
```

### 2. gfx_hands (Hands[])

```sql
CREATE TABLE gfx_hands (
    id BIGSERIAL PRIMARY KEY,
    session_id BIGINT REFERENCES gfx_sessions(id),
    hand_num INT NOT NULL,                    -- HandNum
    ante_amt BIGINT,                          -- AnteAmt
    bet_structure TEXT,                       -- BetStructure
    bomb_pot_amt BIGINT,                      -- BombPotAmt
    description TEXT,                         -- Description
    duration INTERVAL,                        -- Duration (ISO 8601 -> interval)
    game_class TEXT,                          -- GameClass
    game_variant TEXT,                        -- GameVariant
    num_boards INT,                           -- NumBoards
    recording_offset_start INTERVAL,          -- RecordingOffsetStart
    run_it_num_times INT,                     -- RunItNumTimes
    started_at TIMESTAMPTZ                    -- StartDateTimeUTC
);
```

### 3. gfx_events (Hands[].Events[])

```sql
CREATE TABLE gfx_events (
    id BIGSERIAL PRIMARY KEY,
    hand_id BIGINT REFERENCES gfx_hands(id),
    bet_amt BIGINT,                           -- BetAmt
    board_cards JSONB,                        -- BoardCards (null 가능)
    board_num INT,                            -- BoardNum
    event_datetime TIMESTAMPTZ,               -- DateTimeUTC (null 가능)
    event_type TEXT,                          -- EventType
    num_cards_drawn INT,                      -- NumCardsDrawn
    player_num INT,                           -- PlayerNum
    pot BIGINT                                -- Pot
);
```

### 4. gfx_players (Hands[].Players[])

```sql
CREATE TABLE gfx_players (
    id BIGSERIAL PRIMARY KEY,
    hand_id BIGINT REFERENCES gfx_hands(id),
    player_num INT NOT NULL,                  -- PlayerNum
    name TEXT,                                -- Name
    long_name TEXT,                           -- LongName
    aggression_frequency_pct INT,             -- AggressionFrequencyPercent
    blind_bet_straddle_amt BIGINT,            -- BlindBetStraddleAmt
    cumulative_winnings_amt BIGINT,           -- CumulativeWinningsAmt
    elimination_rank INT,                     -- EliminationRank
    end_stack_amt BIGINT,                     -- EndStackAmt
    hole_cards JSONB,                         -- HoleCards
    preflop_raise_pct INT,                    -- PreFlopRaisePercent
    sitting_out BOOLEAN,                      -- SittingOut
    start_stack_amt BIGINT,                   -- StartStackAmt
    vpip_pct INT,                             -- VPIPPercent
    went_to_showdown_pct INT                  -- WentToShowDownPercent
);
```

### 5. gfx_blind_structures (Hands[].FlopDrawBlinds)

```sql
CREATE TABLE gfx_blind_structures (
    id BIGSERIAL PRIMARY KEY,
    hand_id BIGINT REFERENCES gfx_hands(id),
    ante_type TEXT,                           -- AnteType
    big_blind_amt BIGINT,                     -- BigBlindAmt
    big_blind_player_num INT,                 -- BigBlindPlayerNum
    blind_level INT,                          -- BlindLevel
    button_player_num INT,                    -- ButtonPlayerNum
    small_blind_amt BIGINT,                   -- SmallBlindAmt
    small_blind_player_num INT,               -- SmallBlindPlayerNum
    third_blind_amt BIGINT,                   -- ThirdBlindAmt
    third_blind_player_num INT                -- ThirdBlindPlayerNum
);
```

---

## 비교 분석: table-pokercaster vs table-GG

| 항목 | table-pokercaster | table-GG | 차이점 |
|------|-------------------|----------|--------|
| **총 필드 수** | 58개 | 58개 | 동일 |
| **Root Level** | 6개 | 6개 | 동일 |
| **Hands[]** | 14개 | 14개 | 동일 |
| **Events[]** | 8개 | 8개 | 동일 |
| **Players[]** | 14개 | 14개 | 동일 |
| **FlopDrawBlinds** | 9개 | 9개 | 동일 |
| **StudLimits** | 4개 | 4개 | 동일 |
| **전용 필드** | 0개 | 0개 | **없음** |
| **소프트웨어 버전** | PokerGFX 3.2 | PokerGFX 3.2 | 동일 |

**결론**: 두 소스 모두 **동일한 PokerGFX 3.2 형식**을 사용하며, 별도의 정규화 없이 **단일 통합 스키마**로 처리 가능합니다.

---

## 추천 사항

1. **통합 스키마 사용** - table-pokercaster와 table-GG를 구분할 필요 없음
2. **source 컬럼 추가** - 데이터 출처 추적을 위해 `source TEXT ('pokercaster' | 'gg')` 추가 권장
3. **Type 필드 활용** - `FEATURE_TABLE` vs `FINAL_TABLE` 구분으로 테이블 유형 필터링 가능
4. **기존 마이그레이션 재사용** - `supabase/migrations/20260101000000_gfx_json_schema.sql` 그대로 사용 가능

---

## 생성된 파일

| 파일 | 용도 |
|------|------|
| `pokercaster_schema_report.md` | Pokercaster 상세 스키마 리포트 |
| `pokercaster_fields.txt` | Pokercaster 필드 목록 (58개) |
| `gg_fields.txt` | GG 필드 목록 (58개) |
| `schema_comparison_report.md` | Pokercaster vs GG 비교 리포트 |
| `POKERCASTER_SCHEMA_ANALYSIS.md` | **최종 요약 리포트 (본 문서)** |

---

**분석 완료**: 2026-01-19
**분석 도구**: `analyze_pokercaster_schema.py`, `compare_schemas.py`
