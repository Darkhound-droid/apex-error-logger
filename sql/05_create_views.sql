/*
File Name   : 05_create_views.sql
Description : Creates reporting views for recent, summarized, and fatal error analytics.
Author      : Hassan Raza
Created Date: 2026-02-20
Version     : 1.0
*/

CREATE OR REPLACE VIEW v_error_log_recent AS
SELECT *
  FROM (
        SELECT l.log_id,
               l.error_code,
               l.error_message,
               l.error_stack,
               l.severity,
               l.module_name,
               l.apex_user,
               l.apex_app_id,
               l.apex_page_id,
               l.apex_session_id,
               l.additional_info,
               l.created_at,
               l.server_host
          FROM app_error_log l
         ORDER BY l.created_at DESC
       )
 WHERE ROWNUM <= 100;

CREATE OR REPLACE VIEW v_error_log_summary AS
SELECT l.severity,
       l.module_name,
       COUNT(*) AS log_count,
       TRUNC(CAST(l.created_at AS DATE)) AS log_day
  FROM app_error_log l
 WHERE TRUNC(CAST(l.created_at AS DATE)) = TRUNC(SYSDATE)
 GROUP BY l.severity,
          l.module_name,
          TRUNC(CAST(l.created_at AS DATE));

CREATE OR REPLACE VIEW v_error_log_fatal AS
SELECT l.log_id,
       l.error_code,
       l.error_message,
       l.error_stack,
       l.severity,
       l.module_name,
       l.apex_user,
       l.apex_app_id,
       l.apex_page_id,
       l.apex_session_id,
       l.additional_info,
       l.created_at,
       l.server_host
  FROM app_error_log l
 WHERE l.severity = 'FATAL'
   AND l.created_at >= SYSTIMESTAMP - NUMTODSINTERVAL(7, 'DAY')
 ORDER BY l.created_at DESC;
