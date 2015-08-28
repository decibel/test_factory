\i test/helpers/psql.sql
BEGIN;
\i test/helpers/deps.sql

\i test/helpers/tap_setup.sql

-- No IF NOT EXISTS because we'll be confused if we're not loading the new stuff
CREATE TEMP TABLE pre_install_role AS SELECT current_user;
GRANT SELECT ON pre_install_role TO public; -- In case role is different
CREATE EXTENSION test_factory;
CREATE TEMP TABLE post_install_role AS SELECT current_user;
GRANT SELECT ON post_install_role TO public; -- In case role is different
