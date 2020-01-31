#!/usr/bin/env bash
# Purpose: Open SSL public private key encrption
# Usage:
#   Show usage:
#     ./open-ssl-pk-enc.sh 
#   Invoke command:
#     ./open-ssl-pk-enc.sh <command>
# See:
#   https://linux.die.net/man/1/rsautl
#   https://www.openssl.org/docs/man1.0.2/man1/openssl-enc.html
#   https://www.czeskis.com/random/openssl-encrypt-file.html
# TODO:
#   Generate a compatible keypair
#   Annotate keys which are installed as recipients
#   List keys which are installed as recipients annotating those which have a local private key
#   Decrypt files and consult in the current shell
#   Allow parameter override of KEY_DIR
#   Document usage in README
#   Document manual equivelant in README
#   Docker execution
#   Capture Macos (Brew) and Debian package manager dependencies
#   Test package dependencies
#   Test suite
#   Standard approach for parameter handling
#   Key structure diagram
#   Internally call list operations after an update

# Constants
KEY_DIR=~/.ssh
CIPHERNAME='aes-256-cbc'
RECIPIENTS_DIR='recipients'
SECRETS_FILE='secret-files.txt'
ARCHIVE_FILE='archive'
#TAR_DEBUG=' '
#ENC_DEBUG=' '
TAR_DEBUG='--verbose'
ENC_DEBUG='-v'

# Parameters
COMMAND="${1:list}"
PUBLIC_PRIVATE_PAIR="${2}"


if [[ "${COMMAND?}" == 'generate-keypair' ]] ;
then

  echo 'TODO: Generate a compatible keypair' ;

elif [[ "${COMMAND?}" == 'list-available-keypairs' ]] ;
then

  # List PEM files in the local key store
  find "${KEY_DIR?}" \
    -name "*.pem" \
    | while read -r PUBLIC_PRIVATE_PAIR_PEM_FILE ;
    do
      echo -n "[${KEY_DIR?}/] " \
      && basename "${PUBLIC_PRIVATE_PAIR_PEM_FILE?}" \
        | sed -e 's/.pem$/ (.pem format)/' ;
    done ;

  # List RSA files in the local key store
  find "${KEY_DIR?}" \
    -name "*.pub" \
    | while read -r PUBLIC_PRIVATE_PAIR_PEM_FILE ;
    do
      echo -n "[${KEY_DIR?}/] " \
      && basename "${PUBLIC_PRIVATE_PAIR_PEM_FILE?}" \
        | sed -e 's/.pub$/ (RSA format)/' ;
    done ;

  echo 'TODO: Annotate keys which are installed as recipients' ;

elif [[ "${COMMAND?}" == 'list-recipients' ]] ;
then

  # List public key files in the local key store
  find "${RECIPIENTS_DIR?}" \
    -name "*.public" \
    | while read -r PUBLIC_KEY_FILE ;
    do
      echo -n "[${RECIPIENTS_DIR?}/] " \
      && basename "${PUBLIC_KEY_FILE?}" ;
    done ;

  echo 'TODO: Annotate recipients have a private key available' ;

elif [[ "${COMMAND?}" == 'add-recipient' ]] ;
then

  # Resolve file names
  RECIPIENT=$(basename "${PUBLIC_PRIVATE_PAIR?}" | sed -e 's/.pem$//') ;
  PUBLIC_PRIVATE_PAIR_RSA_FILE="${KEY_DIR?}/${RECIPIENT?}.pem" ;
  PUBLIC_PRIVATE_PAIR_PEM_FILE="${KEY_DIR?}/${RECIPIENT?}.pem" ;

  # Generate a PEM if we need to and add to the local key store
  if [[ ! -e "${PUBLIC_PRIVATE_PAIR_PEM_FILE?}" && -e "${PUBLIC_PRIVATE_PAIR_RSA_FILE?}" ]] ;
  then
     echo "Found RSA \"PUBLIC_PRIVATE_PAIR_RSA_FILE\" generating a PEM and adding to \"${KEY_DIR?}\"" \
     && openssl rsa \
       -in "${PUBLIC_PRIVATE_PAIR_RSA_FILE?}" \
       -outform pem \
       > "${PUBLIC_PRIVATE_PAIR_PEM_FILE?}" \
     && chmod 600 "${PUBLIC_PRIVATE_PAIR_PEM_FILE?}" ;
  fi ;

  # Extract a public key from the key store and add this to the recipients list
  if [[ -e "${PUBLIC_PRIVATE_PAIR_PEM_FILE?}" ]] ;
  then
     echo "Found .pem \"PUBLIC_PRIVATE_PAIR_PEM_FILE\" extracting the public key and adding to \"${RECIPIENTS_DIR?}\"" \
     && mkdir -p "${RECIPIENTS_DIR?}" \
     && openssl rsa \
       -in "${PUBLIC_PRIVATE_PAIR_PEM_FILE?}" \
       -pubout \
       > "${RECIPIENTS_DIR?}/${PUBLIC_PRIVATE_PAIR?}.public" \
     ; ls -l "${RECIPIENTS_DIR?}" \
       | grep -v '^total' ;
  fi ;

elif [[ "${COMMAND?}" == 'remove-recipient' ]] ;
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
      tar -r ${TAR_DEBUG} \
        --file "${ARCHIVE_FILE?}.tar" \
        "${SECRET_FILE?}" ;
    done < "${SECRETS_FILE?}" \
  && ls -l "${ARCHIVE_FILE?}.tar" \
  && rm -f "${ARCHIVE_FILE?}.enc.tar" \
  && find "${RECIPIENTS_DIR?}" \
    -name "*.public" \
    | while read -r PUBLIC_KEY_FILE ;
    do
      echo "Encrypting \"${ARCHIVE_FILE?}.tar\" with public key \"${PUBLIC_KEY_FILE?}\"" ;
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
      && tar -r ${TAR_DEBUG} \
        --file "${ARCHIVE_FILE?}.enc.tar" \
        "${RECIPIENT?}.key.bin.enc" \
      ; rm -f "${RECIPIENT?}.key.bin.enc" \
      ; rm -f "${RECIPIENT?}.${ARCHIVE_FILE?}.tar.enc" \
      && openssl enc -${CIPHERNAME?} ${ENC_DEBUG} \
        -salt \
        -in "${ARCHIVE_FILE?}.tar" \
        -out "${RECIPIENT?}.${ARCHIVE_FILE?}.tar.enc" \
        -pass "file:./${RECIPIENT?}.key.bin" \
      ; rm -f "${RECIPIENT?}.key.bin" \
      && tar -r ${TAR_DEBUG} \
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
  && tar -t ${TAR_DEBUG} \
    --file "${ARCHIVE_FILE?}.enc.tar" \
    | grep 'key.bin.enc$' \
    | while read -r RECIPIENT_KEY_ENCRYPTED ;
    do
      RECIPIENT=$(basename "${RECIPIENT_KEY_ENCRYPTED?}" | sed -e 's/.key.bin.enc$//') \
      && RECIPIENT_ARCHIVE_FILE="${RECIPIENT?}.${ARCHIVE_FILE?}.tar.enc" \
      && PUBLIC_PRIVATE_PAIR_PEM_FILE="${KEY_DIR?}/${RECIPIENT?}.pem" \
      && if [[ -e "${PUBLIC_PRIVATE_PAIR_PEM_FILE?}" ]] ;
      then
        echo "Decrypting \"${RECIPIENT_ARCHIVE_FILE?}\" with public key \"${PUBLIC_PRIVATE_PAIR_PEM_FILE?}\"" ;
        tar -x ${TAR_DEBUG} \
          --file "${ARCHIVE_FILE?}.enc.tar" "${RECIPIENT?}.key.bin.enc" \
        && tar -x ${TAR_DEBUG} \
          --file "${ARCHIVE_FILE?}.enc.tar" "${RECIPIENT_ARCHIVE_FILE?}" \
        && openssl rsautl \
          -decrypt \
          -inkey "${PUBLIC_PRIVATE_PAIR_PEM_FILE?}" \
          -in "${RECIPIENT?}.key.bin.enc" \
          -out "${RECIPIENT?}.key.bin" \
        && rm -f "${RECIPIENT?}.key.bin.enc" \
        && openssl enc -${CIPHERNAME?} ${ENC_DEBUG} \
          -d \
          -in "${RECIPIENT_ARCHIVE_FILE?}" \
          -out "${ARCHIVE_FILE?}.tar" \
          -pass "file:./${RECIPIENT?}.key.bin" \
        ; rm -f "${RECIPIENT?}.key.bin" \
        ; rm -f "${RECIPIENT_ARCHIVE_FILE?}" \
        && tar -x ${TAR_DEBUG} \
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
  echo '  ./open-ssl-pk-enc.sh generate-keypair' ;
  echo '  ./open-ssl-pk-enc.sh list-available-keypairs' ;
  echo '  ./open-ssl-pk-enc.sh list-recipients' ;
  echo '  ./open-ssl-pk-enc.sh add-recipient <.pem filename>' ;
  echo '  ./open-ssl-pk-enc.sh remove-recipient <.pem filename>' ;
  echo '  ./open-ssl-pk-enc.sh encrypt' ;
  echo '  ./open-ssl-pk-enc.sh decrypt' ;
  echo '  ./open-ssl-pk-enc.sh decrypt-to-env' ;

fi ;
