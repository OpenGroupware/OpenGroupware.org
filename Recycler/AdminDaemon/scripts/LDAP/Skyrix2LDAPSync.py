#!/usr/bin/env python

# $Id$

import xmlrpclib, string, ConfigParser, sys, ldap, socket
from types import *

class LDAPEntry:
    """ generic LDAP person/team entry """

    def __init__(self, _dn):
        """ init """
        self.__modlist    = []
        self.__modFlag    = ldap.MOD_ADD
        self.__dn         = _dn
        self.__newEntry   = 0

    def valueForKey(self, _object, _key):
        """ recursive valueForKey operation for dictionary """

        if _object.has_key(_key):
            return str(_object[_key])
        elif string.find(str(_key),'.') != -1:
            levels = string.split(str(_key),'.')
            current = _object
            for level in levels[:-1]:
                if current.has_key(level):
                    current = current[level]
                else:
                    return None
            if current.has_key(levels[-1]):
                return str(current[levels[-1]])
        return None        

    def isNewEntry(self):
        """ set new entry flag """
        self.__newEntry   = 1

    def addAttribute(self, _dn, _value):
        """ add 'add' attribute to modlist """
        self.addModlistEntry(ldap.MOD_ADD, _dn, _value)

    def replaceAttribute(self, _dn, _value):
        """ add 'modify' attribute to modlist """
        self.addModlistEntry(ldap.MOD_REPLACE, _dn, _value)

    def deleteAttribute(self, _dn, _value=None):
        """ add 'delete' attribute to modlist """
        self.addModlistEntry(ldap.MOD_DELETE, _dn, _value)        

    def addModlistEntry(self, _flag, _name, _value):
        """ add attribute to modlist """
        if _name == None or _value == None:
            return

	if _name == "userPassword":
	    _value = "{crypt}" + _value

        if type(_value) is IntType:
            _value = str(_value)

        if _value != None and _value != '' and _value != []:
            if _flag == ldap.MOD_ADD and self.__newEntry == 1:
                self.__modlist.append((_name, _value))
            else:
                self.__modlist.append((_flag, _name, _value))

    def updateEntry(self, _entry, _result, _keys):
        """ update entry """
        for key in _result.keys():
	      if _keys.has_key(key):
                realKey = _keys[key]
                if self.valueForKey(_entry,realKey) == None:
            	  		self.deleteAttribute(key,None)

        for key in _keys.keys():
            realKey = _keys[key]
            if not _result.has_key(key):
               	self.addAttribute(key,
                                  self.valueForKey(_entry, realKey))
            else:
                if _result[key] != [self.valueForKey(_entry, realKey),]:
                    self.replaceAttribute(key,
                                          self.valueForKey(_entry, realKey))

    def insert(self, _ldapConnection):
        """ insert new entry into LDAP """
        if self.__modlist != []:
            _ldapConnection.add_s(self.__dn, self.__modlist)

    def update(self, _ldapConnection):
        """ modify entry in LDAP """
        if self.__modlist != []:
            _ldapConnection.modify_s(self.__dn, self.__modlist)

class LDAPPersonEntry(LDAPEntry):
    """ LDAP person entry """

    def __init__(self, _uid, _rootdn, _company = None):
        """ init """
        self.__dn         = "uid=%s,%s" % (_uid, _rootdn)

        LDAPEntry.__init__(self, self.__dn)

        self.__modlist    = []
        self.__uid        = _uid
        self.__imapServer = "mike.ikk-sachsen-anhalt.de"
        self.__smtpServer = "mike.ikk-sachsen-anhalt.de"
        self.__imapPort   = "143"
        self.__mailDomain = "mike.ikk-sachsen-anhalt.de"
        self.__modFlag    = ldap.MOD_ADD
        self.__newEntry   = 0
        self.__company    = _company
        self.__keys = {
            'sn'                       : 'name',
            'cn'                       : 'name',
            'givenName'                : 'firstname',
            'mail'                     : 'extendedAttrs.email1',
            'uid'                      : 'login',
            'userPassword'             : 'password',
            'skyrixObjectVersion'      : 'objectVersion',
            'skyrixObjectIdentifier'   : 'id',
            }

    def keys(self, _elem=None):
        """ return keys/value for key """
        if _elem == None:
            return self.__keys.keys()
        else:
            return self.__keys[_elem]

    def addEmailServerDefaultValues(self, updateEntry=0):
        """ add SuSE EMail Server III LDAP Defaults (and our new
            SKYRiX scheme, too """
        if updateEntry == 0:
            self.addAttribute('objectClass', ['top','account','shadowAccount',
                              'posixAccount','person','inetOrgPerson',
                              'SuSEeMailObject','SKYRiXObject'])
            self.addAttribute('imapServer'        , self.__imapServer)
            self.addAttribute('imapPort'          , self.__imapPort)
            self.addAttribute('mailDomain'        , self.__mailDomain)
            self.addAttribute('smtpServer'        , self.__smtpServer)
            self.addAttribute('o'                 , self.__company)
            self.addAttribute('shadowMin'         , '0')
            self.addAttribute('shadowMax'         , '99999')
            self.addAttribute('shadowWarning'     , '7')
            self.addAttribute('shadowInactive'    , '0')
            self.addAttribute('shadowLastChange'  , '11091')
            self.addAttribute('preferredLanguage' , 'DE')
            self.addAttribute('mailenabled'       , 'ok')
            self.addAttribute('homeDirectory'     , '/home/%s' % self.__uid)
            self.addAttribute('loginShell'        , '/bin/bash')
            self.addAttribute('writeGlobalAddress', 'denied')
        else:
            self.addAttribute('objectClass'           , 'SKYRiXObject')
            self.replaceAttribute('imapServer'        , self.__imapServer)
            self.replaceAttribute('imapPort'          , self.__imapPort)
            self.replaceAttribute('mailDomain'        , self.__mailDomain)
            self.replaceAttribute('smtpServer'        , self.__smtpServer)
            self.replaceAttribute('o'                 , self.__company)

    def updateEntry(self, _entry, _result):
        """ update entry """
        LDAPEntry.updateEntry(self, _entry, _result, self.__keys)

class LDAPTeamEntry(LDAPEntry):
    """ LDAP team entry """

    def __init__(self, _cn, _rootdn, _team):
        """ init """
        self.__dn = "cn=%s,%s" % (_cn, _rootdn)
        LDAPEntry.__init__(self, self.__dn)
        self.__cn         = _cn
        self.__team       = _team
        self.__keys = {
            'description' : 'description',
            }

    def isNewEntry(self):
        """ set values for new entry """
        LDAPEntry.isNewEntry(self)
        self.addAttribute('objectClass', ['top','posixGroup','skyrixObject'])
        self.addAttribute('userPassword', '*')
        self.addAttribute('cn', self.__cn)
        if self.__team.has_key('description'):
            self.addAttribute('description', self.__team['description'])
        if self.__team.has_key('id'):
            self.addAttribute('skyrixObjectIdentifier',self.__team['id'])

        if self.__team.has_key('objectVersion'):
            ov = str(self.__team['objectVersion'])
        else:
            ov = '1'
        self.addAttribute('skyrixObjectVersion',ov)

    def updateEntry(self, _entry, _result):
        """ update entry """
        LDAPEntry.updateEntry(self, _entry, _result, self.__keys)

class Application:
    """ LDAP sync application class """

    def __init__(self):
        """ init """
        self.__teamCache = {}

    def printHeader(self):
        """ print a fancy header """
        print '*' * 60
        print '* SKYRiX <-> SuSE EMS III Sync (Accounts)                  *'
        print '*' * 60

    def printFooter(self):
        """ print a fancy footer """
        print '*' * 60
        print '* SKYRiX <-> SuSE EMS III Sync (Accounts) finished         *'
        print '*' * 60        

    def parseConfigFileEntries(self, _configFile):
        """ parse entries from config file """
        parser = ConfigParser.ConfigParser()
        parser.read(_configFile)

        self.__rootDn     = parser.get('ldap','rootdn')
        self.__ldapHost   = parser.get('ldap','host')
        self.__ldapPasswd = parser.get('ldap','passwd')
        self.__bindDn     = parser.get('ldap','binddn')

        self.__xmlRpcUrl  = parser.get('xmlrpc','url')
        self.__xmlRpcUser = parser.get('xmlrpc','user')
        self.__xmlRpcPass = parser.get('xmlrpc','password')        

        self.__company    = parser.get('defaults','company')

    def initXmlRpcServer(self):
        """ init xml-rpc server """
        self.__server = xmlrpclib.Server(self.__xmlRpcUrl,
                                         login=self.__xmlRpcUser,
                                         password=self.__xmlRpcPass)

    def initLDAPConnection(self):
        """ init LDAP connection """
        try:
            self.__ldapConnection = ldap.open(self.__ldapHost)
            self.__ldapConnection.simple_bind_s(self.__bindDn,
                                                self.__ldapPasswd)
        except ldap.SERVER_DOWN:
            print "Can't contact LDAP server"
            sys.exit(2)
        except:
            print "Unknown LDAP exception"
            sys.exit(2)

    def closeLDAPConnection(self):
        """ close LDAP connection """
        self.__ldapConnection.unbind_s()

    def getMaxValue(self, _dict, _key):
        """ get maximum of all entries for key from dictionary
            (used to get the next free GID """
        maxValue = 0;
        for entry in _dict:
            number = entry[1][_key][0]
            if int(number) > maxValue:
	              maxValue = int(number)
        return str(maxValue + 1);

    def getNextFreeTeamNumber(self):
        """ get next free team number """
        filter = "objectClass=posixGroup"

        result = self.searchLDAP(self.__rootDn, filter,
                                 attributes= ['gidNumber'])
        if result == []:
            return '100'
        else:
            return self.getMaxValue(result, 'gidNumber')

    def getNextFreeAccountNumber(self):
        """ get next free account number """
        filter = "objectClass=posixAccount"

        result = self.searchLDAP(self.__rootDn, filter,
                                 attributes= ['uidNumber'])
        if result == []:
            return '1000'
        else:
            return self.getMaxValue(result, 'uidNumber')

    def addTeamToTeamCache(self, _teamName, _teamGID):
        """ add team to local team cache """
        if type(_teamGID) is ListType:
            self.__teamCache[_teamName] = _teamGID[0]
        else:
            self.__teamCache[_teamName] = _teamGID

    def updateTeam(self, _name, _team, _result):
        """ update team """
        updateEntry = LDAPTeamEntry(_name, self.__rootDn, _team)

        variables = _result[0][1]

        if _team.has_key('objectVersion'):
            ov = _team['objectVersion']
        else:
            ov = '1'

        if variables.has_key('skyrixObjectVersion'):
            updateEntry.replaceAttribute('skyrixObjectVersion',ov)
        else:
            updateEntry.addAttribute('skyrixObjectVersion',ov)
            updateEntry.isNewEntry()

        print "[--->] updating team %s (gid: %s)" % (_name,
                                                     variables['gidNumber'][0])

        memberCache = []
        ldapCache = []

        members = self.__server.team.getMembersForTeam(_team['number'])
        for member in members:
            memberCache.append(member['login'])

        if _result != []:
            if _result[0][1].has_key('memberUid'):
                ldapCache = _result[0][1]['memberUid']

        for member in memberCache:
            if not member in ldapCache:
                updateEntry.addAttribute('memberUid', member);

        for member in ldapCache:
            if not member in memberCache:
                updateEntry.deleteAttribute('memberUid', member);

        updateEntry.updateEntry(_team, variables)
        updateEntry.update(self.__ldapConnection)

        self.addTeamToTeamCache(_team['description'], 
                                variables['gidNumber'])

    def groupNameWithoutSpecialChars(self, _name):
        """ remove spaces in groupname """
        return string.replace(_name,' ','_')
        
    def insertTeam(self, _name, _team):
        """ insert new team """
        if _team != None:
            newTeam = LDAPTeamEntry(_name, self.__rootDn, _team)
            newTeam.isNewEntry()

            gidNumber = self.getNextFreeTeamNumber()
            newTeam.addAttribute('gidNumber', gidNumber)
            newTeam.addAttribute('skyrixObjectVersion', '1')

            print "[--->] adding team %s (gid: %s)" % (_name, gidNumber)

            newTeam.insert(self.__ldapConnection)
            self.addTeamToTeamCache(_team['description'], gidNumber)

    def checkTeams(self, _teams):
        """ check all teams """
        teamCache = {}	
        for team in _teams:
            teamCache[team['description']] = team['objectVersion']

        try:
            ldapTeams = self.searchLDAP(self.__rootDn,
                                        "objectClass=posixGroup",
                                        attributes=["description"])
        except:
            print "Searching for teams in LDAP failed"
            print "Is your database initialized yet ?"
            sys.exit(2)

        for ldapTeam in ldapTeams:
#            if ldapTeam[1].has_key('skyrixObjectIdentifier'):
            if ldapTeam[1].has_key('description'):
                teamDesc = ldapTeam[1]['description'][0]
                if not teamCache.has_key(teamDesc):
                    print 'Team %s got deleted' % teamDesc
                    name = self.groupNameWithoutSpecialChars(teamDesc)
                    self.__ldapConnection.delete_s("cn=%s,%s" % (name,
                                                   self.__rootDn))

        for team in _teams:
            name = self.groupNameWithoutSpecialChars(team['description'])
            filter = "cn=%s" % name
            result = self.searchLDAP(self.__rootDn, filter)
            if result == []:
                self.insertTeam(name, team)
            else:
                vars = result[0][1]
                if not vars.has_key('skyrixObjectVersion') or \
                int(vars['skyrixObjectVersion'][0]) !=\
                team['objectVersion']:
                    self.updateTeam(name, team, result)
                else:
                    self.addTeamToTeamCache(team['description'], 
                                            vars['gidNumber'])

    def handleTeams(self):
        """ handle teams """
        teams = None

        try:
            teams = self.__server.team.getTeams()
        except socket.error:
            print "Can't contact XML-RPC daemon"
            sys.exit(2)
        except:
            print 'Error while fetching teams, check your xmlrpc daemon'
            sys.exit(2)
            
        if teams != None:
            self.checkTeams(teams)

    def modifyLDAPDn(self, _dn, _modlist):
        """ modify LDAP dn """
        if _modlist != None:
            self.__ldapConnection.modify_s(_dn, _modlist)

    def deleteLDAPDn(self, _dn):
        """ delete LDAP dn """
        self.__ldapConnection.delete_s(_dn)

    def searchLDAP(self, _dn, _filter, scope=ldap.SCOPE_SUBTREE,
                   attributes=None):
        return self.__ldapConnection.search_s(_dn, scope, _filter, attributes)

    def getLDAPEntryByLogin(self, _login):
        return self.searchLDAP(self.__rootDn, "uid=%s" % _login)

    def insertAccount(self, _account):
        newEntry = LDAPPersonEntry(_account['login'], self.__rootDn,
                                   self.__company)
        newEntry.isNewEntry()
        uidNumber = self.getNextFreeAccountNumber()

        newEntry.addAttribute('uidNumber', uidNumber)
        teams = self.__server.account.getTeamsForLogin(_account['login'])

      	if teams == []:
            team = {}
            team['description'] = "all intranet"
            teams = [team,]

        firstTeam = 0;
        for team in teams:
            if firstTeam == 0:
                firstTeam = 1
                newEntry.addAttribute('gidNumber',
                                      self.__teamCache[team['description']])
       
        passwd = self.__server.account.passwordForLogin(_account['login'])
        newEntry.addAttribute('userPassword', passwd)

        for key in newEntry.keys():
            newEntry.addAttribute(key,
                                  newEntry.valueForKey(_account,
                                                   newEntry.keys(key)))
        newEntry.addEmailServerDefaultValues()

        newEntry.insert(self.__ldapConnection)

    def checkGroups(self, _account, _result, _entry):
        teams = self.__server.account.getTeamsForLogin(_account['login'])
        
        if teams == []:
          teams = [{'description' : 'all intranet'},]
        
        primaryGID = _result[0][1]['gidNumber'][0]
        
        firstTeam = None
        
        foundPrimary = 0
        for team in teams:
            firstTeam = team
            if self.__teamCache[team['description']] == primaryGID:
                foundPrimary = 1
            else:
                name = self.groupNameWithoutSpecialChars(team['description'])
                dn = "cn=%s,%s" % (name, self.__rootDn)
                result = self.searchLDAP(dn, "cn=%s" % name,
                                         scope=ldap.SCOPE_BASE,
                                         attributes=['memberUid'])
                uids = []
                if result != []:
                    res = result[0][1]
                    if res.has_key('memberUid'):
                        uids = res['memberUid']

                if _account['login'] not in uids:
                    modlist = []
                    # FIXME
                    #modlist.append((ldap.MOD_ADD, 'memberUid',
                    #                _account['login']))
                    #self.modifyLDAPDn(dn, modlist)

        if foundPrimary == 0:
            _entry.deleteAttribute('gidNumber',primaryGID)
            _entry.addAttribute('gidNumber',
                                self.__teamCache[firstTeam['description']])

        filter = "(& (objectClass=posixGroup) (memberUid=%s))" %\
        _account['login']
        results = self.searchLDAP(self.__rootDn,filter,attributes=['cn'])
        
        for result in results:
            cn = result[1]['cn'][0]
            found = 0
            for team in teams:
                name = self.groupNameWithoutSpecialChars(team['description'])
                if name == cn:
                    found = 1
                    break

            if found == 0:
                dn = "cn=%s,%s" % (cn, self.__rootDn)
                modlist = []
                modlist.append((ldap.MOD_DELETE,'memberUid',
                                _account['login']))
                self.modifyLDAPDn(dn, modlist)

    def updateAccount(self, _account, _result):
      	updateEntry = LDAPPersonEntry(_account['login'], self.__rootDn)

        # warning: check if _result is valid here
      	variables = _result[0][1]

        if not variables.has_key('skyrixObjectIdentifier'):
            updateEntry.addEmailServerDefaultValues(1)

        self.checkGroups(_account, _result, updateEntry)
        updateEntry.updateEntry(_account, variables)

        passwd = self.__server.account.passwordForLogin(_account['login'])
      	if ("{crypt}%s" % passwd) != variables['userPassword'][0]:
            updateEntry.replaceAttribute('userPassword', passwd)

      	updateEntry.update(self.__ldapConnection)

    def checkAccounts(self, _idList):
        versionCache = {}
        uidCache     = {}
        
        filter = "objectClass=posixAccount"
        result = self.searchLDAP(self.__rootDn, filter,
                                 attributes=['skyrixObjectVersion',
                                             'skyrixObjectIdentifier',
                                             'uid'])
        for entry in result:
            dict = entry[1]
            if dict.has_key('skyrixObjectIdentifier'):
                myid = dict['skyrixObjectIdentifier'][0]
                myid = string.replace(myid,":80","")
                versionCache[myid] =\
                             dict['skyrixObjectVersion'][0]
            else:
#                uidCache[dict['uid']] = 'uid'
                 uidCache[dict['uid'][0]] = 'uid'
        
        count = 1
        for id in _idList.keys():
            id2 = string.replace(id,":80","")
            if not versionCache.has_key(id2):
                account = self.__server.person.getById(id)
                login = account['login']
                print '[%4d]' % count + ' inserting account ' + login

                if uidCache.has_key(login):
                    result = self.getLDAPEntryByLogin(login)
                    self.updateAccount(account, result)
                else:
                    self.insertAccount(account)
            else:
                if int(_idList[id]) != int(versionCache[id2]):
                    account = self.__server.person.getById(id)
                    login = account['login']
                    print login
                    result = self.getLDAPEntryByLogin(login)
                    print result
                    print '[%4d]' % count + ' updating account ' + login
                    self.updateAccount(account, result)
                else:
                    print '[%4d]' % count + ' skipping account ' + id
            count += 1

        for key in versionCache.keys():
            key = string.replace(id, "skyrix://mike.ikk-sachsen-anhalt.de/","skyrix://mike.ikk-sachsen-anhalt.de:80/")
            if not _idList.has_key(key):
                result = self.searchLDAP(self.__rootDn,
                                         "skyrixObjectIdentifier=%s" % key,
                                         attributes=['uid'])

                if result != []:
                    login = result[0][1]['uid'][0]
                    print '[--->] deleting account ' + login
                    self.deleteLDAPDn("uid=%s,%s" % (login, self.__rootDn))

    def handleAccounts(self):
        idList = None
        print '[<---] fetching IDs and versions ...'
        try:
            idList = self.__server.account.fetchIdsAndVersions("name like '*'")
        except:
            print 'Error while fetching accounts, check your xmlrpc daemon'
            sys.exit(2)

        if idList != None:
            print '[--->] ID fetching done ... found %d IDs' % len(idList)
            self.checkAccounts(idList)

    def run(self):
        self.printHeader()
        self.parseConfigFileEntries('ldap.cfg')
        self.initXmlRpcServer()
        self.initLDAPConnection()
        self.handleTeams()
        self.handleAccounts()
      	self.closeLDAPConnection()
        self.printFooter()
        return 0

if __name__ == '__main__':
    app = Application()
    result = app.run()
    sys.exit(result)
