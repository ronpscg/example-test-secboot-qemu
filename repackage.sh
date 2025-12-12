#!/bin/bash
LOCAL_DIR=$(readlink -f $(dirname ${BASH_SOURCE[0]}))
cd $LOCAL_DIR
: ${SRC_DIR=~/secboot-ovmf-x86_64}
if [ -f local.config ] ; then
	. ./local.config
fi

: ${MACHINE=""}
: ${IMAGE_BASENAME=""}
: ${YOCTO_BUILD_DIR=""}
export YOCTO_BUILD_DIR
export MACHINE
export IMAGE_BASENAME

${SRC_DIR}/scripts/yocto/yocto-copy-artifacts.sh
