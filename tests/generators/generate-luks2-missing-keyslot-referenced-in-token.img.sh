#!/bin/bash

. lib.sh

#
# *** Description ***
#
# generate primary header with missing keyslot object referenced
# in token object
#
# secondary header is corrupted on purpose as well
#

# $1 full target dir
# $2 full source luks2 image

function generate()
{
	read -r json_str_orig < $TMPDIR/json0
	# add missing keyslot reference in keyslots array of token '0'
	json_str=$(jq -r -c -M 'def missks: getpath(["keyslots"]) | keys | max | tonumber + 1 | tostring;
	      .tokens += {"0":{"type":"dummy","keyslots":[ "0", missks ]}}' $TMPDIR/json0)
	test ${#json_str} -lt $((LUKS2_JSON_SIZE*512)) || exit 2

	write_luks2_json "$json_str" $TMPDIR/json0

	merge_bin_hdr_with_json $TMPDIR/hdr0 $TMPDIR/json0 $TMPDIR/area0
	erase_checksum $TMPDIR/area0
	chks0=$(calc_sha256_checksum_file $TMPDIR/area0)
	write_checksum $chks0 $TMPDIR/area0
	write_luks2_hdr0 $TMPDIR/area0 $TGT_IMG
	kill_bin_hdr $TMPDIR/hdr1
	write_luks2_hdr1 $TMPDIR/hdr1 $TGT_IMG
}

function check()
{
	read_luks2_bin_hdr1 $TGT_IMG $TMPDIR/hdr_res1
	local str_res1=$(head -c 6 $TMPDIR/hdr_res1)
	test "$str_res1" = "VACUUM" || exit 2

	read_luks2_json0 $TGT_IMG $TMPDIR/json_res0
	chks_res0=$(read_sha256_checksum $TGT_IMG)
	test "$chks0" = "$chks_res0" || exit 2
	new_arr_len=$(jq -c -M '.tokens."0".keyslots | length' $TMPDIR/json_res0)
	test $new_arr_len -eq 2 || exit 2
}

lib_prepare $@
generate
check
lib_cleanup
