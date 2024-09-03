## OpenGroupware.org

OGo is a groupware server for Unix like operation systems.
It has very rich functionality, extensive APIs, 
but unfortunately a very old Web 1.0 user interface.

This is the
[SOPE](https://github.com/OpenGroupware/SOPE)
based Objective-C version.

There is also a more "modern" Java implementation of the logic layer,
called [OGoCore](https://github.com/OpenGroupware/OGoCore)
which works on the same database / alongside the Objective-C version.

OGo can work on top of a set of databases, from MySQL to Oracle, but the
recommended backend is [PostgreSQL](https://www.postgresql.org).



### Modules

#### Contact Management

Saves and organizes thousands of personal and company contacts, telephone, 
fax, addresses, e-mail contact addresses just to mention a few. Easily 
configurable with extensive and speedy search capabilities, categorization 
and remotely accessible.

#### Group Calendar

Manage meetings and events for an entire group or individual set of accounts. 
Attach notes to appointments. Link appointments to contacts and projects. 
Automatic detection of conflicts.

#### Resource Planner

Keep track of your company's resources such as automobiles, projectors or 
conference rooms. Searchable timeslots to check for availability of specific 
resources or resources assigned to a specific group. Automatically check for 
resource conflicts upon appointment creation. 

#### Task Management

You may organize tasks by person, group or specific project. "Todo" lists can 
be ordered by priority, due date, processing status etc. An overview of all 
tasks is stored in the projects application as well as sorted by company. 
All tasks are also summarized on the personal page.

#### E-Mail Client

The integrated (IMAP4 based) e-mail client offers a comfortable environment for 
reading and creating e-mails as well as organizing email by folders. A 
global, and configurable contact directory eliminates the endless search for 
the correct e-mail address.

#### Projects and Documents

Share documents and files, locally or remotely, in groups or privately in a 
project centric environment. Link projects to customer or employee contacts 
and or link tasks to projects. Store email, Office documents such as faxes in 
the document archive which can be associated with any project. Finally, link 
any OGo application with your project. A true project centric environment. 

#### News

The Newsboard gives you the opportunity to publish important information or 
articles to the Intranet. Defineable headlines that can be linked to other 
related articles or news items. In addition, the Newsboard shows upcoming 
appointments and tasks and serves as a personal page.

#### Palm Sync

Using the Palm application you can synchronize data from your Palm device to 
the other OGo applications. Use the Palm application to resolve remote 
synchronization conflicts and to configure how and when Palm data is 
synchronized with the global enterprise database.

#### Preferences

The OGo user interface is highly configurable by the user or administrator. 
The Preferences application manages all the various options available for the 
applications similar in design to a Windows or KDE control panel. 

#### Usermanager

Management of accounts, groups and configurations for OGo are done using a 
simple and intuitive web interface. Easily create teams, location teams and 
accounts, resources and resource groups or configure server options. The OGo 
Usermanager Application provides extremely fine grained configuration 
options. 

#### Modular

Thats it? No! OpenGroupware.org is an extensible application and portal
server. All the available applications are implemented as plugins to the
main server and can be extended and enhanced in various ways.


### Building OGo

- for an overview over the source tree, take a look at the OVERVIEW file

- for build instructions, go to the developer section on 
  http://www.opengroupware.org/

- to contact the OGo developers, join one of the mailing lists available on
  http://www.opengroupware.org/


### History

OGo was the OpenSource release of the "SKYRIX Groupware Server" written at the 
SKYRIX Software AG in the late nineties.

At the time it was quite popular and widely deployed.

Development mostly slowed down around 2006 and essentially stopped at
the end of 2009.
As of 2024, it is still in heavy use at some companies though :-)

In the late days there was also a Java version of the logic called 
[OGoCore](https://github.com/OpenGroupware/OGoCore),
and a few things around that, like a JSON API. 
But that didn't get maintainance either.

2024-09-03 Let's see whether we can revive it!


### License and Copyright Information

License and copyright information for the various modules are contained
in the appropriate

    COPYRIGHT
    
and

    COPYING / COPYING.LIB

files. Except for modules contained in the ThirdParty directory, most
sources are licensed under the GNU Lesser General Public License and
the copyright is owned by SKYRIX Software AG.


### Contact

[@helge@mastodon.social](https://mastodon.social/@helge)
