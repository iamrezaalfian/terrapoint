-- ==============================================================================
-- TerraPoint MVP - Database Migration (Down)
-- ==============================================================================

DROP TABLE IF EXISTS sync_audit_logs CASCADE;
DROP TABLE IF EXISTS task_raw_breadcrumbs CASCADE;
DROP TABLE IF EXISTS task_evidences CASCADE;
DROP TABLE IF EXISTS tasks CASCADE;
DROP TABLE IF EXISTS drivers CASCADE;
