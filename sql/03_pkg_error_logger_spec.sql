/*
File Name   : 03_pkg_error_logger_spec.sql
Description : Package specification for centralized Oracle APEX error and message logging.
Author      : Hassan Raza
Created Date: 2026-02-20
Version     : 1.0
*/

CREATE OR REPLACE PACKAGE pkg_error_logger IS
    PROCEDURE log_error (
        p_module           IN VARCHAR2,
        p_severity         IN VARCHAR2 DEFAULT 'ERROR',
        p_additional_info  IN CLOB DEFAULT NULL
    );

    PROCEDURE log_message (
        p_module    IN VARCHAR2,
        p_message   IN VARCHAR2,
        p_severity  IN VARCHAR2 DEFAULT 'INFO'
    );

    PROCEDURE purge_logs (
        p_older_than_days IN NUMBER DEFAULT 90
    );

    FUNCTION get_error_count (
        p_severity    IN VARCHAR2 DEFAULT NULL,
        p_since_hours IN NUMBER DEFAULT 24
    ) RETURN NUMBER;

    FUNCTION format_apex_context RETURN VARCHAR2;
END pkg_error_logger;
/

SHOW ERRORS PACKAGE pkg_error_logger;
