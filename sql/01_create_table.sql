/*
File Name   : 01_create_table.sql
Description : Creates the APP_ERROR_LOG table used by the APEX error logging framework.
Author      : Hassan Raza
Created Date: 2026-02-20
Version     : 1.0
*/

CREATE TABLE app_error_log (
    log_id            NUMBER                          NOT NULL,
    error_code        VARCHAR2(50 CHAR),
    error_message     VARCHAR2(4000 CHAR),
    error_stack       CLOB,
    severity          VARCHAR2(20 CHAR)               DEFAULT 'ERROR' NOT NULL,
    module_name       VARCHAR2(255 CHAR),
    apex_user         VARCHAR2(255 CHAR),
    apex_app_id       NUMBER,
    apex_page_id      NUMBER,
    apex_session_id   VARCHAR2(100 CHAR),
    additional_info   CLOB,
    created_at        TIMESTAMP WITH TIME ZONE        DEFAULT SYSTIMESTAMP NOT NULL,
    server_host       VARCHAR2(255 CHAR),
    CONSTRAINT app_error_log_pk PRIMARY KEY (log_id),
    CONSTRAINT app_error_log_severity_ck CHECK (severity IN ('INFO', 'WARNING', 'ERROR', 'FATAL'))
);

COMMENT ON TABLE app_error_log IS
    'Stores application errors and informational logs for Oracle APEX applications.';

COMMENT ON COLUMN app_error_log.log_id IS
    'Unique identifier for each log record.';

COMMENT ON COLUMN app_error_log.error_code IS
    'Oracle SQLCODE or custom error code captured at log time.';

COMMENT ON COLUMN app_error_log.error_message IS
    'Primary error or informational message text.';

COMMENT ON COLUMN app_error_log.error_stack IS
    'Full error backtrace and call stack for troubleshooting.';

COMMENT ON COLUMN app_error_log.severity IS
    'Severity level of the entry: INFO, WARNING, ERROR, or FATAL.';

COMMENT ON COLUMN app_error_log.module_name IS
    'Source module name (package, procedure, process, or job) where event occurred.';

COMMENT ON COLUMN app_error_log.apex_user IS
    'Oracle APEX authenticated user at the time of logging.';

COMMENT ON COLUMN app_error_log.apex_app_id IS
    'Oracle APEX application ID where the event occurred.';

COMMENT ON COLUMN app_error_log.apex_page_id IS
    'Oracle APEX page ID where the event occurred.';

COMMENT ON COLUMN app_error_log.apex_session_id IS
    'Oracle APEX session identifier.';

COMMENT ON COLUMN app_error_log.additional_info IS
    'Optional developer-provided context, payload details, or diagnostics.';

COMMENT ON COLUMN app_error_log.created_at IS
    'Timestamp when the log entry was created (with time zone).' ;

COMMENT ON COLUMN app_error_log.server_host IS
    'Database host name from USERENV context where the event was logged.';
