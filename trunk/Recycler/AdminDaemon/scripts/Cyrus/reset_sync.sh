#!/bin/bash

source vars.sh;

export domain="Imap"

checkPaths;

${python_path} ${write_default} 'export is in progress' 'NO';
