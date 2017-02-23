Common make tasks
=================

<!-- toc -->

- [Introduction](#introduction)
- [Usage](#usage)
  * [Seting Up the common makefiles](#seting-up-the-common-makefiles)
  * [Using in your Makefile](#using-in-your-makefile)
  * [Updating common makefiles](#updating-common-makefiles)
  * [Extending Tasks](#extending-tasks)
- [Tasks](#tasks)
  * [common.mk](#commonmk)
    + [help](#help)
    + [update-makefiles](#update-makefiles)
  * [common-docs.mk](#common-docsmk)
    + [update-readme-toc](#update-readme-toc)
    + [test-readme-toc](#test-readme-toc)
  * [common-docker.mk](#common-dockermk)
    + [Input Environment Variables:](#input-environment-variables)
    + [Exported Environment Variables:](#exported-environment-variables)
    + [build-docker::](#build-docker)
    + [push::](#push)
    + [setup-quay::](#setup-quay)
    + [push-circle::](#push-circle)
  * [common-shell.mk](#common-shellmk)
    + [Input Environment Variables:](#input-environment-variables-1)
    + [test-shell](#test-shell)
  * [common-pants.mk](#common-pantsmk)
  * [install-circle-fetch](#install-circle-fetch)
  * [install-circle-pants](#install-circle-pants)
  * [common-python.mk](#common-pythonmk)
    + [Input Environment Variables:](#input-environment-variables-2)
    + [build-python::](#build-python)
    + [test-python::](#test-python)
    + [test-circle-python::](#test-circle-python)
    + [deps-python::](#deps-python)
    + [deps-circle::](#deps-circle)
    + [deps-coverage::](#deps-coverage)
    + [test-coverage-python::](#test-coverage-python)
    + [test-coveralls::](#test-coveralls)
    + [coverage-report::](#coverage-report)
    + [lint-python::](#lint-python)
    + [lint-pylint::](#lint-pylint)
    + [lint-flake8::](#lint-flake8)
  * [common-go.mk](#common-gomk)
    + [Input Environment Variables:](#input-environment-variables-3)
    + [build-go::](#build-go)
    + [build-linux::](#build-linux)
    + [build-circle::](#build-circle)
    + [test-go::](#test-go)
    + [test-no-race::](#test-no-race)
    + [test-circle::](#test-circle)
    + [deps-go::](#deps-go)
    + [deps-circle::](#deps-circle-1)
    + [deps-coverage::](#deps-coverage-1)
    + [deps-status::](#deps-status)
    + [test-coverage-go::](#test-coverage-go)
    + [test-coveralls::](#test-coveralls-1)
    + [test-coverage-html::](#test-coverage-html)
  * [common-kube.mk](#common-kubemk)
    + [Input Environment Variables:](#input-environment-variables-4)
    + [Exported Environment Variables:](#exported-environment-variables-1)
    + [force-pod-restart::](#force-pod-restart)
    + [update-secrets::](#update-secrets)
    + [update-configmaps::](#update-configmaps)
- [Contributing](#contributing)
  * [Common Patterns for adding to the repo](#common-patterns-for-adding-to-the-repo)
  * [Adding support for a new language](#adding-support-for-a-new-language)
  * [README.md updates](#readmemd-updates)
- [Handy Make stuff](#handy-make-stuff)

<!-- tocstop -->

Introduction
============

This repo contains a library of Makefile tasks and shell scripts that provide
common functions for working with a variety of systems at Pantheon. For example,
tasks for building projects (currently Go supported in `common-go.mk`, others
welcome! send PRs!), tasks for building docker containers, and tasks for
managing resources in Kubernetes.

It also contains an [examples](https://github.com/pantheon-systems/common_makefiles/tree/master/examples/go) folder with project repo skeletons, and the files contain very detailed comments that should provide a good starting point for everyone.

Usage
=====

Seting Up the common makefiles
------------------------------

Add these common tasks to your project by using git subtree from the root of
your project.

First add the remote.

```
git remote add common_makefiles git@github.com:pantheon-systems/common_makefiles.git --no-tags
```

Now add the subtree

**note:** it is important that you keep the import path set to `devops/make` as
the makefiles assume this structure.

```
git subtree add --prefix devops/make common_makefiles master --squash
```

Using in your Makefile
----------------------

you simply need to include the common makefiles you want in your projects root
Makefile:

```
APP := baryon
PROJECT := $$GOOGLE_PROJECT

include devops/make/common.mk
include devops/make/common-kube.mk
include devops/make/common-go.mk
```

Updating common makefiles
-------------------------

The `common.mk` file includes a task named `update-makefiles` which you can
invoke to pull and squash the latest versions of the common tasks into your
project. Put the changes on a branch.

```
git checkout -b update-make

make update-makefiles
```

If this is a new clone you may need to re-run these commands to register the
common-make git repo before running `make update-makefiles`:

```
git remote add common_makefiles git@github.com:pantheon-systems/common_makefiles.git --no-tags
git subtree add --prefix devops/make common_makefiles master --squash
```

Extending Tasks
---------------

All the common makefile tasks can be extended in your top level Makefile by
defining them again. Each common task that can be extended has a `::` target.
e.g. `deps::`

for example if I want to do something after the default build target from
common-go.mk I can add to it in my Makefile like so:

```
build::
  @echo "this is after the common build"
```

Tasks
=====

common.mk
---------

### help

`make help` prints out a list of tasks and descriptions.

Any task that contains a comment following this pattern will be displayed:

```
foo: ## this help message will be display by `make help`
    echo foo
```

Example:

```
$ make help
foo         this help message will be display by `make help`
```

### update-makefiles

Use this to pull the latest `master` branch from `common_makefiles` into the
local project. (Assumes `common_makefiles` were imported to `./devops/make`)

If you get an error such as `fatal: 'common_makefiles' does not appear to be a git repository`
you may need to add the remote repo before running this task:

```
git remote add common_makefiles git@github.com:pantheon-systems/common_makefiles.git --no-tags
```

common-docs.mk
--------------

Common tasks for managing documentation.

### update-readme-toc

Run `make update-readme-toc` to update the TOC in `./README.md`. Uses [markdown-toc](https://github.com/jonschlinkert/markdown-toc#cli)
to edit in place.

This task requires Docker to be running. In your `circle.yml` ensure docker is
available:

```
---
machine:
  services:
    - docker
```

### test-readme-toc

This task executes `markdoc-toc` via Docker and compares the output to the
current TOC in the on-disk `./README.md` file. If they differ, a diff output
will be displayed along with an error message and a non-zero exit will occur.

This is intended to be used in a CI pipeline to fail a build and remind author's
to update the TOC and re-submit their changes.

This task requires Docker to be running.

This task is added to the global `test` task.

common-docker.mk
----------------

### Input Environment Variables:

- `QUAY_USER`: The quay.io user to use (usually set in CI)
- `QUAY_PASSWD`: The quay passwd to use  (usually set in CI)
- `IMAGE`: the docker image to use. will be computed if it doesn't exist.
- `REGISTRY`: The docker registry to use. defaults to quay.

### Exported Environment Variables:

- `BUILD_NUM`: The build number for this build. will use 'dev' if not building
             on circleCI, will use CIRCLE_BUILD_NUM otherwise.
- `IMAGE`: The image to use for the build.
- `REGISTRY`: The registry to use for the build.

### build-docker::

Runs `docker build` to build an image using `./Dockerfile`. Tag `$(IMAGE)` is
applied.

### push::

Runs `docker push $(IMAGE)` to push the docker image and tag to the remote
docker registry (typically quay.io).

### setup-quay::

Runs `docker login` to configure the local docker command with credentials
for quay.io. Requires `QUAY_USER` and `QUAY_PASSWD` environment variables to
be set.

### push-circle::

Runs the `build-docker` and `push` tasks.

common-shell.mk
--------------

Common tasks for shell scripts, such as [shellcheck](https://www.shellcheck.net/)
for linting shell scripts.

Please also try to follow the [Google Shell Style Guide](https://google.github.io/styleguide/shell.xml)
when writing shell scripts.

### Input Environment Variables:

- `SHELL_SOURCES`: (optional) A list of shell scripts that should be tested by
  the `test-shell` and `test` tasks. If none is provided, `find . -name \*.sh`
  is run to find any shell files in the project.
- `SHELLCHECK_VERSION`: (optional) The version of shellcheck to be installed by
  the `deps-circle` task.

### test-shell

Run shell script tests such as `shellcheck`.

This task is added to the global `test` task.

common-pants.mk
---------------

Installs pants version greater than `0.1.3` unless overridden with
`PANTS_VERSION` so that a sandbox integration environment can be created on
circle for integration testing and acceptance criteria review.

- `GITHUB_TOKEN`: (required) Github Token for downloading releases of the [pants](https://github.com/pantheon-systems/pants)
   utility. Go https://github.com/settings/tokens to generate a new token
   (only read:repos access is needed)
- `PANTS_VERSION`: (optional) The version of pants to install
- `PANTS_INCLUDE`: (optional) The services for pants to install or update. E.g `make
  init-pants PANTS_INCLUDE=notification-service,ticket-management`

## install-circle-fetch

Installs the `fetch` utility on Circle-CI

## install-circle-pants

Installs the `pants` utility on Circle-CI from https://github.com/pantheon-systems/pants

This task is added to the global `deps-circle` task. If `make deps-circle` is already in your
circle.yml file then you only need to `include common-pants.mk` in your Makefile.

common-python.mk
------------

### Input Environment Variables:

- `PYTHON_PACKAGE_NAME`: (required) The name of the python package.
- `TEST_RUNNER`: (optional) The name of the python test runner to execute. Defaults to `trial`
- `COVERALLS_TOKEN`: (required by circle) Token to use when pushing coverage to coveralls.

### build-python::

Run `python setup.py sdist` in the current project directory.

This task is added to the global `build` task.

### test-python::

Runs targets `test-coverage-python` and target the global `lint` target. 

This task is added to the global `test` task.

### test-circle-python::

Intended for use in circle.yml to run tests under the Circle-CI context. This
target additionally calls target test-coveralls-python which runs `coveralls`
to report coverage metrics.

### deps-python::

Install this projects' Python dependencies which includes the targets deps-testrunner-python,
deps-lint-python and deps-coverage-python

NOTE: Currently assumes this project is using `pip` for dependency management.

This task is added to the global `deps` task.

### deps-circle::

Install dependencies on Circle-CI which includes the targets deps-coveralls-python

### deps-coverage::

Install dependencies necessary for running the test coverage utilities like
coveralls.

### test-coverage-python::

Run `coverage run --branch --source $(PYTHON_PACKAGE_NAME) $(shell which $(TEST_RUNNER)) $(PYTHON_PACKAGE_NAME)`
which creates the coverage report.

This task is added to the global `test-coverage` task.

### test-coveralls::

Run `coveralls` which sends the coverage report to coveralls.

Requires `COVERALLS_TOKEN` environment variable.

### coverage-report::

Run `coverage report` on the last generated coverage source.

### lint-python::
Run targets `lint-pylint` and `lint-flake8`

This task is added to the global `lint` task.

### lint-pylint::
Run `pylint $(PYTHON_PACKAGE_NAME)`

Pylint is a Python source code analyzer which looks for programming errors, helps enforcing a coding standard and sniffs for some code smells
as defined in Martin Fowler's Refactoring book). Pylint can also be run against any installed python package which is useful for catching
misconfigured setup.py files.

This task is added to `lint-python` task.

### lint-flake8::
Run `flake8 --show-source --statistics --benchmark $(PYTHON_PACKAGE_NAME)`

Flake8 is a combination of three tools (Pyflakes, pep8 and mccabe). Flake8 performs static analysis of your uncompiled code (NOT installed packages).

When the source directory of your project is not found this target prints a warning instead of an error. Pylint does not require the source directory
and can be run on an installed python package. This preserves flexibility.

This task is added to `lint-python` task.

common-go.mk
------------

### Input Environment Variables:

- `COVERALLS_TOKEN`: Token to use when pushing coverage to coveralls.
- `FETCH_CA_CERT:` The presence of this variable will add a  Pull root ca certs
                 to  ca-certificats.crt before build.

### build-go::

Run `go build` in the current project directory.

This task is added to the global `build` task.

### build-linux::

Build a static Linux binary. (Works on any platform.)

### build-circle::

Intended for use in circle.yml files to run a build under the Circle-CI
context.

### test-go::

Run `go test`.

This task is added to the global `test` task.

### test-no-race::

Run `go test` without the race dectector.

### test-circle::

Intended for use in circle.yml to run tests under the Circle-CI context.

### deps-go::

Install this projects' Go dependencies.

NOTE: Currently assumes this project is using `gvt` for dependency management.

This task is added to the global `deps` task.

### deps-circle::

Install dependencies on Circle-CI

### deps-coverage::

Install dependencies necessary for running the test coverage utilities like
coveralls.

### deps-status::

Check status of dependencies with gostatus.

### test-coverage-go::

Run `go cov` test coverage report.

This task is added to the global `test-coverage` task.

### test-coveralls::

Run test coverage report and send it to coveralls.

Requires `COVERALLS_TOKEN` environment variable.

### test-coverage-html::

Run go test coverage report and output to `./coverage.html`.

common-kube.mk
--------------

### Input Environment Variables:

- `APP`: should be defined in your topmost Makefile
- `SECRET_FILES`: list of files that should exist in secrets/* used by
                 `_validate_secrets`

### Exported Environment Variables:

- `KUBE_NAMESPACE`: represents the kube namespace that has been detected based
                   on branch build and circle existence, or the branch explicitly
                   set in the environment.

### force-pod-restart::

Nuke the pod in the current `KUBE_NAMESPACE`.

### update-secrets::

Requires `$APP` variable to be set.
Requires `$KUBE_NAMESPACE` variable to be set.
Requires one of these directories to have files meant to be applied:
- ./devops/k8s/secrets/production
- ./devops/k8s/secrets/non-prod/
- ./devops/k8s/secrets/<NAMESPACE>

There secrets can be created two ways:
1. From a set of files in a directory named after the
   secret. Each file will use its name as a key name for the secret
   and the data in the file as the value.
2. From a 'literal' map. Make a file that has a set of k=v pairs in it
  one per line. Each line will have its data split into secrets keys and values.

_How it works:_

Put secrets into files in a directory such as
`./devops/k8s/secrets/non-prod/<namespace>`,
run `make update-secrets KUBE_NAMESPACE=<namespace>` to upload the secrets
to the specified namespace in a volume named `$APP-certs`. If the directory
`./devops/k8s/secrets/<namespace>/` directory first, and if it doesn't exist it
will default to looking in `./devops/k8s/secrets/non-prod`

NOTE: The `$APP` variable will be prepended to the volume name. eg:
A directory path of `./devops/k8s/secrets/template-sandbox/certs` and `APP=foo` will create a
secret volume named `foo-certs` in the template-sandbox namespace.

_Directory Example:_

```
# for production:

$ mkdir -p ./devops/k8s/secrets/production/api-keys
$ echo -n "secret-API-key!" >./devops/k8s/secrets/production/api-keys/key1.txt
$ echo -n "another-secret-API-key!" >./devops/k8s/secrets/production/api-keys/key2.txt
$ make update-secrets KUBE_NAMESPACE=production APP=foo

# cleanup secrets, do not check them into git!
$ rm -rf -- ./devops/k8s/secrets/*
```

Verify the volume was created and contains the expected files:

```
$ kubectl describe secret foo-api-keys --namespace=production
Name:           foo-api-keys
Namespace:      production
Labels:         app=foo

Type:   Opaque

Data
====
key1.txt:       15 bytes
key2.txt:       22 bytes
```

_Literal File Example_

Make a file with k=value pairs, and name it what you want the secret to be called.
```
$ cat ./devops/k8s/secrets/non-prod/foo-secrets
secret1=foo
secret2=bar
secret3=baz
```

Apply the secrets
```
$ make update-secrets KUBE_NAMESPACE=template-sandbox
```

Verify the secrets contents
```
$ kubectl describe secrets myapp-foo-secrets --namespace=template-sandbox
Name:		myapp-foo-secrets
Namespace:	template-sandbox
Labels:		app=myapp
Annotations:	<none>

Data
====
secret1:	3 bytes
secret2:	3 bytes
secret3:	3 bytes
```

### update-configmaps::

Requires `$APP` variable to be set.
Requires `$KUBE_NAMESPACE` variable to be set.
Requires one of these directories to have files meant to be applied:
- ./devops/k8s/configmaps/production/
- ./devops/k8s/configmaps/non-prod/
- ./devops/k8s/configmaps/<NAMESPACE>/

Use this task to upload Kubernetes configmaps.

_How it works:_

There are 2 types of configmaps that can be used. A configmap complied from a set
of files in a directory or a 'literal' map. Directory of files is what it sounds
like; make a directory and put files in it. Each file will use its name as a key
name for the configmap, and the data in the file as the value. A Literal map is
a file that has a set of k=v pairs in it one per line. Each line will have it's
data split into configmap keys and values.

Put a file or directory in the proper namespace e.g.
`./devops/k8s/configmaps/<namespace>/<map-name>` then run `make update-configmaps`
this will update template-sandbox namespace by default. If you need to use a different
namespace provide that to the make command environment:
`make update-configmaps KUBE_NAMESPACE=<namespace>`. If the <namespace> directory
does not exist and your `KUBE_NAMESPACE` is not `'production'` then the script will
use configmaps defined in `./devops/k8s/configmaps/non-prod/`. This allows you to
apply configmaps to your kube sandbox without having to pollute the directories.

NOTE: The `$APP` variable will be prepended to the configmap name. eg:
A directory path of `./devops/k8s/configmaps/template-sandbox/config-files` and
`APP=foo` will create a configmap named `foo-config-files` in the `template-sandbox`
namespace.

_Directory Example:_

Make the map directory. Given the app named foo this will become a configmap named foo-nginx-config
```
$ mkdir -p ./devops/k8s/configmaps/non-prod/nginx-config
```

Put your app config in the directory you just created
```
$  ls ./devops/k8s/configmaps/non-prod/nginx-config
common-location.conf  common-proxy.conf  common-server.conf  nginx.conf  verify-client-ssl.conf  websocket-proxy.conf
```

Apply the map with the make task
```
$ make update-configmaps KUBE_NAMESPACE=sandbox-foo
# this error is fine, it would say deleted if it existed
Error from server: configmaps "foo-nginx-config" not found
configmap "foo-nginx-config" created
configmap "foo-nginx-config" labeled
```

Verify the volume was created and contains the expected files:

```
$ kubectl describe configmap foo-nginx-config --namespace=sandbox-foo
kubectl describe configmap foo-nginx-config --namespace=sandbox-foo
Name:		foo-nginx-config
Namespace:	sandbox-foo
Labels:		app=foo
Annotations:	<none>

Data
====
verify-client-ssl.conf:	214 bytes
websocket-proxy.conf:	227 bytes
common-location.conf:	561 bytes
common-proxy.conf:	95 bytes
common-server.conf:	928 bytes
nginx.conf:		2357 bytes
```

_Literal File Example_

Make a file with k=value pairs, and name it what you want the map to be called.
Given I am in 'myapp' using commonmake and I run these configs the resultant map
will be  'myapp-foo-config'
```
$ cat ./devops/k8s/configmaps/non-prod/foo-conf
setting1=foo
setting2=bar
setting3=baz
```

Apply the map
```
$ make update-configmaps KUBE_NAMESPACE=sandbox-foo
```

Verify the map contents
```
$ kubectl describe configmap myapp-foo-config --namespace=sandbox-foo
Name:		myapp-foo-config
Namespace:	sandbox-foo
Labels:		app=myapp
Annotations:	<none>

Data
====
setting1:	3 bytes
setting2:	3 bytes
setting3:	3 bytes
```

Contributing
============

make edits here and open a PR against this repo. Please do not push from your
subtree on your project.

1. Have an idea
2. Get feedback from the beautiful people around you
3. Document your new or modified task in this README
4. Commit on a branch (please squash closely related commits into contextually
   single commits)
5. Send PR

Common Patterns for adding to the repo
--------------------------------------

Tasks should follow the form of `<action>-<context>-<object>` for example ifs
I have a build task  and you want to add windows support you would add as
`build-windows` or if you wanted to add a build for onebox you might dos
`build-onebox-linux` or simply `build-onebox`.

There is the expectation that if you are doing a context specific task you adds
the context to your tasks. I.E. `test-circle`

This isn't written in stone, but I think it is a reasonable expectation thats
any engineer should be able to checkout any project and run:
`make deps && make build && make test` to get things running / testing.

Adding support for a new language
---------------------------------

Programming languages tend to share a similar set of common tasks like `test`,
`build`, `deps`. Commmon-make tries to handle this situation by setting a list
of rules and guidelines for adding support for a new language.

There are a set of global tasks defined in the `common.mk`, in particular:

- `deps`
- `lint`
- `test`
- `test-coverage`
- `build`

To add support for a new language, follow this pattern:

- Create the new file: `common-LANG.sh`
- Create a task specific and unique to this language: `test-LANG:`
- Add this task to the global test task: `test:: test-LANG`

The reason for this pattern is:

- It allows running specific test suites, eg: `test-go` to only test go files.
- It keeps the `help` output sane. Otherwise the last-read file would win and
  your users would see a help message like `test   Run all go tests` which may
  not be completely accurate if the project includes multiple common-LANG files.
- Supports running all of a project's tests and builds as the default case.

README.md updates
-----------------

When updating this README, run `make readme-toc` before committing to update
the table of contents.

Ensure your text wraps at 80 columns. Exceptions made for code and command line
examples as well as URLs.

Handy Make stuff
================

Introduction to make Slide deck
http://martinvseticka.eu/temp/make/presentation.htm

The make cheet sheet
https://github.com/mxenoph/cheat_sheets/blob/master/make_cheatsheet.pdf

The make Manual
https://www.gnu.org/software/make/manual/make.html
