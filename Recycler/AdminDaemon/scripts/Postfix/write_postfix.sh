#!/bin/bash
# $Id$

# TODO: -write email on fail [jr]

source vars.sh;
export domain="MTA"

localdomain_tmp=${tmp_dir}${localdomain_file}
account_tmp=${tmp_dir}${account_file}
team_tmp=${tmp_dir}${team_file}

account_hot=${result_dir}${account_file}
team_hot=${result_dir}${team_file}
localdomain_hot=${result_dir}${localdomain_file}

# ececute command error handling 

checkPaths;

# is a procss already in progres ?

if test "x`${python_path} ${check_default} 'export is in progress'`" == "xYES"; then
    ${python_path} ${write_error} "sync is already in progress" 0;
    exit 0;
fi

# set is in progress flag

${python_path} ${write_default} 'export is in progress' 'YES';

# if all should be deleted

if test "x`${python_path} ${check_default} 'delete all'`" == "xYES"; then
    ${python_path} ${write_default} 'delete all' 'NO';
    execute "mv ${account_hot}     ${account_hot}.org";
    execute "mv ${account_hot}.db  ${account_hot}.db.org";
    execute "mv ${team_hot}        ${team_hot}.org";
    execute "mv ${team_hot}.db     ${team_hot}.db.org";
    execute "mv ${localdomain_hot} ${localdomain_hot}.org";
    execute "${postfix_start} reload";
fi

# is the 'export data' flag is set ?

if test "x`${python_path} ${check_default} 'export data'`" != "xYES"; then
    echo "do export flag is set not set"
    ${python_path} ${write_default} 'export is in progress' 'NO';
    exit 1;
fi

# check whether result dir exist, if not create it

if test ! -e ${result_dir}; then
    execute "mkdir ${result_dir}"
fi

# remove temp files

if test -e ${account_tmp}; then
    rm ${account_tmp};
fi
if test -e ${team_tmp}; then
    rm ${team_tmp};
fi
if test -e ${localdomain_tmp}; then
    rm ${localdomain_tmp};
fi

# fetch data

execute "${python_path} ${write_postfix}"


# ** account **

# temp files are written ?
if test ! -e ${account_tmp}; then
    ${python_path} ${write_error} "Missing account aliases file at ${account_tmp}"
    exit 1
fi

# execute popstmap
execute "${postmap_path} ${account_tmp}"

# postmap db file exist?
if test ! -e "${account_tmp}.db"; then
    ${python_path} ${write_error} "Missing account aliases db file at ${account_tmp}.db";
    exit 1
fi

# save old hot file
if test -e ${account_hot}; then
    execute "cp ${account_hot} ${account_hot}.org"
fi
if test -e ${account_hot}.db; then
    execute "cp ${account_hot}.db ${account_hot}.db.org"
fi


# copy new files
execute "cp ${account_tmp} ${account_hot}"
execute "cp ${account_tmp}.db ${account_hot}.db"

# ** team **

# temp files are written ?
if test ! -e ${team_tmp}; then
    ${python_path} ${write_error} "Missing team aliases file at ${team_tmp}";
    exit 1
fi

# execute popstmap
execute "${postmap_path} ${team_tmp}"

# postmap db file exist?
if test ! -e "${team_tmp}.db"; then
    ${python_path} ${write_error} "Missing team aliases db file at ${team_tmp}.db";
    exit 1
fi

# save old hot file
if test -e ${team_hot}; then
    execute "cp ${team_hot} ${team_hot}.org"
fi
if test -e ${team_hot}.db; then
    execute "cp ${team_hot}.db ${team_hot}.db.org"
fi

# copy new files
execute "cp ${team_tmp} ${team_hot}"
execute "cp ${team_tmp}.db ${team_hot}.db"

# **localdomain**
# temp files are written ?

if test ! -e ${localdomain_tmp}; then
    ${python_path} ${write_error} "Missing local domains file at ${localdomain_tmp}";
    exit 1
fi

# save old hot file
if test -e ${localdomain_hot}; then
    execute "cp ${localdomain_hot} ${localdomain_hot}.org"
fi

# copy new file
execute "cp ${localdomain_tmp} ${localdomain_hot}"


# reloead postfix
execute "${postfix_start} reload"

# delete progres flag
${python_path} ${write_default} 'export is in progress' 'NO';
${python_path} ${write_default} 'last export date' "`date`";
