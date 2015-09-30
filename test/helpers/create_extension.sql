\echo Creating extension :extension_name
-- No IF NOT EXISTS because we'll be confused if we're not loading the new stuff
CREATE TEMP TABLE pre_install_role AS SELECT current_user;
GRANT SELECT ON pre_install_role TO public; -- In case role is different
CREATE EXTENSION :extension_name;
CREATE TEMP TABLE post_install_role AS SELECT current_user;
GRANT SELECT ON post_install_role TO public; -- In case role is different
