# $Id$

import xmlrpclib, time, sys, os;
import XmlRpcdClient;

from string import *;
from re import *;

# write account ({login:'l', globalId:'url', version:'1',
# emails:('email1', ..)}, ...)
# if version == -1 this account is marked as dead, he will be removed

class WriteAccounts(XmlRpcdClient.XmlRpcdClient):

    def aliasesForAccount(self, _account):
        aliases = [];
        
        if _account.has_key('firstname'):
            aliases.append(str(_account['firstname'])+"."+str(_account['name']));
            aliases.append(_account['firstname'][0]+_account['name'][0]);

        if (_account.has_key('nickname')):
            if len(_account['nickname']) > 0:
                aliases.append(_account['nickname'])

        return aliases;
        

    def createAliasesForDomains(self, _account, _domain):
        aliases = self.aliasesForAccount(_account);
        result = [];
        for a in aliases: # umlauts handling 
            a = lower(a);
            a = "oe".join(split("\xc3\xb6", a));
            a = "oe".join(split("\xc3\x96", a));
            a = "ue".join(split("\xc3\x9c", a));
            a = "ue".join(split("\xc3\xbc", a));
            a = "ae".join(split("\xc3\x84", a));
            a = "ae".join(split("\xc3\xa4", a));
            a = "ss".join(split("\xc3\x9f", a));
            a = "".join(split("[^a-z0-9_+-.]", a));
            if len(a) > 0:
                result.append(lower(a + "@" + _domain));
                
        return result;

    def addValuesToDict(self, _dict, _obj, _okey, _key, _lower):
        if _obj.has_key(_okey):
            for o in _obj[_okey]:
                if _lower == 1:
                    o = lower(o);
                if _dict.has_key(o):
                    array = _dict[o];
                else:
                    array = [];

                array.append(_key);
                _dict[o] = array;
    
    def write(self):
        dict    = {};
        doubles = {};
        s       = self.server();

        removeDouble = s.defaults_stringForKey("remove double alias entries",
                                               "MTA");
        if removeDouble == 'YES':
            removeDouble = 1;
        else:
            removeDouble = 0;
        
        accounts = s.account.fetchAllMTAInfo();

        for a in accounts:
            l = str(a['login']);

            self.addValuesToDict(dict, a, 'vaddresses', l, 1);
            self.addValuesToDict(dict, a, 'teams', l, 0);

            for e in a['aliasDomains']:
                aliases = self.createAliasesForDomains(a, e);

                for al in aliases:
                    al = lower(al);

                    if removeDouble == 1:
                        if al in doubles.keys(): # got a double entry
                            if dict.has_key(al):
                                array = dict[al]
                                array.remove(doubles[al]);
                                if len(array) == 0:
                                    del dict[al];
                            continue;
                        else:
                            doubles[al] = l;
                
                    if dict.has_key(al):
                        emails = dict[al];
                    else:
                        emails = [];

                    emails.append(l);
                    dict[al] = emails;
        self.writePostmap(self.dataFilePath(), dict);

    def dataFile(self):
        return os.getenv('account_file');

# class: WriteAccounts
