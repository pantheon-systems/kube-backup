#!/bin/bash
# Loop forever, running /app/backup.sh every $INTERVAL

set -eo pipefail

INTERVAL="${INTERVAL:-4h}"

# NOTE this only works with JSON files, not p12
if [[ -n "$GOOGLE_APPLICATION_CREDENTIALS" ]]; then
    gcloud auth activate-service-account "--key-file=$GOOGLE_APPLICATION_CREDENTIALS"
fi

while true; do
    echo "Executing backup.sh @ $(date)"

    bash /app/backup.sh

    echo "Sleeping for $INTERVAL"
    sleep "$INTERVAL"
done
