#!/bin/bash

source vars.sh;
export domain="Imap"

checkPaths;

if test "x`${python_path} ${check_default} 'export immediately'`" != "xYES"; then
    echo "do export flag is set not set"
    exit 1;
fi

${python_path} ${write_default} 'export immediately' 'NO';
${write_quota_sh}
