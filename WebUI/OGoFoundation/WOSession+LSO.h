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

#ifndef __OGoFoundation_WOSession_LSO_H__
#define __OGoFoundation_WOSession_LSO_H__

#include <NGObjWeb/WOSession.h>

@class NSString, NSDictionary, NSTimeZone, NSArray, NSFormatter;
@class NSUserDefaults;
@class EOAdaptor;
@class NGMimeType;
@class WOComponent;
@class OWPasteboard;
@class OGoNavigation, OGoClipboard;

@interface WOSession(LSOffice)

/* command in 'domain::cmd' form */
- (id)runCommand:(NSString *)_command,...;              
- (id)runCommand:(NSString *)_command arguments:(NSDictionary *)_args;

/* Controlling transactions (no begin required) */
- (BOOL)commit;
- (BOOL)rollback;
- (BOOL)isTransactionInProgress;

/* clipboard */

- (OWPasteboard *)clipboard;
- (NSArray *)clipboardTypesForObject:(id)_object;
- (void)placeInClipboard:(id)_object types:(NSArray *)_types;
- (id)objectInClipboardWithType:(NGMimeType *)_type;
- (void)placeInClipboard:(id)_object;
- (id)objectInClipboard;
- (BOOL)clipboardContainsObject;

/* favorites */

- (OGoClipboard *)favorites;
- (id)chosenFavorite;

/* object labels */

- (NSString *)labelForObject:(id)_object;
- (NSString *)labelForObjectInClipboard;

/* defaults */

- (NSUserDefaults *)userDefaults;

/* pasteboard */

- (OWPasteboard *)transferPasteboard;
- (void)transferObject:(id)_object owner:(WOComponent *)_owner;
- (NGMimeType *)preferredTransferObjectType;
- (id)getTransferObject;
- (id)removeTransferObject;

/* activation */

- (WOComponent *)instantiateComponentForCommand:(NSString *)_command
  type:(NGMimeType *)_type;

/* common vars */

- (NSArray *)categories;
- (NSArray *)categoryNames;
- (void)fetchCategories;
- (NSArray *)resources;
- (NSArray *)resourceNames;
- (void)fetchResources;

/* teams */

- (NSArray *)teams;
- (NSArray *)locationTeams;
- (NSArray *)teamsWithNames:(NSArray *)_names;
- (void)fetchTeams;

/* accounts */

- (id)activeAccount;
- (BOOL)activeAccountIsRoot;
- (NSArray *)accounts;
- (void)fetchAccounts;

/* timezones */

- (NSTimeZone *)timeZone;
- (NSArray *)timeZones;

/* configurations */

- (id)configValueForKey:(NSString *)_key 
  inComponent:(WOComponent *)_component;
- (NSDictionary *)componentConfig;
- (NSDictionary *)componentAttributes;

/* formatting */

- (NSFormatter *)formatString;
- (NSFormatter *)formatTime;
- (NSFormatter *)formatDate;
- (NSFormatter *)formatDateTime;
- (NSFormatter *)formatterForValue:(id)_value;

/* misc */

- (OGoNavigation *)navigation;

/* notifications */

- (void)postChange:(NSString *)_change onObject:(id)_obj;

@end

@interface WOSession(OGoSessionPasteboard)

- (OWPasteboard *)transferPasteboard;
- (void)transferObject:(id)_object owner:(WOComponent *)_owner;
- (NGMimeType *)preferredTransferObjectType;
- (id)getTransferObject;
- (id)removeTransferObject;

@end

#endif /* __OGoFoundation_WOSession_LSO_H__ */
