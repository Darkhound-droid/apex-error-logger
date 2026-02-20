/*
File Name   : 06_sample_usage.sql
Description : Provides production-style examples for using PKG_ERROR_LOGGER in APEX and scheduler flows.
Author      : Hassan Raza
Created Date: 2026-02-20
Version     : 1.0
*/

PROMPT Example 1: Basic usage in a PL/SQL process in Oracle APEX
BEGIN
    -- Your business logic here
    INSERT INTO orders (
        order_id,
        customer_id,
        order_total,
        created_on
    )
    VALUES (
        :P10_ORDER_ID,
        :P10_CUSTOMER_ID,
        :P10_ORDER_TOTAL,
        SYSTIMESTAMP
    );
EXCEPTION
    WHEN OTHERS THEN
        pkg_error_logger.log_error(
            p_module          => 'PROCESS_ORDER',
            p_severity        => 'ERROR',
            p_additional_info => 'Order ID: ' || :P10_ORDER_ID
        );
        RAISE; -- Re-raise if you want APEX to also show the error.
END;
/

PROMPT Example 2: Logging informational messages
BEGIN
    pkg_error_logger.log_message(
        p_module   => 'ORDER_WORKFLOW',
        p_message  => 'Order validation completed successfully for order ' || :P10_ORDER_ID,
        p_severity => 'INFO'
    );
EXCEPTION
    WHEN OTHERS THEN
        pkg_error_logger.log_error(
            p_module          => 'ORDER_WORKFLOW.INFO_LOG',
            p_severity        => 'WARNING',
            p_additional_info => 'Unable to save informational audit message for order ' || :P10_ORDER_ID
        );
END;
/

PROMPT Example 3: Using in a scheduled DBMS_SCHEDULER job
BEGIN
    -- Simulate background batch module entry log
    pkg_error_logger.log_message(
        p_module   => 'JOB_NIGHTLY_RECONCILIATION',
        p_message  => 'Nightly reconciliation job started.',
        p_severity => 'INFO'
    );

    -- Batch logic here
    UPDATE invoice_queue
       SET status = 'READY_FOR_EXPORT'
     WHERE status = 'APPROVED'
       AND exported_flag = 'N';
EXCEPTION
    WHEN OTHERS THEN
        pkg_error_logger.log_error(
            p_module          => 'JOB_NIGHTLY_RECONCILIATION',
            p_severity        => 'ERROR',
            p_additional_info => 'Scheduler job failed during invoice queue processing.'
        );
END;
/

PROMPT Example 4: Fatal error with full additional context
DECLARE
    l_context CLOB;
BEGIN
    l_context := 'Context => '
                 || pkg_error_logger.format_apex_context
                 || ' | Request: ' || :REQUEST
                 || ' | Item: P42_PAYMENT_ID=' || :P42_PAYMENT_ID;

    -- Force a sample fatal path
    RAISE_APPLICATION_ERROR(-20001, 'Payment gateway connection unavailable');
EXCEPTION
    WHEN OTHERS THEN
        pkg_error_logger.log_error(
            p_module          => 'PAYMENT_GATEWAY_CALLBACK',
            p_severity        => 'FATAL',
            p_additional_info => l_context
        );
        RAISE;
END;
/
