#!/bin/sh

MIMETYPES="()"

if ! test -d $PWD/../target; then
  mkdir $PWD/../target
fi

skypubexport -login local -project $PWD \
	-source / \
	-target $PWD/../target	\
	-LSMimeTypes "$MIMETYPES"
