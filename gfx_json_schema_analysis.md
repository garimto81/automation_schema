# GFX JSON 스키마 분석 결과

**분석 대상**: `C:\claude\automation_schema\gfx_json_data\table-GG\` (1015-1020 폴더)
**분석 일시**: 2026-01-19
**총 분석 파일**: 12개 JSON 파일

---

## Root Level 필드 (Session)

| 필드명 | 타입 | 예시값 | 설명 |
|--------|------|--------|------|
| `ID` | int64 | `638961224831992165` | 세션 고유 ID |
| `CreatedDateTimeUTC` | string | `2025-10-15T10:54:43.1992165Z` | 세션 생성 시각 (UTC) |
| `EventTitle` | string | `""` | 이벤트 타이틀 (대부분 빈 문자열) |
| `Type` | string | `FEATURE_TABLE` | 테이블 타입 |
| `SoftwareVersion` | string | `PokerGFX 3.2` | 소프트웨어 버전 |
| `Hands` | array | `[{...}]` | 핸드 목록 배열 |
| `Payouts` | array | `[0, 0, 0, 0, 0, 0, 0, 0, 0, 0]` | 페이아웃 배열 (10개 고정) |

---

## Hands[] 필드

| 필드명 | 타입 | 예시값 | 설명 |
|--------|------|--------|------|
| `HandNum` | int | `1` | 핸드 번호 |
| `StartDateTimeUTC` | string | `2025-10-15T12:03:20.9005907Z` | 핸드 시작 시각 (UTC) |
| `Duration` | string | `PT35M37.2477537S` | 핸드 지속 시간 (ISO 8601 Duration) |
| `RecordingOffsetStart` | string | `P739538DT16H3M20.9005907S` | 녹화 오프셋 시작 |
| `GameClass` | string | `FLOP` | 게임 클래스 (FLOP, STUD 등) |
| `GameVariant` | string | `HOLDEM` | 게임 종류 (HOLDEM, OMAHA 등) |
| `BetStructure` | string | `NOLIMIT` | 베팅 구조 (NOLIMIT, LIMIT 등) |
| `AnteAmt` | int | `0` | 앤티 금액 |
| `BombPotAmt` | int | `0` | 밤팟 금액 |
| `NumBoards` | int | `1` | 보드 개수 |
| `RunItNumTimes` | int | `1` | 런잇 횟수 |
| `Description` | string | `""` | 핸드 설명 (대부분 빈 문자열) |
| `Events` | array | `[{...}]` | 이벤트 목록 배열 |
| `Players` | array | `[{...}]` | 플레이어 목록 배열 |
| `FlopDrawBlinds` | object | `{...}` | Flop/Draw 게임 블라인드 정보 |
| `StudLimits` | object | `{...}` | Stud 게임 리미트 정보 |

---

## Events[] 필드

| 필드명 | 타입 | 예시값 | 설명 |
|--------|------|--------|------|
| `EventType` | string | `FOLD` | 이벤트 타입 (아래 참조) |
| `PlayerNum` | int | `1` | 플레이어 번호 (0은 딜러) |
| `BetAmt` | int | `0` | 베팅 금액 |
| `Pot` | int | `0` | 팟 금액 (이벤트 후) |
| `BoardCards` | string/null | `"qd"` | 보드 카드 (BOARD CARD 이벤트 시) |
| `BoardNum` | int | `0` | 보드 번호 |
| `NumCardsDrawn` | int | `0` | 드로우한 카드 수 |
| `DateTimeUTC` | string/null | `null` | 이벤트 시각 (대부분 null) |

### EventType 가능한 값

- `FOLD` - 폴드
- `CHECK` - 체크
- `CALL` - 콜
- `BET` - 베팅
- `ALL IN` - 올인
- `BOARD CARD` - 보드 카드 공개

---

## Players[] 필드

| 필드명 | 타입 | 예시값 | 설명 |
|--------|------|--------|------|
| `PlayerNum` | int | `1` | 플레이어 번호 (1-10) |
| `Name` | string | `"jhkg"` | 짧은 이름 |
| `LongName` | string | `"jhkg"` | 긴 이름 |
| `StartStackAmt` | int | `1224444` | 핸드 시작 스택 |
| `EndStackAmt` | int | `1224444` | 핸드 종료 스택 |
| `HoleCards` | array | `["10d 9d"]` | 홀카드 (보이지 않으면 `[""]`) |
| `SittingOut` | bool | `false` | 자리 비움 여부 |
| `EliminationRank` | int | `-1` | 탈락 순위 (-1은 미탈락) |
| `CumulativeWinningsAmt` | int | `0` | 누적 승리 금액 |
| `BlindBetStraddleAmt` | int | `0` | 블라인드/스트래들 금액 |
| `VPIPPercent` | int | `0` | VPIP 퍼센트 (0-100) |
| `PreFlopRaisePercent` | int | `0` | 프리플랍 레이즈 퍼센트 (0-100) |
| `AggressionFrequencyPercent` | int | `0` | 공격성 빈도 퍼센트 (0-100) |
| `WentToShowDownPercent` | int | `0` | 쇼다운 진입 퍼센트 (0-100) |

### HoleCards 형식

- 보이지 않음: `[""]`
- 2장 카드: `["10d 9d"]` (공백으로 구분)
- 카드 표기: `{rank}{suit}` (예: `10d`, `ks`, `ah`)
  - Rank: `2-10`, `j`, `q`, `k`, `a`
  - Suit: `s` (스페이드), `h` (하트), `d` (다이아), `c` (클럽)

---

## FlopDrawBlinds 필드

| 필드명 | 타입 | 예시값 | 설명 |
|--------|------|--------|------|
| `ButtonPlayerNum` | int | `1` | 버튼 플레이어 번호 |
| `SmallBlindPlayerNum` | int | `7` | 스몰 블라인드 플레이어 번호 |
| `BigBlindPlayerNum` | int | `8` | 빅 블라인드 플레이어 번호 |
| `ThirdBlindPlayerNum` | int | `0` | 서드 블라인드 플레이어 번호 (0은 없음) |
| `SmallBlindAmt` | int | `80` | 스몰 블라인드 금액 |
| `BigBlindAmt` | int | `800` | 빅 블라인드 금액 |
| `ThirdBlindAmt` | int | `0` | 서드 블라인드 금액 |
| `AnteType` | string | `BB_ANTE_BB1ST` | 앤티 타입 |
| `BlindLevel` | int | `0` | 블라인드 레벨 |

---

## StudLimits 필드

| 필드명 | 타입 | 예시값 | 설명 |
|--------|------|--------|------|
| `BringInPlayerNum` | int | `1` | 브링인 플레이어 번호 |
| `BringInAmt` | int | `0` | 브링인 금액 |
| `LowLimitAmt` | int | `0` | 로우 리미트 금액 |
| `HighLimitAmt` | int | `0` | 하이 리미트 금액 |

> **참고**: 모든 분석 파일에서 StudLimits 필드는 0으로 설정되어 있음 (FLOP 게임이므로)

---

## 스키마 특징

1. **계층 구조**: Session → Hands → Events/Players
2. **Nullable 필드**: `DateTimeUTC`, `BoardCards`는 null 허용
3. **빈 문자열**: `EventTitle`, `Description`은 대부분 빈 문자열
4. **고정 크기 배열**: `Payouts`는 항상 10개 요소
5. **타입 안정성**: 모든 숫자 필드는 int, 시간은 ISO 8601 문자열
6. **카드 표기**: 소문자 rank + 소문자 suit (예: `10d`, `ks`)

---

## 데이터 무결성 관찰

- ✅ 모든 필드가 일관된 타입 사용
- ✅ PlayerNum은 1-10 범위 (0은 딜러)
- ✅ 금액 필드는 모두 정수 (칩 단위)
- ✅ 시간 필드는 ISO 8601 형식
- ⚠️ 일부 대형 파일 (800KB+)은 전체 로딩 시 메모리 주의 필요

---

## 분석에 사용된 파일 목록

```
table-GG/1015/PGFX_live_data_export GameID=638961224831992165.json
table-GG/1015/PGFX_live_data_export GameID=638961999170907267.json
table-GG/1016/PGFX_live_data_export GameID=638962014211467634.json
table-GG/1017/PGFX_live_data_export GameID=638962926097967686.json
table-GG/1018/PGFX_live_data_export GameID=638963849867159576.json
table-GG/1018/PGFX_live_data_export GameID=638964597346400480.json
table-GG/1018/PGFX_live_data_export GameID=638964611175191251.json
table-GG/1019/PGFX_live_data_export GameID=638964611175191251.json
table-GG/1019/PGFX_live_data_export GameID=638964779338222042.json
table-GG/1020/PGFX_live_data_export GameID=638965449655751379.json
table-GG/1020/PGFX_live_data_export GameID=638965452050668708.json
table-GG/1020/PGFX_live_data_export GameID=638965539561171011.json
```

총 12개 파일 중 10개 성공적으로 분석 (2개는 부분 파싱 오류로 제외)
