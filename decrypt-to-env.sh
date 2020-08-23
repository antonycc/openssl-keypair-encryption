#!/usr/bin/env bash
# Purpose: Decrypt using one of the key pairs in the local key chain to the environment. 
# Note: This needs to run using a "."" operator or "source"
# Usage: decrypt-to-env.sh <clear file>
# e.g. . ./gpg-scripts/decrypt-to-env.sh credentials.txt

# Parameters
FILE_CLEAR=${1?}

# Constants
SCRIPTS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
OPTIONS_FILE="${SCRIPTS_DIR?}/gpg-options.conf"
TMP_FILE="./tmp_${RANDOM?}"

CMD="echo "${PGP_PRIVATE_KEY_PASSPHRASE}" | gpg --batch --yes --passphrase-fd 0 --options \"${OPTIONS_FILE?}\" --output \"${TMP_FILE?}\" --decrypt \"${FILE_CLEAR?}.gpg\""
echo $CMD
eval $CMD
source "${TMP_FILE?}"
rm "${TMP_FILE?}"
