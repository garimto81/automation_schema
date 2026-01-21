# GFX JSON 데이터 분석 리포트 (table-GG)

**분석 일자**: 2026-01-19
**소스**: table-GG
**파일 수**: 6개
**총 필드 수**: 60개

---

## 1. 전체 구조

```json
{
  "CreatedDateTimeUTC": "string",
  "EventTitle": "string",
  "Hands": "array",
  "ID": "integer",
  "Payouts": "array",
  "SoftwareVersion": "string",
  "Type": "string"
}
```

### 최상위 필드 요약

| 필드 | 타입 | 설명 |
|------|------|------|
| `CreatedDateTimeUTC` | string | 세션 생성 시각 (ISO 8601) |
| `EventTitle` | string | 이벤트 제목 (항상 빈 문자열) |
| `Hands` | array | 핸드 데이터 배열 |
| `ID` | integer | 게임 세션 고유 ID |
| `Payouts` | array | 페이아웃 배열 (모두 0) |
| `SoftwareVersion` | string | "PokerGFX 3.2" |
| `Type` | string | "FEATURE_TABLE" |

---

## 2. 핸드 데이터 구조 (`Hands[*]`)

### 2.1 핸드 메타데이터

| 필드 | 타입 | 샘플값 | null 비율 | 설명 |
|------|------|--------|-----------|------|
| `HandNum` | integer | 1, 2, 3... | 0% | 핸드 번호 |
| `StartDateTimeUTC` | string | "2025-10-15T12:03:20.9Z" | 0% | 핸드 시작 시각 |
| `Duration` | string | "PT35M37.2477537S" | 0% | 핸드 지속 시간 (ISO 8601 Duration) |
| `RecordingOffsetStart` | string | "P739538DT16H3M20.9S" | 0% | 녹화 오프셋 |
| `GameClass` | string | "FLOP" | 0% | 게임 클래스 (플롭 게임) |
| `GameVariant` | string | "HOLDEM" | 0% | 게임 변형 (홀덤) |
| `BetStructure` | string | "NOLIMIT" | 0% | 베팅 구조 (노리밋) |
| `NumBoards` | integer | 1 | 0% | 보드 수 |
| `RunItNumTimes` | integer | 1 | 0% | 런잇 횟수 |

### 2.2 블라인드 정보 (`FlopDrawBlinds`)

| 필드 | 타입 | 샘플값 | null 비율 | 설명 |
|------|------|--------|-----------|------|
| `AnteType` | string | "BB_ANTE_BB1ST" | 0% | 앤티 타입 |
| `BigBlindAmt` | integer | 800, 200, 300, 2000... | 0% | 빅 블라인드 금액 |
| `SmallBlindAmt` | integer | 80, 100, 200, 1000... | 0% | 스몰 블라인드 금액 |
| `BigBlindPlayerNum` | integer | 8, 9, 7, 2... | 0% | 빅 블라인드 플레이어 번호 |
| `SmallBlindPlayerNum` | integer | 7, 8, 5, 2... | 0% | 스몰 블라인드 플레이어 번호 |
| `ButtonPlayerNum` | integer | 1, 7, 4, 5... | 0% | 버튼 플레이어 번호 |
| `BlindLevel` | integer | 0 | 0% | 블라인드 레벨 (항상 0) |
| `ThirdBlindAmt` | integer | 0 | 0% | 서드 블라인드 금액 (항상 0) |
| `ThirdBlindPlayerNum` | integer | 0 | 0% | 서드 블라인드 플레이어 (항상 0) |

### 2.3 추가 필드

| 필드 | 타입 | 샘플값 | null 비율 | 설명 |
|------|------|--------|-----------|------|
| `AnteAmt` | integer | 0, 200, 300, 2000... | 0% | 앤티 금액 |
| `BombPotAmt` | integer | 0 | 0% | 밤팟 금액 (항상 0) |
| `Description` | string | "" | 100% | 설명 (항상 빈 문자열) |

### 2.4 Stud 게임 정보 (`StudLimits`)

**모든 값이 0** (Holdem 게임이므로 사용 안 함)

| 필드 | 타입 | 샘플값 |
|------|------|--------|
| `BringInAmt` | integer | 0 |
| `BringInPlayerNum` | integer | 1 |
| `HighLimitAmt` | integer | 0 |
| `LowLimitAmt` | integer | 0 |

---

## 3. 플레이어 데이터 (`Hands[*].Players[*]`)

총 2,315개 플레이어 레코드 분석

### 3.1 기본 정보

| 필드 | 타입 | 샘플값 | null 비율 | 설명 |
|------|------|--------|-----------|------|
| `PlayerNum` | integer | 1~9 | 0% | 플레이어 좌석 번호 |
| `Name` | string | "jhkg", "SAD", "Ivanus" | 0% | 짧은 이름 |
| `LongName` | string | "jhkg", "Cristian Ivanus" | 0.3% | 긴 이름 (일부 빈값) |
| `SittingOut` | boolean | false | 0% | 자리 비움 여부 (모두 false) |

### 3.2 칩 스택

| 필드 | 타입 | 샘플값 | null 비율 | 설명 |
|------|------|--------|-----------|------|
| `StartStackAmt` | integer | 1224444, 9000, 50000... | 0% | 핸드 시작 스택 |
| `EndStackAmt` | integer | 1224444, 8920, 65300... | 0% | 핸드 종료 스택 |
| `CumulativeWinningsAmt` | integer | 0, -80, 80, 15300... | 0% | 누적 승패 금액 |
| `BlindBetStraddleAmt` | integer | 0 | 0% | 블라인드/스트래들 금액 (항상 0) |

### 3.3 홀 카드

| 필드 | 타입 | 샘플값 | null 비율 | 설명 |
|------|------|--------|-----------|------|
| `HoleCards[*]` | string | "", "10d 9d", "ks qs" | 2% | 홀 카드 (빈 문자열 = 비공개) |

**카드 표기법**: `{rank}{suit}` (예: `ks` = King of Spades, `10d` = 10 of Diamonds)

### 3.4 플레이 통계

| 필드 | 타입 | 샘플값 | null 비율 | 설명 |
|------|------|--------|-----------|------|
| `VPIPPercent` | integer | 0, 100, 50, 66... | 0% | VPIP (자발적 팟 참여율) |
| `PreFlopRaisePercent` | integer | 0, 100, 50, 33... | 0% | 프리플랍 레이즈 비율 |
| `AggressionFrequencyPercent` | integer | 0, 42, 54, 72... | 0% | 공격성 빈도 |
| `WentToShowDownPercent` | integer | 0, 100, 50, 28... | 0% | 쇼다운 진행 비율 |
| `EliminationRank` | integer | -1 | 0% | 탈락 순위 (모두 -1 = 탈락 안 함) |

---

## 4. 이벤트 데이터 (`Hands[*].Events[*]`)

총 4,143개 이벤트 분석

### 4.1 기본 이벤트 정보

| 필드 | 타입 | 샘플값 | null 비율 | 설명 |
|------|------|--------|-----------|------|
| `EventType` | string | "FOLD", "BET", "CALL", "CHECK", "ALL IN", "BOARD CARD" | 0% | 이벤트 타입 |
| `PlayerNum` | integer | 1~9, 0 | 0% | 플레이어 번호 (0 = 보드카드) |
| `BetAmt` | integer | 0, 500, 700, 2000... | 0% | 베팅 금액 |
| `Pot` | integer | 0, 500, 1000, 19800... | 0% | 팟 금액 |
| `BoardNum` | integer | 0, 1 | 0% | 보드 번호 |

### 4.2 이벤트 타입 목록

1. **FOLD** - 폴드
2. **BET** - 베팅
3. **CALL** - 콜
4. **CHECK** - 체크
5. **ALL IN** - 올인
6. **BOARD CARD** - 보드 카드 공개

### 4.3 보드 카드

| 필드 | 타입 | 샘플값 | null 비율 | 설명 |
|------|------|--------|-----------|------|
| `BoardCards` | string | "9h", "ks", "3c", "10c"... | 80.7% | 보드 카드 (BOARD CARD 이벤트만 값 존재) |

**null 비율 80.7%**: 대부분 이벤트는 보드카드가 아니므로 null

### 4.4 미사용 필드

| 필드 | 값 | 설명 |
|------|-----|------|
| `DateTimeUTC` | 항상 null | 타임스탬프 (미사용) |
| `NumCardsDrawn` | 항상 0 | 드로우 카드 수 (Holdem이므로 0) |

---

## 5. 주요 발견사항

### 5.1 항상 고정된 값 (설정 가능성 낮음)

- `EventTitle`: 항상 빈 문자열
- `Type`: 항상 "FEATURE_TABLE"
- `SoftwareVersion`: 항상 "PokerGFX 3.2"
- `GameClass`: 항상 "FLOP"
- `GameVariant`: 항상 "HOLDEM"
- `BetStructure`: 항상 "NOLIMIT"
- `NumBoards`: 항상 1
- `RunItNumTimes`: 항상 1
- `BombPotAmt`: 항상 0
- `BlindLevel`: 항상 0
- `ThirdBlindAmt`/`ThirdBlindPlayerNum`: 항상 0
- `SittingOut`: 항상 false
- `EliminationRank`: 항상 -1

### 5.2 높은 null 비율 필드

- `EventTitle`: 100% (항상 빈값)
- `Description`: 100% (항상 빈값)
- `DateTimeUTC` (이벤트): 100% (미사용)
- `BoardCards`: 80.7% (BOARD CARD 이벤트에만 값 존재)

### 5.3 데이터 품질 이슈

- `HoleCards[*]`: 98% 비공개 (빈 문자열)
- `LongName`: 0.3% 빈값 (일부 플레이어만 전체 이름 제공)

### 5.4 블라인드 구조 패턴

**AnteAmt = BigBlindAmt** (BB Ante 방식)

| AnteAmt | BigBlindAmt | SmallBlindAmt |
|---------|-------------|---------------|
| 0 | 800 | 80 |
| 200 | 200 | 100 |
| 2000 | 2000 | 1000 |
| 3000 | 3000 | 1500 |

**비율**: SB = BB / 10 (대부분), BB Ante = BB

---

## 6. DB 스키마 매핑 권장사항

### 6.1 필수 테이블

```
gfx_sessions
├─ id (bigint, PK) → ID
├─ created_at (timestamptz) → CreatedDateTimeUTC
├─ software_version (text) → SoftwareVersion
└─ session_type (text) → Type

gfx_hands
├─ id (bigserial, PK)
├─ session_id (bigint, FK) → gfx_sessions.id
├─ hand_num (int) → HandNum
├─ started_at (timestamptz) → StartDateTimeUTC
├─ duration (interval) → Duration (ISO 8601 파싱)
├─ game_variant (text) → GameVariant
├─ bet_structure (text) → BetStructure
├─ ante_amt (bigint) → AnteAmt
├─ big_blind_amt (bigint) → BigBlindAmt
├─ small_blind_amt (bigint) → SmallBlindAmt
├─ button_player_num (int) → ButtonPlayerNum
└─ ante_type (text) → AnteType

gfx_players
├─ id (bigserial, PK)
├─ hand_id (bigint, FK) → gfx_hands.id
├─ player_num (int) → PlayerNum
├─ name (text) → Name
├─ long_name (text) → LongName
├─ start_stack (bigint) → StartStackAmt
├─ end_stack (bigint) → EndStackAmt
├─ cumulative_winnings (bigint) → CumulativeWinningsAmt
├─ hole_cards (text[]) → HoleCards (파싱 필요)
├─ vpip_percent (int) → VPIPPercent
├─ pfr_percent (int) → PreFlopRaisePercent
├─ aggression_percent (int) → AggressionFrequencyPercent
└─ showdown_percent (int) → WentToShowDownPercent

gfx_events
├─ id (bigserial, PK)
├─ hand_id (bigint, FK) → gfx_hands.id
├─ event_order (int) → 배열 인덱스
├─ event_type (text) → EventType
├─ player_num (int) → PlayerNum
├─ bet_amt (bigint) → BetAmt
├─ pot (bigint) → Pot
├─ board_num (int) → BoardNum
└─ board_card (text) → BoardCards
```

### 6.2 제외 가능 필드 (모두 고정값)

- `EventTitle`, `Description` (항상 빈값)
- `BombPotAmt`, `ThirdBlindAmt`, `ThirdBlindPlayerNum` (항상 0)
- `BlindLevel` (항상 0)
- `SittingOut` (항상 false)
- `EliminationRank` (항상 -1)
- `StudLimits.*` (Holdem 게임이므로 미사용)
- `DateTimeUTC` (이벤트) (항상 null)
- `NumCardsDrawn` (항상 0)

### 6.3 파싱 필요 필드

| 필드 | 형식 | 파싱 방법 |
|------|------|----------|
| `Duration` | ISO 8601 Duration | Python `isodate.parse_duration()` |
| `RecordingOffsetStart` | ISO 8601 Duration | Python `isodate.parse_duration()` |
| `HoleCards[*]` | "ks qs", "10d 9d" | 공백으로 split → 배열 |
| `BoardCards` | "9h", "ks" | 단일 카드 문자열 |

---

## 7. 다음 단계

1. **GFX 스키마 마이그레이션 업데이트**
   - `gfx_sessions`, `gfx_hands`, `gfx_players`, `gfx_events` 테이블 구조 재검토
   - 고정값 필드 제거, 필수 필드 NOT NULL 제약 추가

2. **gfx_normalizer.py 수정**
   - 실제 JSON 구조에 맞춰 파싱 로직 업데이트
   - Duration, HoleCards 파싱 로직 추가

3. **스키마 검증 테스트**
   - 6개 JSON 파일 전체 import 테스트
   - 데이터 무결성 검증

4. **문서 동기화**
   - `docs/02-GFX-JSON-DB.md` 업데이트
   - 실제 JSON 구조 반영

---

## 부록: 전체 필드 목록

<details>
<summary>60개 필드 전체 목록 (클릭하여 펼치기)</summary>

```
1. CreatedDateTimeUTC
2. EventTitle
3. Hands
4. Hands[*].AnteAmt
5. Hands[*].BetStructure
6. Hands[*].BombPotAmt
7. Hands[*].Description
8. Hands[*].Duration
9. Hands[*].Events
10. Hands[*].Events[*].BetAmt
11. Hands[*].Events[*].BoardCards
12. Hands[*].Events[*].BoardNum
13. Hands[*].Events[*].DateTimeUTC
14. Hands[*].Events[*].EventType
15. Hands[*].Events[*].NumCardsDrawn
16. Hands[*].Events[*].PlayerNum
17. Hands[*].Events[*].Pot
18. Hands[*].FlopDrawBlinds
19. Hands[*].FlopDrawBlinds.AnteType
20. Hands[*].FlopDrawBlinds.BigBlindAmt
21. Hands[*].FlopDrawBlinds.BigBlindPlayerNum
22. Hands[*].FlopDrawBlinds.BlindLevel
23. Hands[*].FlopDrawBlinds.ButtonPlayerNum
24. Hands[*].FlopDrawBlinds.SmallBlindAmt
25. Hands[*].FlopDrawBlinds.SmallBlindPlayerNum
26. Hands[*].FlopDrawBlinds.ThirdBlindAmt
27. Hands[*].FlopDrawBlinds.ThirdBlindPlayerNum
28. Hands[*].GameClass
29. Hands[*].GameVariant
30. Hands[*].HandNum
31. Hands[*].NumBoards
32. Hands[*].Players
33. Hands[*].Players[*].AggressionFrequencyPercent
34. Hands[*].Players[*].BlindBetStraddleAmt
35. Hands[*].Players[*].CumulativeWinningsAmt
36. Hands[*].Players[*].EliminationRank
37. Hands[*].Players[*].EndStackAmt
38. Hands[*].Players[*].HoleCards
39. Hands[*].Players[*].HoleCards[*]
40. Hands[*].Players[*].LongName
41. Hands[*].Players[*].Name
42. Hands[*].Players[*].PlayerNum
43. Hands[*].Players[*].PreFlopRaisePercent
44. Hands[*].Players[*].SittingOut
45. Hands[*].Players[*].StartStackAmt
46. Hands[*].Players[*].VPIPPercent
47. Hands[*].Players[*].WentToShowDownPercent
48. Hands[*].RecordingOffsetStart
49. Hands[*].RunItNumTimes
50. Hands[*].StartDateTimeUTC
51. Hands[*].StudLimits
52. Hands[*].StudLimits.BringInAmt
53. Hands[*].StudLimits.BringInPlayerNum
54. Hands[*].StudLimits.HighLimitAmt
55. Hands[*].StudLimits.LowLimitAmt
56. ID
57. Payouts
58. Payouts[*]
59. SoftwareVersion
60. Type
```

</details>
