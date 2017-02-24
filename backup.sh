#!/bin/bash
#
# A utility to backup a kubernetes cluster's resources to a GCS storage bucket in a
# GPG-encrypted tarball. GPG keys are fetched from keybase.io.
#
# Resources are downloaded in YAML format using 'kubectl'. The currently configured
# cluster will be used, so make sure to set the cluster context to the desired
# cluster before executing.
#
# Usage:
#
#   $ KEYBASE_USERS="joemiller spheromak" \
#     GCS_BUCKET_PATH="gs://pantheon-internal-kube-backups/cluster-01/" \
#     ./backup.sh
#
# Decrypting a tarball:
#
#   $ gpg -d < 20170219-1750.tar.gz.gpg | tar xzvf -
#

set -euo pipefail

# Space-separate list of keybase.io users to GPG-encrypt the backup tarball against.
KEYBASE_USERS="${KEYBASE_USERS:-joemiller spheromak}"

# GCS bucket to store backups
GCS_BUCKET_PATH="${GCS_BUCKET:-gs://pantheon-internal-kube-backups/}"

# max number of kubectl-get processes to run at once
THREADS=${THREADS:-12}

# path to gpg binary
GPG_BIN="${GPG_BIN:-gpg}"

date=$(date -u +%Y%m%d-%H%M)   # ex: 20170101-0101, -u sets UTC
backup_dir="./$date"
ns_objects=(
    configmaps\
    daemonsets\
    deployments\
    horizontalpodautoscalers\
    ingresses\
    jobs\
    limitranges\
    networkpolicies\
    persistentvolumeclaims\
    pods\
    podtemplates\
    replicasets\
    replicationcontrollers\
    resourcequotas\
    secrets\
    serviceaccounts\
    services\
    statefulsets\
    )

cluster_objects=(
    persistentvolumes\
    storageclasses\
    thirdpartyresources\
    )

# setup a global "spaces" variable that lists every namesapce
spaces=$(kubectl get namespaces --no-headers -o custom-columns=NAME:.metadata.name)

init_tmpdir() {
    TMPDIR=$(mktemp -d kube-backup.XXXXXX)
    echo "Using tempdir for YAML file downloads: $TMPDIR"
}

init_gpg() {
    GPG_TMP_DIR=$(mktemp -d gnupg.XXXXXXXX)
    # import keybase users' pub keys
    for username in $KEYBASE_USERS; do
        curl -s -L "https://keybase.io/${username}/pgp_keys.asc" \
           | $GPG_BIN --homedir "$GPG_TMP_DIR" --batch --import
    done
    echo "Initialized temporary GPG keychain directory: $GPG_TMP_DIR"
}

# cleanup tmp dirs on exit
init_cleanup_handler() {
    trap 'rm -rf -- "$TMPDIR" "$GPG_TMP_DIR"' EXIT
}

backup_cluster_objects() {
    for i in "${cluster_objects[@]}" ; do
        mkdir -p "${TMPDIR}/${backup_dir}"
        kubectl get "$i" -oyaml > "${TMPDIR}/${backup_dir}/${i}.yaml" 2> /dev/null
    done
}

backup_namespaces() {
    local nproc=0
    while read -r ns; do
        echo "Backing up $ns"
        local ns_dir="${TMPDIR}/${backup_dir}/${ns}"
        mkdir -p "$ns_dir"
        kubectl get namespace "$ns" -oyaml > "$ns_dir/namespace.yaml"

        for resource_type in "${ns_objects[@]}" ; do
            echo "  $resource_type"
            for obj in $(kubectl get "$resource_type" --namespace="$ns" --no-headers -o custom-columns=NAME:.metadata.name 2>/dev/null); do
                echo "    $obj"
                local resource_dir="${ns_dir}/${resource_type}"
                mkdir -p "$resource_dir"

                kubectl get "$resource_type" "$obj" --namespace="$ns" -oyaml >"${resource_dir}/${obj}.yaml" 2>/dev/null &
                nproc=$((nproc + 1))
                if [[ "$nproc" -ge "$THREADS" ]]; then
                    # echo "max $nproc threads running. Pausing to wait for completion."
                    wait
                    nproc=0
                fi
            done
        done
    done<<< "$spaces"
}

#######################################
# a wrapper around 'gpg --encrypt' that will encrypt data from STDIN against all pubkeys
# in the keychain in $GPG_TMP_DIR. Encrypted data will be sent to STDOUT
# example:
#   cat filename | gpg_encrypt_to_all >filename.gpg
# Globals:
#   GPG_BIN
#   GPG_TMP_DIR
# Arguments:
#   None
# Returns:
#   None
#######################################
gpg_encrypt_to_all() {
    local recipient_list
    recipient_list=$($GPG_BIN --homedir "$GPG_TMP_DIR" --batch --list-keys --with-colons --fast-list-mode \
        | awk -F: '/^pub/{printf "--recipient %s ", $5}')
    # shellcheck disable=SC2086
    $GPG_BIN --homedir "$GPG_TMP_DIR" $recipient_list --trust-model always --batch --encrypt
}

create_tarball() {
    TARBALL="${backup_dir}.tar.gz.gpg"
    echo "Creating GPG encrypted tarball: $TARBALL"
    #tar -C "$TMPDIR" -czf "$tarball" "$backup_dir"
    tar -C "$TMPDIR" -czf - "$backup_dir" | gpg_encrypt_to_all > "$TARBALL"
}

upload_tarball() {
    echo "Uploading $TARBALL to ${GCS_BUCKET_PATH}$(basename "$TARBALL")"
    gsutil cp "$TARBALL" "$GCS_BUCKET_PATH"
}

main() {
    init_gpg
    init_tmpdir
    init_cleanup_handler

    backup_cluster_objects
    backup_namespaces
    create_tarball
    upload_tarball
}

main "$@"
