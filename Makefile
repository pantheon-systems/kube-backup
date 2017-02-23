include common.mk
include common-docs.mk
include common-go.mk
include common-docker.mk
include common-kube.mk
include common-shell.mk
include common-pants.mk

# Required Input Variables for common-python and a default value
PYTHON_PACKAGE_NAME=dummy
TEST_RUNNER=trial
include common-python.mk

NAMESPACE=sandbox-common-make-test
APP=common-make

test-common: test-shell test-readme-toc test-common-make test-common-kube test-common-docker test-common-pants

test-common-lint:
	! make test-common --warn-undefined-variables --just-print 2>&1 >/dev/null | grep warning

test-common-make: clean-common-make
	kubectl create namespace $(NAMESPACE) || true
	sleep 1
	@APP=$(APP) KUBE_NAMESPACE=$(NAMESPACE) bash sh/update-kube-object.sh ./test/fixtures/secrets
	@APP=$(APP) KUBE_NAMESPACE=$(NAMESPACE) bash sh/update-kube-object.sh ./test/fixtures/configmaps
	kubectl --namespace=$(NAMESPACE) get secret $(APP)-supersecret
	kubectl --namespace=$(NAMESPACE) get configmap $(APP)-testfile

clean-common-make:
	# lazy delete if or if it doesn't esxit
	kubectl delete namespace $(NAMESPACE) || true
	# kube needs time to cleanup
	sleep 1

test-common-pants: install-circle-pants
	$(HOME)/bin/pants version

test-common-kube:
	@echo $(KUBE_NAMESPACE)

test-common-docker:
ifdef CIRCLE_BUILD_NUM
	test "$(CIRCLE_BUILD_NUM)" = "$(BUILD_NUM)"
endif
	@echo $(BUILD_NUM)
	@echo $(IMAGE)
