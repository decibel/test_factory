\set ECHO none
\i test/helpers/psql.sql

BEGIN;
\i test/helpers/deps.sql
\i sql/test_format.sql
ROLLBACK;
