#!/bin/bash
# $Id: write_postfix_imm.sh,v 1.1 2003/12/12 14:36:45 helge Exp $

source Postfix/local_vars.sh;

checkPaths;

if test "x`${python_path} ${check_default} 'export immediately'`" != "xYES"; then
    echo "do export flag is set not set"
    exit 1;
fi

${python_path} ${write_default} 'export immediately' 'NO';
${write_postfix_sh}
