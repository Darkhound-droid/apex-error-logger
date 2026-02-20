# Setup Guide: apex-error-logger

This guide explains how to install and operationalize the `apex-error-logger` framework in an Oracle Database schema used by Oracle APEX.

## 1) Required Database Privileges

Connect as a privileged user (for example, `SYS` or a DBA account) and grant required object-creation privileges to your application schema.

```sql
GRANT CREATE TABLE TO your_app_schema;
GRANT CREATE SEQUENCE TO your_app_schema;
GRANT CREATE TRIGGER TO your_app_schema;
GRANT CREATE PROCEDURE TO your_app_schema;
GRANT CREATE VIEW TO your_app_schema;
```

Optional diagnostics privilege:

```sql
GRANT SELECT ON V_$SESSION TO your_app_schema;
```

> Note: `V_$SESSION` access is optional for this framework, but often useful in enterprise support tooling.

## 2) Install in the PL/SQL Schema

1. Open SQL Workshop (APEX) or SQLcl/SQL*Plus as your application schema.
2. Run scripts in order:

```sql
@sql/01_create_table.sql
@sql/02_create_sequence.sql
@sql/03_pkg_error_logger_spec.sql
@sql/04_pkg_error_logger_body.sql
@sql/05_create_views.sql
```

3. Optionally run sample patterns:

```sql
@sql/06_sample_usage.sql
```

4. Validate installed objects:

```sql
SELECT object_name, object_type, status
  FROM user_objects
 WHERE object_name IN (
   'APP_ERROR_LOG',
   'APP_ERROR_LOG_SEQ',
   'APP_ERROR_LOG_BIR',
   'PKG_ERROR_LOGGER',
   'V_ERROR_LOG_RECENT',
   'V_ERROR_LOG_SUMMARY',
   'V_ERROR_LOG_FATAL'
 )
 ORDER BY object_type, object_name;
```

## 3) Connect to an Existing APEX Application

Add logger calls in page processes, process handlers, and package exception blocks.

Recommended pattern:

```sql
BEGIN
  -- Business operation
  NULL;
EXCEPTION
  WHEN OTHERS THEN
    pkg_error_logger.log_error(
      p_module          => 'YOUR_MODULE_NAME',
      p_severity        => 'ERROR',
      p_additional_info => 'Context-specific debug payload'
    );
    RAISE;
END;
```

For operational events (non-errors):

```sql
BEGIN
  pkg_error_logger.log_message(
    p_module   => 'YOUR_MODULE_NAME',
    p_message  => 'Operation completed.',
    p_severity => 'INFO'
  );
END;
```

## 4) Build a Log Viewer Page in APEX (Interactive Report)

1. In App Builder, create a new page.
2. Select **Interactive Report** as the region type.
3. For SQL Source, paste the query from `apex/log_viewer_query.sql`.
4. Create optional filter items on the page:
   - `PXX_SEVERITY` (Select List)
   - `PXX_MODULE` (Text Field)
   - `PXX_FROM_DATE` (Date Picker)
   - `PXX_TO_DATE` (Date Picker)
5. In the report attributes:
   - Format `CREATED_AT` with a timestamp mask.
   - Use `SEVERITY_CSS_CLASS` in a badge or HTML expression for visual severity signaling.
6. Save and run the page.

## 5) Schedule `PURGE_LOGS` Weekly (DBMS_SCHEDULER)

Use a weekly scheduler job to enforce retention.

```sql
BEGIN
  DBMS_SCHEDULER.create_job (
    job_name        => 'JOB_PURGE_APP_ERROR_LOG',
    job_type        => 'PLSQL_BLOCK',
    job_action      => 'BEGIN pkg_error_logger.purge_logs(p_older_than_days => 90); END;',
    start_date      => SYSTIMESTAMP,
    repeat_interval => 'FREQ=WEEKLY;BYDAY=SUN;BYHOUR=2;BYMINUTE=0;BYSECOND=0',
    enabled         => TRUE,
    comments        => 'Purges APP_ERROR_LOG records older than 90 days every week.'
  );
END;
/
```

Check scheduler status:

```sql
SELECT job_name,
       enabled,
       state,
       last_start_date,
       next_run_date
  FROM user_scheduler_jobs
 WHERE job_name = 'JOB_PURGE_APP_ERROR_LOG';
```

---

You now have centralized, queryable error telemetry with autonomous transaction durability for your Oracle APEX application stack.
