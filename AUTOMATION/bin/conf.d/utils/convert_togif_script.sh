#!/bin/bash
filename="${1}"
if [ "${filename##*.}" == "png" ]; then
	convert "${filename}" "${filename%.*}.gif"
	EXIT=$?
else
	echo "!!!ERROR: convert_togif_script: input file $filename is not a png"
	EXIT=1
fi
exit $EXIT
