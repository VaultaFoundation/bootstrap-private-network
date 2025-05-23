#!/usr/bin/env bash

####
# Builds savanna compatible contracts that installed into spring/nodeos
# does not install software
# called from Docker Build
###

EOS_CONTRACTS_GIT_COMMIT_TAG=${1:-v3.8.0}
VAULTA_CONTRACTS_GIT_COMMIT_TAG=${2:-main}
let NPROC=$(nproc)/6
TUID=$(id -ur)

# must not be root to run
if [ "$TUID" -eq 0 ]; then
  echo "Can not run as root user exiting"
  exit
fi

ROOT_DIR=/local/VaultaFoundation
SPRING_BUILD_DIR="${ROOT_DIR}"/spring_build
CDT_BUILD_DIR="${ROOT_DIR}"/repos/cdt/build
SPRING_CONTRACT_DIR="${ROOT_DIR}"/repos/system-contracts
LOG_DIR=/bigata1/log

# eos system contracts
cd "${SPRING_CONTRACT_DIR:?}" || exit
git checkout $EOS_CONTRACTS_GIT_COMMIT_TAG
git pull origin $EOS_CONTRACTS_GIT_COMMIT_TAG
mkdir build
cd build || exit
cmake -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTS=ON -Dspring_DIR="${SPRING_BUILD_DIR}/lib/cmake/spring" .. >> "${LOG_DIR}"/reference_contracts_build.log 2>&1
make -j ${NPROC} >> "${LOG_DIR}"/system_contracts_build.log 2>&1

# time
TIME_CONTRACT_DIR="${ROOT_DIR}"/repos/eosio.time
cd "${TIME_CONTRACT_DIR:?}" || exit
cdt-cpp eosio.time.cpp

# now vaulta
VAULTA_BUILD_DIR="${ROOT_DIR}"/vaulta_build
VAULTA_CONTRACT_DIR="${ROOT_DIR}"/repos/vaulta-system-contract
cd "${VAULTA_CONTRACT_DIR:?}" || exit
git checkout $VAULTA_CONTRACTS_GIT_COMMIT_TAG
git pull origin $VAULTA_CONTRACTS_GIT_COMMIT_TAG
mkdir build
cd build || exit
cmake -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTS=ON -Dcdt_DIR="${CDT_BUILD_DIR}/lib/cmake/cdt" -Dspring_DIR="${SPRING_BUILD_DIR}/lib/cmake/spring" .. >> "${LOG_DIR}"/reference_contracts_build.log 2>&1
make -j ${NPROC} >> "${LOG_DIR}"/vaulta_contracts_build.log 2>&1