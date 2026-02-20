/*
File Name   : 04_pkg_error_logger_body.sql
Description : Package body implementation for Oracle APEX error logging framework.
Author      : Hassan Raza
Created Date: 2026-02-20
Version     : 1.0
*/

CREATE OR REPLACE PACKAGE BODY pkg_error_logger IS

    FUNCTION normalize_severity (
        p_severity IN VARCHAR2,
        p_default  IN VARCHAR2
    ) RETURN VARCHAR2
    IS
        v_severity VARCHAR2(20);
    BEGIN
        v_severity := UPPER(NVL(TRIM(p_severity), p_default));

        IF v_severity NOT IN ('INFO', 'WARNING', 'ERROR', 'FATAL') THEN
            v_severity := p_default;
        END IF;

        RETURN v_severity;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN p_default;
    END normalize_severity;

    FUNCTION format_apex_context RETURN VARCHAR2
    IS
        v_context VARCHAR2(4000);
    BEGIN
        v_context := 'App: '
            || NVL(TO_CHAR(apex_application.g_flow_id), 'N/A')
            || ' | Page: '
            || NVL(TO_CHAR(apex_application.g_flow_step_id), 'N/A')
            || ' | User: '
            || NVL(apex_application.g_user, 'N/A')
            || ' | Session: '
            || NVL(TO_CHAR(apex_application.g_instance), 'N/A');

        RETURN v_context;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN 'App: N/A | Page: N/A | User: N/A | Session: N/A';
    END format_apex_context;

    PROCEDURE log_error (
        p_module           IN VARCHAR2,
        p_severity         IN VARCHAR2 DEFAULT 'ERROR',
        p_additional_info  IN CLOB DEFAULT NULL
    )
    IS
        PRAGMA AUTONOMOUS_TRANSACTION;
        v_error_code      VARCHAR2(50);
        v_error_message   VARCHAR2(4000);
        v_error_stack     CLOB;
        v_severity        VARCHAR2(20);
        v_apex_user       VARCHAR2(255);
        v_apex_app_id     NUMBER;
        v_apex_page_id    NUMBER;
        v_apex_session_id VARCHAR2(100);
        v_server_host     VARCHAR2(255);
    BEGIN
        v_error_code      := TO_CHAR(SQLCODE);
        v_error_message   := SQLERRM;
        v_error_stack     := DBMS_UTILITY.format_error_backtrace || CHR(10) || DBMS_UTILITY.format_call_stack;
        v_severity        := normalize_severity(p_severity, 'ERROR');
        v_apex_user       := apex_application.g_user;
        v_apex_app_id     := apex_application.g_flow_id;
        v_apex_page_id    := apex_application.g_flow_step_id;
        v_apex_session_id := TO_CHAR(apex_application.g_instance);
        v_server_host     := SYS_CONTEXT('USERENV', 'HOST');

        INSERT INTO app_error_log (
            error_code,
            error_message,
            error_stack,
            severity,
            module_name,
            apex_user,
            apex_app_id,
            apex_page_id,
            apex_session_id,
            additional_info,
            server_host
        )
        VALUES (
            v_error_code,
            v_error_message,
            v_error_stack,
            v_severity,
            p_module,
            v_apex_user,
            v_apex_app_id,
            v_apex_page_id,
            v_apex_session_id,
            p_additional_info,
            v_server_host
        );

        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
    END log_error;

    PROCEDURE log_message (
        p_module    IN VARCHAR2,
        p_message   IN VARCHAR2,
        p_severity  IN VARCHAR2 DEFAULT 'INFO'
    )
    IS
        PRAGMA AUTONOMOUS_TRANSACTION;
        v_severity        VARCHAR2(20);
        v_apex_user       VARCHAR2(255);
        v_apex_app_id     NUMBER;
        v_apex_page_id    NUMBER;
        v_apex_session_id VARCHAR2(100);
        v_server_host     VARCHAR2(255);
    BEGIN
        v_severity        := normalize_severity(p_severity, 'INFO');
        v_apex_user       := apex_application.g_user;
        v_apex_app_id     := apex_application.g_flow_id;
        v_apex_page_id    := apex_application.g_flow_step_id;
        v_apex_session_id := TO_CHAR(apex_application.g_instance);
        v_server_host     := SYS_CONTEXT('USERENV', 'HOST');

        INSERT INTO app_error_log (
            error_code,
            error_message,
            error_stack,
            severity,
            module_name,
            apex_user,
            apex_app_id,
            apex_page_id,
            apex_session_id,
            additional_info,
            server_host
        )
        VALUES (
            NULL,
            p_message,
            NULL,
            v_severity,
            p_module,
            v_apex_user,
            v_apex_app_id,
            v_apex_page_id,
            v_apex_session_id,
            NULL,
            v_server_host
        );

        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
    END log_message;

    PROCEDURE purge_logs (
        p_older_than_days IN NUMBER DEFAULT 90
    )
    IS
    BEGIN
        DELETE FROM app_error_log
         WHERE created_at < SYSTIMESTAMP - NUMTODSINTERVAL(NVL(p_older_than_days, 90), 'DAY');

        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
    END purge_logs;

    FUNCTION get_error_count (
        p_severity    IN VARCHAR2 DEFAULT NULL,
        p_since_hours IN NUMBER DEFAULT 24
    ) RETURN NUMBER
    IS
        v_count    NUMBER := 0;
        v_severity VARCHAR2(20);
    BEGIN
        v_severity := CASE
                        WHEN p_severity IS NULL THEN NULL
                        ELSE normalize_severity(p_severity, 'ERROR')
                      END;

        SELECT COUNT(*)
          INTO v_count
          FROM app_error_log
         WHERE created_at >= SYSTIMESTAMP - NUMTODSINTERVAL(NVL(p_since_hours, 24), 'HOUR')
           AND (v_severity IS NULL OR severity = v_severity);

        RETURN v_count;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN 0;
    END get_error_count;

END pkg_error_logger;
/

SHOW ERRORS PACKAGE BODY pkg_error_logger;
