#!/bin/bash
LOCAL_DIR=$(readlink -f $(dirname ${BASH_SOURCE[0]}))
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

if [ $# -lt 1 ] ; then 
	if [ -f /.dockerenv ] ; then
		ARGS="disk -nographic"
	else
		ARGS="disk --serial mon:stdio"
	fi
else
	ARGS="$@"
fi

${LOCAL_DIR}/scripts/yocto/tests/qemu-tpm-bitbake.sh  "$ARGS"
