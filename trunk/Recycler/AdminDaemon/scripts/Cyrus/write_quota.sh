#!/bin/bash

source vars.sh;
export domain="Imap"

checkPaths;

if test "x`${python_path} ${check_default} 'export is in progress'`" == "xYES"; then
    ${python_path} ${write_error} "sync is already in progress";
    exit 0;
fi

${python_path} ${write_default} 'export is in progress' 'YES';

if test "x`${python_path} ${check_default} 'export data'`" != "xYES"; then
    echo "do export flag is set not set"
    ${python_path} ${write_default} 'export is in progress' 'NO';
    exit 1;
fi

execute "${python_path} ${write_quota}"

${python_path} ${write_default} 'export is in progress' 'NO';
${python_path} ${write_default} 'last export date' "`date`";
