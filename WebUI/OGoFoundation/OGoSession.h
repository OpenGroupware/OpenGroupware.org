/*
  Copyright (C) 2000-2004 SKYRIX Software AG

  This file is part of OpenGroupware.org.

  OGo is free software; you can redistribute it and/or modify it under
  the terms of the GNU Lesser General Public License as published by the
  Free Software Foundation; either version 2, or (at your option) any
  later version.

  OGo is distributed in the hope that it will be useful, but WITHOUT ANY
  WARRANTY; without even the implied warranty of MERCHANTABILITY or
  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser General Public
  License for more details.

  You should have received a copy of the GNU Lesser General Public
  License along with OGo; see the file COPYING.  If not, write to the
  Free Software Foundation, 59 Temple Place - Suite 330, Boston, MA
  02111-1307, USA.
*/

#ifndef __OGoFoundation_OGoSession_H__
#define __OGoFoundation_OGoSession_H__

#import <Foundation/NSMapTable.h>
#include <NGObjWeb/WOSession.h>
#include <NGObjWeb/WOComponent.h>

@class NSMutableDictionary, NSDictionary, NSMutableSet, NSNotificationCenter;
@class NSTimeZone, NSFormatter, NSArray, NSUserDefaults, NSMutableArray;
@class NGMimeType;
@class LSSort, LSDBTransaction;
@class EODatabaseChannel, EOAdaptor;
@class WOComponent;
@class OWPasteboard;
@class LSCommandContext, OGoContextSession;
@class OGoNavigation;

@interface OGoSession : WOSession
{
@private
  NSMapTable *name2pb;
  
@private
  OGoContextSession    *lso;
  id                   activeLogin; // EO of login-account
  
  NSMutableDictionary  *componentsConfig;
  OGoNavigation        *navigation;
  LSSort               *eoSorter;
  NSMapTable           *activationCommandToConfig;
  BOOL                 isAwake;
  NSNotificationCenter *notificationCenter;
  NSString             *lastContextId;

  // persistent components
  NSMutableDictionary  *pComponents;

  // shared objects
  NSFormatter          *formatString;
  NSFormatter          *formatDate;
  NSFormatter          *formatTime;
  NSFormatter          *formatDateTime;
  NSFormatter          *formatDateTimeTZ;

  // localization
  NSArray              *accounts;
  NSArray              *allAccounts;
  NSArray              *teams;
  NSArray              *categories;
  NSArray              *categoryNames;
  NSArray              *dockedProjectInfos;

  // favorites
  NSMutableArray       *favorites;
  id                   choosenFavorite;

  // userDefaults
  NSUserDefaults       *userDefaults;
}

/* LSOffice commands */

- (LSCommandContext *)commandContext;

- (LSSort *)eoSorter;

- (id)activeAccount;
- (NSString *)activeLogin;
- (BOOL)activeAccountIsRoot; // TODO: should be replaced with permission-check

/* object labels */

- (NSString *)labelForObject:(id)_object;

- (NSTimeZone *)timeZone;
- (NSArray *)timeZones;

- (OGoNavigation *)navigation;

/* defaults */

- (NSUserDefaults *)userDefaults;

/* localization */

- (void)setPrimaryLanguage:(NSString *)_language;
- (NSString *)primaryLanguage;

@end

@interface WOSession(Pasteboard)

- (OWPasteboard *)pasteboardWithName:(NSString *)_name;
- (OWPasteboard *)pasteboardWithUniqueName;

- (OWPasteboard *)transferPasteboard;
- (void)transferObject:(id)_object owner:(WOComponent *)_owner;
- (NGMimeType *)preferredTransferObjectType;
- (id)getTransferObject;
- (id)removeTransferObject;

@end

@interface WOSession(Activation)

- (WOComponent *)instantiateComponentForCommand:(NSString *)_command
  type:(NGMimeType *)_type;

- (WOComponent *)instantiateComponentForCommand:(NSString *)_command
  type:(NGMimeType *)_type
  object:(id)_object;

@end

@class OWPasteboard, NSArray, NGMimeType;

@interface WOSession(Clipboard)

- (OWPasteboard *)clipboard;
- (NSArray *)clipboardTypesForObject:(id)_object;
- (void)placeInClipboard:(id)_object types:(NSArray *)_types;
- (id)objectInClipboardWithType:(NGMimeType *)_type;
- (void)placeInClipboard:(id)_object;
- (id)objectInClipboard;
- (BOOL)clipboardContainsObject;
- (NSString *)labelForObjectInClipboard;

@end

@class NSString, NSDictionary;

@interface WOSession(Commands)

// running commands

- (id)runCommand1:(NSString *)_command, ...;
- (id)runCommand:(NSString *)_command, ...;
- (id)runCommand:(NSString *)_command arguments:(NSDictionary *)_args;

// Controlling transactions
- (BOOL)commit;
- (BOOL)rollback;
- (BOOL)commitTransaction;   // deprecated
- (BOOL)rollbackTransaction; // deprecated
- (BOOL)isTransactionInProgress;

@end

@class NSArray;

@interface WOSession(UserManagement)

- (void)fetchTeams;
- (void)fetchAccounts;
- (void)fetchAllAccounts;
- (void)fetchCategories;
- (void)fetchResources;
- (void)fetchDockedProjectInfos;
- (NSArray *)teams;
- (NSArray *)locationTeams;
- (NSArray *)teamsWithNames:(NSArray *)_names;
- (NSArray *)accounts;
- (NSArray *)allAccounts;
- (NSArray *)resources;
- (NSArray *)resourceNames;
- (NSArray *)categories;
- (NSArray *)categoryNames;
- (NSArray *)dockProjectInfos;

@end

@class NSFormatter;

@interface WOSession(Formatters)

- (NSFormatter *)formatString;
- (NSFormatter *)formatDate;
- (NSFormatter *)formatTime;
- (NSFormatter *)formatDateTime;
- (NSFormatter *)formatterForValue:(id)_value; // guess formatter

@end

@class NSString;

@interface WOSession(Notifications)

- (void)postChange:(NSString *)_changeName onObject:(id)_object;

- (void)addObserver:(id)observer selector:(SEL)selector 
  name:(NSString*)notificationName object:(id)object;
- (void)removeObserver:(id)observer 
  name:(NSString*)notificationName object:(id)object;
- (void)removeObserver:(id)observer;

@end

@interface WOSession(Favorites)

- (void)addFavorite:(id)_fav;
- (void)removeFavorite:(id)_fav;
- (NSArray *)favorites;

@end

@interface WOSession(PageManagement)

- (WOComponent *)restorePageForContextID:(NSString *)_idx;
- (void)savePage:(WOComponent *)_page;

@end

@interface WOSession(PersistentComponents)

- (NSMutableDictionary *)pComponents;

@end

@interface WOComponent(PersistentComponents)

- (id)persistentInstance;
- (void)registerAsPersistentInstance;

@end

#endif /* __OGoFoundation_OGoSession_H__ */
