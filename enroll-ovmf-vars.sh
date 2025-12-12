#!/usr/bin/bash
# virt-enroll-vars.sh
#
# This script copies the original varstore and produces a modified file
# OVMF_VARS.enrolled.fd in the current directory (unless you pass a second arg).
#
# The script also provides a generic template for modifying variables. Another script that is more concise is provided to just handle toggling secure boot. (SecureBootEnable=<ON|off>)
#
# To replace in place, use, for example:
# ./enroll-ovmf-vars.sh OVMF-local/OVMF_VARS.fd  OVMF-local/OVMF_VARS.fd
#

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
OUT_VARS="${2:-OVMF_VARS.enrolled.fd}"

if [ ! -f "$ORIG_VARS" ]; then
	fatalError "original vars file not found: $ORIG_VARS"
fi

# check commands exist
command -v virt-fw-vars >/dev/null 2>&1 || { echo "virt-fw-vars not found"; exit 1; }
command -v virt-fw-dump >/dev/null 2>&1 || { echo "virt-fw-dump not found"; exit 1; }
command -v uuidgen >/dev/null 2>&1 || { echo "uuidgen not found"; exit 1; }

# Cert files (expected names from your earlier listing)
PK_CERT="${FIRMWARE_ENROLLED_KEYS_DIR}/PK.cer"
KEK_CERT="${FIRMWARE_ENROLLED_KEYS_DIR}/KEK.cer"
DB_CERT="${FIRMWARE_ENROLLED_KEYS_DIR}/db.cer"
DBX_CERT="${FIRMWARE_ENROLLED_KEYS_DIR}/dbx.cer"   # optional

for f in "$PK_CERT" "$KEK_CERT" "$DB_CERT"; do
	if [ ! -f "$f" ]; then
		fatalError "required certificate missing: $f"
	fi
done

# Work on a copy so we don't touch original
cp -a "$ORIG_VARS" "$OUT_VARS.tmp0"
cur="$OUT_VARS.tmp0"
step=0

# Helper to run virt-fw-vars with input/output chaining
# args: full virt-fw-vars args (use -i "$cur" -o "$next" within)
run_step() {
	step=$((step+1))
	next="${OUT_VARS}.tmp${step}"
	echo -e "\e[35m[*] Step ${step}: virt-fw-vars $* -i $cur -o $next\e[0m"
	# run virt-fw-vars with explicit -i/-o layering
	virt-fw-vars "$@" -i "$cur" -o "$next"
	mv -f "$next" "$cur"
}

# 1) Put the firmware into SetupMode=1 (no PK) by removing PK/KEK/db/dbx first (safe step)
#    Some firmwares require SetupMode before you can install PK; removing existing keys is optional.
echo "[*] Clearing PK/KEK/db/dbx from working copy (best-effort; ignore errors)"
# virt-fw-vars uses -d VAR (from usage). Use explicit --delete-variable if available; keep -d as fallback.
if virt-fw-vars --help 2>&1 | grep -q -- "--delete-variable"; then
	# newer versions
	run_step --delete-variable PK || true
	run_step --delete-variable KEK || true
	run_step --delete-variable db || true
	run_step --delete-variable dbx || true
else
	# fallback to short form -d
	run_step -d PK || true
	run_step -d KEK || true
	run_step -d db  || true
	run_step -d dbx || true
fi

# 2) Set PK using PK.cer
PK_GUID=$(uuidgen)
echo "[*] Setting PK (GUID=${PK_GUID}) from $PK_CERT"
run_step --set-pk "${PK_GUID}" "$PK_CERT"

# 3) Add KEK using KEK.cer (KEK is an "add" operation)
KEK_GUID=$(uuidgen)
echo "[*] Adding KEK (GUID=${KEK_GUID}) from $KEK_CERT"
run_step --add-kek "${KEK_GUID}" "$KEK_CERT"

# 4) Add db using db.cer
DB_GUID=$(uuidgen)
echo "[*] Adding db (GUID=${DB_GUID}) from $DB_CERT"
run_step --add-db "${DB_GUID}" "$DB_CERT"

# 5) Optionally set dbx (forbidden) if provided
if [ -f "$DBX_CERT" ]; then
	echo "[*] Setting dbx from $DBX_CERT"
	run_step --set-dbx "$DBX_CERT"
fi

# Final move to clean output name
mv -f "$cur" "$OUT_VARS"
# cleanup other tmp files
rm -f "${OUT_VARS}.tmp"* || true

echo -e "\e[42m[*] Done. Modified varstore saved to: $OUT_VARS\e[0m"
echo
echo -e "\e[34m[*] Verification (virt-fw-dump):\e[0m"
virt-fw-dump -i "$OUT_VARS" | sed -n '1,200p'

echo -e "\e[32mDone."
if [ "$ORIG_VARS" = "$OUT_VARS" ] ; then
	echo "You have successfully replaced $ORIG_VARS, and may run the test.sh script or an equivalent as is ot test your changes\e[0m"
else
	echo "You have updated your variables at $OUT_VARS. You may want now to copy them over to $ORIG_VARS, and run test.sh or an equivalent to test your changes\e[0m"
fi
