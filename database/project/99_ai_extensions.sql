-- database/project/99_ai_extensions.sql
-- Adds embeddings table, audit log, and health risk scoring helpers (dev-safe defaults)
-- Run this file with psql against your development database (see README)

BEGIN;
SET search_path TO app, public;

-- Enable helpful extensions if available in the Postgres image
CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION IF NOT EXISTS vector;

-- Embeddings table for semantic retrieval
CREATE TABLE IF NOT EXISTS app.embedding (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    source_table TEXT NOT NULL,
    source_id TEXT,
    text_snippet TEXT,
    embedding vector(1536),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_indexes WHERE schemaname='app' AND tablename='embedding' AND indexname='idx_embedding_vector_ivfflat'
  ) THEN
    -- ivfflat requires pgvector; lists tuning should be adjusted in production
    CREATE INDEX idx_embedding_vector_ivfflat
      ON app.embedding USING ivfflat (embedding vector_l2_ops)
      WITH (lists = 100);
  END IF;
END$$;

-- Audit log and function
CREATE TABLE IF NOT EXISTS app.audit_log (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    table_name TEXT NOT NULL,
    operation CHAR(1) NOT NULL,
    row_id TEXT,
    changed_by TEXT,
    row_before JSONB,
    row_after JSONB,
    changed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_audit_log_table_name ON app.audit_log(table_name);
CREATE INDEX IF NOT EXISTS idx_audit_log_changed_at ON app.audit_log(changed_at);

CREATE OR REPLACE FUNCTION app.log_audit() RETURNS TRIGGER AS $$
DECLARE
  row_id_val TEXT;
  row_json JSONB;
BEGIN
  IF TG_OP = 'DELETE' THEN
    row_json := to_jsonb(OLD);
    row_id_val := COALESCE(row_json->>'patient_id', row_json->>'user_id', row_json->>'doctor_id', row_json->>'admin_id');
    INSERT INTO app.audit_log(table_name, operation, row_id, row_before, changed_at)
      VALUES (TG_TABLE_NAME, 'D', row_id_val, row_json, NOW());
    RETURN OLD;
  ELSIF TG_OP = 'UPDATE' THEN
    row_json := to_jsonb(NEW);
    row_id_val := COALESCE(row_json->>'patient_id', row_json->>'user_id', row_json->>'doctor_id', row_json->>'admin_id');
    INSERT INTO app.audit_log(table_name, operation, row_id, row_before, row_after, changed_at)
      VALUES (TG_TABLE_NAME, 'U', row_id_val, to_jsonb(OLD), row_json, NOW());
    RETURN NEW;
  ELSIF TG_OP = 'INSERT' THEN
    row_json := to_jsonb(NEW);
    row_id_val := COALESCE(row_json->>'patient_id', row_json->>'user_id', row_json->>'doctor_id', row_json->>'admin_id');
    INSERT INTO app.audit_log(table_name, operation, row_id, row_after, changed_at)
      VALUES (TG_TABLE_NAME, 'I', row_id_val, row_json, NOW());
    RETURN NEW;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Idempotent trigger attachments for common sensitive tables
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='app' AND table_name='patient') THEN
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'audit_patient_trigger') THEN
      CREATE TRIGGER audit_patient_trigger
        AFTER INSERT OR UPDATE OR DELETE ON app.patient
        FOR EACH ROW EXECUTE FUNCTION app.log_audit();
    END IF;
  END IF;

  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='app' AND table_name='user_account') THEN
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'audit_user_account_trigger') THEN
      CREATE TRIGGER audit_user_account_trigger
        AFTER INSERT OR UPDATE OR DELETE ON app.user_account
        FOR EACH ROW EXECUTE FUNCTION app.log_audit();
    END IF;
  END IF;

  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='app' AND table_name='prescription') THEN
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'audit_prescription_trigger') THEN
      CREATE TRIGGER audit_prescription_trigger
        AFTER INSERT OR UPDATE OR DELETE ON app.prescription
        FOR EACH ROW EXECUTE FUNCTION app.log_audit();
    END IF;
  END IF;

  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='app' AND table_name='medication_log') THEN
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'audit_med_log_trigger') THEN
      CREATE TRIGGER audit_med_log_trigger
        AFTER INSERT OR UPDATE OR DELETE ON app.medication_log
        FOR EACH ROW EXECUTE FUNCTION app.log_audit();
    END IF;
  END IF;
END$$;

-- Health risk scoring (heuristic example). Tune or replace with ML model later.
ALTER TABLE app.patient ADD COLUMN IF NOT EXISTS health_risk_score NUMERIC(4,2) DEFAULT 0.00;

CREATE OR REPLACE FUNCTION app.compute_health_risk(p_patient_id TEXT) RETURNS NUMERIC AS $$
DECLARE
  age INT := 0;
  cond_count INT := 0;
  recent_missed INT := 0;
  score NUMERIC := 0;
BEGIN
  -- attempt to read birth_date safely; adjust field names for your schema if different
  BEGIN
    SELECT EXTRACT(YEAR FROM AGE(CURRENT_DATE, birth_date))::INT INTO age FROM app.patient WHERE COALESCE(id::text, patient_id::text) = p_patient_id LIMIT 1;
  EXCEPTION WHEN OTHERS THEN
    age := 0;
  END;

  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='app' AND table_name='patient_symptom') THEN
    SELECT COUNT(*) INTO cond_count FROM app.patient_symptom WHERE COALESCE(patient_id::text, '') = p_patient_id;
  END IF;

  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='app' AND table_name='medication_log') THEN
    SELECT COUNT(*) INTO recent_missed FROM app.medication_log WHERE COALESCE(patient_id::text, '') = p_patient_id AND scheduled_time >= NOW() - INTERVAL '90 days' AND status = 'Missed';
  END IF;

  score := LEAST(1.0,
    (GREATEST(age - 40, 0) / 60.0) * 0.4
    + (cond_count::NUMERIC / 5.0) * 0.35
    + (LEAST(recent_missed, 30)::NUMERIC / 30.0) * 0.25
  );

  RETURN ROUND(score::numeric, 2);
EXCEPTION WHEN OTHERS THEN
  RETURN 0.00;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION app.patient_set_risk_trigger() RETURNS TRIGGER AS $$
BEGIN
  NEW.health_risk_score := app.compute_health_risk(COALESCE(NEW.id::text, NEW.patient_id::text));
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_patient_set_risk ON app.patient;
CREATE TRIGGER trg_patient_set_risk BEFORE INSERT OR UPDATE ON app.patient
  FOR EACH ROW EXECUTE FUNCTION app.patient_set_risk_trigger();

CREATE OR REPLACE FUNCTION app.recompute_patient_risk_after_mod() RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'DELETE' THEN
    UPDATE app.patient SET health_risk_score = app.compute_health_risk(COALESCE(OLD.id::text, OLD.patient_id::text)) WHERE COALESCE(id::text, patient_id::text) = COALESCE(OLD.id::text, OLD.patient_id::text);
  ELSE
    UPDATE app.patient SET health_risk_score = app.compute_health_risk(COALESCE(NEW.id::text, NEW.patient_id::text)) WHERE COALESCE(id::text, patient_id::text) = COALESCE(NEW.id::text, NEW.patient_id::text);
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Attach recompute triggers to related tables if they exist
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='app' AND table_name='patient_symptom') THEN
    DROP TRIGGER IF EXISTS trg_patient_symptom_recompute ON app.patient_symptom;
    CREATE TRIGGER trg_patient_symptom_recompute AFTER INSERT OR UPDATE OR DELETE ON app.patient_symptom
      FOR EACH ROW EXECUTE FUNCTION app.recompute_patient_risk_after_mod();
  END IF;

  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema='app' AND table_name='medication_log') THEN
    DROP TRIGGER IF EXISTS trg_med_log_recompute ON app.medication_log;
    CREATE TRIGGER trg_med_log_recompute AFTER INSERT OR UPDATE OR DELETE ON app.medication_log
      FOR EACH ROW EXECUTE FUNCTION app.recompute_patient_risk_after_mod();
  END IF;
END$$;

COMMIT;
