\set ECHO none
\i test/helpers/setup.sql

SET search_path = tap;
-- IF YOU GET A "schema tf does not exist" error here then the dependency is missing!
SELECT throws_ok(
  $$CREATE EXTENSION test_factory_pgtap$$
  , '42704'
  , 'required extension "test_factory" is not installed'
  , 'Ensure test_factory is a dependency of test_factory_pgtap'
);

\set extension_name test_factory
\i test/helpers/create_extension.sql
DROP TABLE pre_install_role;
DROP TABLE post_install_role;
\set extension_name test_factory_pgtap
\i test/helpers/create_extension.sql

-- NOTE: This runs some tests itself. It also changes search_path
\i test/helpers/create.sql

-- tf.tap already returns tap output
SELECT tf.tap( 'invoice' );
SELECT tf.tap( 'invoice', 'base' );
SELECT throws_ok(
  $$SELECT tf.tap( '"non-existent table"' )$$
  , '42P01'
  , 'relation "non-existent table" does not exist'
  , 'Ensure we get sane error for a non-existent table'
);

ROLLBACK;

-- vi: expandtab ts=2 sw=2
