\set ECHO none
\i test/helpers/setup.sql

SET ROLE = DEFAULT;
CREATE ROLE test_role;
GRANT USAGE ON SCHEMA tap TO test_role;
GRANT test_role TO test_factory__owner;

CREATE SCHEMA test AUTHORIZATION test_role;
SET ROLE = test_role;
SET search_path = test, tap;
\i test/helpers/create.sql

SELECT no_plan();
SELECT is(
  (SELECT * FROM post_install_role)
  , (SELECT * FROM pre_install_role)
  , 'Ensure role is put back after install'
);

SELECT cmp_ok(
      proconfig
      , '@>'
      , '{search_path=pg_catalog}'
      , 'Security definer function ' || p.oid::regproc || ' has search_path=pg_catalog'
    )
  FROM pg_proc p
    JOIN pg_namespace n ON n.oid = pronamespace
  WHERE n.nspname IN ( 'tf', '_tf' )
    AND p.prosecdef
;

SELECT lives_ok(
$lives_ok$SELECT tf.register(
  'customer'
  , array[
    row(
      'insert'
      , $$INSERT INTO customer VALUES (DEFAULT, 'first', 'last' ) RETURNING *$$
    )::tf.test_set
    , row(
      'function'
      , $$SELECT * FROM customer__add( 'func first', 'func last' )$$
    )::tf.test_set
  ]
);$lives_ok$
  , 'Register test customers'
);
SELECT lives_ok(
$lives_ok$CREATE FUNCTION customer__add(
  first_name text
  , last_name text
) RETURNS SETOF customer LANGUAGE plpgsql AS $body$
BEGIN
  RETURN QUERY
    INSERT INTO customer( first_name, last_name )
      VALUES( first_name, last_name )
      RETURNING *
  ;
END
$body$;$lives_ok$
  , 'Create function customer__add'
);

SELECT lives_ok(
$lives_ok$SELECT tf.register(
  'invoice'
  , array[
      row(
        'base'
        , $$INSERT INTO invoice VALUES(
            DEFAULT
            , (tf.get( NULL::customer, 'insert' )).customer_id
            , current_date
            , current_date + 30
          ) RETURNING *$$
      )::tf.test_set
  ]
);$lives_ok$
  , 'Register test invoices'
);

SELECT is_empty(
  'SELECT * FROM customer'
  , 'customer table is empty'
);
SELECT is_empty(
  'SELECT * FROM invoice'
  , 'invoice table is empty'
);

SET ROLE = DEFAULT;
SET log_min_messages = debug5;
SET ROLE = test_role;
SELECT results_eq(
  $$SELECT * FROM tf.get( NULL::invoice, 'base' )$$
  , $$VALUES( 1, 1, current_date, current_date + 30 )$$
  , 'invoice factory output'
);

SELECT bag_eq(
  $$SELECT * FROM invoice$$
  , $$VALUES( 1, 1, current_date, current_date + 30 )$$
  , 'invoice table content'
);

SELECT bag_eq(
  $$SELECT * FROM customer$$
  , $$VALUES( 1, 'first', 'last' )$$
  , 'customer table content'
);

SELECT results_eq(
  $$SELECT * FROM tf.get( NULL::invoice, 'base' )$$
  , $$VALUES( 1, 1, current_date, current_date + 30 )$$
  , 'invoice factory second call'
);

SELECT bag_eq(
  $$SELECT * FROM invoice$$
  , $$VALUES( 1, 1, current_date, current_date + 30 )$$
  , 'invoice table content stayed constant'
);

SELECT bag_eq(
  $$SELECT * FROM customer$$
  , $$VALUES( 1, 'first', 'last' )$$
  , 'customer table content stayed constant'
);

SELECT results_eq(
  $$SELECT * FROM tf.get( NULL::customer, 'function' )$$
  , $$VALUES( 2, 'func first', 'func last' )$$
  , 'Test function factory'
);

SELECT bag_eq(
  $$SELECT * FROM customer$$
  , $$VALUES
      ( 1, 'first', 'last' )
      , ( 2, 'func first', 'func last' )
    $$
  , 'customer table has new row'
);

SELECT lives_ok(
  $$TRUNCATE invoice$$
  , 'truncate invoice'
);

SELECT results_eq(
  $$SELECT * FROM tf.get( NULL::invoice, 'base' )$$
  , $$VALUES( 1, 1, current_date, current_date + 30 )$$
  , 'invoice factory get remains the same after truncate'
);

ROLLBACK;

-- vi: expandtab ts=2 sw=2
