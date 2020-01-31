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
#   https://www.czeskis.com/random/openssl-encrypt-file.html

# Constants
PEM_DIR=~/.ssh
RECIPIENTS_DIR='recipients'
SECRETS_FILE='secret-files.txt'
ARCHIVE_FILE='archive'
TAR_DEBUG='--verbose'

# Parameters
COMMAND="${1:list}"
PUBLIC_PRIVATE_PAIR="${2}"

if [[ "${COMMAND?}" == 'generate' ]] ;
then

  echo 'TODO: Generate a compatible keypair' ;

elif [[ "${COMMAND?}" == 'list' ]] ;
then

  # List PEM files in the local key store
  find "${PEM_DIR?}" \
    -name "*.pem" \
    | while read -r PUBLIC_PRIVATE_PAIR_PEM_FILE ;
    do
      echo -n "[${PEM_DIR?}/] " \
      && basename "${PUBLIC_PRIVATE_PAIR_PEM_FILE?}" \
        | sed -e 's/.pem$//' ;
    done ;

elif [[ "${COMMAND?}" == 'add' ]] ;
then

  # Extract a public key from the key store and add this to the recipients list
  mkdir -p "${RECIPIENTS_DIR?}" \
  && RECIPIENT=$(basename "${PUBLIC_PRIVATE_PAIR?}" | sed -e 's/.pem$//') \
  && openssl rsa \
    -in "${PEM_DIR?}/${PUBLIC_PRIVATE_PAIR?}.pem" \
    -pubout \
    > "${RECIPIENTS_DIR?}/${PUBLIC_PRIVATE_PAIR?}.public" \
  ; ls -l "${RECIPIENTS_DIR?}" \
    | grep -v '^total' ;

elif [[ "${COMMAND?}" == 'remove' ]] ;
then

  # Remove a public key from the recipients list
  rm "${RECIPIENTS_DIR?}/${PUBLIC_PRIVATE_PAIR?}.public" \
  ; ls -l "${RECIPIENTS_DIR?}" \
    | grep -v '^total' ;

elif [[ "${COMMAND?}" == 'encrypt' ]] ;
then

  # Build an archive containing all the secret files,
  # then encrypt the secret archive for each registered recipient
  rm -f "${ARCHIVE_FILE?}.tar" \
  && while IFS='' read -r SECRET_FILE ;
    do
      tar -r "${TAR_DEBUG}" \
        --file "${ARCHIVE_FILE?}.tar" \
        "${SECRET_FILE?}" ;
    done < "${SECRETS_FILE?}" \
  && ls -l "${ARCHIVE_FILE?}.tar" \
  && rm -f "${ARCHIVE_FILE?}.enc.tar" \
  && find "${RECIPIENTS_DIR?}" \
    -name "*.public" \
    | while read -r PUBLIC_KEY_FILE ;
    do
      echo "Encrypting \"${ARCHIVE_FILE?}\" with public key \"${PUBLIC_KEY_FILE?}\"" ;
      RECIPIENT=$(basename "${PUBLIC_KEY_FILE?}" | sed -e 's/.public$//') \
      && rm -f "${RECIPIENT?}.key.bin" \
      && openssl rand -base64 32 > "${RECIPIENT?}.key.bin" \
      && rm -f "${RECIPIENT?}.key.bin.enc" \
      && openssl rsautl \
        -encrypt \
        -inkey "${PUBLIC_KEY_FILE?}" \
        -pubin \
        -in "${RECIPIENT?}.key.bin" \
        -out "${RECIPIENT?}.key.bin.enc" \
      ; rm -f "${RECIPIENT?}.key.bin" \
      && tar -r "${TAR_DEBUG}" \
        --file "${ARCHIVE_FILE?}.enc.tar" \
        "${RECIPIENT?}.key.bin.enc" \
      ; rm -f "${RECIPIENT?}.${ARCHIVE_FILE?}.tar.enc" \
      && openssl enc -aes-256-cbc \
        -salt \
        -in "${ARCHIVE_FILE?}.tar" \
        -out "${RECIPIENT?}.${ARCHIVE_FILE?}.tar.enc" \
        -pass "file:./${RECIPIENT?}.key.bin.enc" \
      ; rm -f "${RECIPIENT?}.key.bin.enc" \
      && tar -r "${TAR_DEBUG}" \
        --file "${ARCHIVE_FILE?}.enc.tar" \
        "${RECIPIENT?}.${ARCHIVE_FILE?}.tar.enc" \
      && rm "${RECIPIENT?}.${ARCHIVE_FILE?}.tar.enc" ;
    done \
  ; rm -f "${ARCHIVE_FILE?}.tar" \
  ; ls -l "${ARCHIVE_FILE?}.enc.tar" ;

elif [[ "${COMMAND?}" == 'decrypt' ]] ;
then
  
  # Extract for the recipients for which a keypair exists locally
  rm -f "${ARCHIVE_FILE?}.tar" \
  && tar -t --file "${ARCHIVE_FILE?}.enc.tar" \
    | grep 'key.bin.enc$' \
    | while read -r RECIPIENT_KEY_ENCRYPTED ;
    do
      RECIPIENT=$(basename "${RECIPIENT_KEY_ENCRYPTED?}" | sed -e 's/.key.bin.enc$//') \
      && RECIPIENT_ARCHIVE_FILE="${RECIPIENT?}.${ARCHIVE_FILE?}.tar.enc" \
      && PUBLIC_PRIVATE_PAIR_PEM_FILE="${PEM_DIR?}/${RECIPIENT?}.pem" \
      && if [[ -e "${PUBLIC_PRIVATE_PAIR_PEM_FILE?}" ]] ;
      then
        echo "Decrypting \"${RECIPIENT_ARCHIVE_FILE?}\" with public key \"${PUBLIC_PRIVATE_PAIR_PEM_FILE?}\"" ;
        tar -x "${TAR_DEBUG}" \
          --file "${ARCHIVE_FILE?}.enc.tar" "${RECIPIENT?}.key.bin.enc" \
        && tar -x "${TAR_DEBUG}" \
          --file "${ARCHIVE_FILE?}.enc.tar" "${RECIPIENT_ARCHIVE_FILE?}" \
        && openssl rsautl \
          -decrypt \
          -inkey "${PUBLIC_PRIVATE_PAIR_PEM_FILE?}" \
          -in "${RECIPIENT?}.key.bin.enc" \
          -out "${RECIPIENT?}.key.bin" \
        && rm -f "${RECIPIENT?}.key.bin.enc" \
        && openssl enc -aes-256-cbc \
          -d \
          -in "${RECIPIENT_ARCHIVE_FILE?}" \
          -out "${ARCHIVE_FILE?}.tar" \
          -pass "file:./${RECIPIENT?}.key.bin" \
        ; rm -f "${RECIPIENT?}.key.bin" \
        ; rm -f "${RECIPIENT_ARCHIVE_FILE?}" \
        && tar -x "${TAR_DEBUG}" \
          --file "${ARCHIVE_FILE?}.tar" \
        ; rm -f "${ARCHIVE_FILE?}.tar" ;
      else
        echo "Skipping \"${PUBLIC_PRIVATE_PAIR_PEM_FILE?}\" (no local key pair)" ;
      fi ;
    done ;

elif [[ "${COMMAND?}" == 'decrypt-to-env' ]] ;
then

  echo 'TODO: Decrypt files and consult in the current shell' ;

else

  echo 'Usage:' ;
  echo '  ./open-ssl-pk-enc.sh generate' ;
  echo '  ./open-ssl-pk-enc.sh list' ;
  echo '  ./open-ssl-pk-enc.sh add <.pem filename>' ;
  echo '  ./open-ssl-pk-enc.sh remove <.pem filename>' ;
  echo '  ./open-ssl-pk-enc.sh encrypt' ;
  echo '  ./open-ssl-pk-enc.sh decrypt' ;
  echo '  ./open-ssl-pk-enc.sh decrypt-to-env' ;

fi ;
