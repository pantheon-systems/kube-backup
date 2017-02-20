# install and configure pants on circle-ci
#
# The following ENV vars must be set before calling this script:
#
#   GITHUB_TOKEN          # Github Personal Access token to read the private repository
#
# Optional:
#   PANTS_VERSION         # Version of pants to install.
#   PANTS_INCLUDE         # Services for pants to include. Default is all.
#

FETCH_URL := "https://github.com/gruntwork-io/fetch/releases/download/v0.1.0/fetch_linux_amd64"
# Installs greater than 0.1.3 unless overridden.
PANTS_VERSION := ">=0.1.3"
FLAGS := --update-onebox=false
ifdef PANTS_INCLUDE
  FLAGS += --include $(PANTS_INCLUDE)
endif

## append to the global task
deps-circle:: install-circle-pants

install-circle-fetch:
	curl -L $(FETCH_URL) -o $(HOME)/bin/fetch
	chmod 755 $(HOME)/bin/fetch

install-circle-pants: install-circle-fetch
	fetch --repo="https://github.com/pantheon-systems/pants" \
	--tag=$(PANTS_VERSION) \
	--release-asset="pants-linux" \
	--github-oauth-token=$(GITHUB_TOKEN) \
	$(HOME)/bin
	mv $(HOME)/bin/pants-linux $(HOME)/bin/pants
	chmod 755 $(HOME)/bin/pants

init-circle-pants:: ## initializes pants sandbox, updates sandbox if it exists
	pants sandbox init --sandbox=$(KUBE_NAMESPACE) $(FLAGS) || pants sandbox update --sandbox=$(KUBE_NAMESPACE) $(FLAGS)
