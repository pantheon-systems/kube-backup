# Common kube things. This is the simplest set of common kube tasks
#
# INPUT VARIABLES
# 	- APP: should be defined in your topmost Makefile
# 	- SECRET_FILES: list of files that should exist in secrets/* used by
# 									_validate_secrets task
#
# EXPORT VARIABLES
# 	- KUBE_NAMESPACE: represents the kube namespace that has been detected based on
# 	           branch build and circle existence.
#-------------------------------------------------------------------------------

## Append tasks to the global tasks
deps-circle:: deps-circle-kube

# Use pants to divine the namespace on local development.
ifndef CIRCLECI
  KUBE_NAMESPACE := $(shell pants sandbox | grep Default |  awk '{print $$NF}' )
endif

# If we are on master branch, use production kube env
ifeq ($(CIRCLE_BRANCH), master) # prod
  KUBE_NAMESPACE := production
endif

# If on circle and not on master, build into a sandbox environment.
ifndef KUBE_NAMESPACE
  KUBE_NAMESPACE := sandbox-$(CIRCLE_PROJECT_REPONAME)-$(CIRCLE_BRANCH)
endif

# debatable weather this should be in common or not, but I see it needed enough in dev.
# TODO(jesse): possibly guard this to prevent accidentally nuking production.
force-pod-restart:: ## nuke the pod
	kubectl --namespace=$(KUBE_NAMESPACE) get  pod -l"app=$(APP)" --no-headers | awk '{print $$1}' | xargs kubectl delete pod

# extend or define circle deps to install gcloud
deps-circle-kube::
	@bash devops/make/sh/update-gcloud.sh

update-secrets:: ## update secret volumes in a kubernetes cluster
	@APP=$(APP) KUBE_NAMESPACE=$(KUBE_NAMESPACE) bash devops/make/sh/update-kube-object.sh ./devops/k8s/secrets

update-configmaps:: ## update configmaps in a kubernetes cluster
	@APP=$(APP) KUBE_NAMESPACE=$(KUBE_NAMESPACE) bash devops/make/sh/update-kube-object.sh ./devops/k8s/configmaps

# set SECRET_FILES to a list, and this will ensure they are there
_validate-secrets::
		@for j in $(SECRET_FILES) ; do \
			if [ ! -e secrets/$$j ] ; then  \
			echo "Missing file: secrets/$$j" ;\
				exit 1 ;  \
			fi \
		done

.PHONY::  deps-circle force-pod-restart
