#!/usr/bin/env bash

# a quick script to validate a deprecation contribution against a catalog
set -euo pipefail

# presumes and enforces execution from repo root
CWD=$(readlink -e .)
if [ $(basename "$CWD") != "deprecated-catalog-content" ]; then
    echo "This script must be run from the root of the repository (not $CWD)"
    exit 1
fi

CATALOG_NAME="registry.redhat.io/redhat/redhat-operator-index"
CATALOG_VERSION="4.15"
FBC_CAT_PREFIX="redhat-operator-index"
CATALOG_PULLSPEC="${CATALOG_NAME}:v${CATALOG_VERSION}"
FBC_DIR="${FBC_CAT_PREFIX}/${CATALOG_VERSION}"
CATALOG_PATH="${FBC_DIR}/${FBC_CAT_PREFIX}-v${CATALOG_VERSION}.yaml"

# grab the catalog (and ./opm if missing)
./scripts/grab_catalog.sh ${CATALOG_PULLSPEC} ${CATALOG_PATH}
set -x
./opm validate ${FBC_DIR}
set +x
