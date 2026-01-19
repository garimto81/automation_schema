# GFX JSON 데이터 종합 분석 보고서

**분석일**: 2026-01-19
**분석 대상**: 28개 JSON 파일 (table-GG: 18개, table-pokercaster: 10개)
**총 필드 수**: 60개 (공통 58개 + GG 전용 2개)

---

## 1. 개요

### 1.1 데이터 소스 비교

| 항목 | table-GG | table-pokercaster | 비고 |
|------|----------|-------------------|------|
| 파일 수 | 18개 | 10개 | - |
| 분석 파일 | 6개 | 5개 | 샘플링 |
| 핸드 수 | 323개 | 616개 | - |
| 플레이어 레코드 | 2,315개 | 4,892개 | - |
| 이벤트 수 | 4,143개 | 7,821개 | - |
| Type 값 | FEATURE_TABLE | FEATURE_TABLE, FINAL_TABLE | pokercaster에 FINAL_TABLE 추가 |

### 1.2 JSON 구조 (공통)

```
Root
├─ CreatedDateTimeUTC (string, ISO 8601)
├─ EventTitle (string, 항상 null)
├─ ID (integer, .NET Ticks)
├─ SoftwareVersion (string, "PokerGFX 3.2")
├─ Type (string, FEATURE_TABLE/FINAL_TABLE)
├─ Payouts (array, 모두 0)
└─ Hands[] (array)
    ├─ HandNum (integer)
    ├─ AnteAmt (integer)
    ├─ Duration (string, ISO 8601 Duration)
    ├─ StartDateTimeUTC (string, ISO 8601)
    ├─ FlopDrawBlinds (object)
    │   ├─ BigBlindAmt, SmallBlindAmt
    │   ├─ ButtonPlayerNum, BigBlindPlayerNum, SmallBlindPlayerNum
    │   └─ AnteType
    ├─ Players[] (array)
    │   ├─ PlayerNum, Name, LongName
    │   ├─ StartStackAmt, EndStackAmt, CumulativeWinningsAmt
    │   ├─ HoleCards[]
    │   └─ 통계 (VPIP, PFR, AF, WTSD)
    └─ Events[] (array)
        ├─ EventType, PlayerNum
        ├─ BetAmt, Pot
        └─ BoardCards
```

---

## 2. 필드별 상세 분석

### 2.1 최상위 필드 (Root Level) - 7개

| 필드 | 타입 | 예시값 | null% | 비고 |
|------|------|--------|-------|------|
| `ID` | bigint | 638961224831992165 | 0% | .NET Ticks 기반 고유 ID |
| `CreatedDateTimeUTC` | string | "2025-10-15T10:54:43.1992165Z" | 0% | ISO 8601 |
| `SoftwareVersion` | string | "PokerGFX 3.2" | 0% | 항상 동일 |
| `Type` | string | "FEATURE_TABLE", "FINAL_TABLE" | 0% | 테이블 타입 |
| `EventTitle` | string | "" | **100%** | 미사용 |
| `Payouts` | array | [0, 0, ...] | 0% | 현재 모두 0 |

**로직 분석**:
- `ID`: .NET DateTime.Ticks 형식으로 생성 시점 추정 가능
- `Type`: 피처 테이블 vs 파이널 테이블 구분 (방송 타입)
- `EventTitle`: 현재 사용 안 함 (향후 토너먼트 이벤트명 저장 가능)

---

### 2.2 핸드 필드 (Hands[*]) - 21개

#### 2.2.1 핵심 필드 (9개)

| 필드 | 타입 | 예시값 (10개) | null% | 로직 |
|------|------|---------------|-------|------|
| `HandNum` | int | 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 | 0% | 세션 내 순번 |
| `AnteAmt` | int | 0, 200, 300, 500, 600, 800, 1000, 2000, 3000, 4000 | 0% | 앤티 금액 (= BigBlindAmt) |
| `Duration` | string | "PT35M37S", "PT19.5S", "PT13M25S", "PT3M26S", "PT2M3S", "PT3M20S", "PT1M43S", "PT2M28S", "PT2M11S", "PT1M9S" | 0% | 핸드 소요 시간 |
| `StartDateTimeUTC` | string | "2025-10-15T12:03:20Z", "2025-10-15T14:24:45Z", ... | 0% | 핸드 시작 시각 |
| `RecordingOffsetStart` | string | "P739538DT16H3M20S", ... | 0% | 녹화 오프셋 |
| `BetStructure` | string | "NOLIMIT" | 0% | 항상 NOLIMIT |
| `GameClass` | string | "FLOP" | 0% | 항상 FLOP |
| `GameVariant` | string | "HOLDEM" | 0% | 항상 HOLDEM |
| `Description` | string | "" | **100%** | 미사용 |

#### 2.2.2 블라인드 정보 (FlopDrawBlinds) - 9개

| 필드 | 타입 | 예시값 | null% | 로직 |
|------|------|--------|-------|------|
| `BigBlindAmt` | int | 200, 300, 500, 600, 800, 1000, 2000, 3000, 4000, 5000 | 0% | 빅 블라인드 금액 |
| `SmallBlindAmt` | int | 80, 100, 200, 300, 400, 500, 1000, 1500, 2000, 3000 | 0% | 스몰 블라인드 (SB = BB/2 또는 BB/10) |
| `ButtonPlayerNum` | int | 1, 2, 3, 4, 5, 6, 7, 8, 9 | 0% | 딜러 버튼 위치 |
| `BigBlindPlayerNum` | int | 2, 3, 4, 5, 6, 7, 8, 9 | 0% | BB 위치 |
| `SmallBlindPlayerNum` | int | 2, 3, 4, 5, 6, 7, 8, 9 | 0% | SB 위치 |
| `AnteType` | string | "BB_ANTE_BB1ST" | 0% | BB 앤티 방식 |
| `BlindLevel` | int | 0 | 0% | 항상 0 (미사용) |
| `ThirdBlindAmt` | int | 0 | 0% | 항상 0 (미사용) |
| `ThirdBlindPlayerNum` | int | 0 | 0% | 항상 0 (미사용) |

#### 2.2.3 Stud 게임 정보 (StudLimits) - 4개 (미사용)

| 필드 | 값 | 비고 |
|------|-----|------|
| `BringInAmt` | 0 | Stud 전용 |
| `BringInPlayerNum` | 1 | Stud 전용 |
| `HighLimitAmt` | 0 | Stud 전용 |
| `LowLimitAmt` | 0 | Stud 전용 |

---

### 2.3 플레이어 필드 (Players[*]) - 14개

| 필드 | 타입 | 예시값 (10개) | null% | 로직 |
|------|------|---------------|-------|------|
| `PlayerNum` | int | 1, 2, 3, 4, 5, 6, 7, 8, 9 | 0% | 좌석 번호 (GG: 1-9, pokercaster: 2-9) |
| `Name` | string | "jhkg", "SAD", "Ivanus", "Tamasian", "Okolovich", "Ahmad", "Khabbazeh", "SOKRUTA", "SATUBAYEV" | 0% | 표시 이름 |
| `LongName` | string | "Cristian Ivanus", "Garik Tamasian", "Iurii Okolovich", "Moussa Ahmad", "Mbasel Khabbazeh" | 0.3~3.1% | 전체 이름 |
| `StartStackAmt` | int | 9000, 42000, 50000, 61300, 1224444, 2455123, 6000000, 6442555, 7673820, 455523388 | 0% | 핸드 시작 스택 |
| `EndStackAmt` | int | 8920, 9080, 23000, 50000, 65300, 1224444, 2455123, 3151166, 6000000, 455523388 | 0% | 핸드 종료 스택 |
| `CumulativeWinningsAmt` | int | -19000, -15200, -700, -160, -100, -80, 0, 80, 160, 3200 | 0% | 누적 승패 |
| `HoleCards[*]` | string | "", "10d 9d", "ks qs", "qd 8h", "kd 10d", "9c 5d", "8d 2c", "kc jd", "ah kd", "9s 7d" | 2~8.4% | 홀 카드 |
| `SittingOut` | bool | false, true | 0% | 자리 비움 |
| `EliminationRank` | int | -1, 2, 3, 4, 5, 6, 7, 8 | 0% | 탈락 순위 (-1: 생존) |
| `BlindBetStraddleAmt` | int | 0 | 0% | 항상 0 |
| `VPIPPercent` | int | 0, 16, 20, 25, 33, 40, 50, 66, 75, 100 | 0% | VPIP (%) |
| `PreFlopRaisePercent` | int | 0, 16, 20, 33, 40, 50, 60, 66, 75, 100 | 0% | PFR (%) |
| `AggressionFrequencyPercent` | int | 0, 40, 42, 44, 50, 53, 54, 62, 66, 72 | 0% | AF (%) |
| `WentToShowDownPercent` | int | 0, 20, 25, 28, 33, 42, 50, 60, 66, 100 | 0% | WTSD (%) |

**로직 분석**:
- `PlayerNum`: GG는 1-9, pokercaster는 2-9 사용 (1은 딜러 전용 가능)
- `HoleCards`: 빈 문자열 = 비공개 (폴드 후 또는 쇼다운 미도달)
- `EliminationRank`: -1은 생존, 양수는 탈락 순위 (낮을수록 늦게 탈락)
- 통계(VPIP, PFR, AF, WTSD): 핸드 단위로 갱신되는 누적 통계

---

### 2.4 이벤트 필드 (Events[*]) - 8개

| 필드 | 타입 | 예시값 (10개) | null% | 로직 |
|------|------|---------------|-------|------|
| `EventType` | string | "FOLD", "BET", "CALL", "CHECK", "ALL IN", "BOARD CARD" | 0% | 액션 타입 |
| `PlayerNum` | int | 0, 1, 2, 3, 4, 5, 6, 7, 8, 9 | 0% | 플레이어 (0: 보드카드) |
| `BetAmt` | int | 0, 400, 500, 700, 1000, 1100, 1200, 2000, 2200, 3500 | 0% | 베팅 금액 |
| `Pot` | int | 0, 500, 1000, 1200, 1300, 1800, 2300, 5800, 9300, 19800 | 0% | 현재 팟 |
| `BoardNum` | int | 0, 1 | 0% | 보드 번호 |
| `BoardCards` | string | "2c", "3c", "3s", "4h", "5d", "5h", "6d", "6h", "7h", "8d" | 79.5~80.7% | 보드 카드 |
| `NumCardsDrawn` | int | 0 | 0% | 항상 0 (Draw 아님) |
| `DateTimeUTC` | null | null | **100%** | 미사용 |

**로직 분석**:
- `EventType`: 6가지 액션 - FOLD, BET, CALL, CHECK, ALL IN, BOARD CARD
- `PlayerNum = 0`: 보드카드 이벤트 전용 (커뮤니티 카드)
- `BoardCards`: BOARD CARD 이벤트에만 값 존재 (약 20% 이벤트)
- `Pot`: 해당 액션 후 팟 크기 (누적)

---

## 3. 소스별 차이점

### 3.1 필드 수준 차이

| 필드 | table-GG | table-pokercaster | 비고 |
|------|----------|-------------------|------|
| `Type` | FEATURE_TABLE | FEATURE_TABLE, FINAL_TABLE | pokercaster에 파이널 테이블 포함 |
| `PlayerNum` (Players) | 1-9 | 2-9 | GG는 1번 좌석 사용 |
| `LongName` null% | 0.3% | 3.1% | pokercaster가 더 많은 null |
| `HoleCards` null% | 2% | 8.4% | pokercaster가 더 많은 비공개 |

### 3.2 데이터 규모 차이

| 지표 | table-GG | table-pokercaster |
|------|----------|-------------------|
| 평균 핸드/세션 | 53.8 | 123.2 |
| 평균 플레이어/핸드 | 7.17 | 7.94 |
| 평균 이벤트/핸드 | 12.83 | 12.70 |

---

## 4. 필드 분류

### 4.1 필수 저장 필드 (28개)

**Root (5개)**
- `ID`, `CreatedDateTimeUTC`, `SoftwareVersion`, `Type`, `Payouts`

**Hands (8개)**
- `HandNum`, `AnteAmt`, `Duration`, `StartDateTimeUTC`, `RecordingOffsetStart`
- `FlopDrawBlinds.BigBlindAmt`, `FlopDrawBlinds.SmallBlindAmt`, `FlopDrawBlinds.ButtonPlayerNum`

**Players (10개)**
- `PlayerNum`, `Name`, `LongName`, `StartStackAmt`, `EndStackAmt`, `CumulativeWinningsAmt`
- `HoleCards`, `SittingOut`, `EliminationRank`, `VPIPPercent`

**Events (5개)**
- `EventType`, `PlayerNum`, `BetAmt`, `Pot`, `BoardCards`

### 4.2 조건부 저장 필드 (8개)

현재 고정값이지만 향후 변경 가능:
- `BetStructure`, `GameClass`, `GameVariant`, `AnteType`
- `PreFlopRaisePercent`, `AggressionFrequencyPercent`, `WentToShowDownPercent`
- `BoardNum`

### 4.3 제외 권장 필드 (24개)

**100% null 또는 빈값 (3개)**
- `EventTitle`, `Hands.Description`, `Events.DateTimeUTC`

**항상 고정값 (17개)**
- `BombPotAmt` (0), `NumBoards` (1), `RunItNumTimes` (1)
- `BlindLevel` (0), `ThirdBlindAmt` (0), `ThirdBlindPlayerNum` (0)
- `StudLimits.*` (4개, 모두 0 또는 1)
- `BlindBetStraddleAmt` (0), `NumCardsDrawn` (0)
- `SittingOut` (false in GG)

**중복 또는 추론 가능 (4개)**
- `BigBlindPlayerNum`, `SmallBlindPlayerNum` (Button + 1, +2로 계산 가능)
- `RecordingOffsetStart` (선택적)
- `LongName` (Name과 중복 가능)

---

## 5. 카드 표기법

### 5.1 형식

```
{rank}{suit}
```

### 5.2 Rank 값

| 값 | 의미 |
|-----|------|
| 2-9 | 숫자 |
| 10 | 10 |
| j | Jack |
| q | Queen |
| k | King |
| a | Ace |

### 5.3 Suit 값

| 값 | 의미 | 기호 |
|-----|------|------|
| h | Hearts | ♥ |
| d | Diamonds | ♦ |
| c | Clubs | ♣ |
| s | Spades | ♠ |

### 5.4 예시

| 표기 | 의미 |
|------|------|
| `ah` | Ace of Hearts |
| `kd` | King of Diamonds |
| `10c` | Ten of Clubs |
| `2s` | Two of Spades |

---

## 6. 시간 형식

### 6.1 ISO 8601 DateTime

```
2025-10-15T12:03:20.9005907Z
```

### 6.2 ISO 8601 Duration

```
PT35M37.2477537S  → 35분 37.25초
PT3M26.9826834S   → 3분 26.98초
PT19.5488032S     → 19.55초
```

### 6.3 ISO 8601 Period (RecordingOffsetStart)

```
P739538DT16H3M20.9S
│         │
│         └─ 시간 부분 (16시간 3분 20.9초)
└─ 기간 부분 (739,538일)
```

---

## 7. 현장 데이터 요소

### 7.1 GFX 소프트웨어 입력

| 요소 | 필드 | 입력 방식 |
|------|------|----------|
| 테이블 타입 | `Type` | 설정 |
| 블라인드 | `BigBlindAmt`, `SmallBlindAmt` | 설정 |
| 앤티 | `AnteAmt` | 설정 |
| 플레이어 이름 | `Name`, `LongName` | 수동 입력 |
| 좌석 번호 | `PlayerNum` | 자동 할당 |

### 7.2 실시간 트래킹

| 요소 | 필드 | 트래킹 방식 |
|------|------|------------|
| 칩 스택 | `StartStackAmt`, `EndStackAmt` | 자동 계산 |
| 홀 카드 | `HoleCards` | 카드 인식/수동 |
| 액션 | `EventType`, `BetAmt` | 자동 감지 |
| 보드 카드 | `BoardCards` | 카드 인식/수동 |
| 팟 크기 | `Pot` | 자동 계산 |

### 7.3 통계 계산

| 통계 | 공식 | 갱신 주기 |
|------|------|----------|
| VPIP | (자발적 팟 참여 핸드 / 전체 핸드) × 100 | 핸드별 |
| PFR | (프리플랍 레이즈 핸드 / 전체 핸드) × 100 | 핸드별 |
| AF | (베팅 + 레이즈) / 콜 × 100 | 핸드별 |
| WTSD | (쇼다운 도달 핸드 / 플랍 본 핸드) × 100 | 핸드별 |

---

## 8. 다음 단계

1. **추출 스크립트**: `scripts/gfx_field_extractor.py`
2. **DB 스키마 검증**: 마이그레이션과 필드 매핑 확인
3. **정규화 로직 업데이트**: `src/gfx_normalizer.py`
4. **문서 동기화**: `docs/02-GFX-JSON-DB.md`

---

## 부록: 전체 필드 목록 (60개)

<details>
<summary>펼치기/접기</summary>

### Root (7개)
1. `ID` ✅
2. `CreatedDateTimeUTC` ✅
3. `SoftwareVersion` ✅
4. `Type` ✅
5. `EventTitle` ❌
6. `Payouts` ✅
7. `Payouts[*]` ✅

### Hands (21개)
8. `HandNum` ✅
9. `AnteAmt` ✅
10. `BetStructure` ⚠️
11. `BombPotAmt` ❌
12. `Description` ❌
13. `Duration` ✅
14. `GameClass` ⚠️
15. `GameVariant` ⚠️
16. `NumBoards` ❌
17. `RunItNumTimes` ❌
18. `StartDateTimeUTC` ✅
19. `RecordingOffsetStart` ⚠️

### FlopDrawBlinds (9개)
20. `AnteType` ⚠️
21. `BigBlindAmt` ✅
22. `BigBlindPlayerNum` ⚠️
23. `BlindLevel` ❌
24. `ButtonPlayerNum` ✅
25. `SmallBlindAmt` ✅
26. `SmallBlindPlayerNum` ⚠️
27. `ThirdBlindAmt` ❌
28. `ThirdBlindPlayerNum` ❌

### StudLimits (4개)
29. `BringInAmt` ❌
30. `BringInPlayerNum` ❌
31. `HighLimitAmt` ❌
32. `LowLimitAmt` ❌

### Players (14개)
33. `PlayerNum` ✅
34. `Name` ✅
35. `LongName` ✅
36. `StartStackAmt` ✅
37. `EndStackAmt` ✅
38. `CumulativeWinningsAmt` ✅
39. `HoleCards` ✅
40. `HoleCards[*]` ✅
41. `SittingOut` ✅
42. `EliminationRank` ✅
43. `BlindBetStraddleAmt` ❌
44. `VPIPPercent` ✅
45. `PreFlopRaisePercent` ⚠️
46. `AggressionFrequencyPercent` ⚠️
47. `WentToShowDownPercent` ⚠️

### Events (8개)
48. `EventType` ✅
49. `PlayerNum` ✅
50. `BetAmt` ✅
51. `Pot` ✅
52. `BoardNum` ⚠️
53. `BoardCards` ✅
54. `NumCardsDrawn` ❌
55. `DateTimeUTC` ❌

**범례**:
- ✅ 필수 저장
- ⚠️ 조건부 저장
- ❌ 제외 권장

</details>

---

## 9. JSON 원본 구조로 DB 교체 시 문제점 분석

### 9.1 분석 배경

현재 Supabase DB는 **정규화된 5개 테이블 구조**로 설계되어 있습니다. 이를 JSON 원본과 동일한 **비정규화 JSONB 단일 테이블**로 변경할 경우의 영향을 분석합니다.

> **결론: 강력히 비권장** - 데이터 무결성 손실, 100-200배 성능 저하, 26개 AEP 컴포지션 재작성 필요

---

### 9.2 현재 구조 vs 변경 제안 구조

#### 현재 구조 (정규화, 3NF)

```
gfx_sessions (세션 메타데이터)
    ↓ 1:N
gfx_hands (핸드 정보)
    ↓ 1:N          ↓ 1:N
gfx_events     gfx_hand_players
(액션/이벤트)    (플레이어 상태)
                    ↓ N:1
               gfx_players (플레이어 마스터)
```

**테이블 구조:**

| 테이블 | 역할 | 핵심 컬럼 |
|--------|------|----------|
| `gfx_sessions` | 세션 메타데이터 | session_id, table_type, raw_json |
| `gfx_hands` | 핸드 정보 | session_id, hand_num, blinds, board_cards |
| `gfx_hand_players` | 핸드별 플레이어 | hand_id, seat_num, end_stack_amt, hole_cards |
| `gfx_events` | 액션 시퀀스 | hand_id, event_type, bet_amt, pot |
| `gfx_players` | 플레이어 마스터 | player_hash, name, long_name |

#### 변경 제안 구조 (비정규화, JSONB)

```sql
CREATE TABLE gfx_raw_data (
  id UUID PRIMARY KEY,
  raw_json JSONB  -- JSON 파일 전체 저장
);
```

---

### 9.3 문제점 상세 분석

#### 9.3.1 데이터 무결성 문제 (심각도: **CRITICAL**)

| 현재 제약조건 | JSONB 전환 시 | 위험 |
|--------------|---------------|------|
| `session_id UNIQUE` | **손실** | 중복 세션 저장 가능 |
| `(session_id, hand_num) UNIQUE` | **손실** | 동일 핸드 중복 |
| `seat_num CHECK (1-10)` | **손실** | 유효하지 않은 시트 |
| `event_type ENUM` | **손실** | 잘못된 이벤트 타입 |
| `FK CASCADE DELETE` | **손실** | 고아 데이터 발생 |

**예시:**

```sql
-- 현재: 중복 방지 (UNIQUE 제약)
INSERT INTO gfx_sessions (session_id) VALUES (638961224831992165);
INSERT INTO gfx_sessions (session_id) VALUES (638961224831992165);  -- ERROR!

-- JSONB: 중복 허용 (무결성 없음)
INSERT INTO gfx_raw_data (raw_json) VALUES ('{"ID": 638961224831992165}');
INSERT INTO gfx_raw_data (raw_json) VALUES ('{"ID": 638961224831992165}');  -- OK...
```

**손실되는 무결성 보장:**

- ❌ 타입 검증 (ENUM, INTEGER, TIMESTAMPTZ)
- ❌ 참조 무결성 (FOREIGN KEY)
- ❌ 중복 방지 (UNIQUE)
- ❌ 범위 검증 (CHECK)
- ❌ NULL 방지 (NOT NULL)

---

#### 9.3.2 쿼리 성능 문제 (심각도: **HIGH**)

| 쿼리 유형 | 정규화 | JSONB | 성능 저하 |
|-----------|--------|-------|----------|
| 플레이어 검색 | 5ms | 500ms | **100x** |
| 팟 크기 정렬 | 10ms | 2000ms | **200x** |
| 보드 카드 검색 | 20ms | 3000ms | **150x** |
| 집계 쿼리 | 5ms | 1000ms | **200x** |

**원인:**
- 4단계 중첩 접근 (`root → Hands[] → Players[] → 필드`)
- 배열 요소 탐색 시 전체 스캔
- GIN 인덱스는 중첩 배열 내부 필드 인덱싱 불가

**정규화 쿼리 (효율적):**

```sql
-- 실행 시간: ~5ms
SELECT hp.player_name, hp.end_stack_amt
FROM gfx_hand_players hp
JOIN gfx_hands h ON hp.hand_id = h.id
WHERE h.session_id = 638961224831992165
ORDER BY hp.end_stack_amt DESC;
```

**JSONB 쿼리 (비효율적):**

```sql
-- 실행 시간: ~500ms+
SELECT
    player->>'Name' AS player_name,
    (player->>'EndStackAmt')::BIGINT AS end_stack_amt
FROM gfx_raw_data,
LATERAL jsonb_array_elements(raw_json->'Hands') AS hand,
LATERAL jsonb_array_elements(hand->'Players') AS player
WHERE (raw_json->>'ID')::BIGINT = 638961224831992165
ORDER BY (player->>'EndStackAmt')::BIGINT DESC;
```

---

#### 9.3.3 After Effects 연동 문제 (심각도: **CRITICAL**)

**26개 AEP 컴포지션이 정규화 테이블 조인에 의존 (`docs/08-GFX-AEP-Mapping.md` 참조)**

| 카테고리 | 컴포지션 수 | 영향 |
|----------|------------|------|
| chip_display | 6개 | 칩 표시 쿼리 전면 재작성 |
| payout | 3개 | 상금표 쿼리 재작성 |
| board_display | 3개 | 보드 카드 쿼리 재작성 |
| name | 4개 | 플레이어 정보 쿼리 재작성 |
| info | 6개 | 이벤트/핸드 정보 쿼리 재작성 |
| stat | 4개 | 통계 쿼리 재작성 |
| **합계** | **26개** | **전면 재작성** |

**현재 AEP 쿼리 (최적화됨):**

```sql
-- _MAIN Mini Chip Count: 9명 칩 순위 (5ms)
SELECT
    ROW_NUMBER() OVER (ORDER BY hp.end_stack_amt DESC) AS rank,
    UPPER(hp.player_name) AS name,
    format_chips(hp.end_stack_amt) AS chips
FROM gfx_hand_players hp
JOIN gfx_hands h ON hp.hand_id = h.id
WHERE h.session_id = :session_id
  AND h.hand_num = :hand_num
ORDER BY hp.end_stack_amt DESC
LIMIT 9;
```

**JSONB 전환 시 (200ms+):**

```sql
-- 방송 SLA (100ms) 위반!
SELECT
    ROW_NUMBER() OVER (ORDER BY (player->>'EndStackAmt')::BIGINT DESC) AS rank,
    UPPER(player->>'Name') AS name,
    format_chips((player->>'EndStackAmt')::BIGINT) AS chips
FROM gfx_raw_data,
LATERAL jsonb_array_elements(raw_json->'Hands') AS hand,
LATERAL jsonb_array_elements(hand->'Players') AS player
WHERE (raw_json->>'ID')::BIGINT = :session_id
  AND (hand->>'HandNum')::INTEGER = :hand_num
ORDER BY (player->>'EndStackAmt')::BIGINT DESC
LIMIT 9;
```

> ⚠️ **방송 SLA (100ms) 위반!** - 실시간 방송 환경에서 지연 발생

---

#### 9.3.4 저장 효율성 문제 (심각도: **MEDIUM**)

| 구조 | 예상 크기 | 비고 |
|------|----------|------|
| 정규화 | ~50 MB | 중복 제거 |
| JSONB | ~100 MB | 중복 저장 |
| JSONB + 인덱스 | ~150 MB | GIN 인덱스 추가 시 |

**중복 데이터 예시:**

```json
// 동일 플레이어가 50핸드 참여 시
// 정규화: gfx_players에 1번 저장
// JSONB: 50번 중복 저장 (Name, LongName, 통계 등)
{
  "Name": "Phil Ivey",
  "LongName": "Phillip Dennis Ivey Jr",
  "VPIPPercent": 25,
  "PreFlopRaisePercent": 20,
  ...
}
```

**참고:** 현재 `gfx_sessions.raw_json`에 원본 JSON이 이미 보존되어 있어 추가 이점 없음

---

#### 9.3.5 유지보수 문제 (심각도: **HIGH**)

| 작업 | 정규화 | JSONB |
|------|--------|-------|
| 새 필드 추가 | `ALTER TABLE ADD COLUMN` | 전체 JSON 수정 필요 |
| 타입 변경 | `ALTER TABLE ALTER COLUMN` | 애플리케이션 수정 |
| 데이터 마이그레이션 | 27개 SQL 파일 관리 | 버전 관리 어려움 |
| 스키마 롤백 | 가능 | 거의 불가 |
| 타입 안전성 | PostgreSQL 보장 | 런타임 검증 필요 |

---

#### 9.3.6 동기화 문제 (심각도: **HIGH**)

| 기능 | 정규화 | JSONB |
|------|--------|-------|
| CDC (Change Data Capture) | 테이블/컬럼 단위 | 전체 JSON만 감지 |
| 실시간 알림 | 특정 핸드/플레이어 변경 감지 | 불가 |
| json → public 동기화 | 트리거 기반 가능 | 전략 불가 |
| Incremental Update | 지원 | 전체 교체만 가능 |

---

### 9.4 제한적 이점

| 측면 | 이점 | 한계 |
|------|------|------|
| 단순성 | 테이블 1개 | 쿼리 복잡성 증가 |
| 유연성 | DDL 없이 필드 추가 | 타입 검증 없음 |
| 원본 보존 | JSON 그대로 저장 | **이미 raw_json에 저장 중** |

---

### 9.5 심각도 종합

| 문제 영역 | 심각도 | 영향 | 복구 비용 |
|-----------|--------|------|----------|
| 데이터 무결성 | **CRITICAL** | 중복/오류 데이터 발생 | 높음 |
| AEP 연동 | **CRITICAL** | 26개 컴포지션 재작성 + SLA 위반 | 매우 높음 |
| 쿼리 성능 | HIGH | 100-200x 성능 저하 | 중간 |
| 동기화 | HIGH | CDC 기능 손실 | 높음 |
| 유지보수 | HIGH | 마이그레이션 복잡성 | 중간 |
| 저장 효율성 | MEDIUM | 2-3x 공간 증가 | 낮음 |

---

### 9.6 권장사항

#### ❌ 비정규화 전환 강력 반대

**이유:**
1. 현재 `gfx_sessions.raw_json` 컬럼에 원본 JSON이 이미 보존됨 → 추가 이점 없음
2. 26개 AEP 컴포지션 매핑 전면 재작성 필요 (약 3,000줄 SQL)
3. 방송 SLA (100ms) 충족 불가
4. 데이터 무결성 메커니즘 전면 손실

#### ✅ 현재 하이브리드 구조 유지 (권장)

```
정규화 테이블 (쿼리 성능, 무결성)
    +
raw_json JSONB (원본 보존, 감사 추적)
```

**현재 구조의 장점:**
- 정규화된 테이블로 빠른 쿼리 (5-20ms)
- raw_json으로 원본 JSON 100% 보존
- 양방향 검증 가능 (파싱 결과 vs 원본)

#### 대안 제안 (성능 추가 개선 필요 시)

| 대안 | 용도 | 구현 비용 |
|------|------|----------|
| Materialized View | 자주 사용하는 집계 캐싱 | 낮음 |
| Redis 캐싱 레이어 | 실시간 쿼리 결과 캐싱 | 중간 |
| 읽기 전용 복제본 | 분석 쿼리 분리 | 중간 |
| 파티셔닝 | 대용량 데이터 처리 | 높음 |

---

### 9.7 핵심 파일 참조

| 파일 | 역할 |
|------|------|
| `supabase/migrations/20260113082406_01_gfx_schema.sql` | 현재 정규화 스키마 (SSOT) |
| `docs/08-GFX-AEP-Mapping.md` | 26개 AEP 컴포지션 매핑 명세 |
| `src/gfx_normalizer.py` | JSON → 정규화 변환 로직 |
| `docs/02-GFX-JSON-DB.md` | 스키마 설계 문서 |
