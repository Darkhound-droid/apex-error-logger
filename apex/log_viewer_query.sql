/*
File Name   : log_viewer_query.sql
Description : Interactive Report source query for viewing and filtering APP_ERROR_LOG entries in Oracle APEX.
Author      : Hassan Raza
Created Date: 2026-02-20
Version     : 1.0
*/

SELECT l.log_id                           AS log_id,
       l.created_at                       AS created_at,
       l.severity                         AS severity,
       CASE l.severity
           WHEN 'FATAL' THEN 'severity-red'
           WHEN 'ERROR' THEN 'severity-orange'
           WHEN 'WARNING' THEN 'severity-yellow'
           WHEN 'INFO' THEN 'severity-green'
           ELSE 'severity-default'
       END                                AS severity_css_class,
       l.module_name                      AS module_name,
       l.error_code                       AS error_code,
       l.error_message                    AS error_message,
       l.apex_user                        AS apex_user,
       l.apex_app_id                      AS apex_app_id,
       l.apex_page_id                     AS apex_page_id,
       l.apex_session_id                  AS apex_session_id,
       l.server_host                      AS server_host,
       DBMS_LOB.SUBSTR(l.additional_info, 2000, 1) AS additional_info_preview,
       DBMS_LOB.SUBSTR(l.error_stack, 2000, 1)     AS error_stack_preview
  FROM app_error_log l
 WHERE (:PXX_SEVERITY IS NULL OR l.severity = :PXX_SEVERITY)
   AND (:PXX_MODULE IS NULL OR l.module_name LIKE :PXX_MODULE || '%')
   AND (:PXX_FROM_DATE IS NULL OR l.created_at >= :PXX_FROM_DATE)
   AND (:PXX_TO_DATE IS NULL OR l.created_at < :PXX_TO_DATE + 1)
 ORDER BY l.created_at DESC;
