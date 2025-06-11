\set ECHO none
\i test/helpers/setup.sql

SET client_min_messages = WARNING;

/*
 * DO NOT use CASCADE here; we want this to fail if there's anything installed
 * that depends on it.
 */
SELECT lives_ok($$DROP EXTENSION IF EXISTS test_factory_pgtap$$, 'drop extension test_factory_pgtap');
SELECT lives_ok($$DROP EXTENSION IF EXISTS test_factory$$, 'drop extension test_factory');

SELECT hasnt_extension( 'test_factory' );
SELECT hasnt_extension( 'test_factory_pgtap' );

SELECT lives_ok($$CREATE EXTENSION test_factory_pgtap CASCADE$$, 'create extension');
COMMIT;

SELECT has_function('tf', 'tap', array['text','text']);

-- Cleanup
SELECT lives_ok($$DROP EXTENSION IF EXISTS test_factory_pgtap$$, 'clean-up test_factory_pgtap');
SELECT lives_ok($$DROP EXTENSION IF EXISTS test_factory$$, 'clean-up test_factory');

/*
 * Arguably we should cleanup pgtap and the tap schema...
 */

-- vi: expandtab ts=2 sw=2

