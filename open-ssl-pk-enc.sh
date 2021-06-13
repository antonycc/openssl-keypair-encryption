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
#   https://rietta.com/blog/openssl-generating-rsa-key-from-command/
# TODO:
#   Decrypt files and consult in the current shell
#   Is there a standard way to locate the local .PEMs?
#   Allow parameter override of key_dir
#   Standard approach for parameter handling
#   Document manual equivalent in README
#   Docker execution
#   Capture Macos (Brew) and Debian package manager dependencies
#   Test package dependencies
#   Test suite
#   Key structure diagram
#   Adopt Google Coding standards: https://google.github.io/styleguide/shell.xml

# Constants
readonly key_dir=~/.ssh
readonly cipher_name='aes-256-cbc'
readonly rsa_key_size='2048'
readonly rsa_key_algo='des3'
readonly recipients_dir='recipients'
readonly secrets_file='secret-files.txt'
readonly archive_file='archive'
#readonly tar_debug=' '
#readonly enc_debug=' '
readonly tar_debug='--verbose'
readonly enc_debug='-v'

# Parameters
readonly command="${1:list}"
readonly public_private_pair="${2}"

if [[ "${command?}" == 'generate-keypair' ]] ;
then

  openssl genrsa -${rsa_key_algo?} \
    -out "${public_private_pair?}.pem" \
    ${rsa_key_size?} \
  && mv "${public_private_pair?}.pem" "${key_dir?}/." \
  && chmod 600 "${key_dir?}/${public_private_pair?}.pem" \
  ; ls -l "${key_dir?}/${public_private_pair?}.pem"

elif [[ "${command?}" == 'list-available-keypairs' ]] ;
then

  # List PEM files in the local key store
  find "${key_dir?}" \
    -name "*.pem" \
    | while read -r public_private_pair_pem_file ;
    do
      echo -n "[${key_dir?}/] " ;
      public_private_pair="${public_private_pair_pem_file//.pem/}" ;
      public_key_file="${recipients_dir?}/$(basename "${public_private_pair?}".public)" ;
      if [[ -e "${public_key_file}" ]] ;
      then
        echo "$public_private_pair_pem_file?} (.pem format, installed to ${recipients_dir?})" ;
      else
        echo "${public_private_pair_pem_file?} (.pem format)" ;
      fi ;
    done ;

  # List RSA files in the local key store
  find "${key_dir?}" \
    -name "*.pub" \
    | while read -r public_private_pair_pem_file ;
    do
      echo -n "[${key_dir?}/] " ;
      public_private_pair="${public_private_pair_pem_file//.pub/}" ;
      public_key_file="${recipients_dir?}/$(basename "${public_private_pair?}".public)" ;
      if [[ -e "${public_key_file}" ]] ;
      then
        echo "${public_private_pair?} (RSA format, installed to ${recipients_dir?})" ;
      else
        echo "${public_private_pair?} (RSA format)" ;
      fi ;
    done ;

elif [[ "${command?}" == 'list-recipients' ]] ;
then

  # List public key files in the local key store
  find "${recipients_dir?}" \
    -name "*.public" \
    | while read -r public_key_file ;
    do
      echo -n "[${recipients_dir?}/] " ;
      recipient=$(basename "${public_key_file?}" | sed -e 's/.public$//') ;
      public_private_pair_pem_file="${key_dir?}/${recipient?}.pem" ;
      public_private_pair_rsa_file="${key_dir?}/${recipient?}" ;
      if [[ -e "${public_private_pair_pem_file}" ]] ;
      then
        echo "${recipient?} (PEM is available locally in ${key_dir?})" ;
      elif [[ -e "${public_private_pair_rsa_file}" ]] ;
      then
        echo "${recipient?} (RSA is available locally in ${key_dir?})" ;
      else
        echo "${recipient?}" ;
      fi ;
    done ;

elif [[ "${command?}" == 'add-recipient' ]] ;
then

  # Resolve file names
  recipient=$(basename "${public_private_pair?}" | sed -e 's/.pem$//') ;
  public_private_pair_rsa_file="${key_dir?}/${recipient?}.pem" ;
  public_private_pair_pem_file="${key_dir?}/${recipient?}.pem" ;

  # Generate a PEM if we need to and add to the local key store
  if [[ ! -e "${public_private_pair_pem_file?}" && -e "${public_private_pair_rsa_file?}" ]] ;
  then
     echo "Found RSA \"${public_private_pair_rsa_file?}\" generating a PEM and adding to \"${key_dir?}\"" \
     && openssl rsa \
       -in "${public_private_pair_rsa_file?}" \
       -outform pem \
       > "${public_private_pair_pem_file?}" \
     && chmod 600 "${public_private_pair_pem_file?}" ;
  fi ;

  # Extract a public key from the key store and add this to the recipients list
  if [[ -e "${public_private_pair_pem_file?}" ]] ;
  then
    echo "Found .pem \"${public_private_pair_pem_file?}\" extracting the public key and adding to \"${recipients_dir?}\"" \
    && mkdir -p "${recipients_dir?}" \
    && openssl rsa \
      -in "${public_private_pair_pem_file?}" \
      -pubout \
      > "${recipients_dir?}/${recipient?}.public" \
    ; "./${0}" list-recipients

  fi ;

elif [[ "${command?}" == 'remove-recipient' ]] ;
then

  # Remove a public key from the recipients list
  rm "${recipients_dir?}/${public_private_pair?}.public" \
  ; "./${0}" list-recipients

elif [[ "${command?}" == 'encrypt' ]] ;
then

  # Build an archive containing all the secret files,
  # then encrypt the secret archive for each registered recipient
  rm -f "${archive_file?}.tar" \
  && while IFS='' read -r secret_file ;
    do
      tar -r ${tar_debug} \
        --file "${archive_file?}.tar" \
        "${secret_file?}" ;
    done < "${secrets_file?}" \
  && ls -l "${archive_file?}.tar" \
  && rm -f "${archive_file?}.enc.tar" \
  && find "${recipients_dir?}" \
    -name "*.public" \
    | while read -r public_key_file ;
    do
      echo "Encrypting \"${archive_file?}.tar\" with public key \"${public_key_file?}\"" ;
      recipient=$(basename "${public_key_file?}" | sed -e 's/.public$//') \
      && rm -f "${recipient?}.key.bin" \
      && openssl rand -base64 32 > "${recipient?}.key.bin" \
      && rm -f "${recipient?}.key.bin.enc" \
      && openssl rsautl \
        -encrypt \
        -inkey "${public_key_file?}" \
        -pubin \
        -in "${recipient?}.key.bin" \
        -out "${recipient?}.key.bin.enc" \
      && tar -r ${tar_debug} \
        --file "${archive_file?}.enc.tar" \
        "${recipient?}.key.bin.enc" \
      ; rm -f "${recipient?}.key.bin.enc" \
      ; rm -f "${recipient?}.${archive_file?}.tar.enc" \
      && openssl enc -${cipher_name?} ${enc_debug} \
        -salt \
        -in "${archive_file?}.tar" \
        -out "${recipient?}.${archive_file?}.tar.enc" \
        -pass "file:./${recipient?}.key.bin" \
      ; rm -f "${recipient?}.key.bin" \
      && tar -r ${tar_debug} \
        --file "${archive_file?}.enc.tar" \
        "${recipient?}.${archive_file?}.tar.enc" \
      && rm "${recipient?}.${archive_file?}.tar.enc" ;
    done \
  ; rm -f "${archive_file?}.tar" \
  ; ls -l "${archive_file?}.enc.tar" ;

elif [[ "${command?}" == 'decrypt' ]] ;
then

  # Extract for the recipients for which a keypair exists locally
  rm -f "${archive_file?}.tar" \
  && tar -t \
    --file "${archive_file?}.enc.tar" \
    | grep 'key.bin.enc$' \
    | while read -r recipient_key_encrypted ;
    do
      echo "recipient_key_encrypted = \"${recipient_key_encrypted?}\""
      recipient=$(basename "${recipient_key_encrypted?}" | sed -e 's/.key.bin.enc$//') \
      && public_private_pair_pem_file="${key_dir?}/${recipient?}.pem" \
      && if [[ -e "${public_private_pair_pem_file?}" ]] ;
      then
        echo "Decrypting \"${recipient?}.${archive_file?}.tar.enc\" with public key \"${public_private_pair_pem_file?}\"" ;
        tar -x ${tar_debug} \
          --file "${archive_file?}.enc.tar" "${recipient?}.key.bin.enc" \
        && tar -x ${tar_debug} \
          --file "${archive_file?}.enc.tar" "${recipient?}.${archive_file?}.tar.enc" \
        && openssl rsautl \
          -decrypt \
          -inkey "${public_private_pair_pem_file?}" \
          -in "${recipient?}.key.bin.enc" \
          -out "${recipient?}.key.bin" \
        && rm -f "${recipient?}.key.bin.enc" \
        && openssl enc -${cipher_name?} ${enc_debug} \
          -d \
          -in "${recipient?}.${archive_file?}.tar.enc" \
          -out "${archive_file?}.tar" \
          -pass "file:./${recipient?}.key.bin" \
        ; rm -f "${recipient?}.key.bin" \
        ; rm -f "${recipient?}.${archive_file?}.tar.enc" \
        && tar -x ${tar_debug} \
          --file "${archive_file?}.tar" \
        ; rm -f "${archive_file?}.tar" ;
      else
        echo "Skipping \"${public_private_pair_pem_file?}\" (no local key pair)" ;
      fi ;
    done ;

elif [[ "${command?}" == 'decrypt-to-env' ]] ;
then

  echo 'TODO: Decrypt files and consult in the current shell' ;

else

  echo 'Usage:' ;
  echo '  ./open-ssl-pk-enc.sh generate-keypair <keypair name>' ;
  echo '  ./open-ssl-pk-enc.sh list-available-keypairs' ;
  echo '  ./open-ssl-pk-enc.sh list-recipients' ;
  echo '  ./open-ssl-pk-enc.sh add-recipient <.pem filename>' ;
  echo '  ./open-ssl-pk-enc.sh remove-recipient <.pem filename>' ;
  echo '  ./open-ssl-pk-enc.sh encrypt' ;
  echo '  ./open-ssl-pk-enc.sh decrypt' ;
  echo '  ./open-ssl-pk-enc.sh decrypt-to-env' ;

fi ;
