#!/bin/bash
# $Id$

source vars.sh;

export domain="MTA"

checkPaths;

${python_path} ${write_default} 'export is in progress' 'NO';
