\i test/helpers/psql.sql
BEGIN;
\i test/helpers/deps.sql

\i test/helpers/tap_setup.sql
SELECT no_plan();
