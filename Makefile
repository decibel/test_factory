include pgxntool/variables.mk

include $(PGXS)

include pgxntool/targets.mk

# Hook for test to ensure dependencies in control file are set correctly
testdeps: check_control

.PHONY: check_control
check_control:
	grep -q "requires = 'pgtap, test_factory'" test_factory_pgtap.control
