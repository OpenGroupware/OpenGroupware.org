#!/bin/sh

find ~/GNUstep/ -type f | \
  grep -v Makefiles|\
  grep -v opentool|grep -v debugapp|grep -v openapp|\
  grep -v share/config.site

