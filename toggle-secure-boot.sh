#!/bin/bash
set -euo pipefail

fatalError() {
        echo -e "$0: \e[41m$@\e[0m"
        exit 1
}

LOCAL_DIR=$(readlink -f $(dirname ${BASH_SOURCE[0]}))
cd $LOCAL_DIR

if [ -f local.config ] ; then
        . ./local.config
fi

if [ -z "${FIRMWARE_ENROLLED_KEYS_DIR:-}" ]; then
        fatalError "FIRMWARE_ENROLLED_KEYS_DIR must be set (dir containing PK.cer, KEK.cer, db.cer etc.)"
fi

ORIG_VARS="${1:-OVMF-local/OVMF_VARS.fd}"

if [ ! -f "$ORIG_VARS" ]; then
        fatalError "original vars file not found: $ORIG_VARS"
fi

command -v virt-fw-vars >/dev/null 2>&1 || { echo "virt-fw-vars not found"; exit 1; }
command -v virt-fw-dump >/dev/null 2>&1 || { echo "virt-fw-dump not found"; exit 1; }

if virt-fw-dump -i $ORIG_VARS | grep -A1 SecureBootEnable | grep ON ; then
	echo -e "Secure boot enabled. \e[31mDisabling it\e[0m"
	virt-fw-vars --set-false SecureBootEnable --inplace $ORIG_VARS
else
	echo -e "Secure boot disabled. \e[32mEnabling it\e[0m"
	virt-fw-vars --set-true SecureBootEnable --inplace $ORIG_VARS
fi

