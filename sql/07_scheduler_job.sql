-- File: 07_scheduler_job.sql
-- Description: DBMS_SCHEDULER integration examples for PKG_ERROR_LOGGER
-- Demonstrates error logging outside APEX context (scheduler jobs, background processes)
-- Author: Hassan Raza
-- Version: 1.0

/*
APEX_DEBUG relies on an active Oracle APEX web session context.
DBMS_SCHEDULER jobs execute in background database sessions without APEX runtime globals.
Because no interactive page/session exists, APEX_DEBUG traces are not available for these jobs.
PKG_ERROR_LOGGER fills this gap by persisting structured diagnostics directly to APP_ERROR_LOG.
This enables reliable troubleshooting and monitoring for unattended background processing.
*/

CREATE OR REPLACE PROCEDURE proc_nightly_data_cleanup IS
    c_module_name        CONSTANT VARCHAR2(255) := 'PROC_NIGHTLY_DATA_CLEANUP';
    c_archive_days       CONSTANT PLS_INTEGER   := 180;
    c_temp_retention_days CONSTANT PLS_INTEGER  := 7;
    c_info_preview_rows  CONSTANT PLS_INTEGER   := 500;

    v_rows_archived      NUMBER := 0;
    v_rows_purged        NUMBER := 0;
    v_info_rows_reviewed NUMBER := 0;
BEGIN
    pkg_error_logger.log_message(
        p_module   => c_module_name,
        p_message  => 'Nightly cleanup started.',
        p_severity => 'INFO'
    );

    pkg_error_logger.log_message(
        p_module   => c_module_name,
        p_message  => 'Step 1/4: Archiving old application log records older than ' || c_archive_days || ' days.',
        p_severity => 'INFO'
    );

    UPDATE app_error_log
       SET additional_info = NVL(additional_info, TO_CLOB(''))
                             || TO_CLOB(' [ARCHIVE_CANDIDATE:' || TO_CHAR(SYSTIMESTAMP, 'YYYY-MM-DD HH24:MI:SS TZH:TZM') || ']')
     WHERE created_at < SYSTIMESTAMP - NUMTODSINTERVAL(c_archive_days, 'DAY')
       AND ROWNUM <= c_info_preview_rows;
    v_rows_archived := SQL%ROWCOUNT;

    pkg_error_logger.log_message(
        p_module   => c_module_name,
        p_message  => 'Step 2/4: Archive candidate tagging complete. Rows tagged = ' || v_rows_archived,
        p_severity => 'INFO'
    );

    DELETE FROM app_error_log
     WHERE created_at < SYSTIMESTAMP - NUMTODSINTERVAL(c_temp_retention_days, 'DAY')
       AND severity = 'INFO';
    v_rows_purged := SQL%ROWCOUNT;

    pkg_error_logger.log_message(
        p_module   => c_module_name,
        p_message  => 'Step 3/4: Purged informational temp records older than ' || c_temp_retention_days || ' days. Rows deleted = ' || v_rows_purged,
        p_severity => 'INFO'
    );

    SELECT COUNT(*)
      INTO v_info_rows_reviewed
      FROM app_error_log
     WHERE severity = 'INFO'
       AND created_at >= SYSTIMESTAMP - NUMTODSINTERVAL(24, 'HOUR');

    pkg_error_logger.log_message(
        p_module   => c_module_name,
        p_message  => 'Step 4/4: Post-cleanup review complete. INFO rows in last 24h = ' || v_info_rows_reviewed,
        p_severity => 'INFO'
    );

    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        pkg_error_logger.log_error(
            p_module          => c_module_name,
            p_severity        => 'ERROR',
            p_additional_info => 'Nightly cleanup failed during scheduled processing.'
        );
        ROLLBACK;
        RAISE;
END proc_nightly_data_cleanup;
/

SHOW ERRORS PROCEDURE proc_nightly_data_cleanup;

BEGIN
    DBMS_SCHEDULER.drop_job(
        job_name => 'JOB_NIGHTLY_DATA_CLEANUP',
        force    => TRUE
    );
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE != -27475 THEN
            pkg_error_logger.log_error(
                p_module          => 'JOB_NIGHTLY_DATA_CLEANUP.DROP',
                p_severity        => 'WARNING',
                p_additional_info => 'Unexpected error while dropping existing scheduler job.'
            );
        END IF;
END;
/

BEGIN
    DBMS_SCHEDULER.create_job(
        job_name        => 'JOB_NIGHTLY_DATA_CLEANUP',
        job_type        => 'STORED_PROCEDURE',
        job_action      => 'PROC_NIGHTLY_DATA_CLEANUP',
        start_date      => SYSTIMESTAMP,
        repeat_interval => 'FREQ=DAILY;BYHOUR=2;BYMINUTE=0;BYSECOND=0',
        enabled         => FALSE,
        auto_drop       => FALSE,
        comments        => 'Runs nightly data cleanup and logs telemetry through PKG_ERROR_LOGGER.'
    );

    DBMS_SCHEDULER.enable(name => 'JOB_NIGHTLY_DATA_CLEANUP');
EXCEPTION
    WHEN OTHERS THEN
        pkg_error_logger.log_error(
            p_module          => 'JOB_NIGHTLY_DATA_CLEANUP.CREATE',
            p_severity        => 'FATAL',
            p_additional_info => 'Failed to create or enable JOB_NIGHTLY_DATA_CLEANUP.'
        );
        RAISE;
END;
/

CREATE OR REPLACE PROCEDURE proc_sync_external_data IS
    c_module_name          CONSTANT VARCHAR2(255) := 'PROC_SYNC_EXTERNAL_DATA';
    c_max_allowed_value    CONSTANT PLS_INTEGER   := 1000;
    c_simulated_source_cnt CONSTANT PLS_INTEGER   := 6;

    TYPE t_sync_value_tab IS TABLE OF NUMBER INDEX BY PLS_INTEGER;
    l_values t_sync_value_tab;

    v_idx NUMBER;
BEGIN
    pkg_error_logger.log_message(
        p_module   => c_module_name,
        p_message  => 'External data sync started.',
        p_severity => 'INFO'
    );

    l_values(1) := 120;
    l_values(2) := NULL;
    l_values(3) := 850;
    l_values(4) := 1500;
    l_values(5) := 430;
    l_values(6) := -10;

    pkg_error_logger.log_message(
        p_module   => c_module_name,
        p_message  => 'Loaded simulated inbound payload with ' || c_simulated_source_cnt || ' records.',
        p_severity => 'INFO'
    );

    v_idx := l_values.FIRST;
    WHILE v_idx IS NOT NULL LOOP
        IF l_values(v_idx) IS NULL THEN
            pkg_error_logger.log_message(
                p_module   => c_module_name,
                p_message  => 'Record ' || v_idx || ' has NULL value in source payload.',
                p_severity => 'WARNING'
            );
        ELSIF l_values(v_idx) < 0 OR l_values(v_idx) > c_max_allowed_value THEN
            pkg_error_logger.log_message(
                p_module   => c_module_name,
                p_message  => 'Record ' || v_idx || ' has out-of-range value: ' || l_values(v_idx),
                p_severity => 'WARNING'
            );
        END IF;

        v_idx := l_values.NEXT(v_idx);
    END LOOP;

    BEGIN
        -- Simulated recoverable issue (for example: transient network timeout).
        RAISE_APPLICATION_ERROR(-20031, 'Recoverable sync issue: temporary timeout from upstream endpoint.');
    EXCEPTION
        WHEN OTHERS THEN
            pkg_error_logger.log_error(
                p_module          => c_module_name,
                p_severity        => 'ERROR',
                p_additional_info => 'Recoverable integration issue occurred; job will continue retry flow.'
            );
    END;

    -- Simulated critical failure path.
    RAISE_APPLICATION_ERROR(-20032, 'Critical sync failure: inbound payload contract mismatch.');

    pkg_error_logger.log_message(
        p_module   => c_module_name,
        p_message  => 'External data sync completed.',
        p_severity => 'INFO'
    );
EXCEPTION
    WHEN OTHERS THEN
        pkg_error_logger.log_error(
            p_module          => c_module_name,
            p_severity        => 'FATAL',
            p_additional_info => 'Fatal sync failure; manual intervention required before next cycle.'
        );
        RAISE;
END proc_sync_external_data;
/

SHOW ERRORS PROCEDURE proc_sync_external_data;

BEGIN
    DBMS_SCHEDULER.drop_job(
        job_name => 'JOB_SYNC_EXTERNAL_DATA',
        force    => TRUE
    );
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE != -27475 THEN
            pkg_error_logger.log_error(
                p_module          => 'JOB_SYNC_EXTERNAL_DATA.DROP',
                p_severity        => 'WARNING',
                p_additional_info => 'Unexpected error while dropping existing sync scheduler job.'
            );
        END IF;
END;
/

BEGIN
    DBMS_SCHEDULER.create_job(
        job_name        => 'JOB_SYNC_EXTERNAL_DATA',
        job_type        => 'STORED_PROCEDURE',
        job_action      => 'PROC_SYNC_EXTERNAL_DATA',
        start_date      => SYSTIMESTAMP,
        repeat_interval => 'FREQ=HOURLY;INTERVAL=4',
        enabled         => FALSE,
        auto_drop       => FALSE,
        comments        => 'Runs external data sync every 4 hours with severity-based telemetry.'
    );

    DBMS_SCHEDULER.enable(name => 'JOB_SYNC_EXTERNAL_DATA');
EXCEPTION
    WHEN OTHERS THEN
        pkg_error_logger.log_error(
            p_module          => 'JOB_SYNC_EXTERNAL_DATA.CREATE',
            p_severity        => 'FATAL',
            p_additional_info => 'Failed to create or enable JOB_SYNC_EXTERNAL_DATA.'
        );
        RAISE;
END;
/

/*
Monitoring Query (paste into SQL Developer / APEX report):

SELECT TO_CHAR(created_at, 'YYYY-MM-DD HH24:00') AS log_hour,
       module_name,
       severity,
       COUNT(*) AS entry_count
  FROM app_error_log
 WHERE created_at >= SYSTIMESTAMP - NUMTODSINTERVAL(24, 'HOUR')
   AND (module_name LIKE 'PROC\_%' ESCAPE '\\'
        OR module_name LIKE 'JOB\_%' ESCAPE '\\')
 GROUP BY TO_CHAR(created_at, 'YYYY-MM-DD HH24:00'),
          module_name,
          severity
 ORDER BY log_hour DESC,
          module_name,
          severity;
*/
