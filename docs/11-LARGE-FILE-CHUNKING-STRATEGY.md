# 11. 대용량 파일 청킹 전략

**Version**: 1.0.0
**Last Updated**: 2026-01-19
**Status**: Active
**Project**: Automation DB Schema

---

## 1. 개요

### 1.1 목적

256KB 이상의 대용량 파일에 대한 청킹(분할) 전략을 정의합니다.

### 1.2 256KB 초과 파일 현황

| 파일 유형 | 개수 | 위치 | 최대 크기 |
|----------|------|------|----------|
| GFX JSON 데이터 | 11개 | `gfx_json_data/table-*/*.json` | 800KB |
| 문서 파일 (.md) | **0개** | - | 86KB (최대) |
| SQL 파일 | **0개** | - | 194KB (최대) |

**결론**: 256KB 초과 파일은 **모두 GFX JSON 원본 데이터 파일**입니다.

### 1.3 문서 파일 (JSON 제외) 크기 분포

| 크기 범위 | 파일 수 | 대표 파일 | 청킹 필요 |
|----------|--------|----------|----------|
| 256KB+ | **0개** | - | 불필요 |
| 100-256KB | 1개 | `schema_dump.sql` (194KB) | 권장 (선택) |
| 50-100KB | 5개 | `08-GFX-AEP-Mapping.md` (86KB) | 불필요 |
| 20-50KB | 15개 | 대부분 문서/마이그레이션 | 불필요 |
| 20KB 미만 | 다수 | 소형 문서 | 불필요 |

**결론**: 문서 파일은 **청킹이 필요 없습니다**. 모든 파일이 256KB 미만입니다.

---

## 2. 대용량 파일 상세

### 2.1 파일 목록 (256KB+)

| 파일명 | 크기 | 소스 | Hands 수 (추정) |
|--------|------|------|-----------------|
| GameID=638963849867159576.json | 800KB | table-GG | ~100+ |
| GameID=638963847602984623.json | 756KB | table-pokercaster | ~90+ |
| GameID=638962967524560670.json | 681KB | table-pokercaster | ~80+ |
| GameID=638962090875783819.json | 605KB | table-pokercaster | ~70+ |
| GameID=638966318331324926.json | 563KB | table-pokercaster | ~65+ |
| GameID=638965461665708016.json | 521KB | table-pokercaster | ~60+ |
| GameID=638962097323397879.json | 502KB | table-GG | ~55+ |
| GameID=638963043524931047.json | 494KB | table-GG | ~55+ |
| GameID=638964611175191251.json | 381KB | table-GG | ~45+ |
| GameID=638965539561171011.json | 325KB | table-GG | ~40+ |
| GameID=638964605283023723.json | 323KB | table-pokercaster | ~40+ |

### 2.2 GFX JSON 구조

```json
{
  "CreatedDateTimeUTC": "ISO8601",
  "EventTitle": "string",
  "ID": "int64 (GameID)",
  "SoftwareVersion": "string",
  "Type": "FEATURE_TABLE | ...",
  "Payouts": [...],
  "Hands": [
    {
      "HandNum": 1,
      "Players": [...],      // 8-10 플레이어
      "Events": [...],       // 핸드당 10-50 이벤트
      "FlopDrawBlinds": {},
      ...
    },
    // ... 수십~수백 개의 핸드
  ]
}
```

**파일 크기 결정 요인**: `Hands[]` 배열 길이 (핸드 수 × 플레이어 수 × 이벤트 수)

---

## 3. 청킹 전략

### 3.1 전략 선택

| 전략 | 설명 | 적합성 |
|------|------|--------|
| **A. Hands 기반 분할** | 핸드 단위로 분할 | **권장** |
| B. 시간 기반 분할 | 시간 범위로 분할 | 부적합 |
| C. 크기 기반 분할 | 고정 크기로 분할 | 구조 파괴 |

### 3.2 권장: Hands 기반 분할 (전략 A)

```
원본: GameID=638963849867159576.json (800KB, 100+ hands)
      │
      ▼
청킹: ┌─────────────────────────────────────────────────┐
      │ GameID=638963849867159576_meta.json (메타데이터) │
      │ - CreatedDateTimeUTC, EventTitle, ID, Type      │
      │ - Payouts[], SoftwareVersion                    │
      │ - chunk_count: 5                                │
      └─────────────────────────────────────────────────┘
      │
      ├─ GameID=638963849867159576_hands_001-020.json
      ├─ GameID=638963849867159576_hands_021-040.json
      ├─ GameID=638963849867159576_hands_041-060.json
      ├─ GameID=638963849867159576_hands_061-080.json
      └─ GameID=638963849867159576_hands_081-100.json
```

### 3.3 청킹 규칙

| 규칙 | 값 | 설명 |
|------|-----|------|
| 청크 크기 | 20 hands | 약 150-200KB |
| 파일명 패턴 | `{GameID}_hands_{start}-{end}.json` | 범위 명시 |
| 메타 파일 | `{GameID}_meta.json` | 공통 정보 분리 |
| 인덱스 파일 | `{GameID}_index.json` | 청크 목록 및 매핑 |

### 3.4 인덱스 파일 구조

```json
{
  "game_id": 638963849867159576,
  "original_file": "PGFX_live_data_export GameID=638963849867159576.json",
  "original_size_kb": 800,
  "total_hands": 100,
  "chunk_size": 20,
  "chunks": [
    {
      "file": "GameID=638963849867159576_hands_001-020.json",
      "hand_range": [1, 20],
      "size_kb": 160
    },
    {
      "file": "GameID=638963849867159576_hands_021-040.json",
      "hand_range": [21, 40],
      "size_kb": 155
    }
    // ...
  ],
  "meta_file": "GameID=638963849867159576_meta.json"
}
```

---

## 4. 구현 방안

### 4.1 청킹 스크립트

위치: `scripts/chunk_gfx_json.py`

```python
#!/usr/bin/env python3
"""GFX JSON 대용량 파일 청킹 스크립트"""

import json
import os
from pathlib import Path
from typing import Any

CHUNK_SIZE = 20  # 청크당 핸드 수
SIZE_THRESHOLD_KB = 256  # 청킹 대상 크기 임계값


def chunk_gfx_json(input_path: Path, output_dir: Path) -> dict:
    """GFX JSON 파일을 청크로 분할"""

    with open(input_path, 'r', encoding='utf-8') as f:
        data = json.load(f)

    game_id = data.get('ID', input_path.stem.split('=')[-1])
    hands = data.get('Hands', [])
    total_hands = len(hands)

    if total_hands == 0:
        return {"status": "skip", "reason": "no hands"}

    # 메타데이터 분리
    meta = {k: v for k, v in data.items() if k != 'Hands'}
    meta['total_hands'] = total_hands
    meta['chunk_size'] = CHUNK_SIZE

    # 청크 생성
    chunks = []
    for i in range(0, total_hands, CHUNK_SIZE):
        chunk_hands = hands[i:i + CHUNK_SIZE]
        start = i + 1
        end = min(i + CHUNK_SIZE, total_hands)

        chunk_file = f"GameID={game_id}_hands_{start:03d}-{end:03d}.json"
        chunk_path = output_dir / chunk_file

        with open(chunk_path, 'w', encoding='utf-8') as f:
            json.dump({"Hands": chunk_hands}, f, indent=2)

        chunks.append({
            "file": chunk_file,
            "hand_range": [start, end],
            "size_kb": round(chunk_path.stat().st_size / 1024, 1)
        })

    # 메타 파일 저장
    meta_file = f"GameID={game_id}_meta.json"
    meta_path = output_dir / meta_file
    with open(meta_path, 'w', encoding='utf-8') as f:
        json.dump(meta, f, indent=2)

    # 인덱스 파일 생성
    index = {
        "game_id": game_id,
        "original_file": input_path.name,
        "original_size_kb": round(input_path.stat().st_size / 1024, 1),
        "total_hands": total_hands,
        "chunk_size": CHUNK_SIZE,
        "chunks": chunks,
        "meta_file": meta_file
    }

    index_file = f"GameID={game_id}_index.json"
    index_path = output_dir / index_file
    with open(index_path, 'w', encoding='utf-8') as f:
        json.dump(index, f, indent=2)

    return {
        "status": "success",
        "game_id": game_id,
        "total_hands": total_hands,
        "chunks_created": len(chunks),
        "index_file": str(index_path)
    }
```

### 4.2 사용 예시

```powershell
# 단일 파일 청킹
python scripts/chunk_gfx_json.py \
  --input "gfx_json_data/table-GG/1018/PGFX_live_data_export GameID=638963849867159576.json" \
  --output "gfx_json_data/table-GG/1018/chunked/"

# 전체 대용량 파일 일괄 청킹
python scripts/chunk_gfx_json.py --scan-all --threshold 256
```

---

## 5. 디렉토리 구조

### 5.1 청킹 전

```
gfx_json_data/
├── table-GG/
│   ├── 1018/
│   │   └── PGFX_live_data_export GameID=638963849867159576.json (800KB)
│   └── ...
└── table-pokercaster/
    └── ...
```

### 5.2 청킹 후

```
gfx_json_data/
├── table-GG/
│   ├── 1018/
│   │   ├── PGFX_live_data_export GameID=638963849867159576.json (원본, 보관)
│   │   └── chunked/
│   │       ├── GameID=638963849867159576_index.json
│   │       ├── GameID=638963849867159576_meta.json
│   │       ├── GameID=638963849867159576_hands_001-020.json
│   │       ├── GameID=638963849867159576_hands_021-040.json
│   │       └── ...
│   └── ...
└── table-pokercaster/
    └── ...
```

---

## 6. 인덱싱 전략

### 6.1 마스터 인덱스

위치: `gfx_json_data/master_index.json`

```json
{
  "version": "1.0.0",
  "last_updated": "2026-01-19T00:00:00Z",
  "total_files": 28,
  "total_hands": 939,
  "chunked_files": 11,
  "sources": {
    "table-GG": {
      "file_count": 18,
      "hand_count": 323,
      "dates": ["2025-10-15", "2025-10-20"]
    },
    "table-pokercaster": {
      "file_count": 10,
      "hand_count": 616,
      "dates": ["2025-10-16", "2025-10-21"]
    }
  },
  "large_files": [
    {
      "original": "table-GG/1018/PGFX_live_data_export GameID=638963849867159576.json",
      "index": "table-GG/1018/chunked/GameID=638963849867159576_index.json",
      "size_kb": 800,
      "hands": 100
    }
    // ...
  ]
}
```

### 6.2 검색 인덱스

위치: `gfx_json_data/search_index.json`

```json
{
  "by_date": {
    "2025-10-18": [
      "table-GG/1018/PGFX_live_data_export GameID=638963849867159576.json"
    ]
  },
  "by_player": {
    "Tony Lin": ["GameID=638963849867159576", "GameID=638964611175191251"],
    "Daniel Negreanu": ["GameID=638962967524560670"]
  },
  "by_hand_count": {
    "100+": ["GameID=638963849867159576"],
    "50-99": ["GameID=638962967524560670", "GameID=638965461665708016"],
    "1-49": ["GameID=638961224831992165", ...]
  }
}
```

---

## 7. 데이터 접근 패턴

### 7.1 청킹된 파일 읽기

```python
def load_gfx_game(game_id: int, base_dir: Path) -> dict:
    """청킹된 GFX 게임 데이터 로드"""

    # 인덱스 파일 찾기
    index_pattern = f"GameID={game_id}_index.json"
    index_files = list(base_dir.rglob(index_pattern))

    if not index_files:
        # 원본 파일 직접 로드
        return load_original_file(game_id, base_dir)

    index_path = index_files[0]
    with open(index_path, 'r') as f:
        index = json.load(f)

    # 메타데이터 로드
    meta_path = index_path.parent / index['meta_file']
    with open(meta_path, 'r') as f:
        data = json.load(f)

    # 청크별 핸드 로드
    data['Hands'] = []
    for chunk in index['chunks']:
        chunk_path = index_path.parent / chunk['file']
        with open(chunk_path, 'r') as f:
            chunk_data = json.load(f)
            data['Hands'].extend(chunk_data['Hands'])

    return data
```

### 7.2 특정 핸드 범위만 로드

```python
def load_hands_range(game_id: int, start: int, end: int, base_dir: Path) -> list:
    """특정 핸드 범위만 효율적으로 로드"""

    index_path = find_index_file(game_id, base_dir)
    with open(index_path, 'r') as f:
        index = json.load(f)

    hands = []
    for chunk in index['chunks']:
        chunk_start, chunk_end = chunk['hand_range']

        # 범위 겹침 확인
        if chunk_end < start or chunk_start > end:
            continue

        chunk_path = index_path.parent / chunk['file']
        with open(chunk_path, 'r') as f:
            chunk_data = json.load(f)

        for hand in chunk_data['Hands']:
            if start <= hand['HandNum'] <= end:
                hands.append(hand)

    return hands
```

---

## 8. 마이그레이션 가이드

### 8.1 기존 코드 호환성

| 기존 코드 | 수정 필요 여부 | 설명 |
|----------|--------------|------|
| `gfx_normalizer.py` | 수정 필요 | 청킹된 파일 지원 추가 |
| `analyze_*.py` | 수정 필요 | 인덱스 기반 로딩 |
| `validate_*.py` | 수정 필요 | 청크 무결성 검증 |

### 8.2 마이그레이션 단계

1. **Phase 1**: 청킹 스크립트 구현 및 테스트
2. **Phase 2**: 11개 대용량 파일 청킹 실행
3. **Phase 3**: 마스터/검색 인덱스 생성
4. **Phase 4**: 기존 스크립트 업데이트
5. **Phase 5**: 원본 파일 아카이브 (선택)

---

## 9. 권장사항

### 9.1 즉시 적용

| 항목 | 권장 조치 |
|------|----------|
| 원본 보존 | 원본 파일은 삭제하지 않고 보관 |
| 점진적 적용 | 필요 시에만 청킹 수행 |
| 인덱스 유지 | 마스터 인덱스 자동 업데이트 |

### 9.2 향후 고려사항

| 항목 | 설명 |
|------|------|
| DB 정규화 | 대용량 JSON → Supabase 테이블 직접 적재 |
| 스트리밍 처리 | 메모리 효율적 JSON 파싱 (ijson 등) |
| 압축 | gzip 압축으로 저장 공간 절약 |

---

## 10. 변경 이력

| 버전 | 날짜 | 변경 내용 |
|------|------|----------|
| 1.0.0 | 2026-01-19 | 초기 작성 |
