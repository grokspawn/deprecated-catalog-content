#!/usr/bin/env bash
#
set -euo pipefail

if [ $# -lt 2 ]; then
    echo "usage: $0 catalog destination [opm-version] [format]"
    exit 255
fi

CATALOG=$1
DESTINATION=$2
OPM_VERSION=${3:-latest}
FORMAT=${4:-yaml}

DEST_DIR_PART=$(dirname ${DESTINATION})
DEST_FILE_PART=$(basename ${DESTINATION})

OS=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m | sed 's/x86_64/amd64/')

if [[ -z "${FORMAT}"  ]]; then
    FORMAT="yaml"
fi

function version {
    echo "$@" | awk -F. '{ printf("%d%03d%03d%03d\n", $1,$2,$3,$4); }'; 
}

if [[ "${OPM_VERSION}" == "latest" ]]; then
	OPM_VERSION=$(curl -sL https://api.github.com/repos/operator-framework/operator-registry/releases/latest | jq -r '.tag_name')
fi

# compare the opm version to see if we can pull a late enough version to use the migrate option
# which results in a much smaller catalog file
# pull the leading 'v' off so we can do numerical comparison
COMPARE_VER=$(echo ${OPM_VERSION} | sed -e 's/^v//')
OPM_OPTS=
echo "comparing versions: " $(version ${COMPARE_VER}) -ge $(version "1.28.0")
if [[ $(version ${COMPARE_VER}) -ge $(version "1.28.0") ]]; then
    OPM_OPTS="--migrate"
fi

if [ ! -e ./opm ]; then
    set -x 
    curl -sLO "https://github.com/operator-framework/operator-registry/releases/download/${OPM_VERSION}/${OS}-${ARCH}-opm" && chmod +x "${OS}-${ARCH}-opm" && mv "${OS}-${ARCH}-opm" "./opm"
    set +x
fi


if [ ! -e ${DESTINATION} ]; then 
    mkdir -p ${DEST_DIR_PART}
fi

if [ $(find ${DEST_DIR_PART} -mtime -1 -type f -name ${DEST_FILE_PART} 2>/dev/null) ]; then
    echo "cached catalog is fresh (${DESTINATION})"
else
    ./opm render ${OPM_OPTS} ${CATALOG} -o ${FORMAT} > ${DESTINATION}
fi


