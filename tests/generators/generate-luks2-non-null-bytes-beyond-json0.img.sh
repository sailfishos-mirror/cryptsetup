#!/bin/bash

. lib.sh

#
# *** Description ***
#
# generate primary header with json area containing illegal bytes
# beyond well-formed json format.
#
# secondary header is corrupted on purpose as well
#

# $1 full target dir
# $2 full source luks2 image

QUOTE="[Homer J. Simpson]: Keep looking shocked and move slowly towards the cake."
SPACE=20

function generate()
{
	read -r json_str < $TMPDIR/json0
	json_len_orig=${#json_str}
	json_len=$((json_len_orig+${#QUOTE}+SPACE))
	test ${#json_str} -lt $((LUKS2_JSON_SIZE*512)) || exit 2

	printf '%s' "$QUOTE" | _dd of=$TMPDIR/json0 seek=$((json_len_orig+SPACE)) bs=1 conv=notrunc

	lib_mangle_json_hdr0_kill_hdr1
}

function check()
{
	read_luks2_bin_hdr1 $TGT_IMG $TMPDIR/hdr_res1
	local str_res1=$(head -c 6 $TMPDIR/hdr_res1)
	test "$str_res1" = "VACUUM" || exit 2

	read_luks2_json0 $TGT_IMG $TMPDIR/json_res0
	chks_res0=$(read_sha256_checksum $TGT_IMG)
	test "$chks0" = "$chks_res0" || exit 2

	_dd if=$TMPDIR/json_res0 of=$TMPDIR/quote skip=$((json_len_orig+SPACE)) count=${#QUOTE} bs=1
	json_str_res0=$(head -c ${#QUOTE} $TMPDIR/quote)
	test "$json_str_res0" = "$QUOTE" || exit 2
}

lib_prepare $@
generate
check
lib_cleanup
