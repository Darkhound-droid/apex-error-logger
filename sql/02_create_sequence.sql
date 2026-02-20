/*
File Name   : 02_create_sequence.sql
Description : Creates sequence and before-insert trigger for APP_ERROR_LOG primary key population.
Author      : Hassan Raza
Created Date: 2026-02-20
Version     : 1.0
*/

CREATE SEQUENCE app_error_log_seq
    START WITH 1
    INCREMENT BY 1
    CACHE 20
    NOCYCLE;

CREATE OR REPLACE TRIGGER app_error_log_bir
    BEFORE INSERT ON app_error_log
    FOR EACH ROW
BEGIN
    IF :NEW.log_id IS NULL THEN
        :NEW.log_id := app_error_log_seq.NEXTVAL;
    END IF;
END;
/

SHOW ERRORS TRIGGER app_error_log_bir;
