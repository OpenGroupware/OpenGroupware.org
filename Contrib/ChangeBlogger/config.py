##
##  CONFIG
##

EMAIL = {
    "Helge Hess  <helge@grove>" : "Helge He� <helge.hess@opengroupware.org>",
    "Marcus Mueller  <znek@mulle-kybernetik.com>" : "Marcus M�ller <znek@mulle-kybernetik.com>",
}

CONFIG = {
        # top level project's realname
        "project" : "OpenGroupware.org",
        
        # the base directory of a checked-out copy of 'project'
        "basedir" : "/home/znek/Projects/OpenGroupware.org",
        
        # the URL where generated html pages can be accessed
        "webURL" : "http://creutzfeld.mulle-kybernetik.com/OGo/",

        # the directory where generated html pages will go to
        "webRoot" : "/www/sites/creutzfeld.mulle-kybernetik.com/htdocs/OGo",

        # a subdirectory for these archives, based in 'webRoot'
        "webArchivePath" : "",
        
        # the URL for viewcvs (or cvsweb, whatever)
        "viewcvs" : "http://www.opengroupware.org/cvsweb/cvsweb.cgi/OpenGroupware.org/",

        # the changelogs
        # Note: each entry consists of a dictionary with the following keys:
        # 'project' -> a realname describing the project
        # 'path' -> the path as seen relative to 'basedir'
        # 'log' -> same as path but including changelog itself
        "logs" :
            [
                { 'project' : 'OGoModel', 'path' : 'Database/OGoModel', 'log' : 'Database/OGoModel/ChangeLog' },
                { 'project' : 'PostgreSQL', 'path' : 'Database/PostgreSQL', 'log' : 'Database/PostgreSQL/ChangeLog' },
                { 'project' : 'OGoAccounts', 'path' : 'DocumentAPI/OGoAccounts', 'log' : 'DocumentAPI/OGoAccounts/ChangeLog' },
                { 'project' : 'OGoBase', 'path' : 'DocumentAPI/OGoBase', 'log' : 'DocumentAPI/OGoBase/ChangeLog' },
                { 'project' : 'OGoContacts', 'path' : 'DocumentAPI/OGoContacts', 'log' : 'DocumentAPI/OGoContacts/ChangeLog' },
                { 'project' : 'OGoDatabaseProject', 'path' : 'DocumentAPI/OGoDatabaseProject', 'log' : 'DocumentAPI/OGoDatabaseProject/ChangeLog' },
                { 'project' : 'OGoDocuments', 'path' : 'DocumentAPI/OGoDocuments', 'log' : 'DocumentAPI/OGoDocuments/ChangeLog' },
                { 'project' : 'OGoFileSystemProject', 'path' : 'DocumentAPI/OGoFileSystemProject', 'log' : 'DocumentAPI/OGoFileSystemProject/ChangeLog' },
                { 'project' : 'OGoJobs', 'path' : 'DocumentAPI/OGoJobs', 'log' : 'DocumentAPI/OGoJobs/ChangeLog' },
                { 'project' : 'OGoProject', 'path' : 'DocumentAPI/OGoProject', 'log' : 'DocumentAPI/OGoProject/ChangeLog' },
                { 'project' : 'OGoRawDatabase', 'path' : 'DocumentAPI/OGoRawDatabase', 'log' : 'DocumentAPI/OGoRawDatabase/ChangeLog' },
                { 'project' : 'OGoScheduler', 'path' : 'DocumentAPI/OGoScheduler', 'log' : 'DocumentAPI/OGoScheduler/ChangeLog' },
                { 'project' : 'LSAccount', 'path' : 'Logic/LSAccount', 'log' : 'Logic/LSAccount/ChangeLog' },
                { 'project' : 'LSAddress', 'path' : 'Logic/LSAddress', 'log' : 'Logic/LSAddress/ChangeLog' },
                { 'project' : 'LSBase', 'path' : 'Logic/LSBase', 'log' : 'Logic/LSBase/ChangeLog' },
                { 'project' : 'LSEnterprise', 'path' : 'Logic/LSEnterprise', 'log' : 'Logic/LSEnterprise/ChangeLog' },
                { 'project' : 'LSFoundation', 'path' : 'Logic/LSFoundation', 'log' : 'Logic/LSFoundation/ChangeLog' },
                { 'project' : 'LSMail', 'path' : 'Logic/LSMail', 'log' : 'Logic/LSMail/ChangeLog' },
                { 'project' : 'LSNews', 'path' : 'Logic/LSNews', 'log' : 'Logic/LSNews/ChangeLog' },
                { 'project' : 'LSPerson', 'path' : 'Logic/LSPerson', 'log' : 'Logic/LSPerson/ChangeLog' },
                { 'project' : 'LSProject', 'path' : 'Logic/LSProject', 'log' : 'Logic/LSProject/ChangeLog' },
                { 'project' : 'LSResource', 'path' : 'Logic/LSResource', 'log' : 'Logic/LSResource/ChangeLog' },
                { 'project' : 'LSScheduler', 'path' : 'Logic/LSScheduler', 'log' : 'Logic/LSScheduler/ChangeLog' },
                { 'project' : 'LSSearch', 'path' : 'Logic/LSSearch', 'log' : 'Logic/LSSearch/ChangeLog' },
                { 'project' : 'LSTeam', 'path' : 'Logic/LSTeam', 'log' : 'Logic/LSTeam/ChangeLog' },
                { 'project' : 'export', 'path' : 'Migration/SLEMS3/export', 'log' : 'Migration/SLEMS3/export/ChangeLog' },
                { 'project' : 'import', 'path' : 'Migration/SLEMS3/import', 'log' : 'Migration/SLEMS3/import/ChangeLog' },
                { 'project' : 'skyprojectd', 'path' : 'Misc/skyprojectd', 'log' : 'Misc/skyprojectd/ChangeLog' },
                { 'project' : 'OGoNHSSync', 'path' : 'PDA/OGoNHSSync', 'log' : 'PDA/OGoNHSSync/ChangeLog' },
                { 'project' : 'OGoPalm', 'path' : 'PDA/OGoPalm', 'log' : 'PDA/OGoPalm/ChangeLog' },
                { 'project' : 'OGoPalmUI', 'path' : 'PDA/OGoPalmUI', 'log' : 'PDA/OGoPalmUI/ChangeLog' },
                { 'project' : 'OGoPalmWebUI', 'path' : 'PDA/OGoPalmWebUI', 'log' : 'PDA/OGoPalmWebUI/ChangeLog' },
                { 'project' : 'PPSync', 'path' : 'PDA/PPSync', 'log' : 'PDA/PPSync/ChangeLog' },
                { 'project' : 'Publisher', 'path' : 'Publisher', 'log' : 'Publisher/ChangeLog' },
                { 'project' : 'NGSoap', 'path' : 'SandStorm/NGSoap', 'log' : 'SandStorm/NGSoap/ChangeLog' },
                { 'project' : 'OGoDaemon', 'path' : 'SandStorm/OGoDaemon', 'log' : 'SandStorm/OGoDaemon/ChangeLog' },
                { 'project' : 'OGoIDL', 'path' : 'SandStorm/OGoIDL', 'log' : 'SandStorm/OGoIDL/ChangeLog' },
                { 'project' : 'OGoRegistryBrowser', 'path' : 'SandStorm/OGoRegistryBrowser', 'log' : 'SandStorm/OGoRegistryBrowser/ChangeLog' },
                { 'project' : 'Mail', 'path' : 'SandStorm/Scripts/Mail', 'log' : 'SandStorm/Scripts/Mail/ChangeLog' },
                { 'project' : 'skyaccountd', 'path' : 'SandStorm/skyaccountd', 'log' : 'SandStorm/skyaccountd/ChangeLog' },
                { 'project' : 'skyaptd', 'path' : 'SandStorm/skyaptd', 'log' : 'SandStorm/skyaptd/ChangeLog' },
                { 'project' : 'skycontactd', 'path' : 'SandStorm/skycontactd', 'log' : 'SandStorm/skycontactd/ChangeLog' },
                { 'project' : 'skydbd', 'path' : 'SandStorm/skydbd', 'log' : 'SandStorm/skydbd/ChangeLog' },
                { 'project' : 'skygreetingd', 'path' : 'SandStorm/skygreetingd', 'log' : 'SandStorm/skygreetingd/ChangeLog' },
                { 'project' : 'skyjobd', 'path' : 'SandStorm/skyjobd', 'log' : 'SandStorm/skyjobd/ChangeLog' },
                { 'project' : 'skymaild', 'path' : 'SandStorm/skymaild', 'log' : 'SandStorm/skymaild/ChangeLog' },
                { 'project' : 'skymasterd', 'path' : 'SandStorm/skymasterd', 'log' : 'SandStorm/skymasterd/ChangeLog' },
                { 'project' : 'skyobjinfod', 'path' : 'SandStorm/skyobjinfod', 'log' : 'SandStorm/skyobjinfod/ChangeLog' },
                { 'project' : 'skyregistryd', 'path' : 'SandStorm/skyregistryd', 'log' : 'SandStorm/skyregistryd/ChangeLog' },
                { 'project' : 'skysoapproxyd', 'path' : 'SandStorm/skysoapproxyd', 'log' : 'SandStorm/skysoapproxyd/ChangeLog' },
                { 'project' : 'skysystemd', 'path' : 'SandStorm/skysystemd', 'log' : 'SandStorm/skysystemd/ChangeLog' },
                { 'project' : 'mod_ngobjweb', 'path' : 'SOPE/mod_ngobjweb', 'log' : 'SOPE/mod_ngobjweb/ChangeLog' },
                { 'project' : 'EOControl', 'path' : 'SOPE/skyrix-core/EOControl', 'log' : 'SOPE/skyrix-core/EOControl/ChangeLog' },
                { 'project' : 'NGExtensions', 'path' : 'SOPE/skyrix-core/NGExtensions', 'log' : 'SOPE/skyrix-core/NGExtensions/ChangeLog' },
                { 'project' : 'NGiCal', 'path' : 'SOPE/skyrix-core/NGiCal', 'log' : 'SOPE/skyrix-core/NGiCal/ChangeLog' },
                { 'project' : 'NGLdap', 'path' : 'SOPE/skyrix-core/NGLdap', 'log' : 'SOPE/skyrix-core/NGLdap/ChangeLog' },
                { 'project' : 'NGMime', 'path' : 'SOPE/skyrix-core/NGMime', 'log' : 'SOPE/skyrix-core/NGMime/ChangeLog' },
                { 'project' : 'NGImap4', 'path' : 'SOPE/skyrix-core/NGMime/NGImap4', 'log' : 'SOPE/skyrix-core/NGMime/NGImap4/ChangeLog' },
                { 'project' : 'NGMail', 'path' : 'SOPE/skyrix-core/NGMime/NGMail', 'log' : 'SOPE/skyrix-core/NGMime/NGMail/ChangeLog' },
                { 'project' : 'NGStreams', 'path' : 'SOPE/skyrix-core/NGStreams', 'log' : 'SOPE/skyrix-core/NGStreams/ChangeLog' },
                { 'project' : 'samples', 'path' : 'SOPE/skyrix-core/samples', 'log' : 'SOPE/skyrix-core/samples/ChangeLog' },
                { 'project' : 'NGJavaScript', 'path' : 'SOPE/skyrix-sope/NGJavaScript', 'log' : 'SOPE/skyrix-sope/NGJavaScript/ChangeLog' },
                { 'project' : 'NGObjDOM', 'path' : 'SOPE/skyrix-sope/NGObjDOM', 'log' : 'SOPE/skyrix-sope/NGObjDOM/ChangeLog' },
                { 'project' : 'Dynamic.subproj', 'path' : 'SOPE/skyrix-sope/NGObjDOM/Dynamic.subproj', 'log' : 'SOPE/skyrix-sope/NGObjDOM/Dynamic.subproj/ChangeLog' },
                { 'project' : 'XHTML.subproj', 'path' : 'SOPE/skyrix-sope/NGObjDOM/XHTML.subproj', 'log' : 'SOPE/skyrix-sope/NGObjDOM/XHTML.subproj/ChangeLog' },
                { 'project' : 'NGObjWeb', 'path' : 'SOPE/skyrix-sope/NGObjWeb', 'log' : 'SOPE/skyrix-sope/NGObjWeb/ChangeLog' },
                { 'project' : 'NGHttp', 'path' : 'SOPE/skyrix-sope/NGObjWeb/NGHttp', 'log' : 'SOPE/skyrix-sope/NGObjWeb/NGHttp/ChangeLog' },
                { 'project' : 'NGXmlRpc', 'path' : 'SOPE/skyrix-sope/NGObjWeb/NGXmlRpc', 'log' : 'SOPE/skyrix-sope/NGObjWeb/NGXmlRpc/ChangeLog' },
                { 'project' : 'NGScripting', 'path' : 'SOPE/skyrix-sope/NGScripting', 'log' : 'SOPE/skyrix-sope/NGScripting/ChangeLog' },
                { 'project' : 'TestSite', 'path' : 'SOPE/skyrix-sope/samples/TestSite', 'log' : 'SOPE/skyrix-sope/samples/TestSite/ChangeLog' },
                { 'project' : 'WOxExtTest', 'path' : 'SOPE/skyrix-sope/samples/WOxExtTest', 'log' : 'SOPE/skyrix-sope/samples/WOxExtTest/ChangeLog' },
                { 'project' : 'SxComponents', 'path' : 'SOPE/skyrix-sope/SxComponents', 'log' : 'SOPE/skyrix-sope/SxComponents/ChangeLog' },
                { 'project' : 'WEExtensions', 'path' : 'SOPE/skyrix-sope/WEExtensions', 'log' : 'SOPE/skyrix-sope/WEExtensions/ChangeLog' },
                { 'project' : 'WOExtensions', 'path' : 'SOPE/skyrix-sope/WOExtensions', 'log' : 'SOPE/skyrix-sope/WOExtensions/ChangeLog' },
                { 'project' : 'CFXMLSaxDriver', 'path' : 'SOPE/skyrix-xml/CFXMLSaxDriver', 'log' : 'SOPE/skyrix-xml/CFXMLSaxDriver/ChangeLog' },
                { 'project' : 'DOM', 'path' : 'SOPE/skyrix-xml/DOM', 'log' : 'SOPE/skyrix-xml/DOM/ChangeLog' },
                { 'project' : 'iCalSaxDriver', 'path' : 'SOPE/skyrix-xml/iCalSaxDriver', 'log' : 'SOPE/skyrix-xml/iCalSaxDriver/ChangeLog' },
                { 'project' : 'libxmlSAXDriver', 'path' : 'SOPE/skyrix-xml/libxmlSAXDriver', 'log' : 'SOPE/skyrix-xml/libxmlSAXDriver/ChangeLog' },
                { 'project' : 'pyxSAXDriver', 'path' : 'SOPE/skyrix-xml/pyxSAXDriver', 'log' : 'SOPE/skyrix-xml/pyxSAXDriver/ChangeLog' },
                { 'project' : 'samples', 'path' : 'SOPE/skyrix-xml/samples', 'log' : 'SOPE/skyrix-xml/samples/ChangeLog' },
                { 'project' : 'SaxObjC', 'path' : 'SOPE/skyrix-xml/SaxObjC', 'log' : 'SOPE/skyrix-xml/SaxObjC/ChangeLog' },
                { 'project' : 'XmlRpc', 'path' : 'SOPE/skyrix-xml/XmlRpc', 'log' : 'SOPE/skyrix-xml/XmlRpc/ChangeLog' },
                { 'project' : 'Themes', 'path' : 'Themes', 'log' : 'Themes/ChangeLog' },
                { 'project' : 'FrontBase2', 'path' : 'ThirdParty/gnustep-db/FrontBase2', 'log' : 'ThirdParty/gnustep-db/FrontBase2/ChangeLog' },
                { 'project' : 'GDLAccess', 'path' : 'ThirdParty/gnustep-db/GDLAccess', 'log' : 'ThirdParty/gnustep-db/GDLAccess/ChangeLog' },
                { 'project' : 'GDLExtensions', 'path' : 'ThirdParty/gnustep-db/GDLAccess/GDLExtensions', 'log' : 'ThirdParty/gnustep-db/GDLAccess/GDLExtensions/ChangeLog' },
                { 'project' : 'PostgreSQL72', 'path' : 'ThirdParty/gnustep-db/PostgreSQL72', 'log' : 'ThirdParty/gnustep-db/PostgreSQL72/ChangeLog' },
                { 'project' : 'gnustep-make', 'path' : 'ThirdParty/gnustep-make', 'log' : 'ThirdParty/gnustep-make/ChangeLog' },
                { 'project' : 'gnustep-objc', 'path' : 'ThirdParty/gnustep-objc', 'log' : 'ThirdParty/gnustep-objc/ChangeLog' },
                { 'project' : 'js-1.5', 'path' : 'ThirdParty/js-1.5', 'log' : 'ThirdParty/js-1.5/ChangeLog' },
                { 'project' : 'libFoundation', 'path' : 'ThirdParty/libFoundation', 'log' : 'ThirdParty/libFoundation/ChangeLog' },
                { 'project' : 'libical', 'path' : 'ThirdParty/libical', 'log' : 'ThirdParty/libical/ChangeLog' },
                { 'project' : 'python', 'path' : 'ThirdParty/libical/src/python', 'log' : 'ThirdParty/libical/src/python/ChangeLog' },
                { 'project' : 'libxml2', 'path' : 'ThirdParty/libxml2', 'log' : 'ThirdParty/libxml2/ChangeLog' },
                { 'project' : 'nhsc', 'path' : 'ThirdParty/nhsc', 'log' : 'ThirdParty/nhsc/ChangeLog' },
                { 'project' : 'pilot-link', 'path' : 'ThirdParty/pilot-link', 'log' : 'ThirdParty/pilot-link/ChangeLog' },
                { 'project' : 'pyxmlrpc', 'path' : 'ThirdParty/pyxmlrpc', 'log' : 'ThirdParty/pyxmlrpc/ChangeLog' },
                { 'project' : 'Tools', 'path' : 'Tools', 'log' : 'Tools/ChangeLog' },
                { 'project' : 'AdminUI', 'path' : 'WebUI/AdminUI', 'log' : 'WebUI/AdminUI/ChangeLog' },
                { 'project' : 'BaseUI', 'path' : 'WebUI/Common/BaseUI', 'log' : 'WebUI/Common/BaseUI/ChangeLog' },
                { 'project' : 'OGoUIElements', 'path' : 'WebUI/Common/OGoUIElements', 'log' : 'WebUI/Common/OGoUIElements/ChangeLog' },
                { 'project' : 'PropertiesUI', 'path' : 'WebUI/Common/PropertiesUI', 'log' : 'WebUI/Common/PropertiesUI/ChangeLog' },
                { 'project' : 'AddressUI', 'path' : 'WebUI/Contact/AddressUI', 'log' : 'WebUI/Contact/AddressUI/ChangeLog' },
                { 'project' : 'EnterprisesUI', 'path' : 'WebUI/Contact/EnterprisesUI', 'log' : 'WebUI/Contact/EnterprisesUI/ChangeLog' },
                { 'project' : 'LDAPAccounts', 'path' : 'WebUI/Contact/LDAPAccounts', 'log' : 'WebUI/Contact/LDAPAccounts/ChangeLog' },
                { 'project' : 'PersonsUI', 'path' : 'WebUI/Contact/PersonsUI', 'log' : 'WebUI/Contact/PersonsUI/ChangeLog' },
                { 'project' : 'JobUI', 'path' : 'WebUI/JobUI', 'log' : 'WebUI/JobUI/ChangeLog' },
                { 'project' : 'LSWMail', 'path' : 'WebUI/Mailer/LSWMail', 'log' : 'WebUI/Mailer/LSWMail/ChangeLog' },
                { 'project' : 'OGoMailInfo', 'path' : 'WebUI/Mailer/OGoMailInfo', 'log' : 'WebUI/Mailer/OGoMailInfo/ChangeLog' },
                { 'project' : 'OGoMailViewers', 'path' : 'WebUI/Mailer/OGoMailViewers', 'log' : 'WebUI/Mailer/OGoMailViewers/ChangeLog' },
                { 'project' : 'OGoWebMail', 'path' : 'WebUI/Mailer/OGoWebMail', 'log' : 'WebUI/Mailer/OGoWebMail/ChangeLog' },
                { 'project' : 'NewsUI', 'path' : 'WebUI/NewsUI', 'log' : 'WebUI/NewsUI/ChangeLog' },
                { 'project' : 'OGoForms', 'path' : 'WebUI/OGoForms', 'log' : 'WebUI/OGoForms/ChangeLog' },
                { 'project' : 'OGoFoundation', 'path' : 'WebUI/OGoFoundation', 'log' : 'WebUI/OGoFoundation/ChangeLog' },
                { 'project' : 'OpenGroupware.org', 'path' : 'WebUI/OpenGroupware.org', 'log' : 'WebUI/OpenGroupware.org/ChangeLog' },
                { 'project' : 'PreferencesUI', 'path' : 'WebUI/PreferencesUI', 'log' : 'WebUI/PreferencesUI/ChangeLog' },
                { 'project' : 'LSWProject', 'path' : 'WebUI/Project/LSWProject', 'log' : 'WebUI/Project/LSWProject/ChangeLog' },
                { 'project' : 'OGoDocInlineViewers', 'path' : 'WebUI/Project/OGoDocInlineViewers', 'log' : 'WebUI/Project/OGoDocInlineViewers/ChangeLog' },
                { 'project' : 'OGoNote', 'path' : 'WebUI/Project/OGoNote', 'log' : 'WebUI/Project/OGoNote/ChangeLog' },
                { 'project' : 'OGoProject', 'path' : 'WebUI/Project/OGoProject', 'log' : 'WebUI/Project/OGoProject/ChangeLog' },
                { 'project' : 'OGoProjectForms', 'path' : 'WebUI/Project/OGoProjectForms', 'log' : 'WebUI/Project/OGoProjectForms/ChangeLog' },
                { 'project' : 'OGoProjectInfo', 'path' : 'WebUI/Project/OGoProjectInfo', 'log' : 'WebUI/Project/OGoProjectInfo/ChangeLog' },
                { 'project' : 'OGoProjectZip', 'path' : 'WebUI/Project/OGoProjectZip', 'log' : 'WebUI/Project/OGoProjectZip/ChangeLog' },
                { 'project' : 'Resources', 'path' : 'WebUI/Resources', 'log' : 'WebUI/Resources/ChangeLog' },
                { 'project' : 'LSWScheduler', 'path' : 'WebUI/Scheduler/LSWScheduler', 'log' : 'WebUI/Scheduler/LSWScheduler/ChangeLog' },
                { 'project' : 'OGoResourceScheduler', 'path' : 'WebUI/Scheduler/OGoResourceScheduler', 'log' : 'WebUI/Scheduler/OGoResourceScheduler/ChangeLog' },
                { 'project' : 'OGoScheduler', 'path' : 'WebUI/Scheduler/OGoScheduler', 'log' : 'WebUI/Scheduler/OGoScheduler/ChangeLog' },
                { 'project' : 'OGoSchedulerDock', 'path' : 'WebUI/Scheduler/OGoSchedulerDock', 'log' : 'WebUI/Scheduler/OGoSchedulerDock/ChangeLog' },
                { 'project' : 'OGoSchedulerViews', 'path' : 'WebUI/Scheduler/OGoSchedulerViews', 'log' : 'WebUI/Scheduler/OGoSchedulerViews/ChangeLog' },
                { 'project' : 'AdminDaemon', 'path' : 'XmlRpcAPI/AdminDaemon', 'log' : 'XmlRpcAPI/AdminDaemon/ChangeLog' },
                { 'project' : 'Daemon', 'path' : 'XmlRpcAPI/Daemon', 'log' : 'XmlRpcAPI/Daemon/ChangeLog' },
                { 'project' : 'Backend', 'path' : 'ZideStore/Backend', 'log' : 'ZideStore/Backend/ChangeLog' },
                { 'project' : 'ZideStore', 'path' : 'ZideStore', 'log' : 'ZideStore/ChangeLog' },
                { 'project' : 'EvoConnect', 'path' : 'ZideStore/EvoConnect', 'log' : 'ZideStore/EvoConnect/ChangeLog' },
                { 'project' : 'Frontend', 'path' : 'ZideStore/Frontend', 'log' : 'ZideStore/Frontend/ChangeLog' },
                { 'project' : 'PrefsUI', 'path' : 'ZideStore/PrefsUI', 'log' : 'ZideStore/PrefsUI/ChangeLog' },
            ],
}
