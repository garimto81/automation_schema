# GFX JSON 필드 분석 보고서 (table-pokercaster)

**분석일**: 2026-01-19
**소스**: table-pokercaster
**분석 파일 수**: 5개
**총 필드 수**: 58개

---

## 1. 분석 대상 파일

| # | 디렉토리 | GameID | 파일명 |
|---|----------|--------|--------|
| 1 | 1016 | 638962090875783819 | PGFX_live_data_export GameID=638962090875783819.json |
| 2 | 1017 | 638962967524560670 | PGFX_live_data_export GameID=638962967524560670.json |
| 3 | 1018 | 638963847602984623 | PGFX_live_data_export GameID=638963847602984623.json |
| 4 | 1019 | 638964779563363778 | PGFX_live_data_export GameID=638964779563363778.json |
| 5 | 1021 | 638966318331324926 | PGFX_live_data_export GameID=638966318331324926.json |

---

## 2. JSON 구조 개요

```
Root (최상위)
├─ CreatedDateTimeUTC (string)
├─ EventTitle (string)
├─ ID (integer)
├─ SoftwareVersion (string)
├─ Type (string)
├─ Payouts (array)
└─ Hands (array)
    ├─ HandNum (integer)
    ├─ AnteAmt (integer)
    ├─ BetStructure (string)
    ├─ BombPotAmt (integer)
    ├─ Description (string)
    ├─ Duration (string)
    ├─ GameClass (string)
    ├─ GameVariant (string)
    ├─ NumBoards (integer)
    ├─ RunItNumTimes (integer)
    ├─ StartDateTimeUTC (string)
    ├─ RecordingOffsetStart (string)
    ├─ FlopDrawBlinds (object)
    │   ├─ AnteType (string)
    │   ├─ BigBlindAmt (integer)
    │   ├─ BigBlindPlayerNum (integer)
    │   ├─ BlindLevel (integer)
    │   ├─ ButtonPlayerNum (integer)
    │   ├─ SmallBlindAmt (integer)
    │   ├─ SmallBlindPlayerNum (integer)
    │   ├─ ThirdBlindAmt (integer)
    │   └─ ThirdBlindPlayerNum (integer)
    ├─ StudLimits (object)
    │   ├─ BringInAmt (integer)
    │   ├─ BringInPlayerNum (integer)
    │   ├─ HighLimitAmt (integer)
    │   └─ LowLimitAmt (integer)
    ├─ Players (array)
    │   ├─ PlayerNum (integer)
    │   ├─ Name (string)
    │   ├─ LongName (string)
    │   ├─ StartStackAmt (integer)
    │   ├─ EndStackAmt (integer)
    │   ├─ CumulativeWinningsAmt (integer)
    │   ├─ HoleCards (array of string)
    │   ├─ SittingOut (boolean)
    │   ├─ EliminationRank (integer)
    │   ├─ BlindBetStraddleAmt (integer)
    │   ├─ VPIPPercent (integer)
    │   ├─ PreFlopRaisePercent (integer)
    │   ├─ AggressionFrequencyPercent (integer)
    │   └─ WentToShowDownPercent (integer)
    └─ Events (array)
        ├─ EventType (string)
        ├─ PlayerNum (integer)
        ├─ BetAmt (integer)
        ├─ Pot (integer)
        ├─ BoardNum (integer)
        ├─ BoardCards (string)
        ├─ NumCardsDrawn (integer)
        └─ DateTimeUTC (null)
```

---

## 3. 필드별 상세 분석

### 3.1 최상위 필드 (Root Level)

| 필드 | 타입 | Null 비율 | 샘플값 | 용도 |
|------|------|-----------|--------|------|
| `CreatedDateTimeUTC` | string | 0.0% | "2025-10-16T10:58:07.5783819Z" | 파일 생성 시각 (ISO 8601) |
| `EventTitle` | string | **100%** | (전체 null) | 이벤트 제목 (미사용) |
| `ID` | integer | 0.0% | 638962090875783819 | 게임 세션 고유 ID |
| `SoftwareVersion` | string | 0.0% | "PokerGFX 3.2" | GFX 소프트웨어 버전 |
| `Type` | string | 0.0% | "FEATURE_TABLE", "FINAL_TABLE" | 테이블 타입 (피처/파이널) |
| `Payouts` | array | 0.0% | [0, 0, ...] | 상금 배열 (현재 모두 0) |

**주요 발견**:
- `EventTitle`은 5개 파일 모두 null → DB 스키마에서 nullable 또는 제외 고려
- `ID`는 .NET Ticks 기반 타임스탬프로 추정 (638xxx...로 시작)
- `Type`은 2가지 값만 존재: "FEATURE_TABLE", "FINAL_TABLE"

---

### 3.2 Hands (핸드 레벨)

**총 616개 핸드 분석**

| 필드 | 타입 | Null 비율 | 샘플값 | 용도 |
|------|------|-----------|--------|------|
| `Hands.HandNum` | integer | 0.0% | 1, 2, 3, ... | 핸드 순번 |
| `Hands.AnteAmt` | integer | 0.0% | 500, 600, 800, 1000 | 앤티 금액 |
| `Hands.BetStructure` | string | 0.0% | "NOLIMIT" | 베팅 구조 (노리밋만 확인) |
| `Hands.BombPotAmt` | integer | 0.0% | 0 | 밤팟 금액 (모두 0) |
| `Hands.Description` | string | **100%** | (전체 null) | 핸드 설명 (미사용) |
| `Hands.Duration` | string | 0.0% | "PT3M18.0255475S" | 핸드 지속 시간 (ISO 8601 Duration) |
| `Hands.GameClass` | string | 0.0% | "FLOP" | 게임 클래스 (플랍만 확인) |
| `Hands.GameVariant` | string | 0.0% | "HOLDEM" | 게임 변형 (홀덤만 확인) |
| `Hands.NumBoards` | integer | 0.0% | 1 | 보드 개수 (항상 1) |
| `Hands.RunItNumTimes` | integer | 0.0% | 1 | Run-It 횟수 (항상 1) |
| `Hands.StartDateTimeUTC` | string | 0.0% | "2025-10-16T11:37:27.4134621Z" | 핸드 시작 시각 |
| `Hands.RecordingOffsetStart` | string | 0.0% | "P739539DT14H37M27.4134621S" | 녹화 오프셋 (ISO 8601 Period) |

**주요 발견**:
- `Duration`과 `RecordingOffsetStart`는 ISO 8601 Duration/Period 형식
- `Description`은 616개 모두 null → DB 스키마에서 제외 고려
- `BombPotAmt`, `NumBoards`, `RunItNumTimes`는 모두 고정값 → 현재 사용 안 함

---

### 3.3 FlopDrawBlinds (블라인드 정보)

| 필드 | 타입 | Null 비율 | 샘플값 | 용도 |
|------|------|-----------|--------|------|
| `Hands.FlopDrawBlinds.AnteType` | string | 0.0% | "BB_ANTE_BB1ST" | 앤티 타입 |
| `Hands.FlopDrawBlinds.BigBlindAmt` | integer | 0.0% | 500, 600, 800 | 빅블라인드 금액 |
| `Hands.FlopDrawBlinds.BigBlindPlayerNum` | integer | 0.0% | 2, 3, 4, ... | 빅블라인드 플레이어 번호 |
| `Hands.FlopDrawBlinds.BlindLevel` | integer | 0.0% | 0 | 블라인드 레벨 (항상 0) |
| `Hands.FlopDrawBlinds.ButtonPlayerNum` | integer | 0.0% | 2, 3, 4, ... | 버튼 플레이어 번호 |
| `Hands.FlopDrawBlinds.SmallBlindAmt` | integer | 0.0% | 300, 400, 500 | 스몰블라인드 금액 |
| `Hands.FlopDrawBlinds.SmallBlindPlayerNum` | integer | 0.0% | 2, 3, 4, ... | 스몰블라인드 플레이어 번호 |
| `Hands.FlopDrawBlinds.ThirdBlindAmt` | integer | 0.0% | 0 | 서드블라인드 금액 (항상 0) |
| `Hands.FlopDrawBlinds.ThirdBlindPlayerNum` | integer | 0.0% | 0 | 서드블라인드 플레이어 (항상 0) |

**주요 발견**:
- `BlindLevel`은 항상 0 → 현재 미사용
- `ThirdBlindAmt/ThirdBlindPlayerNum`은 항상 0 → 3-way 블라인드 미사용
- 플레이어 번호는 2~9 범위 (1은 사용 안 함)

---

### 3.4 StudLimits (스터드 리밋 - 미사용)

| 필드 | 타입 | Null 비율 | 샘플값 | 용도 |
|------|------|-----------|--------|------|
| `Hands.StudLimits.BringInAmt` | integer | 0.0% | 0 | 브링인 금액 (항상 0) |
| `Hands.StudLimits.BringInPlayerNum` | integer | 0.0% | 1 | 브링인 플레이어 (항상 1) |
| `Hands.StudLimits.HighLimitAmt` | integer | 0.0% | 0 | 하이리밋 (항상 0) |
| `Hands.StudLimits.LowLimitAmt` | integer | 0.0% | 0 | 로우리밋 (항상 0) |

**주요 발견**:
- 전체 필드가 고정값 → Holdem에서는 사용 안 함
- DB 스키마에서 제외 고려 (또는 nullable)

---

### 3.5 Players (플레이어 정보)

**총 4,892개 플레이어 레코드 분석**

| 필드 | 타입 | Null 비율 | 샘플값 | 용도 |
|------|------|-----------|--------|------|
| `Hands.Players.PlayerNum` | integer | 0.0% | 2, 3, 4, 5, 6, 7, 8, 9 | 플레이어 번호 (2~9) |
| `Hands.Players.Name` | string | 0.0% | "SOKRUTA", "SATUBAYEV" | 플레이어 이름 |
| `Hands.Players.LongName` | string | **3.1%** | "SOKRUTA" | 플레이어 풀네임 |
| `Hands.Players.StartStackAmt` | integer | 0.0% | 42000, 61300 | 핸드 시작 칩 |
| `Hands.Players.EndStackAmt` | integer | 0.0% | 23000, 61300 | 핸드 종료 칩 |
| `Hands.Players.CumulativeWinningsAmt` | integer | 0.0% | -19000, 0, 19300 | 누적 승패 금액 |
| `Hands.Players.HoleCards` | array | **8.4%** | ["ah kd"], ["ks 8c"] | 홀카드 (null은 폴드) |
| `Hands.Players.SittingOut` | boolean | 0.0% | false, true | 앉아있음/나감 |
| `Hands.Players.EliminationRank` | integer | 0.0% | -1, 2, 3, 4 | 탈락 순위 (-1: 생존) |
| `Hands.Players.BlindBetStraddleAmt` | integer | 0.0% | 0 | 블라인드/스트래들 (항상 0) |
| `Hands.Players.VPIPPercent` | integer | 0.0% | 0, 25, 50, 100 | VPIP 통계 (%) |
| `Hands.Players.PreFlopRaisePercent` | integer | 0.0% | 0, 25, 50, 100 | 프리플랍 레이즈율 (%) |
| `Hands.Players.AggressionFrequencyPercent` | integer | 0.0% | 0, 38, 40, 80 | 공격성 빈도 (%) |
| `Hands.Players.WentToShowDownPercent` | integer | 0.0% | 0, 25, 50, 100 | 쇼다운 진출률 (%) |

**주요 발견**:
- `LongName`은 3.1% null → `Name`과 중복 가능성
- `HoleCards`는 8.4% null → 폴드한 경우 null (정상)
- `BlindBetStraddleAmt`는 항상 0 → 현재 미사용
- 통계 필드(VPIP, PFR, AF, WTSD)는 모두 정수형 퍼센트 (0~100)
- `PlayerNum`은 2~9만 사용 (1은 없음, 0은 보드카드용)

---

### 3.6 Events (이벤트/액션)

**총 7,821개 이벤트 분석**

| 필드 | 타입 | Null 비율 | 샘플값 | 용도 |
|------|------|-----------|--------|------|
| `Hands.Events.EventType` | string | 0.0% | "FOLD", "BET", "CALL", "CHECK", "ALL IN", "BOARD CARD" | 액션 타입 |
| `Hands.Events.PlayerNum` | integer | 0.0% | 0, 2, 3, 4, 5, 6, 7, 8, 9 | 플레이어 번호 (0: 보드카드) |
| `Hands.Events.BetAmt` | integer | 0.0% | 0, 500, 1000, 2500 | 베팅 금액 |
| `Hands.Events.Pot` | integer | 0.0% | 0, 1300, 2300, 6000 | 현재 팟 크기 |
| `Hands.Events.BoardNum` | integer | 0.0% | 0, 1 | 보드 번호 |
| `Hands.Events.BoardCards` | string | **79.5%** | "3s", "4h", "2c", "kc" | 보드카드 (액션 시 null) |
| `Hands.Events.NumCardsDrawn` | integer | 0.0% | 0 | 드로우 카드 수 (항상 0) |
| `Hands.Events.DateTimeUTC` | null | **100%** | (전체 null) | 이벤트 시각 (미사용) |

**주요 발견**:
- `EventType`은 6가지: FOLD, BET, CALL, CHECK, ALL IN, BOARD CARD
- `BoardCards`는 79.5% null → "BOARD CARD" 이벤트에만 값 존재
- `DateTimeUTC`는 100% null → 현재 미사용 (핸드 Duration으로 계산 가능)
- `NumCardsDrawn`은 항상 0 → Draw 게임 아님
- `PlayerNum = 0`은 보드카드 이벤트 전용

---

## 4. 데이터 품질 분석

### 4.1 항상 null인 필드 (DB 스키마 제외 권장)

| 필드 경로 | Null 비율 | 총 출현 횟수 |
|-----------|-----------|--------------|
| `EventTitle` | 100% | 5 |
| `Hands.Description` | 100% | 616 |
| `Hands.Events.DateTimeUTC` | 100% | 7,821 |

### 4.2 항상 고정값인 필드 (현재 미사용)

| 필드 경로 | 고정값 | 총 출현 횟수 |
|-----------|--------|--------------|
| `Hands.BetStructure` | "NOLIMIT" | 616 |
| `Hands.BombPotAmt` | 0 | 616 |
| `Hands.GameClass` | "FLOP" | 616 |
| `Hands.GameVariant` | "HOLDEM" | 616 |
| `Hands.NumBoards` | 1 | 616 |
| `Hands.RunItNumTimes` | 1 | 616 |
| `Hands.FlopDrawBlinds.AnteType` | "BB_ANTE_BB1ST" | 616 |
| `Hands.FlopDrawBlinds.BlindLevel` | 0 | 616 |
| `Hands.FlopDrawBlinds.ThirdBlindAmt` | 0 | 616 |
| `Hands.FlopDrawBlinds.ThirdBlindPlayerNum` | 0 | 616 |
| `Hands.StudLimits.*` | 0 또는 1 | 616 × 4 |
| `Hands.Players.BlindBetStraddleAmt` | 0 | 4,892 |
| `Hands.Events.NumCardsDrawn` | 0 | 7,821 |

### 4.3 부분 null 필드 (비즈니스 로직 반영)

| 필드 경로 | Null 비율 | 의미 |
|-----------|-----------|------|
| `Hands.Players.LongName` | 3.1% | Name과 동일한 경우 null 가능 |
| `Hands.Players.HoleCards` | 8.4% | 폴드 시 null (정상) |
| `Hands.Events.BoardCards` | 79.5% | 보드카드 이벤트만 값 존재 |

---

## 5. DB 스키마 매핑 권장사항

### 5.1 필수 저장 필드 (58개 중 28개 권장)

#### Root Level (5개)
- `CreatedDateTimeUTC` → `created_at` (timestamptz)
- `ID` → `game_id` (bigint, PK)
- `SoftwareVersion` → `software_version` (text)
- `Type` → `table_type` (text)
- `Payouts` → 별도 테이블 `payouts` (관계형)

#### Hands Level (8개)
- `Hands.HandNum` → `hand_number` (integer)
- `Hands.AnteAmt` → `ante_amount` (integer)
- `Hands.Duration` → `duration` (interval)
- `Hands.StartDateTimeUTC` → `started_at` (timestamptz)
- `Hands.RecordingOffsetStart` → `recording_offset` (interval)
- `Hands.FlopDrawBlinds.BigBlindAmt` → `big_blind` (integer)
- `Hands.FlopDrawBlinds.SmallBlindAmt` → `small_blind` (integer)
- `Hands.FlopDrawBlinds.ButtonPlayerNum` → `button_player` (integer)

#### Players Level (10개)
- `Hands.Players.PlayerNum` → `player_number` (integer)
- `Hands.Players.Name` → `player_name` (text)
- `Hands.Players.StartStackAmt` → `start_stack` (integer)
- `Hands.Players.EndStackAmt` → `end_stack` (integer)
- `Hands.Players.CumulativeWinningsAmt` → `cumulative_winnings` (integer)
- `Hands.Players.HoleCards` → `hole_cards` (text[])
- `Hands.Players.SittingOut` → `sitting_out` (boolean)
- `Hands.Players.EliminationRank` → `elimination_rank` (integer)
- `Hands.Players.VPIPPercent` → `vpip` (integer)
- `Hands.Players.AggressionFrequencyPercent` → `aggression_frequency` (integer)

#### Events Level (5개)
- `Hands.Events.EventType` → `event_type` (text)
- `Hands.Events.PlayerNum` → `player_number` (integer)
- `Hands.Events.BetAmt` → `bet_amount` (integer)
- `Hands.Events.Pot` → `pot_amount` (integer)
- `Hands.Events.BoardCards` → `board_card` (text, nullable)

### 5.2 제외 권장 필드 (30개)

**완전 미사용 (null 또는 고정값)**:
- `EventTitle` (100% null)
- `Hands.Description` (100% null)
- `Hands.Events.DateTimeUTC` (100% null)
- `Hands.BombPotAmt` (항상 0)
- `Hands.NumBoards` (항상 1)
- `Hands.RunItNumTimes` (항상 1)
- `Hands.FlopDrawBlinds.BlindLevel` (항상 0)
- `Hands.FlopDrawBlinds.ThirdBlindAmt` (항상 0)
- `Hands.FlopDrawBlinds.ThirdBlindPlayerNum` (항상 0)
- `Hands.StudLimits.*` (전체 4개 필드, 항상 0 또는 1)
- `Hands.Players.BlindBetStraddleAmt` (항상 0)
- `Hands.Events.NumCardsDrawn` (항상 0)

**추론 가능 또는 중복**:
- `Hands.BetStructure` (항상 "NOLIMIT", 현재 고정)
- `Hands.GameClass` (항상 "FLOP", 현재 고정)
- `Hands.GameVariant` (항상 "HOLDEM", 현재 고정)
- `Hands.Players.LongName` (Name과 중복)
- `Hands.Players.PreFlopRaisePercent` (PFR, 선택적)
- `Hands.Players.WentToShowDownPercent` (WTSD, 선택적)

---

## 6. 핵심 발견사항

### 6.1 데이터 구조
- **3계층 중첩 구조**: Root → Hands → Players/Events
- **616개 핸드, 4,892개 플레이어 레코드, 7,821개 이벤트**
- 플레이어 번호는 **2~9 사용** (1은 없음, 0은 보드카드 전용)

### 6.2 데이터 품질
- **3개 필드 100% null** → DB 스키마 제외 권장
- **13개 필드 고정값** → 현재 Holdem 전용 (향후 확장 가능)
- **부분 null은 비즈니스 로직 반영** (폴드 시 홀카드 null 등)

### 6.3 시간 데이터
- ISO 8601 형식 사용: `CreatedDateTimeUTC`, `StartDateTimeUTC`
- Duration/Period 형식: `Duration`, `RecordingOffsetStart`
- PostgreSQL `timestamptz`, `interval` 타입 매핑 가능

### 6.4 카드 표기
- 소문자 형식: `"ah kd"` (ace of hearts, king of diamonds)
- HoleCards는 공백 구분 문자열 배열: `["ah kd"]` → `text[]` 타입

### 6.5 플레이어 통계
- 정수형 퍼센트 (0~100): VPIP, PFR, AF, WTSD
- **EliminationRank**: -1은 생존, 2~8은 탈락 순위

---

## 7. 다음 단계

### 7.1 스키마 검증
- [ ] 기존 `gfx_sessions`, `gfx_hands`, `gfx_players`, `gfx_events` 테이블과 비교
- [ ] 누락된 필드 확인
- [ ] 데이터 타입 일치 여부 확인

### 7.2 정규화 스크립트 업데이트
- [ ] `src/gfx_normalizer.py`에 table-pokercaster 로직 반영
- [ ] null 처리 로직 추가 (LongName, HoleCards, BoardCards)
- [ ] 고정값 필드 제외 또는 디폴트 처리

### 7.3 마이그레이션 생성
- [ ] 필드 추가/삭제 마이그레이션 작성
- [ ] 인덱스 최적화 (PlayerNum, HandNum, EventType)
- [ ] RLS 정책 검토

---

## 부록: 전체 필드 목록 (58개)

<details>
<summary>접기/펼치기</summary>

1. CreatedDateTimeUTC (string)
2. EventTitle (string) ❌
3. ID (integer)
4. SoftwareVersion (string)
5. Type (string)
6. Payouts (array)
7. Hands.HandNum (integer)
8. Hands.AnteAmt (integer)
9. Hands.BetStructure (string) ⚠️
10. Hands.BombPotAmt (integer) ❌
11. Hands.Description (string) ❌
12. Hands.Duration (string)
13. Hands.GameClass (string) ⚠️
14. Hands.GameVariant (string) ⚠️
15. Hands.NumBoards (integer) ❌
16. Hands.RunItNumTimes (integer) ❌
17. Hands.StartDateTimeUTC (string)
18. Hands.RecordingOffsetStart (string)
19. Hands.FlopDrawBlinds.AnteType (string) ⚠️
20. Hands.FlopDrawBlinds.BigBlindAmt (integer)
21. Hands.FlopDrawBlinds.BigBlindPlayerNum (integer)
22. Hands.FlopDrawBlinds.BlindLevel (integer) ❌
23. Hands.FlopDrawBlinds.ButtonPlayerNum (integer)
24. Hands.FlopDrawBlinds.SmallBlindAmt (integer)
25. Hands.FlopDrawBlinds.SmallBlindPlayerNum (integer)
26. Hands.FlopDrawBlinds.ThirdBlindAmt (integer) ❌
27. Hands.FlopDrawBlinds.ThirdBlindPlayerNum (integer) ❌
28. Hands.StudLimits.BringInAmt (integer) ❌
29. Hands.StudLimits.BringInPlayerNum (integer) ❌
30. Hands.StudLimits.HighLimitAmt (integer) ❌
31. Hands.StudLimits.LowLimitAmt (integer) ❌
32. Hands.Players.PlayerNum (integer)
33. Hands.Players.Name (string)
34. Hands.Players.LongName (string) ⚠️
35. Hands.Players.StartStackAmt (integer)
36. Hands.Players.EndStackAmt (integer)
37. Hands.Players.CumulativeWinningsAmt (integer)
38. Hands.Players.HoleCards (array)
39. Hands.Players.SittingOut (boolean)
40. Hands.Players.EliminationRank (integer)
41. Hands.Players.BlindBetStraddleAmt (integer) ❌
42. Hands.Players.VPIPPercent (integer)
43. Hands.Players.PreFlopRaisePercent (integer) ⚠️
44. Hands.Players.AggressionFrequencyPercent (integer)
45. Hands.Players.WentToShowDownPercent (integer) ⚠️
46. Hands.Events.EventType (string)
47. Hands.Events.PlayerNum (integer)
48. Hands.Events.BetAmt (integer)
49. Hands.Events.Pot (integer)
50. Hands.Events.BoardNum (integer)
51. Hands.Events.BoardCards (string)
52. Hands.Events.NumCardsDrawn (integer) ❌
53. Hands.Events.DateTimeUTC (null) ❌

**범례**:
- ❌ 제외 권장 (null 또는 고정값)
- ⚠️ 조건부 저장 (현재 고정값이지만 향후 확장 가능)

</details>
