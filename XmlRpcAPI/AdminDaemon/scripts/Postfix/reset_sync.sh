#!/bin/bash
# $Id: reset_sync.sh,v 1.1 2003/12/12 14:36:45 helge Exp $

source vars.sh;

export domain="MTA"

checkPaths;

${python_path} ${write_default} 'export is in progress' 'NO';
