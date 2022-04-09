#!/bin/bash

. lib.sh

#
# *** Description ***
#
# generate primary header with well-formed json format
# where top level value is not of type object.
#
# secondary header is corrupted on purpose as well
#

# $1 full target dir
# $2 full source luks2 image

function generate()
{
	read -r json_str < $TMPDIR/json0
	json_str="[$json_str]" # make top level value an array
	test ${#json_str} -lt $((LUKS2_JSON_SIZE*512)) || exit 2

	printf "%s" "$json_str" | _dd of=$TMPDIR/json0 bs=1 conv=notrunc

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
	read -r json_str_res0 < $TMPDIR/json_res0
	test "$json_str" = "$json_str_res0" || exit 2
}

lib_prepare $@
generate
check
lib_cleanup
