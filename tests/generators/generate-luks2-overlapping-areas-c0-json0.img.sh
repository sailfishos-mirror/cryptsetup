#!/bin/bash

. lib.sh

#
# *** Description ***
#
# generate primary header with two exactly same areas in terms of 'offset' and 'length'.
#
# secondary header is corrupted on purpose as well
#

# $1 full target dir
# $2 full source luks2 image

function generate()
{
	# copy area 6 offset and length into area 7
	json_str=$(jq -c '.keyslots."7".area.offset = .keyslots."6".area.offset |
	       .keyslots."7".area.size = .keyslots."6".area.size' $TMPDIR/json0)
	test ${#json_str} -lt $((LUKS2_JSON_SIZE*512)) || exit 2

	write_luks2_json "$json_str" $TMPDIR/json0

	lib_mangle_json_hdr0_kill_hdr1
}

function check()
{
	read_luks2_bin_hdr1 $TGT_IMG $TMPDIR/hdr_res1
	local str_res1=$(head -c 6 $TMPDIR/hdr_res1)
	test "$str_res1" = "VACUUM" || exit 2

	read_luks2_json0 $TGT_IMG $TMPDIR/json_res0
	jq -c 'if (.keyslots."6".area.offset != .keyslots."7".area.offset) or (.keyslots."6".area.size != .keyslots."7".area.size)
	       then error("Unexpected value in result json") else empty end' $TMPDIR/json_res0 || exit 5
}

lib_prepare $@
generate
check
lib_cleanup
