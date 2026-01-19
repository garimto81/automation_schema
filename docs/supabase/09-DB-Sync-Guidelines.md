# 09. PostgreSQL ↔ Supabase DB 동기화 지침

**Version**: 1.0.0
**Last Updated**: 2026-01-17
**Status**: Active
**Project**: Feature Table Automation (FT-0001)

---

## 1. 개요

### 1.1 목적

External PostgreSQL (Production Source)와 Supabase (Managed Target) 간의 데이터 동기화를 위한 아키텍처, 전략, 운영 지침을 정의합니다.

### 1.2 적용 범위

| 데이터베이스 | 역할 | 호스트 |
|-------------|------|--------|
| External PostgreSQL | Production Source (GFX, WSOP+ 원본) | 자체 서버 |
| Supabase PostgreSQL | Managed Target (렌더링, API) | Supabase Cloud |

### 1.3 동기화 원칙

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         동기화 핵심 원칙                                      │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  1️⃣ Single Source of Truth (SSOT)                                         │
│     - GFX 원본 데이터: External PostgreSQL이 절대 우선                      │
│     - Override 데이터: Supabase가 우선 (UI 편집)                            │
│                                                                             │
│  2️⃣ Eventually Consistent                                                  │
│     - 실시간 동기화 목표, 일시적 불일치 허용 (< 5분)                        │
│     - 충돌 시 timestamp 기반 Last-Write-Wins                                │
│                                                                             │
│  3️⃣ Idempotent Operations                                                  │
│     - 모든 동기화 작업은 멱등성 보장                                        │
│     - 중복 실행 시에도 동일한 결과                                          │
│                                                                             │
│  4️⃣ Audit Trail                                                            │
│     - 모든 동기화 작업은 sync_log에 기록                                    │
│     - 실패 시 자동 재시도 및 알림                                           │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 2. 동기화 아키텍처

### 2.1 데이터 흐름 다이어그램

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    PostgreSQL ↔ Supabase 동기화 아키텍처                      │
└─────────────────────────────────────────────────────────────────────────────┘

┌──────────────────────┐                         ┌──────────────────────┐
│   External PostgreSQL │                         │       Supabase       │
│   (Production Source) │                         │   (Managed Target)   │
├──────────────────────┤                         ├──────────────────────┤
│                      │                         │                      │
│  ┌────────────────┐  │    ┌──────────────┐     │  ┌────────────────┐  │
│  │ gfx_sessions   │  │    │              │     │  │ gfx_sessions   │  │
│  │ gfx_hands      │──┼───▶│  CDC Stream  │────▶│  │ gfx_hands      │  │
│  │ gfx_hand_players│ │    │  (Debezium)  │     │  │ gfx_hand_players│ │
│  │ gfx_players    │  │    │              │     │  │ gfx_players    │  │
│  └────────────────┘  │    └──────────────┘     │  └────────────────┘  │
│                      │                         │                      │
│  ┌────────────────┐  │    ┌──────────────┐     │  ┌────────────────┐  │
│  │ wsop_events    │  │    │              │     │  │ wsop_events    │  │
│  │ wsop_players   │──┼───▶│ Batch Sync   │────▶│  │ wsop_players   │  │
│  │ wsop_chip_counts│ │    │  (15분 주기) │     │  │ wsop_chip_counts│ │
│  └────────────────┘  │    └──────────────┘     │  └────────────────┘  │
│                      │                         │                      │
│  ┌────────────────┐  │    ┌──────────────┐     │  ┌────────────────┐  │
│  │ render_queue   │◀─┼────│  Realtime    │◀────│  │ render_queue   │  │
│  │ (결과 수신)     │  │    │ Subscription │     │  │ (작업 생성)     │  │
│  └────────────────┘  │    └──────────────┘     │  └────────────────┘  │
│                      │                         │                      │
│  ┌────────────────┐  │    ┌──────────────┐     │  ┌────────────────┐  │
│  │ player_overrides│◀┼───▶│  Bi-directional│◀──▶│ │ player_overrides│ │
│  │ profile_images │  │    │  Event Sync  │     │  │ profile_images │  │
│  └────────────────┘  │    └──────────────┘     │  └────────────────┘  │
│                      │                         │                      │
└──────────────────────┘                         └──────────────────────┘
```

### 2.2 동기화 방식별 상세

| 테이블 그룹 | 방식 | 빈도 | 방향 | 우선순위 |
|------------|------|------|------|----------|
| **GFX 핸드 데이터** | CDC (Debezium) | 실시간 (< 1초) | External → Supabase | External 절대 우선 |
| **WSOP+ 데이터** | Batch Sync | 15분 | External → Supabase | External 우선 |
| **Override/프로필** | Event-driven | 변경 시 | 양방향 | Supabase 우선 |
| **렌더링 큐** | Supabase Realtime | 실시간 | Supabase → External | Supabase 우선 |
| **큐시트** | Supabase Realtime | 실시간 | 양방향 | Last-Write-Wins |

---

## 3. CDC (Change Data Capture) 설정

### 3.1 Debezium Connector 설정

```json
{
  "name": "gfx-postgres-connector",
  "config": {
    "connector.class": "io.debezium.connector.postgresql.PostgresConnector",
    "database.hostname": "external-postgres-host",
    "database.port": "5432",
    "database.user": "debezium",
    "database.password": "${secrets.DEBEZIUM_PASSWORD}",
    "database.dbname": "gfx_production",
    "database.server.name": "gfx_cdc",
    "table.include.list": "public.gfx_sessions,public.gfx_hands,public.gfx_hand_players,public.gfx_players",
    "plugin.name": "pgoutput",
    "slot.name": "gfx_slot",
    "publication.name": "gfx_publication",
    "transforms": "route",
    "transforms.route.type": "org.apache.kafka.connect.transforms.RegexRouter",
    "transforms.route.regex": "gfx_cdc.public.(.*)",
    "transforms.route.replacement": "gfx.$1"
  }
}
```

### 3.2 PostgreSQL Logical Replication 설정

```sql
-- External PostgreSQL에서 실행
-- 1. wal_level 설정 확인
SHOW wal_level;  -- 'logical' 이어야 함

-- 2. Publication 생성
CREATE PUBLICATION gfx_publication FOR TABLE
    gfx_sessions,
    gfx_hands,
    gfx_hand_players,
    gfx_players;

-- 3. Replication Slot 생성
SELECT pg_create_logical_replication_slot('gfx_slot', 'pgoutput');
```

### 3.3 Kafka Consumer (Supabase 적용)

```python
# sync_worker.py
from kafka import KafkaConsumer
from supabase import create_client
import json

consumer = KafkaConsumer(
    'gfx.gfx_sessions',
    'gfx.gfx_hands',
    'gfx.gfx_hand_players',
    'gfx.gfx_players',
    bootstrap_servers=['kafka:9092'],
    value_deserializer=lambda m: json.loads(m.decode('utf-8'))
)

supabase = create_client(SUPABASE_URL, SUPABASE_SERVICE_KEY)

for message in consumer:
    table = message.topic.split('.')[-1]
    payload = message.value['payload']
    operation = payload['op']  # 'c' (create), 'u' (update), 'd' (delete)

    if operation == 'c':
        supabase.table(table).insert(payload['after']).execute()
    elif operation == 'u':
        supabase.table(table).update(payload['after']).eq('id', payload['after']['id']).execute()
    elif operation == 'd':
        supabase.table(table).delete().eq('id', payload['before']['id']).execute()

    # sync_log 기록
    log_sync_operation(table, operation, payload)
```

---

## 4. Batch Sync 설정

### 4.1 WSOP+ 데이터 동기화 스크립트

```python
# batch_sync_wsop.py
import schedule
from datetime import datetime, timedelta

def sync_wsop_events():
    """WSOP 이벤트 동기화 (15분 주기)"""

    # 1. External에서 변경된 데이터 조회
    last_sync = get_last_sync_time('wsop', 'events')
    external_data = external_db.query("""
        SELECT * FROM wsop_events
        WHERE updated_at > %s
        ORDER BY updated_at
    """, [last_sync])

    # 2. Supabase에 UPSERT
    for event in external_data:
        supabase.table('wsop_events').upsert(
            event,
            on_conflict='id'
        ).execute()

    # 3. sync_status 업데이트
    update_sync_status('wsop', 'events', 'synced')

def sync_wsop_players():
    """WSOP 플레이어 동기화"""
    # 동일 패턴...

def sync_wsop_chip_counts():
    """WSOP 칩 카운트 동기화"""
    # 동일 패턴...

# 스케줄 등록
schedule.every(15).minutes.do(sync_wsop_events)
schedule.every(15).minutes.do(sync_wsop_players)
schedule.every(15).minutes.do(sync_wsop_chip_counts)
```

### 4.2 sync_status 테이블 활용

```sql
-- 동기화 상태 확인
SELECT
    source,
    entity_type,
    status,
    last_synced_at,
    consecutive_failures,
    CASE
        WHEN consecutive_failures > 3 THEN 'CRITICAL'
        WHEN consecutive_failures > 0 THEN 'WARNING'
        WHEN last_synced_at < NOW() - sync_interval THEN 'STALE'
        ELSE 'HEALTHY'
    END AS health_status
FROM sync_status
ORDER BY health_status DESC;
```

---

## 5. 양방향 동기화 (Override/Profile)

### 5.1 충돌 해결 전략

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         충돌 해결 Matrix                                      │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  데이터 유형           충돌 발생 시 우선순위                                  │
│  ─────────────────────────────────────────────────────────────             │
│  GFX 원본 데이터       External PostgreSQL 절대 우선                        │
│                        (Supabase 변경 거부)                                 │
│                                                                             │
│  Override 데이터       Supabase 우선 (UI 편집)                              │
│  (player_overrides)    Last-Write-Wins (timestamp)                          │
│                                                                             │
│  Profile 이미지        Supabase 우선 (관리자 업로드)                         │
│  (profile_images)      Last-Write-Wins (timestamp)                          │
│                                                                             │
│  큐시트 데이터         Last-Write-Wins (timestamp)                          │
│  (cue_sheets)          양측 동등                                            │
│                                                                             │
│  렌더링 결과           Supabase 절대 우선                                   │
│  (render_queue)        (External은 읽기 전용)                                │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 5.2 양방향 동기화 트리거

```sql
-- Supabase에서 설정 (player_overrides 변경 감지)
CREATE OR REPLACE FUNCTION notify_override_change()
RETURNS TRIGGER AS $$
BEGIN
    -- Supabase Realtime으로 변경 알림
    PERFORM pg_notify(
        'override_changes',
        json_build_object(
            'table', TG_TABLE_NAME,
            'operation', TG_OP,
            'id', COALESCE(NEW.id, OLD.id),
            'timestamp', NOW()
        )::TEXT
    );
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_override_notify
    AFTER INSERT OR UPDATE OR DELETE ON player_overrides
    FOR EACH ROW
    EXECUTE FUNCTION notify_override_change();
```

### 5.3 External PostgreSQL 수신 처리

```python
# override_listener.py
import asyncio
from supabase import create_client

async def listen_override_changes():
    """Supabase override 변경 수신"""

    supabase = create_client(SUPABASE_URL, SUPABASE_KEY)

    # Realtime 구독
    channel = supabase.channel('override-changes')

    async def handle_change(payload):
        table = payload['table']
        operation = payload['eventType']
        record = payload['new'] or payload['old']

        # External DB에 적용
        if operation == 'INSERT':
            external_db.execute(
                f"INSERT INTO {table} VALUES (...) ON CONFLICT DO NOTHING"
            )
        elif operation == 'UPDATE':
            # timestamp 비교 후 적용
            external_record = external_db.query(
                f"SELECT updated_at FROM {table} WHERE id = %s",
                [record['id']]
            )
            if record['updated_at'] > external_record['updated_at']:
                external_db.execute(f"UPDATE {table} SET ... WHERE id = %s")
        elif operation == 'DELETE':
            external_db.execute(f"DELETE FROM {table} WHERE id = %s")

    channel.on('postgres_changes',
               event='*',
               schema='public',
               table='player_overrides',
               callback=handle_change)

    await channel.subscribe()
```

---

## 6. 모니터링 및 알림

### 6.1 건강 상태 대시보드 뷰

> **참고**: 07-Supabase-Orchestration.md의 `v_sync_dashboard` 뷰와 유사한 기능. 아래는 확장 버전.

```sql
-- v_sync_dashboard 뷰 확장 (건강 상태 포함)
CREATE OR REPLACE VIEW v_sync_dashboard AS
SELECT
    source,
    entity_type,
    status,
    last_synced_at,
    records_synced,
    records_failed,
    consecutive_failures,
    sync_interval,
    next_sync_at,
    -- 건강 상태 판정
    CASE
        WHEN consecutive_failures > 5 THEN 'CRITICAL'
        WHEN consecutive_failures > 2 THEN 'WARNING'
        WHEN last_synced_at < NOW() - sync_interval * 2 THEN 'STALE'
        WHEN status = 'failed' THEN 'ERROR'
        ELSE 'HEALTHY'
    END AS health_status,
    -- 지연 시간
    EXTRACT(EPOCH FROM (NOW() - last_synced_at)) AS lag_seconds
FROM sync_status
ORDER BY
    CASE
        WHEN consecutive_failures > 5 THEN 1
        WHEN consecutive_failures > 2 THEN 2
        WHEN status = 'failed' THEN 3
        ELSE 4
    END,
    last_synced_at;
```

### 6.2 알림 규칙

```sql
-- 알림 생성 함수
CREATE OR REPLACE FUNCTION check_sync_health_and_notify()
RETURNS VOID AS $$
DECLARE
    v_unhealthy RECORD;
BEGIN
    FOR v_unhealthy IN
        SELECT * FROM v_sync_dashboard
        WHERE health_status IN ('CRITICAL', 'ERROR')
    LOOP
        -- 알림 생성
        INSERT INTO notifications (
            type,
            severity,
            title,
            message,
            metadata,
            target_user
        ) VALUES (
            'sync_failure',
            CASE v_unhealthy.health_status
                WHEN 'CRITICAL' THEN 'critical'
                ELSE 'error'
            END,
            '동기화 실패: ' || v_unhealthy.source || '.' || v_unhealthy.entity_type,
            '연속 실패 ' || v_unhealthy.consecutive_failures || '회. 마지막 동기화: ' ||
                v_unhealthy.last_synced_at,
            jsonb_build_object(
                'source', v_unhealthy.source,
                'entity_type', v_unhealthy.entity_type,
                'lag_seconds', v_unhealthy.lag_seconds
            ),
            'admin'
        );
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- 5분마다 건강 체크
-- (pg_cron 또는 외부 스케줄러 사용)
```

### 6.3 자동 복구 메커니즘

```sql
-- 실패한 동기화 자동 재시도
CREATE OR REPLACE FUNCTION retry_failed_syncs()
RETURNS INTEGER AS $$
DECLARE
    v_retry_count INTEGER := 0;
BEGIN
    -- 5회 미만 실패, 5분 이상 경과한 건 재시도
    UPDATE sync_status
    SET
        status = 'pending',
        next_sync_at = NOW()
    WHERE status = 'failed'
      AND consecutive_failures < 5
      AND last_synced_at < NOW() - INTERVAL '5 minutes';

    GET DIAGNOSTICS v_retry_count = ROW_COUNT;

    -- 로그 기록
    IF v_retry_count > 0 THEN
        INSERT INTO activity_log (action, entity_type, details)
        VALUES ('sync_retry', 'sync_status',
                jsonb_build_object('retry_count', v_retry_count));
    END IF;

    RETURN v_retry_count;
END;
$$ LANGUAGE plpgsql;
```

---

## 7. 롤백 및 복구

### 7.1 롤백 절차

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         동기화 롤백 절차                                      │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  1️⃣ 동기화 중단                                                            │
│     - CDC Connector 일시 중지                                               │
│     - Batch Sync 스케줄러 중단                                              │
│     - Realtime 구독 해제                                                    │
│                                                                             │
│  2️⃣ 영향 범위 파악                                                         │
│     - sync_log에서 최근 변경 이력 조회                                      │
│     - 영향받은 테이블 및 레코드 식별                                        │
│                                                                             │
│  3️⃣ 데이터 복구                                                            │
│     - External PostgreSQL 기준으로 Supabase 복구 (GFX 데이터)              │
│     - Supabase 기준으로 External 복구 (Override 데이터)                     │
│                                                                             │
│  4️⃣ 동기화 재개                                                            │
│     - 복구 완료 확인 후 동기화 재시작                                       │
│     - 모니터링 강화 (알림 임계값 하향)                                      │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 7.2 데이터 복구 스크립트

```sql
-- External → Supabase 전체 복구 (GFX 데이터)
CREATE OR REPLACE FUNCTION restore_gfx_from_external()
RETURNS VOID AS $$
BEGIN
    -- 1. Supabase 데이터 백업 (safety)
    CREATE TABLE IF NOT EXISTS _backup_gfx_sessions AS
        SELECT * FROM gfx_sessions;

    -- 2. Supabase 데이터 삭제
    TRUNCATE gfx_sessions CASCADE;

    -- 3. External에서 복사 (FDW 사용)
    INSERT INTO gfx_sessions
    SELECT * FROM external_db.gfx_sessions;

    -- 4. 복구 완료 로그
    INSERT INTO activity_log (action, entity_type, details)
    VALUES ('restore', 'gfx_sessions',
            jsonb_build_object('source', 'external', 'timestamp', NOW()));
END;
$$ LANGUAGE plpgsql;
```

---

## 8. 체크리스트

### 8.1 초기 설정 체크리스트

- [ ] External PostgreSQL `wal_level = logical` 설정
- [ ] Debezium Connector 배포
- [ ] Kafka 토픽 생성
- [ ] Supabase Service Role Key 설정
- [ ] sync_status 초기 데이터 삽입
- [ ] 모니터링 대시보드 구성
- [ ] 알림 채널 (Slack/Email) 연동

### 8.2 운영 체크리스트 (일일)

- [ ] `v_sync_dashboard` 뷰 확인 (HEALTHY 상태)
- [ ] `sync_log` 최근 오류 확인
- [ ] CDC lag 확인 (< 5초)
- [ ] Batch Sync 완료 확인

### 8.3 장애 대응 체크리스트

- [ ] 동기화 중단 여부 확인
- [ ] 영향 범위 파악 (테이블, 레코드 수)
- [ ] 원인 분석 (네트워크, DB, 코드)
- [ ] 복구 절차 실행
- [ ] 복구 완료 검증
- [ ] 사후 분석 보고서 작성

---

## 9. 스키마 덤프 관리

### 9.1 current_schema_dump.sql 재생성

마이그레이션 적용 후 `docs/current_schema_dump.sql` 파일을 재생성해야 합니다.

```bash
# Supabase CLI 사용
supabase db dump --schema public > docs/current_schema_dump.sql

# 또는 psql 직접 사용
pg_dump --schema-only --no-owner --no-privileges \
  -h db.xxx.supabase.co -p 5432 -U postgres -d postgres \
  > docs/current_schema_dump.sql
```

### 9.2 스키마 정합성 검증

```bash
# 마이그레이션과 덤프 비교
diff <(grep "CREATE TABLE" supabase/migrations/*.sql | sort) \
     <(grep "CREATE TABLE" docs/current_schema_dump.sql | sort)

# 누락된 테이블 확인
psql -h db.xxx.supabase.co -c "
  SELECT table_name FROM information_schema.tables
  WHERE table_schema = 'public'
  ORDER BY table_name;
"
```

### 9.3 재생성 시점

| 시점 | 필수 여부 |
|------|:--------:|
| 마이그레이션 추가 후 | **필수** |
| 테이블/뷰 변경 후 | **필수** |
| 함수 추가/수정 후 | 권장 |
| 주간 정기 점검 | 권장 |

---

## 10. 관련 문서

| 문서 | 위치 | 설명 |
|------|------|------|
| 08-GFX-AEP-Mapping | `docs/08-GFX-AEP-Mapping.md` | GFX-AEP 필드 매핑 명세 |
| 07-Supabase-Orchestration | `docs/07-Supabase-Orchestration.md` | Supabase 오케스트레이션 상세 |
| 01-DATA_FLOW | `docs/01-DATA_FLOW.md` | 전체 데이터 흐름 아키텍처 |
| 마이그레이션 | `supabase/migrations/` | DB 스키마 마이그레이션 |
| 스키마 덤프 | `docs/current_schema_dump.sql` | 현재 스키마 스냅샷 |

---

## 11. 문서 그룹 및 인덱스

> **그룹 A**: GFX-AEP 매핑 대전략 (Master: 08-GFX-AEP-Mapping)

### 11.1 문서 계층

```
08-GFX-AEP-Mapping.md (Master - 대전략)
├── 09-DB-Sync-Guidelines.md (본 문서 - DB 동기화 구현)
│   └── External PostgreSQL ↔ Supabase CDC/Batch 동기화
│
└── DOCUMENT_SYNC_STRATEGY.md (문서-코드 동기화)
```

### 11.2 관련 문서

| 문서 | 역할 | 관계 |
|------|------|------|
| **00-DOCUMENT-INDEX.md** | 전체 문서 인덱스 | 그룹/SSOT 정의 |
| **08-GFX-AEP-Mapping.md** | GFX-AEP 매핑 대전략 | Master 문서 |
| **DOCUMENT_SYNC_STRATEGY.md** | 문서-코드 동기화 | 동일 그룹 종속 |
| 01-DATA_FLOW.md | 전체 데이터 흐름 | 그룹 B Master |
| 07-Supabase-Orchestration.md | 오케스트레이션 DDL | sync_status 연동 |

### 11.3 수정 가이드라인

본 문서 수정 시 08-GFX-AEP-Mapping.md와의 일관성을 확인하세요.

> **SSOT 정책**: 마이그레이션 SQL (`supabase/migrations/*.sql`)이 진실의 소스.

---

## 변경 이력

| 버전 | 날짜 | 변경 내용 |
|------|------|----------|
| 1.2.0 | 2026-01-16 | 문서 그룹 인덱스 섹션 추가 |
| 1.1.0 | 2026-01-18 | 스키마 덤프 관리 섹션 추가 |
| 1.0.0 | 2026-01-17 | 초기 작성 |
