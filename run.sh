#!/bin/bash
#
# Loop forever, running ./backup.sh every $INTERVAL

set -eou pipefail

INTERVAL="${INTERVAL:-4h}"

gcloud auth activate-service-account "--key-file=$GOOGLE_APPLICATION_CREDENTIALS"

while true; do
    echo "Executing backup.sh @ $(date)"
    bash ./backup.sh

    echo "Sleeping for $INTERVAL"
    sleep "$INTERVAL"
done
