


SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;


CREATE SCHEMA IF NOT EXISTS "public";


ALTER SCHEMA "public" OWNER TO "pg_database_owner";


COMMENT ON SCHEMA "public" IS 'standard public schema';



CREATE TYPE "public"."analysis_status" AS ENUM (
    'pending',
    'analyzing',
    'completed',
    'failed'
);


ALTER TYPE "public"."analysis_status" OWNER TO "postgres";


COMMENT ON TYPE "public"."analysis_status" IS '콤포지션 분석 진행 상태';



CREATE TYPE "public"."footage_type" AS ENUM (
    'image',
    'video',
    'audio',
    'solid',
    'sequence',
    'other'
);


ALTER TYPE "public"."footage_type" OWNER TO "postgres";


COMMENT ON TYPE "public"."footage_type" IS 'Footage 미디어 파일 타입 분류';



CREATE TYPE "public"."layer_type" AS ENUM (
    'text',
    'footage',
    'shape',
    'precomp',
    'solid',
    'camera',
    'light',
    'null',
    'adjustment'
);


ALTER TYPE "public"."layer_type" OWNER TO "postgres";


COMMENT ON TYPE "public"."layer_type" IS 'After Effects 레이어 타입 분류';



CREATE OR REPLACE FUNCTION "public"."calculate_bb_count"("chips" bigint, "big_blind" integer) RETURNS numeric
    LANGUAGE "plpgsql" IMMUTABLE
    AS $$
BEGIN
    IF chips IS NULL OR big_blind IS NULL OR big_blind = 0 THEN
        RETURN NULL;
    END IF;
    RETURN ROUND(chips::DECIMAL / big_blind, 2);
END;
$$;


ALTER FUNCTION "public"."calculate_bb_count"("chips" bigint, "big_blind" integer) OWNER TO "postgres";


COMMENT ON FUNCTION "public"."calculate_bb_count"("chips" bigint, "big_blind" integer) IS 'Calculate big blind count from chips';



CREATE OR REPLACE FUNCTION "public"."format_chips"("chips" bigint) RETURNS character varying
    LANGUAGE "plpgsql" IMMUTABLE
    AS $$
BEGIN
    IF chips IS NULL THEN
        RETURN NULL;
    ELSIF chips >= 1000000000 THEN
        RETURN ROUND(chips / 1000000000.0, 1)::TEXT || 'B';
    ELSIF chips >= 1000000 THEN
        RETURN ROUND(chips / 1000000.0, 1)::TEXT || 'M';
    ELSIF chips >= 1000 THEN
        RETURN ROUND(chips / 1000.0, 0)::TEXT || 'K';
    ELSE
        RETURN chips::TEXT;
    END IF;
END;
$$;


ALTER FUNCTION "public"."format_chips"("chips" bigint) OWNER TO "postgres";


COMMENT ON FUNCTION "public"."format_chips"("chips" bigint) IS 'Format chip count: 1500000 -> 1.5M';



CREATE OR REPLACE FUNCTION "public"."format_currency"("amount" numeric) RETURNS character varying
    LANGUAGE "plpgsql" IMMUTABLE
    AS $_$
BEGIN
    IF amount IS NULL THEN
        RETURN NULL;
    END IF;
    RETURN '$' || TO_CHAR(amount, 'FM999,999,999,999');
END;
$_$;


ALTER FUNCTION "public"."format_currency"("amount" numeric) OWNER TO "postgres";


COMMENT ON FUNCTION "public"."format_currency"("amount" numeric) IS 'Format currency: 1500000 -> $1,500,000';



CREATE OR REPLACE FUNCTION "public"."get_dynamic_layers"("p_project_id" "uuid") RETURNS TABLE("layer_id" "uuid", "composition_id" "uuid", "composition_name" "text", "layer_name" "text", "layer_index" integer, "dynamic_type" "text", "properties" "jsonb")
    LANGUAGE "plpgsql"
    AS $$
BEGIN
  RETURN QUERY
  SELECT
    l.id,
    c.id,
    c.name,
    l.layer_name,
    l.layer_index,
    l.dynamic_type,
    l.properties
  FROM layers l
  JOIN compositions c ON l.composition_id = c.id
  WHERE c.project_id = p_project_id
  AND l.is_dynamic = true
  ORDER BY c.name, l.layer_index;
END;
$$;


ALTER FUNCTION "public"."get_dynamic_layers"("p_project_id" "uuid") OWNER TO "postgres";


COMMENT ON FUNCTION "public"."get_dynamic_layers"("p_project_id" "uuid") IS '프로젝트 내 동적 레이어 목록 조회';



CREATE OR REPLACE FUNCTION "public"."get_hands_from_session"("p_session_id" "uuid") RETURNS "jsonb"
    LANGUAGE "plpgsql" STABLE
    AS $$
BEGIN
    RETURN (
        SELECT raw_json->'Hands'
        FROM gfx_sessions
        WHERE id = p_session_id
    );
END;
$$;


ALTER FUNCTION "public"."get_hands_from_session"("p_session_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_project_stats"("p_project_id" "uuid") RETURNS TABLE("total_compositions" integer, "total_layers" integer, "total_footage" integer, "text_layers" integer, "av_layers" integer, "shape_layers" integer, "dynamic_layers" integer, "completed_compositions" integer, "pending_compositions" integer)
    LANGUAGE "plpgsql"
    AS $$
BEGIN
  RETURN QUERY
  SELECT
    (SELECT COUNT(*)::INT FROM compositions WHERE project_id = p_project_id),
    (SELECT COUNT(*)::INT FROM layers l JOIN compositions c ON l.composition_id = c.id WHERE c.project_id = p_project_id),
    (SELECT COUNT(*)::INT FROM footage_assets WHERE project_id = p_project_id),
    (SELECT COUNT(*)::INT FROM layers l JOIN compositions c ON l.composition_id = c.id WHERE c.project_id = p_project_id AND l.layer_type = 'text'),
    (SELECT COUNT(*)::INT FROM layers l JOIN compositions c ON l.composition_id = c.id WHERE c.project_id = p_project_id AND l.layer_type = 'footage'),
    (SELECT COUNT(*)::INT FROM layers l JOIN compositions c ON l.composition_id = c.id WHERE c.project_id = p_project_id AND l.layer_type = 'shape'),
    (SELECT COUNT(*)::INT FROM layers l JOIN compositions c ON l.composition_id = c.id WHERE c.project_id = p_project_id AND l.is_dynamic = true),
    (SELECT COUNT(*)::INT FROM compositions WHERE project_id = p_project_id AND analysis_status = 'completed'),
    (SELECT COUNT(*)::INT FROM compositions WHERE project_id = p_project_id AND analysis_status = 'pending');
END;
$$;


ALTER FUNCTION "public"."get_project_stats"("p_project_id" "uuid") OWNER TO "postgres";


COMMENT ON FUNCTION "public"."get_project_stats"("p_project_id" "uuid") IS '프로젝트 전체 통계 조회';



CREATE OR REPLACE FUNCTION "public"."search_layers_by_text"("p_project_id" "uuid", "p_search_text" "text") RETURNS TABLE("layer_id" "uuid", "composition_name" "text", "layer_name" "text", "layer_index" integer, "text_content" "text")
    LANGUAGE "plpgsql"
    AS $$
BEGIN
  RETURN QUERY
  SELECT
    l.id,
    c.name,
    l.layer_name,
    l.layer_index,
    l.properties->>'textContent'
  FROM layers l
  JOIN compositions c ON l.composition_id = c.id
  WHERE c.project_id = p_project_id
  AND l.layer_type = 'text'
  AND l.properties->>'textContent' ILIKE '%' || p_search_text || '%'
  ORDER BY c.name, l.layer_index;
END;
$$;


ALTER FUNCTION "public"."search_layers_by_text"("p_project_id" "uuid", "p_search_text" "text") OWNER TO "postgres";


COMMENT ON FUNCTION "public"."search_layers_by_text"("p_project_id" "uuid", "p_search_text" "text") IS '프로젝트 내 텍스트 레이어 검색';



CREATE OR REPLACE FUNCTION "public"."search_sessions_with_premium_hands"() RETURNS TABLE("session_id" "uuid", "file_name" "text", "hand_count" integer, "processed_at" timestamp with time zone)
    LANGUAGE "plpgsql" STABLE
    AS $$
BEGIN
    RETURN QUERY
    SELECT
        gs.id,
        gs.file_name,
        gs.hand_count,
        gs.processed_at
    FROM gfx_sessions gs
    WHERE EXISTS (
        SELECT 1
        FROM jsonb_array_elements(gs.raw_json->'Hands') AS hand
        WHERE (hand->'Players') IS NOT NULL
    )
    ORDER BY gs.processed_at DESC;
END;
$$;


ALTER FUNCTION "public"."search_sessions_with_premium_hands"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_footage_usage_count"("p_project_id" "uuid") RETURNS "void"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
  UPDATE footage_assets fa
  SET usage_count = (
    SELECT COUNT(*)
    FROM layers l
    JOIN compositions c ON l.composition_id = c.id
    WHERE c.project_id = p_project_id
    AND l.properties->>'sourcePath' = fa.source_path
  )
  WHERE fa.project_id = p_project_id;
END;
$$;


ALTER FUNCTION "public"."update_footage_usage_count"("p_project_id" "uuid") OWNER TO "postgres";


COMMENT ON FUNCTION "public"."update_footage_usage_count"("p_project_id" "uuid") IS '프로젝트 내 Footage 사용 횟수 갱신';



CREATE OR REPLACE FUNCTION "public"."update_updated_at"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."update_updated_at"() OWNER TO "postgres";


COMMENT ON FUNCTION "public"."update_updated_at"() IS 'Auto-update updated_at column on row update';



CREATE OR REPLACE FUNCTION "public"."update_updated_at_column"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."update_updated_at_column"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."upsert_composition"("p_project_id" "uuid", "p_composition" "jsonb", "p_layers" "jsonb") RETURNS "uuid"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
  v_comp_id UUID;
  v_layer JSONB;
BEGIN
  -- 1. Composition UPSERT
  INSERT INTO compositions (
    project_id,
    name,
    width,
    height,
    duration,
    frame_rate,
    num_layers,
    text_layer_count,
    av_layer_count,
    shape_layer_count,
    analysis_status,
    analyzed_at
  )
  VALUES (
    p_project_id,
    p_composition->>'name',
    COALESCE((p_composition->>'width')::INT, 1920),
    COALESCE((p_composition->>'height')::INT, 1080),
    (p_composition->>'duration')::NUMERIC,
    COALESCE((p_composition->>'frameRate')::NUMERIC, 30),
    COALESCE((p_composition->>'numLayers')::INT, 0),
    COALESCE((p_composition->>'textLayerCount')::INT, 0),
    COALESCE((p_composition->>'avLayerCount')::INT, 0),
    COALESCE((p_composition->>'shapeLayerCount')::INT, 0),
    'completed',
    NOW()
  )
  ON CONFLICT (project_id, name) DO UPDATE SET
    width = EXCLUDED.width,
    height = EXCLUDED.height,
    duration = EXCLUDED.duration,
    frame_rate = EXCLUDED.frame_rate,
    num_layers = EXCLUDED.num_layers,
    text_layer_count = EXCLUDED.text_layer_count,
    av_layer_count = EXCLUDED.av_layer_count,
    shape_layer_count = EXCLUDED.shape_layer_count,
    analysis_status = 'completed',
    analyzed_at = NOW(),
    analysis_error = NULL,
    updated_at = NOW()
  RETURNING id INTO v_comp_id;

  -- 2. 기존 레이어 삭제 (UPSERT 대신 DELETE + INSERT)
  DELETE FROM layers WHERE composition_id = v_comp_id;

  -- 3. 레이어 일괄 INSERT
  FOR v_layer IN SELECT * FROM jsonb_array_elements(p_layers)
  LOOP
    INSERT INTO layers (
      composition_id,
      layer_index,
      layer_name,
      layer_type,
      enabled,
      in_point,
      out_point,
      is_dynamic,
      dynamic_type,
      properties
    )
    VALUES (
      v_comp_id,
      COALESCE((v_layer->>'index')::INT, 0),
      COALESCE(v_layer->>'name', 'Unnamed'),
      COALESCE((v_layer->>'layerType')::layer_type, 'footage'),
      COALESCE((v_layer->>'enabled')::BOOLEAN, true),
      (v_layer->>'inPoint')::NUMERIC,
      (v_layer->>'outPoint')::NUMERIC,
      COALESCE((v_layer->>'isDynamic')::BOOLEAN, false),
      v_layer->>'dynamicType',
      COALESCE(v_layer->'properties', '{}')
    );
  END LOOP;

  RETURN v_comp_id;
END;
$$;


ALTER FUNCTION "public"."upsert_composition"("p_project_id" "uuid", "p_composition" "jsonb", "p_layers" "jsonb") OWNER TO "postgres";


COMMENT ON FUNCTION "public"."upsert_composition"("p_project_id" "uuid", "p_composition" "jsonb", "p_layers" "jsonb") IS '콤포지션과 레이어를 원자적으로 UPSERT (병렬 분석용)';



CREATE OR REPLACE FUNCTION "public"."upsert_footage_batch"("p_project_id" "uuid", "p_footage_items" "jsonb") RETURNS integer
    LANGUAGE "plpgsql"
    AS $$
DECLARE
  v_item JSONB;
  v_count INT := 0;
BEGIN
  FOR v_item IN SELECT * FROM jsonb_array_elements(p_footage_items)
  LOOP
    INSERT INTO footage_assets (
      project_id,
      name,
      source_path,
      footage_type,
      width,
      height,
      duration,
      frame_rate,
      file_size
    )
    VALUES (
      p_project_id,
      COALESCE(v_item->>'name', 'Unnamed'),
      COALESCE(v_item->>'sourcePath', ''),
      COALESCE((v_item->>'footageType')::footage_type, 'other'),
      (v_item->>'width')::INT,
      (v_item->>'height')::INT,
      (v_item->>'duration')::NUMERIC,
      (v_item->>'frameRate')::NUMERIC,
      (v_item->>'fileSize')::BIGINT
    )
    ON CONFLICT (project_id, source_path) DO UPDATE SET
      name = EXCLUDED.name,
      footage_type = EXCLUDED.footage_type,
      width = EXCLUDED.width,
      height = EXCLUDED.height,
      duration = EXCLUDED.duration,
      frame_rate = EXCLUDED.frame_rate,
      file_size = EXCLUDED.file_size,
      updated_at = NOW();

    v_count := v_count + 1;
  END LOOP;

  RETURN v_count;
END;
$$;


ALTER FUNCTION "public"."upsert_footage_batch"("p_project_id" "uuid", "p_footage_items" "jsonb") OWNER TO "postgres";


COMMENT ON FUNCTION "public"."upsert_footage_batch"("p_project_id" "uuid", "p_footage_items" "jsonb") IS 'Footage 에셋 일괄 UPSERT';


SET default_tablespace = '';

SET default_table_access_method = "heap";


CREATE TABLE IF NOT EXISTS "public"."aep_projects" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" "text" NOT NULL,
    "file_path" "text" NOT NULL,
    "total_compositions" integer DEFAULT 0,
    "total_footage" integer DEFAULT 0,
    "total_folders" integer DEFAULT 0,
    "scan_time" timestamp with time zone,
    "metadata" "jsonb" DEFAULT '{}'::"jsonb",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "created_by" "uuid"
);


ALTER TABLE "public"."aep_projects" OWNER TO "postgres";


COMMENT ON TABLE "public"."aep_projects" IS 'After Effects 프로젝트 파일 (.aep) 메타데이터';



COMMENT ON COLUMN "public"."aep_projects"."metadata" IS 'JSX 분석 결과 원본 메타데이터 (JSONB)';



CREATE TABLE IF NOT EXISTS "public"."footage_assets" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "project_id" "uuid" NOT NULL,
    "name" "text" NOT NULL,
    "source_path" "text" NOT NULL,
    "footage_type" "public"."footage_type" DEFAULT 'other'::"public"."footage_type" NOT NULL,
    "width" integer,
    "height" integer,
    "duration" numeric(10,4),
    "frame_rate" numeric(6,2),
    "file_size" bigint,
    "usage_count" integer DEFAULT 0,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."footage_assets" OWNER TO "postgres";


COMMENT ON TABLE "public"."footage_assets" IS 'AEP 프로젝트 내 미디어 에셋 (이미지/비디오/오디오)';



COMMENT ON COLUMN "public"."footage_assets"."usage_count" IS '레이어에서 참조되는 횟수';



CREATE TABLE IF NOT EXISTS "public"."gfx_sessions" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "session_id" bigint NOT NULL,
    "file_name" "text" NOT NULL,
    "file_hash" "text" NOT NULL,
    "raw_json" "jsonb" NOT NULL,
    "table_type" "text" DEFAULT 'UNKNOWN'::"text" NOT NULL,
    "event_title" "text",
    "software_version" "text",
    "hand_count" integer DEFAULT 0 NOT NULL,
    "session_created_at" timestamp with time zone,
    "processed_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "nas_path" "text",
    "sync_status" "text" DEFAULT 'synced'::"text" NOT NULL,
    "error_message" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."gfx_sessions" OWNER TO "postgres";


COMMENT ON TABLE "public"."gfx_sessions" IS 'PokerGFX JSON 세션 원본 저장소';



COMMENT ON COLUMN "public"."gfx_sessions"."session_id" IS 'PokerGFX ID (Windows FileTime 형식)';



COMMENT ON COLUMN "public"."gfx_sessions"."file_hash" IS 'SHA256 해시 (중복 감지용)';



COMMENT ON COLUMN "public"."gfx_sessions"."raw_json" IS '원본 PokerGFX JSON 전체';



CREATE TABLE IF NOT EXISTS "public"."layers" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "composition_id" "uuid" NOT NULL,
    "layer_index" integer NOT NULL,
    "layer_name" "text" NOT NULL,
    "layer_type" "public"."layer_type" NOT NULL,
    "enabled" boolean DEFAULT true,
    "in_point" numeric(10,4),
    "out_point" numeric(10,4),
    "is_dynamic" boolean DEFAULT false,
    "dynamic_type" "text",
    "properties" "jsonb" DEFAULT '{}'::"jsonb",
    "footage_id" "uuid",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."layers" OWNER TO "postgres";


COMMENT ON TABLE "public"."layers" IS 'AE 레이어 통합 테이블 (모든 타입)';



COMMENT ON COLUMN "public"."layers"."is_dynamic" IS 'var_, img_, vid_ 접두사 동적 레이어 여부';



COMMENT ON COLUMN "public"."layers"."properties" IS '레이어 타입별 속성 데이터 (JSONB)';



CREATE TABLE IF NOT EXISTS "public"."sync_log" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "file_name" "text" NOT NULL,
    "file_path" "text" NOT NULL,
    "file_hash" "text" NOT NULL,
    "file_size_bytes" bigint,
    "operation" "text" NOT NULL,
    "status" "text" NOT NULL,
    "session_id" "uuid",
    "error_message" "text",
    "retry_count" integer DEFAULT 0,
    "started_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "completed_at" timestamp with time zone,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."sync_log" OWNER TO "postgres";


COMMENT ON TABLE "public"."sync_log" IS 'NAS 파일 동기화 작업 로그';



CREATE OR REPLACE VIEW "public"."v_recent_sessions" AS
 SELECT "id",
    "session_id",
    "file_name",
    "table_type",
    "event_title",
    "hand_count",
    "session_created_at",
    "processed_at",
    "sync_status"
   FROM "public"."gfx_sessions"
  ORDER BY "processed_at" DESC
 LIMIT 100;


ALTER VIEW "public"."v_recent_sessions" OWNER TO "postgres";


CREATE OR REPLACE VIEW "public"."v_sync_stats" AS
 SELECT "status",
    "count"(*) AS "count",
    "max"("created_at") AS "last_activity"
   FROM "public"."sync_log"
  WHERE ("created_at" > ("now"() - '24:00:00'::interval))
  GROUP BY "status";


ALTER VIEW "public"."v_sync_stats" OWNER TO "postgres";


ALTER TABLE ONLY "public"."aep_projects"
    ADD CONSTRAINT "aep_projects_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."footage_assets"
    ADD CONSTRAINT "footage_assets_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."gfx_sessions"
    ADD CONSTRAINT "gfx_sessions_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."layers"
    ADD CONSTRAINT "layers_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."sync_log"
    ADD CONSTRAINT "sync_log_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."aep_projects"
    ADD CONSTRAINT "uq_aep_projects_file_path" UNIQUE ("file_path");



ALTER TABLE ONLY "public"."footage_assets"
    ADD CONSTRAINT "uq_footage_project_path" UNIQUE ("project_id", "source_path");



ALTER TABLE ONLY "public"."gfx_sessions"
    ADD CONSTRAINT "uq_gfx_sessions_file_hash" UNIQUE ("file_hash");



ALTER TABLE ONLY "public"."gfx_sessions"
    ADD CONSTRAINT "uq_gfx_sessions_session_id" UNIQUE ("session_id");



ALTER TABLE ONLY "public"."layers"
    ADD CONSTRAINT "uq_layers_comp_index" UNIQUE ("composition_id", "layer_index");



CREATE INDEX "idx_aep_projects_created_by" ON "public"."aep_projects" USING "btree" ("created_by");



CREATE INDEX "idx_aep_projects_scan_time" ON "public"."aep_projects" USING "btree" ("scan_time" DESC NULLS LAST);



CREATE INDEX "idx_footage_name" ON "public"."footage_assets" USING "btree" ("name");



CREATE INDEX "idx_footage_project" ON "public"."footage_assets" USING "btree" ("project_id");



CREATE INDEX "idx_footage_type" ON "public"."footage_assets" USING "btree" ("footage_type");



CREATE INDEX "idx_footage_usage" ON "public"."footage_assets" USING "btree" ("usage_count" DESC);



CREATE INDEX "idx_gfx_sessions_file_hash" ON "public"."gfx_sessions" USING "btree" ("file_hash");



CREATE INDEX "idx_gfx_sessions_processed_at" ON "public"."gfx_sessions" USING "btree" ("processed_at" DESC);



CREATE INDEX "idx_gfx_sessions_raw_json" ON "public"."gfx_sessions" USING "gin" ("raw_json");



CREATE INDEX "idx_gfx_sessions_session_id" ON "public"."gfx_sessions" USING "btree" ("session_id");



CREATE INDEX "idx_gfx_sessions_table_type" ON "public"."gfx_sessions" USING "btree" ("table_type");



CREATE INDEX "idx_layers_comp_index" ON "public"."layers" USING "btree" ("composition_id", "layer_index");



CREATE INDEX "idx_layers_composition" ON "public"."layers" USING "btree" ("composition_id");



CREATE INDEX "idx_layers_dynamic" ON "public"."layers" USING "btree" ("is_dynamic") WHERE ("is_dynamic" = true);



CREATE INDEX "idx_layers_dynamic_type" ON "public"."layers" USING "btree" ("dynamic_type") WHERE ("is_dynamic" = true);



CREATE INDEX "idx_layers_footage" ON "public"."layers" USING "btree" ("footage_id") WHERE ("footage_id" IS NOT NULL);



CREATE INDEX "idx_layers_properties" ON "public"."layers" USING "gin" ("properties");



CREATE INDEX "idx_layers_type" ON "public"."layers" USING "btree" ("layer_type");



CREATE INDEX "idx_sync_log_created_at" ON "public"."sync_log" USING "btree" ("created_at" DESC);



CREATE INDEX "idx_sync_log_file_hash" ON "public"."sync_log" USING "btree" ("file_hash");



CREATE INDEX "idx_sync_log_session_id" ON "public"."sync_log" USING "btree" ("session_id");



CREATE INDEX "idx_sync_log_status" ON "public"."sync_log" USING "btree" ("status");



CREATE OR REPLACE TRIGGER "trigger_aep_projects_updated_at" BEFORE UPDATE ON "public"."aep_projects" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "trigger_footage_assets_updated_at" BEFORE UPDATE ON "public"."footage_assets" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "trigger_layers_updated_at" BEFORE UPDATE ON "public"."layers" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



CREATE OR REPLACE TRIGGER "update_gfx_sessions_updated_at" BEFORE UPDATE ON "public"."gfx_sessions" FOR EACH ROW EXECUTE FUNCTION "public"."update_updated_at_column"();



ALTER TABLE ONLY "public"."aep_projects"
    ADD CONSTRAINT "aep_projects_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "auth"."users"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."footage_assets"
    ADD CONSTRAINT "footage_assets_project_id_fkey" FOREIGN KEY ("project_id") REFERENCES "public"."aep_projects"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."layers"
    ADD CONSTRAINT "layers_footage_id_fkey" FOREIGN KEY ("footage_id") REFERENCES "public"."footage_assets"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."sync_log"
    ADD CONSTRAINT "sync_log_session_id_fkey" FOREIGN KEY ("session_id") REFERENCES "public"."gfx_sessions"("id") ON DELETE SET NULL;



CREATE POLICY "Authenticated read on gfx_sessions" ON "public"."gfx_sessions" FOR SELECT USING (("auth"."role"() = 'authenticated'::"text"));



CREATE POLICY "Authenticated read on sync_log" ON "public"."sync_log" FOR SELECT USING (("auth"."role"() = 'authenticated'::"text"));



CREATE POLICY "Authenticated users can create projects" ON "public"."aep_projects" FOR INSERT WITH CHECK (("auth"."uid"() = "created_by"));



CREATE POLICY "Service role full access on gfx_sessions" ON "public"."gfx_sessions" USING (("auth"."role"() = 'service_role'::"text")) WITH CHECK (("auth"."role"() = 'service_role'::"text"));



CREATE POLICY "Service role full access on sync_log" ON "public"."sync_log" USING (("auth"."role"() = 'service_role'::"text")) WITH CHECK (("auth"."role"() = 'service_role'::"text"));



CREATE POLICY "Users can create footage in own projects" ON "public"."footage_assets" FOR INSERT WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."aep_projects"
  WHERE (("aep_projects"."id" = "footage_assets"."project_id") AND ("aep_projects"."created_by" = "auth"."uid"())))));



CREATE POLICY "Users can delete footage of own projects" ON "public"."footage_assets" FOR DELETE USING ((EXISTS ( SELECT 1
   FROM "public"."aep_projects"
  WHERE (("aep_projects"."id" = "footage_assets"."project_id") AND ("aep_projects"."created_by" = "auth"."uid"())))));



CREATE POLICY "Users can delete own projects" ON "public"."aep_projects" FOR DELETE USING (("auth"."uid"() = "created_by"));



CREATE POLICY "Users can update footage of own projects" ON "public"."footage_assets" FOR UPDATE USING ((EXISTS ( SELECT 1
   FROM "public"."aep_projects"
  WHERE (("aep_projects"."id" = "footage_assets"."project_id") AND ("aep_projects"."created_by" = "auth"."uid"())))));



CREATE POLICY "Users can update own projects" ON "public"."aep_projects" FOR UPDATE USING (("auth"."uid"() = "created_by"));



CREATE POLICY "Users can view footage of own projects" ON "public"."footage_assets" FOR SELECT USING ((EXISTS ( SELECT 1
   FROM "public"."aep_projects"
  WHERE (("aep_projects"."id" = "footage_assets"."project_id") AND ("aep_projects"."created_by" = "auth"."uid"())))));



CREATE POLICY "Users can view own projects" ON "public"."aep_projects" FOR SELECT USING (("auth"."uid"() = "created_by"));



ALTER TABLE "public"."aep_projects" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."footage_assets" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."gfx_sessions" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."layers" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."sync_log" ENABLE ROW LEVEL SECURITY;


GRANT USAGE ON SCHEMA "public" TO "postgres";
GRANT USAGE ON SCHEMA "public" TO "anon";
GRANT USAGE ON SCHEMA "public" TO "authenticated";
GRANT USAGE ON SCHEMA "public" TO "service_role";



GRANT ALL ON FUNCTION "public"."calculate_bb_count"("chips" bigint, "big_blind" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."calculate_bb_count"("chips" bigint, "big_blind" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."calculate_bb_count"("chips" bigint, "big_blind" integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."format_chips"("chips" bigint) TO "anon";
GRANT ALL ON FUNCTION "public"."format_chips"("chips" bigint) TO "authenticated";
GRANT ALL ON FUNCTION "public"."format_chips"("chips" bigint) TO "service_role";



GRANT ALL ON FUNCTION "public"."format_currency"("amount" numeric) TO "anon";
GRANT ALL ON FUNCTION "public"."format_currency"("amount" numeric) TO "authenticated";
GRANT ALL ON FUNCTION "public"."format_currency"("amount" numeric) TO "service_role";



GRANT ALL ON FUNCTION "public"."get_dynamic_layers"("p_project_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."get_dynamic_layers"("p_project_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_dynamic_layers"("p_project_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."get_hands_from_session"("p_session_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."get_hands_from_session"("p_session_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_hands_from_session"("p_session_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."get_project_stats"("p_project_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."get_project_stats"("p_project_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_project_stats"("p_project_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."search_layers_by_text"("p_project_id" "uuid", "p_search_text" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."search_layers_by_text"("p_project_id" "uuid", "p_search_text" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."search_layers_by_text"("p_project_id" "uuid", "p_search_text" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."search_sessions_with_premium_hands"() TO "anon";
GRANT ALL ON FUNCTION "public"."search_sessions_with_premium_hands"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."search_sessions_with_premium_hands"() TO "service_role";



GRANT ALL ON FUNCTION "public"."update_footage_usage_count"("p_project_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."update_footage_usage_count"("p_project_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_footage_usage_count"("p_project_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."update_updated_at"() TO "anon";
GRANT ALL ON FUNCTION "public"."update_updated_at"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_updated_at"() TO "service_role";



GRANT ALL ON FUNCTION "public"."update_updated_at_column"() TO "anon";
GRANT ALL ON FUNCTION "public"."update_updated_at_column"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_updated_at_column"() TO "service_role";



GRANT ALL ON FUNCTION "public"."upsert_composition"("p_project_id" "uuid", "p_composition" "jsonb", "p_layers" "jsonb") TO "anon";
GRANT ALL ON FUNCTION "public"."upsert_composition"("p_project_id" "uuid", "p_composition" "jsonb", "p_layers" "jsonb") TO "authenticated";
GRANT ALL ON FUNCTION "public"."upsert_composition"("p_project_id" "uuid", "p_composition" "jsonb", "p_layers" "jsonb") TO "service_role";



GRANT ALL ON FUNCTION "public"."upsert_footage_batch"("p_project_id" "uuid", "p_footage_items" "jsonb") TO "anon";
GRANT ALL ON FUNCTION "public"."upsert_footage_batch"("p_project_id" "uuid", "p_footage_items" "jsonb") TO "authenticated";
GRANT ALL ON FUNCTION "public"."upsert_footage_batch"("p_project_id" "uuid", "p_footage_items" "jsonb") TO "service_role";



GRANT ALL ON TABLE "public"."aep_projects" TO "anon";
GRANT ALL ON TABLE "public"."aep_projects" TO "authenticated";
GRANT ALL ON TABLE "public"."aep_projects" TO "service_role";



GRANT ALL ON TABLE "public"."footage_assets" TO "anon";
GRANT ALL ON TABLE "public"."footage_assets" TO "authenticated";
GRANT ALL ON TABLE "public"."footage_assets" TO "service_role";



GRANT ALL ON TABLE "public"."gfx_sessions" TO "anon";
GRANT ALL ON TABLE "public"."gfx_sessions" TO "authenticated";
GRANT ALL ON TABLE "public"."gfx_sessions" TO "service_role";



GRANT ALL ON TABLE "public"."layers" TO "anon";
GRANT ALL ON TABLE "public"."layers" TO "authenticated";
GRANT ALL ON TABLE "public"."layers" TO "service_role";



GRANT ALL ON TABLE "public"."sync_log" TO "anon";
GRANT ALL ON TABLE "public"."sync_log" TO "authenticated";
GRANT ALL ON TABLE "public"."sync_log" TO "service_role";



GRANT ALL ON TABLE "public"."v_recent_sessions" TO "anon";
GRANT ALL ON TABLE "public"."v_recent_sessions" TO "authenticated";
GRANT ALL ON TABLE "public"."v_recent_sessions" TO "service_role";



GRANT ALL ON TABLE "public"."v_sync_stats" TO "anon";
GRANT ALL ON TABLE "public"."v_sync_stats" TO "authenticated";
GRANT ALL ON TABLE "public"."v_sync_stats" TO "service_role";



ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "service_role";







