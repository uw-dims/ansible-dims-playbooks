#!/bin/bash

EMAIL=$1
NAME=$2

which git
RESULT=$?

if [ ${RESULT} != 0 ]; then
  echo "[-] Git is not installed."
  exit 1
fi

if [ "x${EMAIL}" -eq "x" ]; then
  echo "[-] Empty email string."
  exit 1
fi

git config --global user.email "${EMAIL}"
RESULT=$?

if [ ${RESULT} != 0 ]; then
  echo "[-] Failed to set git config for email ${EMAIL}."
  exit 1
fi

if [ "x${NAME}" -eq "x" ]; then
  echo "[-] Empty name string."
fi

git config --global user.name "${NAME}"
RESULT=$?

if [ ${RESULT} != 0 ]; then
  echo "[-] Failed to set git config for name ${NAME}."
  exit 1
fi

exit 0
