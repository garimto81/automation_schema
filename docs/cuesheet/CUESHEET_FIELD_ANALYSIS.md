# Cuesheet 필드 정밀 분석 보고서

**Version**: 2.0.0
**Date**: 2026-01-19
**Source**: WSOP Super Circuit Cyprus Main Event (Day 1A ~ Day 5 Final)

---

## 0. Day별 통합 분석 (5개 문서)

### 0.1 분석 대상 문서

| Day | Google Sheets URL | 상태 |
|-----|------------------|------|
| Day 1A | [1XiZqoZ3DggHdafWGEzN3PTbCNmTRSt8Ab1Ofclsoc34](https://docs.google.com/spreadsheets/d/1XiZqoZ3DggHdafWGEzN3PTbCNmTRSt8Ab1Ofclsoc34) | ✅ 분석 완료 |
| Day 2 | [1N5urtYwKIPZTiZ83-GSHMaS2I3swGJd5Tdaugpoqu3A](https://docs.google.com/spreadsheets/d/1N5urtYwKIPZTiZ83-GSHMaS2I3swGJd5Tdaugpoqu3A) | ✅ 분석 완료 |
| Day 3 | [1-f5mQLVUmHqxg57Y7xGcQIZKiClUjQLrO8p095hbHAo](https://docs.google.com/spreadsheets/d/1-f5mQLVUmHqxg57Y7xGcQIZKiClUjQLrO8p095hbHAo) | ✅ 분석 완료 |
| Day 4 | [1ZNW7QoVvfijtTMusvTVRb1UGeaVlMfN8UJh8T78zuZE](https://docs.google.com/spreadsheets/d/1ZNW7QoVvfijtTMusvTVRb1UGeaVlMfN8UJh8T78zuZE) | ✅ 분석 완료 |
| Day 5 Final | [10w7SJj8Q2JtxDnwgOQ0pNCB0D-AbGO10VQnT9b4wRwM](https://docs.google.com/spreadsheets/d/10w7SJj8Q2JtxDnwgOQ0pNCB0D-AbGO10VQnT9b4wRwM) | ✅ 분석 완료 (템플릿) |

### 0.2 Day별 핵심 통계

| Day | Blocks | Total Hands | MAIN | SUB | VIRTUAL | Est. RT | Actual RT |
|-----|:------:|:-----------:|:----:|:---:|:-------:|--------:|----------:|
| **Day 1A** | 12 | 142 | 63 | 79 | 34 | ~7:00 | 06:49:19 |
| **Day 2** | 15 | 161 | 72 | 89 | 38 | ~13:00 | 08:06:29 |
| **Day 3** | 13 | 134 | 63 | 71 | 32 | ~11:00 | 06:19:52 |
| **Day 4** | 12 | 125 | 58 | 67 | 9 | ~6:00 | 06:28:56 |
| **Day 5 Final** | 7 | (템플릿) | - | - | - | 00:54 | - |
| **합계** | **59** | **562** | **256** | **306** | **113** | - | **~27:44** |

### 0.3 토너먼트 진행 요약

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    WSOP SC Cyprus ME Tournament Flow                         │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  Day 1A        Day 2        Day 3        Day 4        Day 5 Final           │
│  ──────        ─────        ─────        ─────        ──────────            │
│  Entry         ~350명       112명        24명         9명                    │
│  → ~350명      → 112명      → 24명       → 9명        → 우승자              │
│                                                                             │
│  Blocks: 12    Blocks: 15   Blocks: 13   Blocks: 12   Blocks: 7             │
│  Hands: 142    Hands: 161   Hands: 134   Hands: 125   (Template)            │
│  Virtual: 34   Virtual: 38  Virtual: 32  Virtual: 9   -                     │
│                                                                             │
│  상금 풀: $6,860,000                                                        │
│  1위: $1,000,000                                                            │
│  206명 입상권                                                               │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 0.4 시트 구조 일관성 검증

| 시트명 | Day 1A | Day 2 | Day 3 | Day 4 | Day 5 | 일관성 |
|--------|:------:|:-----:|:-----:|:-----:|:-----:|:------:|
| INFO | ✅ | ✅ | ✅ | ✅ | ✅ | 100% |
| FRONT (LIVE) | ✅ | ✅ | ✅ | ✅ | ✅ | 100% |
| main | ✅ | ✅ | ✅ | ✅ | ✅ | 100% |
| sub | ✅ | ✅ | ✅ | ✅ | ✅ | 100% |
| virtual | ✅ | ✅ | ✅ | ✅ | ✅ | 100% |
| chipcount | ✅ | ✅ | ✅ | ✅ | ✅ | 100% |
| leaderboard | ✅ | ✅ | ✅ | ✅ | ✅ | 100% |
| payout | ✅ | ✅ | ✅ | ✅ | ✅ | 100% |
| template | ✅ | ✅ | ✅ | ✅ | ✅ | 100% |
| PD | ✅ | ✅ | ✅ | ✅ | ✅ | 100% |
| SUBTITLE | ✅ | ✅ | ✅ | ✅ | ✅ | 100% |

**결론**: 모든 Day의 시트 구조가 일관됨 → DB 스키마 단일화 가능

---

## 1. 스프레드시트 개요 (Day 3 기준 상세)

| 항목 | 값 |
|------|-----|
| **문서 제목** | CUE SHEET [1019 WSOP SC Cyprus Main Event Day 3] |
| **이벤트** | WSOP Super Circuit Cyprus Main Event |
| **일자** | 2024년 10월 19일 (Day 3) |
| **시트 수** | 14개+ |
| **시작 플레이어** | 112명 |
| **종료 플레이어** | 24명 |
| **총 상금 풀** | $6,860,000 |

---

## 2. 시트별 분석

### 2.1 INFO 시트 (gid=1451613436)

**용도**: 블록별 핸드 수 및 런타임 통계

#### 컬럼 구조

| 컬럼 | 필드명 | 타입 | 설명 |
|------|--------|------|------|
| A | BLOCK | INTEGER | 블록 번호 (1-21) |
| B | MAIN | INTEGER | 메인 테이블 핸드 수 |
| C | SUB | INTEGER | 서브 테이블 핸드 수 |
| D | HANDS | INTEGER | 총 핸드 수 (MAIN + SUB) |
| E | VIRTUAL | INTEGER | 버추얼 GFX 수 |
| F | Estimated RT | TIME | 예상 런타임 |
| G | Actual RT | TIME | 실제 런타임 |
| H | BREAK (방송) | TIME | 방송 휴식 시간 |
| I | Break (실제) | TIME | 실제 휴식 시간 |

#### 필드값 예시 (5개)

| BLOCK | MAIN | SUB | HANDS | VIRTUAL | Estimated RT | Actual RT |
|-------|------|-----|-------|---------|--------------|-----------|
| 1 | 11 | 8 | 19 | 5 | 0:56:20 | 01:01:02 |
| 2 | 6 | 6 | 12 | 7 | 0:37:30 | 00:37:43 |
| 3 | 4 | 5 | 9 | 2 | 0:25:00 | 00:27:16 |
| 7 | 0 | 15 | 15 | 1 | 0:30:30 | 00:31:50 |
| 11 | 5 | 7 | 12 | 3 | 0:25:30 | 00:31:16 |

---

### 2.2 FRONT 시트 (LIVE) (gid=390049308)

**용도**: 타임라인 기반 전체 큐 (MAIN/SUB/VIRTUAL 통합 뷰)

#### 컬럼 구조

| 컬럼 | 필드명 | 타입 | 설명 |
|------|--------|------|------|
| A | FRONT | TEXT | 테이블 구분 (MAIN/SUB/VIRTUAL) |
| B | Content | TEXT | 콘텐츠 타입 |
| C | Rank | TEXT | 핸드 등급 (A, B, B-, C, SOFT) |
| D | Hand History | TEXT | 핸드 히스토리 (액션 기록) |
| E | Edit Point | TEXT | 편집 시작점 |
| F | PD Note | TEXT | PD 노트 |
| G | Time | TIME | 촬영 시간 |
| H | FIELD | INTEGER | 남은 플레이어 수 |
| I | Subtitle (컨펌용) | TEXT | 자막 (컨펌용) |
| J | Subtitle (자막팀) | TEXT | 자막 (자막팀용) |
| K | 📋 | TEXT | 복사 상태 |
| L | File Name | TEXT | 파일명 |
| M | In | TEXT | 시작 타임코드 |
| N | Out | TEXT | 종료 타임코드 |

#### 필드값 예시 (5개)

| Content | Rank | Hand History (요약) | Edit Point | PD Note |
|---------|------|---------------------|------------|---------|
| MAIN | A | VORONIN A5 RAISE, LESKO 30K CALL | 모두 사용 | VORONIN WIN |
| SUB | B- | MARTINS AK RAISE, ALL FOLD | 모두 사용 | MARTINS AK WIN |
| VIRTUAL | SOFT | Player intro conversation | - | Soft content |
| MAIN | B | ISAR 76o RAISE sequences | 플랍부터 | ISAR WIN |
| SUB | A | ZHAO JT RAISE, KLEZYS AK 3-BET | 프리플랍부터 | ZHAO JT WIN |

---

### 2.3 main 시트 (gid=495054819)

**용도**: MAIN 테이블 핸드 상세 타임라인

#### 컬럼 구조

| 컬럼 | 필드명 | 타입 | 설명 |
|------|--------|------|------|
| A | FIELD | INTEGER | 남은 플레이어 수 |
| B | Cyprus | TIME | 키프로스 현지 시간 |
| C | Seoul | TIME | 서울 시간 (+6h) |
| D | # | INTEGER | 핸드 번호 |
| E | 📋 | TEXT | 복사 상태 ("복사완료") |
| F | File | TEXT | 파일명 (A_XXXX 형식) |
| G | 🏆 | TEXT | 핸드 등급 (A/B/B-/C) |
| H | Hand History | TEXT | 핸드 히스토리 |
| I | Edit Point | TEXT | 편집 시작점 |
| J | PD Note | TEXT | PD 노트 |

#### 필드값 예시 (5개)

| FIELD | Cyprus | Seoul | # | File | 🏆 | Hand History | PD Note |
|-------|--------|-------|---|------|-----|--------------|---------|
| 112 | 12:06 | 18:06 | 1 | A_0001 | B | VORONIN A5 RAISE | VORONIN WIN |
| 110 | 12:18 | 18:18 | 3 | A_0003 | A | LIPAUKA KK RAISE | LIPAUKA KK WIN |
| 97 | 13:07 | 19:07 | 22 | A_0022 | B- | Blind level, ISAR 76o | ISAR WIN |
| 56 | 15:46 | 21:46 | 68 | A_0068 | A | DIMOV AT vs NEVES KQ | DIMOV ELIMINATED |
| 24 | 19:12 | 01:12 | 119 | A_0119 | B | LIPAUKA A8 sequences | LIPAUKA WIN |

---

### 2.4 sub 시트 (gid=360071413)

**용도**: SUB 테이블 핸드 상세 타임라인

#### 컬럼 구조

| 컬럼 | 필드명 | 타입 | 설명 |
|------|--------|------|------|
| A | FIELD | INTEGER | 남은 플레이어 수 |
| B | Cyprus | TIME | 키프로스 현지 시간 |
| C | Seoul | TIME | 서울 시간 |
| D | # | INTEGER | 핸드 번호 |
| E | 📋 | TEXT | 복사 상태 |
| F | File | TEXT | 파일명 (B_XXXX 형식) |
| G | 🏆 | TEXT | 핸드 등급 |
| H | Hand History | TEXT | 핸드 히스토리 |
| I | Edit Point | TEXT | 편집 시작점 |
| J | PD Note | TEXT | PD 노트 |

#### 필드값 예시 (5개)

| FIELD | Cyprus | Seoul | # | File | 🏆 | Hand History | PD Note |
|-------|--------|-------|---|------|-----|--------------|---------|
| 112 | 12:06 | 18:06 | 1 | B_0002 | B- | MARTINS AK RAISE, ALL FOLD | MARTINS AK WIN |
| 112 | 12:08 | 18:08 | 2 | B_0003 | A | ZHAO JT RAISE, KLEZYS AK 3-BET | ZHAO JT WIN |
| 110 | 12:12 | 18:12 | 3 | B_0004 | B | TSOULOFTAS 44 RAISE | MARTINS JT WIN |
| 108 | 12:16 | 18:16 | 4 | B_0005 | B | MARTINS T5 CALL | TSOULOFTAS JT WIN |
| 24 | 19:14 | 01:14 | 132 | B_0132 | B | Final hand SUB | - |

---

### 2.5 virtual 시트 (gid=561799849)

**용도**: 버추얼 GFX 타임라인 (플레이어 프로필, 오프닝 등)

#### 컬럼 구조

| 컬럼 | 필드명 | 타입 | 설명 |
|------|--------|------|------|
| A | Blinds | TEXT | 블라인드 레벨 |
| B | Cyprus | TIME | 키프로스 현지 시간 |
| C | Seoul | TIME | 서울 시간 |
| D | # | INTEGER | 버추얼 번호 |
| E | 📋 | TEXT | 복사 상태 |
| F | File | TEXT | 파일명 (HHMM_SC###_Description 형식) |
| G | 🏆 | TEXT | 콘텐츠 등급 (SOFT/A/B) |
| H | Hand History | TEXT | 콘텐츠 설명 |
| I | Edit Point | TEXT | 편집 포인트 |
| J | Subtitle | TEXT | 자막 텍스트 |
| K | PD Note | TEXT | PD 노트 |

#### 필드값 예시 (5개)

| # | Cyprus | File | 🏆 | Description | PD Note |
|---|--------|------|-----|-------------|---------|
| 1 | 12:13 | 1413_SC001_Opening01 | SOFT | Dealer & chip setup sketch | Opening |
| 4 | 12:38 | 1438_SC011_Mikhail_Shalamov_L3_Profile | SOFT | Player intro | Mikhail Shalamov / RU |
| 22 | 14:22 | 1626_VT001_SIBGATOVA_lose | A | Sibgatova K♠6♣ vs Soika 9♣8♠ | Virtual table |
| 52 | 17:00 | 1900_VT005_Weis | A | KK vs JJ River J eliminates | Oliver Weis / DE ELIMINATED |
| 56 | - | - | SOFT | Closing sequence | Closing |

---

### 2.6 chipcount 시트 (gid=863418569)

**용도**: 실시간 칩카운트 (포커캐스터 연동)

#### 컬럼 구조

| 컬럼 | 필드명 | 타입 | 설명 |
|------|--------|------|------|
| A | Rank | INTEGER | 칩 순위 |
| B | PokerRoom | TEXT | 포커룸 식별자 |
| C | TableName | TEXT | 테이블명 |
| D | TableId | INTEGER | 테이블 ID |
| E | TableNo | INTEGER | 테이블 번호 |
| F | SeatId | INTEGER | 좌석 ID |
| G | SeatNo | INTEGER | 좌석 번호 |
| H | PlayerId | INTEGER | 플레이어 ID |
| I | PlayerName | TEXT | 플레이어 이름 |
| J | Nationality | TEXT | 국적 (ISO 2자리) |
| K | Chipcount | INTEGER | 칩 수량 |
| L | BB | INTEGER | BB 스택 |
| M | (계산용) | INTEGER | 블라인드 기준값 |
| N | PLAYER REMAINING | INTEGER | 남은 플레이어 수 |
| O | OUTPUT용 | TEXT | 출력용 정제 데이터 |

#### 필드값 예시 (5개)

| Rank | PlayerName | Nationality | Chipcount | BB |
|------|------------|-------------|-----------|-----|
| 1 | Vadzim Lipauka | BY | 2,145,000 | 53 |
| 2 | Dzhavad Abdolvand | UA | 2,030,000 | 50 |
| 3 | Pascal Vos | NL | 1,685,000 | 42 |
| 4 | Konstantin Voronin | RU | 1,625,000 | 40 |
| 5 | Arsenii Karmatckii | RU | 1,600,000 | 40 |

---

### 2.7 leaderboard 시트 (gid=369994611)

**용도**: 전체 리더보드 (최종 24명)

#### 컬럼 구조

| 컬럼 | 필드명 | 타입 | 설명 |
|------|--------|------|------|
| A | Rank | INTEGER | 순위 |
| B | PokerRoom | TEXT | 포커룸 |
| C | TableName | TEXT | 테이블명 |
| D | TableId | INTEGER | 테이블 ID |
| E | TableNo | INTEGER | 테이블 번호 |
| F | SeatId | INTEGER | 좌석 ID |
| G | SeatNo | INTEGER | 좌석 번호 |
| H | PlayerId | INTEGER | 플레이어 ID |
| I | PlayerName | TEXT | 플레이어 이름 |
| J | Nationality | TEXT | 국적 |
| K | Chipcount | INTEGER | 칩 수량 |
| L | BB | INTEGER | BB 스택 |

#### 필드값 예시 (5개)

| Rank | PlayerName | Nationality | Chipcount | BB |
|------|------------|-------------|-----------|-----|
| 1 | Jon Kyte | NO | 5,510,000 | 69 |
| 2 | Andrei Spataru | RO | 4,905,000 | 61 |
| 3 | Daniel Rezaei | AT | 4,700,000 | 59 |
| 4 | Mehmet Dalkilic | TR | 4,165,000 | 52 |
| 5 | Georgios Tsouloftas | CY | 4,040,000 | 51 |

---

### 2.8 payout 시트 (gid=1594013979)

**용도**: 상금 구조

#### 컬럼 구조

| 컬럼 | 필드명 | 타입 | 설명 |
|------|--------|------|------|
| A | № | TEXT | 순위 범위 |
| B | ID | INTEGER | 플레이어 ID |
| C | NAME | TEXT | 플레이어 이름 |
| D | NATION | TEXT | 국적 |
| E | PRIZE POOL | CURRENCY | 상금액 |
| F | DEAL | CURRENCY | 딜 금액 (선택적) |

#### 필드값 예시 (5개)

| 순위 | 상금 |
|------|------|
| 1st | $1,000,000 |
| 2nd | $670,000 |
| 3rd | $475,000 |
| 4th | $345,000 |
| 5th | $250,000 |

#### 상금 구조 전체

| 순위 범위 | 상금 | 인원 |
|-----------|------|------|
| 1st | $1,000,000 | 1 |
| 2nd | $670,000 | 1 |
| 3rd | $475,000 | 1 |
| 4th | $345,000 | 1 |
| 5th | $250,000 | 1 |
| 6th | $185,000 | 1 |
| 7th | $140,000 | 1 |
| 8th | $107,500 | 1 |
| 9th | $82,000 | 1 |
| 10th-11th | $64,500 | 2 |
| 12th-15th | $50,400 | 4 |
| 16th-23rd | $40,800 | 8 |
| 24th-31st | $33,400 | 8 |
| 32nd-39th | $27,700 | 8 |
| 40th-47th | $23,400 | 8 |
| 48th-55th | $20,100 | 8 |
| 56th-63rd | $17,500 | 8 |
| 64th-71st | $15,400 | 8 |
| 72nd-79th | $13,800 | 8 |
| 80th-99th | $12,500 | 20 |
| 100th-117th | $11,400 | 18 |
| 118th-135th | $10,800 | 18 |
| 136th-206th | $10,500 | 71 |

**총 상금**: $6,860,000 | **Paid Positions**: 206명

---

### 2.9 template 시트 (gid=487939277)

**용도**: GFX 템플릿 정의

#### 컬럼 구조

| 컬럼 | 필드명 | 타입 | 설명 |
|------|--------|------|------|
| A | Template Type | TEXT | 템플릿 타입 |
| B | Position | TEXT | 위치 (LEFT/RIGHT) |
| C | Player Name | TEXT | 플레이어 이름 |
| D | Country | TEXT | 국가 |
| E | Chip Count | INTEGER | 칩 수량 |
| F | Status | TEXT | 상태 (WINNER/AT RISK 등) |
| G | Blinds | TEXT | 블라인드 정보 |

#### 템플릿 타입별 예시

**Mini Chip Counts Table**
```
[LEFT]MINI_CHIP_TABLE 24
DAVID / 21,240,000
J.SANGHYON CHEONG / 10,030,000 (WINNER)
JAEWON / 10,030,000
S.CAMILO TORO HENAO / 10,000,000
L.PARK / 10,000,000
MIKE / 9,980,000
YOHAN / 8,750,000
Blinds: 1K/2K - 2K (BB)
```

**Mini Payouts Table**
```
[LEFT]MINI_PAYOUTS_TABLE
14TH-15TH: $42,000
16TH-21ST: $35,500
22ND: ZED LEE, KOREA, $35,500
Blinds: 1K/2K - 2K (BB)
```

**Feature Table (10명)**
```
FEATURE TABLE 101
Player Name | Country | Stack | Level
Ranges from 5,920,000 to 5,250,000 chips
Levels 35-39
Blinds: 10K/20K - 20K (BB)
```

**Player Status Templates**
- `[ELIMINATION AT RISK]`: 한테 (50TH, $8,700)
- `[ELIMINATED]`: SAMUEL JU/GERMANY (42ND, $10,300)
- `[MONEY LIST]`: trey/KR ranked 3rd on South Korea all-time money list

---

### 2.10 PD 시트 (gid=481406284)

**용도**: PD(프로덕션 디렉터)용 타임라인

#### 컬럼 구조

main/sub 시트와 동일하며 추가 필드:
- **Production Notes**: 그래픽 요청, RFID 에러, 카메라 이슈 기록

#### PD Note 예시 (5개)

| 시간 | Note |
|------|------|
| 12:15 | "DAY 2" 그래픽 마스킹 필요 |
| 13:30 | RFID 데이터 에러 - 수동 수정 필요 |
| 14:00 | 칩 클로즈업 그래픽 삽입 |
| 15:45 | 블라인드 업 그래픽 오버레이 |
| 17:30 | 플레이어 프로필 삽입 타임스탬프 |

---

### 2.11 SUBTITLE 시트 (gid=1333911885)

**용도**: 자막팀용 타임라인

#### 컬럼 구조

| 컬럼 | 필드명 | 타입 | 설명 |
|------|--------|------|------|
| A-J | (main/sub와 동일) | - | 기본 핸드 정보 |
| K | Subtitle (Table 1) | TEXT | 테이블 1 자막 |
| L-T | (반복) | - | 테이블별 자막 정보 |

#### 자막 예시 (5개)

| # | Content | Subtitle |
|---|---------|----------|
| 1 | Hand Action | "VORONIN defeats LESKO with A5s" |
| 22 | Blind Level | "Blinds increase to 10K/15K" |
| 63 | Chip Update | "[LEFT]MINI_CHIP_TABLE 24..." |
| 68 | Elimination | "DIMOV eliminated in 56th place ($17,500)" |
| 105 | Split Pot | "Split pot between LIPAUKA and VOS" |

---

## 3. 데이터 관계 분석

### 3.1 시트 간 관계도

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         Cuesheet Data Relationships                          │
└─────────────────────────────────────────────────────────────────────────────┘

                    ┌──────────────┐
                    │    INFO      │ ← 블록별 통계 (집계)
                    └──────────────┘
                           │
                           ▼
┌──────────────────────────────────────────────────────────────────┐
│                         FRONT (LIVE)                              │
│                    통합 타임라인 뷰 (Master)                      │
└──────────────────────────────────────────────────────────────────┘
           │                    │                    │
           ▼                    ▼                    ▼
    ┌──────────┐         ┌──────────┐         ┌──────────┐
    │   main   │         │   sub    │         │ virtual  │
    │  (MAIN)  │         │  (SUB)   │         │  (GFX)   │
    │ A_XXXX   │         │ B_XXXX   │         │ SC/VT    │
    └──────────┘         └──────────┘         └──────────┘
           │                    │                    │
           ▼                    ▼                    ▼
    ┌──────────┐         ┌──────────┐         ┌──────────┐
    │    PD    │         │ SUBTITLE │         │ template │
    │  (제작)  │         │  (자막)  │         │ (GFX정의)│
    └──────────┘         └──────────┘         └──────────┘

┌──────────────────────────────────────────────────────────────────┐
│                    실시간 데이터 소스                             │
├──────────────────┬───────────────────┬───────────────────────────┤
│    chipcount     │    leaderboard    │         payout            │
│  (Feature Table) │   (전체 순위)     │       (상금 구조)         │
└──────────────────┴───────────────────┴───────────────────────────┘
```

### 3.2 핵심 필드 매핑

| 공통 필드 | main | sub | virtual | 용도 |
|-----------|------|-----|---------|------|
| # | Hand Number | Hand Number | Virtual Number | 순번 |
| Cyprus | Local Time | Local Time | Local Time | 시간 |
| File | A_XXXX | B_XXXX | HHMM_SC/VT_XXX | 파일명 |
| 🏆 | A/B/B-/C | A/B/B-/C | SOFT/A/B | 등급 |
| 📋 | 복사완료 | 복사완료 | 복사완료 | 상태 |

---

## 4. DB 스키마 매핑

### 4.1 cue_items 테이블 매핑

| 시트 컬럼 | DB 필드 | 타입 | 예시 값 |
|-----------|---------|------|---------|
| Content | content_type | ENUM | 'main', 'sub', 'virtual' |
| # | hand_number | INTEGER | 1-132 |
| 🏆/Rank | hand_rank | ENUM | 'A', 'B', 'B-', 'C', 'SOFT' |
| Hand History | hand_history | TEXT | "VORONIN A5 RAISE..." |
| Edit Point | edit_point | TEXT | "프리플랍부터" |
| PD Note | pd_note | TEXT | "VORONIN WIN" |
| Cyprus/Time | recording_time | TIME | "12:06" |
| Subtitle (컨펌용) | subtitle_confirm | TEXT | 자막 텍스트 |
| 📋 | copy_status | TEXT | "복사완료" |
| File | file_name | TEXT | "A_0001", "B_0002" |

### 4.2 chipcount → wsop_chip_counts 매핑

| 시트 컬럼 | DB 필드 | 타입 |
|-----------|---------|------|
| Rank | chip_rank | INTEGER |
| PlayerId | pokercaster_player_id | INTEGER |
| PlayerName | player_name | TEXT |
| Nationality | country_code | TEXT |
| Chipcount | chip_count | BIGINT |
| BB | bb_stack | INTEGER |
| TableNo | table_number | INTEGER |
| SeatNo | seat_number | INTEGER |

### 4.3 template → cue_templates 매핑

| 템플릿 타입 | DB template_type | 용도 |
|-------------|------------------|------|
| [LEFT]MINI_CHIP_TABLE | mini_chip_left | 좌측 미니 칩 테이블 |
| [RIGHT]MINI_CHIP_TABLE | mini_chip_right | 우측 미니 칩 테이블 |
| [LEFT]MINI_PAYOUTS_TABLE | mini_payouts | 좌측 상금 테이블 |
| [ELIMINATION AT RISK] | elimination_risk | 탈락 위험 표시 |
| [ELIMINATED] | eliminated | 탈락 표시 |
| FEATURE TABLE | feature_table_chip | 피처 테이블 |

---

## 5. 블라인드 레벨 참조

| Level | Blinds | Ante | Duration | Type |
|-------|--------|------|----------|------|
| 20 | 6K/12K | 12K | 60 min | - |
| 21 | 10K/15K | 15K | 60 min | HL |
| 22 | 10K/20K | 20K | 60 min | - |
| 25 | 20K/40K | 40K | 60 min | HL |
| 27 | 30K/60K | 60K | 60 min | HL |

**HL**: Highlight (칩 리더 확정 시점)

---

## 6. 파일 명명 규칙

### 6.1 핸드 파일

| 패턴 | 예시 | 설명 |
|------|------|------|
| `A_XXXX` | A_0001 | MAIN 테이블 핸드 |
| `B_XXXX` | B_0002 | SUB 테이블 핸드 |

### 6.2 버추얼 GFX 파일

| 패턴 | 예시 | 설명 |
|------|------|------|
| `HHMM_SCNNN_Description` | 1438_SC011_Mikhail_Shalamov_L3_Profile | 소프트 콘텐츠 |
| `HHMM_VTNNN_Description` | 1626_VT001_SIBGATOVA_lose | 버추얼 테이블 |
| `HHMM_SCNNN_OpeningNN` | 1413_SC001_Opening01 | 오프닝 시퀀스 |

---

## 7. 결론 및 권장사항

### 7.1 현재 스키마와의 차이점

| 항목 | Google Sheets | 현재 DB 스키마 | 권장 조치 |
|------|---------------|----------------|-----------|
| 시간대 | Cyprus + Seoul | recording_time (단일) | **Seoul 시간 필드 추가 고려** |
| 파일명 형식 | A_/B_/SC_/VT_ | file_name (단일) | **content_type으로 구분 가능** |
| 블라인드 정보 | Blinds 컬럼 | blind_level | 동일 |
| 칩카운트 | 별도 시트 | wsop_chip_counts 참조 | **기존 설계 유지** |

### 7.2 데이터 임포트 우선순위

1. **FRONT (LIVE)**: 통합 큐시트 → `cue_items`
2. **chipcount**: 실시간 칩카운트 → `wsop_chip_counts`
3. **leaderboard**: 최종 순위 → `wsop_chip_counts` (시점별)
4. **template**: GFX 템플릿 → `cue_templates`
5. **payout**: 상금 구조 → 별도 `payout_structures` 테이블 고려

### 7.3 추가 필요 필드

| 필드 | 타입 | 용도 |
|------|------|------|
| seoul_time | TIME | 서울 시간 |
| field_count | INTEGER | 남은 플레이어 수 |
| table_number | INTEGER | 테이블 번호 (main: 44186, sub: 44187) |

---

## Appendix A: 시트 GID 참조

| 시트명 | GID | URL |
|--------|-----|-----|
| INFO | 1451613436 | `gid=1451613436` |
| FRONT (LIVE) | 390049308 | `gid=390049308` |
| main | 495054819 | `gid=495054819` |
| sub | 360071413 | `gid=360071413` |
| virtual | 561799849 | `gid=561799849` |
| chipcount | 863418569 | `gid=863418569` |
| leaderboard | 369994611 | `gid=369994611` |
| payout | 1594013979 | `gid=1594013979` |
| template | 487939277 | `gid=487939277` |
| PD | 481406284 | `gid=481406284` |
| SUBTITLE | 1333911885 | `gid=1333911885` |
| FRONT (timeline) | 1427920466 | `gid=1427920466` |

---

## Appendix B: Day별 상세 블록 통계

### B.1 Day 1A (2024-10-17)

| BLOCK | MAIN | SUB | HANDS | VIRTUAL | Est. RT | Actual RT | BREAK |
|:-----:|:----:|:---:|:-----:|:-------:|--------:|----------:|------:|
| 1 | 5 | 7 | 12 | 4 | 0:35 | 00:38:12 | - |
| 2 | 6 | 8 | 14 | 3 | 0:42 | 00:45:30 | - |
| 3 | 4 | 6 | 10 | 2 | 0:28 | 00:32:15 | 0:15 |
| ... | ... | ... | ... | ... | ... | ... | ... |
| **합계** | **63** | **79** | **142** | **34** | **~7:00** | **06:49:19** | - |

### B.2 Day 2 (2024-10-18)

| BLOCK | MAIN | SUB | HANDS | VIRTUAL | Est. RT | Actual RT | BREAK |
|:-----:|:----:|:---:|:-----:|:-------:|--------:|----------:|------:|
| 1 | 5 | 6 | 11 | 3 | 0:32 | 00:35:45 | - |
| 2 | 4 | 5 | 9 | 2 | 0:26 | 00:28:30 | - |
| ... | ... | ... | ... | ... | ... | ... | ... |
| **합계** | **72** | **89** | **161** | **38** | **~13:00** | **08:06:29** | - |

### B.3 Day 3 (2024-10-19)

| BLOCK | MAIN | SUB | HANDS | VIRTUAL | Est. RT | Actual RT | BREAK |
|:-----:|:----:|:---:|:-----:|:-------:|--------:|----------:|------:|
| 1 | 11 | 8 | 19 | 5 | 0:56:20 | 01:01:02 | - |
| 2 | 6 | 6 | 12 | 7 | 0:37:30 | 00:37:43 | - |
| 3 | 4 | 5 | 9 | 2 | 0:25:00 | 00:27:16 | 0:15 |
| 7 | 0 | 15 | 15 | 1 | 0:30:30 | 00:31:50 | - |
| 11 | 5 | 7 | 12 | 3 | 0:25:30 | 00:31:16 | - |
| **합계** | **63** | **71** | **134** | **32** | **~11:00** | **06:19:52** | - |

### B.4 Day 4 (2024-10-20)

| BLOCK | MAIN | SUB | HANDS | VIRTUAL | Est. RT | Actual RT | BREAK |
|:-----:|:----:|:---:|:-----:|:-------:|--------:|----------:|------:|
| 1 | 6 | 7 | 13 | 2 | 0:38 | 00:42:18 | - |
| 2 | 5 | 6 | 11 | 1 | 0:32 | 00:35:45 | - |
| ... | ... | ... | ... | ... | ... | ... | ... |
| **합계** | **58** | **67** | **125** | **9** | **~6:00** | **06:28:56** | - |

### B.5 Day 5 Final (2024-10-21)

- **상태**: 템플릿 (데이터 미입력)
- **블록 수**: 7
- **예상 RT**: 00:54:00

---

## Appendix C: 데이터 임포트 전략

### C.1 임포트 우선순위

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    Google Sheets → Supabase 임포트 순서                      │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  [1] broadcast_sessions 생성                                                │
│       └─ Day별 세션 (Day 1A, Day 2, Day 3, Day 4, Day 5)                   │
│       └─ block_stats JSONB 업데이트                                        │
│                                                                             │
│  [2] cue_sheets 생성                                                        │
│       └─ session_id FK 연결                                                 │
│       └─ sheet_type: 'main_show' | 'backup'                                │
│                                                                             │
│  [3] cue_items 벌크 임포트                                                  │
│       └─ main/sub/virtual 시트 데이터                                       │
│       └─ content_type 구분                                                  │
│       └─ gfx_data JSONB                                                    │
│                                                                             │
│  [4] wsop_chip_counts 동기화                                                │
│       └─ chipcount/leaderboard 시트                                        │
│       └─ 시점별 스냅샷                                                      │
│                                                                             │
│  [5] cue_templates 초기화                                                   │
│       └─ template 시트                                                      │
│       └─ data_schema 정의                                                   │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### C.2 임포트 스크립트 예시

```python
# scripts/import_cuesheet.py

import gspread
from supabase import create_client
from pathlib import Path

SHEET_IDS = {
    "day1a": "1XiZqoZ3DggHdafWGEzN3PTbCNmTRSt8Ab1Ofclsoc34",
    "day2": "1N5urtYwKIPZTiZ83-GSHMaS2I3swGJd5Tdaugpoqu3A",
    "day3": "1-f5mQLVUmHqxg57Y7xGcQIZKiClUjQLrO8p095hbHAo",
    "day4": "1ZNW7QoVvfijtTMusvTVRb1UGeaVlMfN8UJh8T78zuZE",
    "day5": "10w7SJj8Q2JtxDnwgOQ0pNCB0D-AbGO10VQnT9b4wRwM",
}

def import_info_sheet(gc, sheet_id, supabase, session_id):
    """INFO 시트 → broadcast_sessions.block_stats"""
    sheet = gc.open_by_key(sheet_id)
    info = sheet.worksheet("INFO")
    data = info.get_all_records()

    blocks = []
    for row in data:
        if row.get("BLOCK"):
            blocks.append({
                "block_number": row["BLOCK"],
                "main_hands": row.get("MAIN", 0),
                "sub_hands": row.get("SUB", 0),
                "total_hands": row.get("HANDS", 0),
                "virtual_count": row.get("VIRTUAL", 0),
                "estimated_runtime": row.get("Estimated RT"),
                "actual_runtime": row.get("Actual RT"),
            })

    supabase.table("broadcast_sessions").update({
        "block_stats": {"blocks": blocks}
    }).eq("id", session_id).execute()

def import_main_sub_hands(gc, sheet_id, supabase, sheet_id_db):
    """main/sub 시트 → cue_items"""
    sheet = gc.open_by_key(sheet_id)

    for sheet_name, content_type in [("main", "main"), ("sub", "sub")]:
        ws = sheet.worksheet(sheet_name)
        data = ws.get_all_records()

        items = []
        for row in data:
            items.append({
                "sheet_id": sheet_id_db,
                "content_type": content_type,
                "hand_number": row.get("#"),
                "hand_rank": row.get("🏆"),
                "hand_history": row.get("Hand History"),
                "edit_point": row.get("Edit Point"),
                "pd_note": row.get("PD Note"),
                "recording_time": row.get("Cyprus"),
                "file_name": row.get("File"),
                "field_count": row.get("FIELD"),
            })

        supabase.table("cue_items").insert(items).execute()
```

### C.3 데이터 검증 쿼리

```sql
-- Day별 핸드 수 검증
SELECT
    bs.event_title,
    bs.day_number,
    (bs.block_stats->'totals'->>'total_hands')::int as expected_hands,
    (SELECT COUNT(*) FROM cue_items ci
     JOIN cue_sheets cs ON ci.sheet_id = cs.id
     WHERE cs.session_id = bs.id
     AND ci.content_type IN ('main', 'sub')) as actual_hands
FROM broadcast_sessions bs
WHERE bs.event_title LIKE 'WSOP SC Cyprus%';

-- 블록-핸드 일관성 검증
SELECT
    bs.day_number,
    block->>'block_number' as block_num,
    (block->>'total_hands')::int as block_hands,
    (SELECT COUNT(*) FROM cue_items ci
     JOIN cue_sheets cs ON ci.sheet_id = cs.id
     WHERE cs.session_id = bs.id
     AND ci.block_number = (block->>'block_number')::int) as actual_block_hands
FROM broadcast_sessions bs,
     jsonb_array_elements(bs.block_stats->'blocks') as block
WHERE bs.event_title LIKE 'WSOP SC Cyprus%';
```

---

## Appendix D: 변경 이력

| 버전 | 날짜 | 변경 내용 |
|------|------|----------|
| 2.0.0 | 2026-01-19 | Day 1A~Day 5 전체 분석 통합, 임포트 전략 추가 |
| 1.0.0 | 2026-01-19 | 초기 작성 (Day 3 단일 분석) |

---

**문서 작성**: Claude Code
**검증**: WSOP SC Cyprus ME Day 1A~Day 5 실제 Google Sheets 데이터 기반 분석
