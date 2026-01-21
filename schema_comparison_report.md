# table-pokercaster vs table-GG 스키마 비교

**분석 일시**: 2026-01-19

**Pokercaster 필드 수**: 58개

**GG 필드 수**: 58개

**공통 필드 수**: 58개


---


## Pokercaster 전용 필드 (0개)


> GG에는 없고 Pokercaster에만 존재하는 필드


## GG 전용 필드 (0개)


> Pokercaster에는 없고 GG에만 존재하는 필드


## 공통 필드 (58개)


> 양쪽 모두에 존재하는 필드


### Root Level (7개)

- `CreatedDateTimeUTC`
- `EventTitle`
- `Hands`
- `ID`
- `Payouts`
- `SoftwareVersion`
- `Type`

### Hands[] (14개)

- `Hands[].AnteAmt`
- `Hands[].BetStructure`
- `Hands[].BombPotAmt`
- `Hands[].Description`
- `Hands[].Duration`
- `Hands[].Events`
- `Hands[].GameClass`
- `Hands[].GameVariant`
- `Hands[].HandNum`
- `Hands[].NumBoards`
- `Hands[].Players`
- `Hands[].RecordingOffsetStart`
- `Hands[].RunItNumTimes`
- `Hands[].StartDateTimeUTC`

### Events[] (8개)

- `Hands[].Events[].BetAmt`
- `Hands[].Events[].BoardCards`
- `Hands[].Events[].BoardNum`
- `Hands[].Events[].DateTimeUTC`
- `Hands[].Events[].EventType`
- `Hands[].Events[].NumCardsDrawn`
- `Hands[].Events[].PlayerNum`
- `Hands[].Events[].Pot`

### Players[] (14개)

- `Hands[].Players[].AggressionFrequencyPercent`
- `Hands[].Players[].BlindBetStraddleAmt`
- `Hands[].Players[].CumulativeWinningsAmt`
- `Hands[].Players[].EliminationRank`
- `Hands[].Players[].EndStackAmt`
- `Hands[].Players[].HoleCards`
- `Hands[].Players[].LongName`
- `Hands[].Players[].Name`
- `Hands[].Players[].PlayerNum`
- `Hands[].Players[].PreFlopRaisePercent`
- `Hands[].Players[].SittingOut`
- `Hands[].Players[].StartStackAmt`
- `Hands[].Players[].VPIPPercent`
- `Hands[].Players[].WentToShowDownPercent`

### FlopDrawBlinds (10개)

- `Hands[].FlopDrawBlinds`
- `Hands[].FlopDrawBlinds.AnteType`
- `Hands[].FlopDrawBlinds.BigBlindAmt`
- `Hands[].FlopDrawBlinds.BigBlindPlayerNum`
- `Hands[].FlopDrawBlinds.BlindLevel`
- `Hands[].FlopDrawBlinds.ButtonPlayerNum`
- `Hands[].FlopDrawBlinds.SmallBlindAmt`
- `Hands[].FlopDrawBlinds.SmallBlindPlayerNum`
- `Hands[].FlopDrawBlinds.ThirdBlindAmt`
- `Hands[].FlopDrawBlinds.ThirdBlindPlayerNum`

### StudLimits (5개)

- `Hands[].StudLimits`
- `Hands[].StudLimits.BringInAmt`
- `Hands[].StudLimits.BringInPlayerNum`
- `Hands[].StudLimits.HighLimitAmt`
- `Hands[].StudLimits.LowLimitAmt`