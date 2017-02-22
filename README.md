kube-backup
===========

A utility to backup Kubernetes cluster's resources to a GCS storage bucket in
a GPG-encrypted tarball. GPG keys are fetched from keybase.io.

<!-- toc -->

- [Usage](#usage)
  * [Configuration](#configuration)
  * [Auth / Credentials](#auth--credentials)
    + [Google Service Account (gcloud/gsutil)](#google-service-account-gcloudgsutil)
    + [Kubernetes Authentiation (Kubectl)](#kubernetes-authentiation-kubectl)
- [Deployment](#deployment)
- [Limitations](#limitations)
- [Development & Testing](#development--testing)

<!-- tocstop -->

Usage
-----

### Configuration

Configuration is handled through environment variables:

- `KEYBASE_USERS`: A space-separated list of keybase.io users whose GPG
  keys will be used to encrypt the backup.
- `INTERVAL`: Used by the run.sh wrapper when running as a Kubernetes pod. This
  setting defines how often the backup.sh script is executed. Default is 4h.
- `GCS_BUCKET_PATH`: Google Cloud Storage path to store backups under, eg:
  `gs://pantheon-internal-kube-backups/cluster-01/`
- `GOOGLE_APPLICATION_CREDENTIALS`: Path to a JSON file containing a service
  account that has access to upload objects to `GCS_BUCKET_PATH`. Optional. See
  below for details.

### Auth / Credentials

#### Google Service Account (gcloud/gsutil)

The script uses `gsutil` from the Google Cloud SDK to upload encrypted tarballs
to GCS. Authentication for the SDK is defined
by [Google Application Default Credentials](https://developers.google.com/identity/protocols/application-default-credentials)

In many cases you may not need to do anything to configure authentication for
GCS since it may already be available in your local workstation environment
or if running on a Google Compute VM (including GKE cluster) whose built-in
service account has read/write access to GCS.

Alternatively, you can explicitly set a service-account to use by setting the
`$GOOGLE_APPLICATION_CREDENTIALS` environment var to a JSON file. The service-account
needs the *Storage Object Creator* role.

#### Kubernetes Authentiation (Kubectl)

It is assumed that kubectl is installed and configured to access the cluster
you want to backup. This is usually the case when run locally from your
workstation or if run from within the kube-system namespace and the pod has
access to the default token.

Deployment
----------

TODO

Limitations
-----------

The list of resource types to be backed up is currently hard-coded. If a new
resource type is added by a newer version of Kubernetes or if you have
ThirdPartyResources defined you will need to modify the `ns_objects=` array in
backup.sh for namespaced objectds and `cluster_objects=` for cluster-level
objects.

Development & Testing
---------------------

It's just a few simple shell scripts. All code should pass shellcheck linting
(`make test` or `make test-shell`) and follow the
[Google Shell Style Guide](https://google.github.io/styleguide/shell.xml).

`make build-docker` will build the docker container. `make push` will push
it to quay.io.

A few methods are available for testing against a real cluster:

- *Local*: Assuming have you `gcloud` and `kubectl` installed and authentication
  is configured, you can run the backup.sh script directly.
```
./backup.sh
```

- *Interactive pod within a Kubernetes Cluster*:
```
make build-docker push
kubectl run joe-test --image=quay.io/getpantheon/kube-backup:dev --restart=Never --image-pull-policy=Always -it --command -- /bin/bash

root@kube-backup-test# ./backup.sh
# or exec ./run.sh if you want to test the wrapper

# cleanup the pod when done:
kubectl delete pod kube-backup-test
```
