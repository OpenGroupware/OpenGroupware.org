# $Id: vars.sh,v 1.2 2003/12/12 14:26:19 helge Exp $

# what a mess ... rewrite as proper Python config file as demonstrated by
# Bjoern in the LDAP code.

python_path='/usr/bin/python'
postmap_path='/usr/sbin/postmap'
postfix_start='/etc/init.d/postfix'
script_path='/home/jan41e/bdev/skyrix5/XmlRpcAPI/AdminDaemon/scripts/';

stdout_path='/tmp/out'

export tmp_dir='/tmp/'
export result_dir='/tmp/postfix/'

export xmlrpcd_url='http://localhost:20000/RPC2'
export xmlrpcd_login='mailadmin'
export xmlrpcd_pwd='xxx'

export imap_host='localhost'
export imap_port='143'
export imap_root='cyrus'
export imap_pwd='xxx'
export imap_user_prefix='user.'

export localdomain_file='localdomains'
export account_file='account'
export team_file='team'

export domain='MTA';

check_default=${script_path}'ReadDefault.py';
write_default=${script_path}'WriteDefault.py';
write_error=${script_path}'WriteError.py';

write_postfix_sh=${script_path}'Postfix/write_postfix.sh';
write_postfix=${script_path}'Postfix/write_postfix.py';
write_quota=${script_path}'Cyrus/WriteQuota.py';
write_quota_sh=${script_path}'Cyrus/write_quota.sh';

execute ()
{
    err=`$1 2>&1 1>>${stdout_path}`
    if test "x$err" != "x" ; then
        echo "*** ERROR ***";
        echo $err;
        ${python_path} ${write_error} "$err";
        exit 1;
    fi    
} # Function declaration must precede call.

checkScript ()
{
    if test ! -r $1; then
        echo "missing  $1";
        exit 1;
    fi
}

checkPaths ()
{
    if test ! -x ${python_path}; then
        echo "missing python executable";
        exit 1;
    fi
    if test ! -x ${postmap_path}; then
        echo "missing postmap executable";
        exit 1;
    fi
    if test ! -x ${postfix_start}; then
        echo "missing postfix init executable";
        exit 1;
    fi
    checkScript ${write_postfix}
    checkScript ${write_default}
    checkScript ${check_default}
    checkScript ${write_error}
    checkScript ${write_postfix_sh}
    checkScript ${write_quota}
    checkScript ${write_quota_sh}
}
