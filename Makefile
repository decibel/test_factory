PGXN = $(shell grep -m 1 '"name":' META.json | \
sed -e 's/[[:space:]]*"name":[[:space:]]*"\([^"]*\)",/\1/')
PGXNVERSION = $(shell grep -m 1 '"version":' META.json | tail -n 1 | \
sed -e 's/[[:space:]]*"version":[[:space:]]*"\([^"]*\)",\{0,1\}/\1/')
EXTENSION1 = $(PGXN)
EXTVERSION1 = $(shell grep -m 2 '"version":' META.json | tail -n 1 | \
sed -e 's/[[:space:]]*"version":[[:space:]]*"\([^"]*\)",\{0,1\}/\1/')
EXTENSION2 = test_factory_pgtap
EXTVERSION2 = $(shell grep -m 3 '"version":' META.json | tail -n 1 | \
sed -e 's/[[:space:]]*"version":[[:space:]]*"\([^"]*\)",\{0,1\}/\1/')

DATA         = $(filter-out $(wildcard sql/*-*-*.sql),$(wildcard sql/*.sql))
DOCS         = $(wildcard doc/*.asc)
TESTS        = $(wildcard test/sql/*.sql)
REGRESS      = $(patsubst test/sql/%.sql,%,$(TESTS))
REGRESS_OPTS = --inputdir=test --load-language=plpgsql
#
# Uncoment the MODULES line if you are adding C files
# to your extention.
#
#MODULES      = $(patsubst %.c,%,$(wildcard src/*.c))
PG_CONFIG    = pg_config

EXTRA_CLEAN  = $(wildcard ../$(PGXN)-*.zip) $(wildcard sql/$(EXTENSION1)--*.sql) $(wildcard sql/$(EXTENSION2)--*.sql)

# Get Postgres version, as well as major (9.4, etc) version. Remove '.' from MAJORVER.
VERSION 	 = $(shell $(PG_CONFIG) --version | awk '{print $$2}' | sed -e 's/devel$$//')
MAJORVER 	 = $(shell echo $(VERSION) | cut -d . -f1,2 | tr -d .)

# Function for testing a condition
test		 = $(shell test $(1) $(2) $(3) && echo yes || echo no)

GE91		 = $(call test, $(MAJORVER), -ge, 91)

ifeq ($(GE91),yes)
all: sql/$(EXTENSION1)--$(EXTVERSION1).sql sql/$(EXTENSION2)--$(EXTVERSION2).sql

sql/$(EXTENSION1)--$(EXTVERSION1).sql: sql/$(EXTENSION1).sql META.json
	cp $< $@
sql/$(EXTENSION2)--$(EXTVERSION2).sql: sql/$(EXTENSION2).sql META.json
	cp $< $@

DATA = $(wildcard sql/*--*.sql)
EXTRA_CLEAN += sql/$(EXTENSION1)--$(EXTVERSION1).sql
EXTRA_CLEAN += sql/$(EXTENSION2)--$(EXTVERSION2).sql
endif

# Need to do this because we're not setting EXTENSION
MODULEDIR = extension
DATA += $(wildcard *.control)

PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)

# Hook for test to ensure dependencies in control file are set correctly
testdeps: check_control

.PHONY: check_control
check_control:
	grep -q "requires = 'pgtap, test_factory'" $(EXTENSION2).control

# Don't have installcheck bomb on error
.IGNORE: installcheck

#
# pgtap
#
.PHONY: pgtap
pgtap: $(DESTDIR)$(datadir)/extension/pgtap.control

$(DESTDIR)$(datadir)/extension/pgtap.control:
	pgxn install pgtap

#
# testdeps
#
.PHONY: testdeps
testdeps: pgtap

.PHONY: test
test: clean testdeps install installcheck
	@if [ -r regression.diffs ]; then cat regression.diffs; fi

.PHONY: results
results: test
	rsync -rlpgovP results/ test/expected

rmtag:
	git fetch origin # Update our remotes
	@test -z "$$(git branch --list $(PGXNVERSION))" || git branch -d $(PGXNVERSION)
	@test -z "$$(git branch --list -r origin/$(PGXNVERSION))" || git push --delete origin $(PGXNVERSION)

tag:
	@test -z "$$(git status --porcelain)" || (echo 'Untracked changes!'; echo; git status; exit 1)
	git branch $(PGXNVERSION)
	git push --set-upstream origin $(PGXNVERSION)

.PHONY: forcetag
forcetag: rmtag tag

dist: tag
	git archive --prefix=$(PGXN)-$(PGXNVERSION)/ -o ../$(PGXN)-$(PGXNVERSION).zip $(PGXNVERSION)

.PHONY: forcedist
forcedist: forcetag dist

# To use this, do make print-VARIABLE_NAME
print-%  : ; @echo $* = $($*)
