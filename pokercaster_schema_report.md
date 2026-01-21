# table-pokercaster JSON 스키마 분석 리포트

**분석 파일 수**: 7개

**분석 폴더**: 1016, 1017, 1018, 1019, 1021

**총 필드 수**: 58개


---


## Root Level

**필드 수**: 6개


- **CreatedDateTimeUTC**: string: "2025-10-16T10:58:07.5783819Z" | string: "2025-10-17T11:19:12.4560670Z" | string: "2025-10-18T11:46:00.2984623Z"
- **EventTitle**: string: ""
- **Hands**: array[113]: [dict...] | array[130]: [dict...] | array[144]: [dict...]
- **ID**: integer: 638962090875783819 | integer: 638962967524560670 | integer: 638963847602984623
- **SoftwareVersion**: string: "PokerGFX 3.2"
- **Type**: string: "FEATURE_TABLE" | string: "FINAL_TABLE"

## Hands[]

**필드 수**: 14개


- **AnteAmt**: integer: 15000 | integer: 200000 | integer: 3000
- **BetStructure**: string: "NOLIMIT"
- **BombPotAmt**: integer: 0
- **Description**: string: ""
- **Duration**: string: "PT19.0628118S" | string: "PT1M13.8126823S" | string: "PT1M23.870148S"
- **Events**: array: [] | array[10]: [dict...] | array[15]: [dict...]
- **GameClass**: string: "FLOP"
- **GameVariant**: string: "HOLDEM"
- **HandNum**: integer: 1
- **NumBoards**: integer: 1
- **Players**: array[8]: [dict...]
- **RecordingOffsetStart**: string: "P739539DT14H37M27.4134621S" | string: "P739540DT14H26M49.5160775S" | string: "P739541DT15H10M4.6012766S"
- **RunItNumTimes**: integer: 1
- **StartDateTimeUTC**: string: "2025-10-16T11:37:27.4134621Z" | string: "2025-10-17T11:26:49.5160775Z" | string: "2025-10-18T12:10:04.6012766Z"

## Hands[].Events[]

**필드 수**: 8개


- **BetAmt**: integer: 0 | integer: 1000 | integer: 6500
- **BoardCards**: null
- **BoardNum**: integer: 0
- **DateTimeUTC**: null
- **EventType**: string: "BET" | string: "FOLD"
- **NumCardsDrawn**: integer: 0
- **PlayerNum**: integer: 2 | integer: 6 | integer: 7
- **Pot**: integer: 0 | integer: 1300 | integer: 7500

## Hands[].Players[]

**필드 수**: 14개


- **AggressionFrequencyPercent**: integer: 0 | integer: 40 | integer: 66
- **BlindBetStraddleAmt**: integer: 0
- **CumulativeWinningsAmt**: integer: -19000 | integer: -40000 | integer: 0
- **EliminationRank**: integer: -1
- **EndStackAmt**: integer: 1220000 | integer: 23000 | integer: 2975000
- **HoleCards**: array[1]: [str...]
- **LongName**: string: "Demirkol" | string: "Konstantin Voronin" | string: "Korochenskiy"
- **Name**: string: "ANZULEWICZ" | string: "Demirkol" | string: "Korochenskiy"
- **PlayerNum**: integer: 2
- **PreFlopRaisePercent**: integer: 0 | integer: 100
- **SittingOut**: boolean: False
- **StartStackAmt**: integer: 109500 | integer: 1220000 | integer: 2975000
- **VPIPPercent**: integer: 0 | integer: 100
- **WentToShowDownPercent**: integer: 0 | integer: 100

## Hands[].FlopDrawBlinds

**필드 수**: 10개


- **Hands[].FlopDrawBlinds**: object: {9 keys}
- **AnteType**: string: "BB_ANTE_BB1ST"
- **BigBlindAmt**: integer: 15000 | integer: 200000 | integer: 3000
- **BigBlindPlayerNum**: integer: 2 | integer: 5 | integer: 6
- **BlindLevel**: integer: 0
- **ButtonPlayerNum**: integer: 10 | integer: 3 | integer: 4
- **SmallBlindAmt**: integer: 10000 | integer: 100000 | integer: 1500
- **SmallBlindPlayerNum**: integer: 1 | integer: 4 | integer: 5
- **ThirdBlindAmt**: integer: 0
- **ThirdBlindPlayerNum**: integer: 0

## Hands[].StudLimits

**필드 수**: 5개


- **Hands[].StudLimits**: object: {4 keys}
- **BringInAmt**: integer: 0
- **BringInPlayerNum**: integer: 1
- **HighLimitAmt**: integer: 0
- **LowLimitAmt**: integer: 0

## Payouts[]

**필드 수**: 1개


- **Payouts**: array[10]: [int...]