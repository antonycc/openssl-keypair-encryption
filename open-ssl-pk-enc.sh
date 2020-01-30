#!/usr/bin/env bash
# Purpose: Open SSL public private key encrption
# Usage:
#   Show usage:
#     ./open-ssl-pk-enc.sh 
#   Invoke command:
#     ./open-ssl-pk-enc.sh <command>
# See:
#   https://unix.stackexchange.com/questions/296697/how-to-encrypt-a-file-with-private-key
#   https://cheapsslsecurity.com/blog/various-types-ssl-commands-keytool/
#   https://linux.die.net/man/1/rsautl

# Constants
PEM_DIR=~/.ssh
PEM_EXT='*.pem'
RECIPIENTS_LOCAL_DIR='recipients'
SECRETS_FILE='secret-files.txt'
CLEAR_ARCHIVE_FILE='clear-archive.tmp'

# Parameters
COMMAND="${1:list}"
PUBLIC_PRIVATE_PAIR_PEM="${2}"

if [[ "${COMMAND?}" == "nop" ]] ;
then

  echo 'NOP'

elif [[ "${COMMAND?}" == 'list' ]] ;
then

  # List files in the local key store
  find "${PEM_DIR?}" -name "${PEM_EXT?}"

elif [[ "${COMMAND?}" == 'add' ]] ;
then

  # Extract a public key from the key store and add this to the recipients list
  mkdir -p "${RECIPIENTS_LOCAL_DIR?}"
  openssl rsa i\
    -in "${PUBLIC_PRIVATE_PAIR_PEM?}" \
    -pubout \
    > "${RECIPIENTS_LOCAL_DIR?}/${PUBLIC_PRIVATE_PAIR_PEM?}.public"

elif [[ "${COMMAND?}" == 'remove' ]] ;
then

  # Remove a public key from the recipients list
  rm -f "${RECIPIENTS_LOCAL_DIR?}/${PUBLIC_PRIVATE_PAIR_PEM?}.public"

elif [[ "${COMMAND?}" == 'encrypt' ]] ;
then

  # Build an archive containing all the secret files
  cat "${SECRETS_FILE?}" \
    | while read SECRET_FILE \
      ; do \
        ; tar -r --file "${CLEAR_ARCHIVE_FILE?}" --verbose "${SECRET_FILE?}" \
      ; done

  # Encrypt the secret archive for each registered recipient
  For each recipient
    openssl rsautl \
      -encrypt \
      -inkey "${PUBLIC_PRIVATE_PAIR_PEM?}.public" \
      -pubin \
      -in "${CLEAR_ARCHIVE_FILE?}" i
      -out "${ENCRYPTED_ARCHIVE_FILE?}.${PUBLIC_PRIVATE_PAIR_PEM?}.enc"
    tar -r --file "${ENCRYPTED_ARCHIVE_FILE?}" --verbose "${ENCRYPTED_ARCHIVE_FILE?}.${PUBLIC_PRIVATE_PAIR_PEM?}.enc" \

elif [[ "${COMMAND?}" == 'decrypt' ]] ;
then
  
  # Extract the secret archive
  tar -x --file "${CLEAR_ARCHIVE_FILE?}.enc.tar"

  # If there is named keypair select the first one that matches a local kaypair 
  if [[ "${PUBLIC_PRIVATE_PAIR_PEM}" == "" ]] ;
  then
    PUBLIC_PRIVATE_PAIR_PEM='antony-pikselmbp-projects.pem'
  fi

  # Decrypt the files using a local keypair
  openssl rsautl \
    -decrypt \
    -inkey "${PUBLIC_PRIVATE_PAIR_PEM?}" \
    -in "${CLEAR_FILE?}.${PUBLIC_PRIVATE_PAIR_PEM?}.enc" 
    -out "${CLEAR_FILE?}"
  rm -f "${CLEAR_FILE?}.${PUBLIC_PRIVATE_PAIR_PEM?}.enc"
  tar -x --file "${CLEAR_ARCHIVE_FILE?}"
  rm -f "${CLEAR_ARCHIVE_FILE?}"

else

  echo 'Usage:'
  echo '  ./open-ssl-pk-enc.sh list'
  echo '  ./open-ssl-pk-enc.sh add <.pem filename>'
  echo '  ./open-ssl-pk-enc.sh remove <.pem filename>'
  echo '  ./open-ssl-pk-enc.sh encrypt'
  echo '  ./open-ssl-pk-enc.sh encrypt <.pem filename>'
  echo '  ./open-ssl-pk-enc.sh decrypt'
  echo '  ./open-ssl-pk-enc.sh decrypt <.pem filename>'

fi

