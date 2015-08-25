\set ECHO none
\i test/helpers/setup.sql

SELECT no_plan();
ROLLBACK;

-- vi: expandtab ts=2 sw=2
