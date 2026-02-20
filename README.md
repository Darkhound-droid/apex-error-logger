# apex-error-logger

[![Oracle APEX](https://img.shields.io/badge/Oracle%20APEX-20.1%2B-EA1D25?logo=oracle&logoColor=white)](https://apex.oracle.com/)
[![PL/SQL](https://img.shields.io/badge/PL%2FSQL-Oracle%2012c%2B-F80000)](https://www.oracle.com/database/)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Oracle ACE Apprentice](https://img.shields.io/badge/Oracle%20ACE-Apprentice-blueviolet)](https://ace.oracle.com/)

A production-ready Oracle PL/SQL error logging framework for Oracle APEX applications.

## Overview

`apex-error-logger` provides centralized, structured, and low-risk logging for enterprise Oracle APEX environments. Instead of scattering ad-hoc exception handlers and `DBMS_OUTPUT` calls, this framework captures errors, call stacks, runtime context, and operational messages in a single table. This improves debugging speed, operational visibility, and auditability across development, test, and production workloads.

## Features

- Centralized logging table (`APP_ERROR_LOG`) with rich contextual metadata.
- Severity model with enforced values: `INFO`, `WARNING`, `ERROR`, `FATAL`.
- Automatic capture of:
  - `SQLCODE` and `SQLERRM`
  - Backtrace (`DBMS_UTILITY.FORMAT_ERROR_BACKTRACE`)
  - Call stack (`DBMS_UTILITY.FORMAT_CALL_STACK`)
  - APEX user, app, page, and session context
  - Database host name from `SYS_CONTEXT('USERENV', 'HOST')`
- `PRAGMA AUTONOMOUS_TRANSACTION` logging procedures to prevent log loss on rollback.
- Utility operations:
  - message logging (`LOG_MESSAGE`)
  - retention cleanup (`PURGE_LOGS`)
  - fast aggregate lookup (`GET_ERROR_COUNT`)
  - APEX context formatting (`FORMAT_APEX_CONTEXT`)
- Prebuilt reporting views:
  - `V_ERROR_LOG_RECENT`
  - `V_ERROR_LOG_SUMMARY`
  - `V_ERROR_LOG_FATAL`
- APEX Interactive Report source query with filter-friendly aliases and severity CSS class mapping.
- Ready-to-run sample usage scripts for page processes and scheduler jobs.

## Prerequisites

- Oracle Database **12c or higher**
- Oracle APEX **20.1 or higher**
- Schema privileges:
  - `CREATE TABLE`
  - `CREATE SEQUENCE`
  - `CREATE TRIGGER`
  - `CREATE PROCEDURE`
  - `CREATE VIEW`
  - `SELECT` on `V$SESSION` (optional, if your diagnostics and governance standards require session-level enrichments)

## Installation

Run the SQL scripts in the exact order shown:

1. `sql/01_create_table.sql`
2. `sql/02_create_sequence.sql`
3. `sql/03_pkg_error_logger_spec.sql`
4. `sql/04_pkg_error_logger_body.sql`
5. `sql/05_create_views.sql`
6. `sql/06_sample_usage.sql` (optional; examples/reference)
7. `sql/07_scheduler_job.sql` (optional: scheduler job examples and background process logging)

Example SQL*Plus / SQLcl flow:

```sql
@sql/01_create_table.sql
@sql/02_create_sequence.sql
@sql/03_pkg_error_logger_spec.sql
@sql/04_pkg_error_logger_body.sql
@sql/05_create_views.sql
```

## Usage

Use this standard exception pattern in APEX process code:

```sql
BEGIN
  -- Business logic
  INSERT INTO orders (order_id, customer_id, order_total)
  VALUES (:P10_ORDER_ID, :P10_CUSTOMER_ID, :P10_ORDER_TOTAL);
EXCEPTION
  WHEN OTHERS THEN
    pkg_error_logger.log_error(
      p_module          => 'PROCESS_ORDER',
      p_severity        => 'ERROR',
      p_additional_info => 'Order ID: ' || :P10_ORDER_ID
    );
    RAISE;
END;
```

## Package Reference

| Procedure / Function | Parameters | Description |
|---|---|---|
| `LOG_ERROR` | `p_module IN VARCHAR2`, `p_severity IN VARCHAR2 DEFAULT 'ERROR'`, `p_additional_info IN CLOB DEFAULT NULL` | Logs exception details with SQL error metadata, stack/backtrace, APEX context, and host information. |
| `LOG_MESSAGE` | `p_module IN VARCHAR2`, `p_message IN VARCHAR2`, `p_severity IN VARCHAR2 DEFAULT 'INFO'` | Logs non-exception operational messages and warnings/informational events. |
| `PURGE_LOGS` | `p_older_than_days IN NUMBER DEFAULT 90` | Deletes old log records based on retention threshold (in days). |
| `GET_ERROR_COUNT` | `p_severity IN VARCHAR2 DEFAULT NULL`, `p_since_hours IN NUMBER DEFAULT 24` | Returns count of log records within a time window, optionally filtered by severity. |
| `FORMAT_APEX_CONTEXT` | None | Returns a readable context string such as `App: 100 | Page: 10 | User: HASSAN | Session: 12345678`. |

## Log Viewer in APEX

Use `apex/log_viewer_query.sql` as the source query of an APEX Interactive Report region:

- Create a new page (Interactive Report).
- Set source type to SQL Query.
- Paste query from `apex/log_viewer_query.sql`.
- Add optional page items used by the query (`PXX_SEVERITY`, `PXX_MODULE`, `PXX_FROM_DATE`, `PXX_TO_DATE`) for runtime filtering.
- Apply column formatting and badge/template classes using `SEVERITY_CSS_CLASS` for color cues.

## Scheduler Job Integration

Oracle APEX debug instrumentation is session-bound, so it does not provide visibility for background `DBMS_SCHEDULER` executions where no APEX web session exists. The `sql/07_scheduler_job.sql` script demonstrates how to use `PKG_ERROR_LOGGER` for step-by-step telemetry, recoverable error tracking, warning classification, and fatal failure capture in unattended jobs. Use the same exception-first pattern in all scheduler procedures to keep diagnostics durable and queryable.

```sql
BEGIN
  -- Scheduler procedure body
EXCEPTION
  WHEN OTHERS THEN
    pkg_error_logger.log_error(
      p_module          => 'JOB_OR_PROC_NAME',
      p_severity        => 'ERROR',
      p_additional_info => 'Background execution context details'
    );
    RAISE;
END;
```

## Why `PRAGMA AUTONOMOUS_TRANSACTION` matters

Error logging should be resilient even when the main business transaction fails and rolls back. By isolating logging in autonomous transactions, the framework commits diagnostic data independently from the parent transaction, preserving evidence that would otherwise be lost during rollback. This behavior is essential in enterprise support models where reproducibility and root-cause timelines depend on durable telemetry.

## Contributing

Contributions are welcome.

1. Fork the repository.
2. Create a feature branch.
3. Follow Oracle PL/SQL style and naming conventions.
4. Add or update documentation for any functional changes.
5. Submit a pull request with clear rationale and testing notes.

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.

## Author

**Hassan Raza**  
Oracle ACE Apprentice  
Senior Oracle APEX Developer at S&H Software Solutions, Pakistan

- Github: [Hassan Raza on GitHub](https://github.com/Darkhound-droid)
- LinkedIn: [Hassan Raza](https://www.linkedin.com/in/link-hassan-raza/)
