/*
  Copyright (C) 2000-2005 SKYRIX Software AG

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

#include "LSWPreferencesEditor.h"
#include <OGoFoundation/LSWNotifications.h>
#include <OGoBase/LSCommandContext+Doc.h>
#include "common.h"

// TODO: more cleanups!

@interface LSWPreferencesEditor(PrivateMethods)
- (BOOL)isRootEdited;
- (BOOL)isLoginEditable;
- (BOOL)isAccountErasable;
@end

@interface LSWPreferencesEditor(AccountLog)
- (void)_logChangesOnAccount:(id)_eo;
@end /* LSWPreferencesEditor(AccountLog) */

@implementation LSWPreferencesEditor

static NSNumber *yesNum             = nil;
static NSNumber *tmplUserID         = nil;
static BOOL     IsMailConfigEnabled = NO;
static NSArray  *UserDefKeys        = nil;

+ (void)initialize {
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  
  if (yesNum     == nil) yesNum     = [[NSNumber numberWithBool:YES] retain];
  if (tmplUserID == nil) tmplUserID = [[NSNumber numberWithInt:9999] retain];

  IsMailConfigEnabled = [ud boolForKey:@"MailConfigEnabled"];
  UserDefKeys = [[ud arrayForKey:@"usermanager_newreccopydefnames"] copy];
}

- (void)dealloc {
  [self->teams            release];
  [self->data             release];
  [self->filePath         release];
  [self->item             release];
  [self->popupItem        release];
  [self->selectedTeams    release];
  [self->categories       release];
  [self->templateUsers    release];
  [self->defaults         release];
  [self->localDomains     release];
  [super dealloc];
}

/* operations */

- (void)clearEditor {
  [self->data       release];   self->data       = nil;
  [self->filePath   release];   self->filePath   = nil;
  [self->categories release];   self->categories = nil;
  [self->localDomains release]; self->localDomains = nil;
  [super clearEditor];
}

/* activation */

- (BOOL)prepareForActivationCommand:(NSString *)_command
  type:(NGMimeType *)_type
  configuration:(NSDictionary *)_cmdCfg
{
  /* prepare templateUser */
  NSArray      *tmpUser;
  NSEnumerator *enumerator;
  id           tmp;

  [self->templateUsers release]; self->templateUsers = nil;
    
  tmpUser = [self runCommand:
                    @"account::get",
                    @"isTemplateUser",  yesNum,
                    @"returnType", intObj(LSDBReturnType_ManyObjects), 
                    nil];
  self->templateUsers = (id)
    [[NSMutableDictionary alloc] initWithCapacity:[tmpUser count]];
  
  enumerator = [tmpUser objectEnumerator];
  while ((tmp = [enumerator nextObject])) {
      [(id)self->templateUsers setObject:[tmp objectForKey:@"companyId"]
           forKey:[tmp objectForKey:@"login"]];
  }
  tmp = self->templateUsers;
  self->templateUsers = [tmp copy];
  [tmp release]; tmp = nil;
    
  return [super prepareForActivationCommand:_command type:_type
                configuration:_cmdCfg];
}

- (BOOL)prepareForNewCommand:(NSString *)_command
  type:(NGMimeType *)_type
  configuration:(NSDictionary *)_cmdCfg
{
  NSArray *ts;
  int     i, cnt;
  
  [self->selectedTeams release]; self->selectedTeams = nil;
  [self->teams         release]; self->teams         = nil;
  
  self->selectedTeams = [[NSMutableArray alloc] init];
  self->teams         = [[NSMutableArray alloc] init];
  
  // TODO: replace with command call!
  ts = [[self session] teams];
  for (i = 0, cnt = [ts count]; i < cnt; i++) {
    id   t;
    BOOL isLT;

    t    = [ts objectAtIndex:i];
    isLT = [[t valueForKey:@"isLocationTeam"] boolValue];
      
    if (!isLT)
      [self->teams addObject:t];
  }

  [self->defaults release]; self->defaults = nil;
  self->defaults = [[self runCommand:@"userdefaults::get", nil] retain];
  return YES;
}

- (BOOL)prepareForEditCommand:(NSString *)_command
  type:(NGMimeType *)_type
  configuration:(NSDictionary *)_cmdCfg
{
  WOSession *s;
  id        obj;
  
  s   = [self session];
  obj = [self object];

  [self runCommand:
        @"account::teams",
        @"object",     obj,
        @"returnType", intObj(LSDBReturnType_ManyObjects), 
        nil];

  ASSIGN(self->selectedTeams, nil);
  ASSIGN(self->categories,    nil);
  ASSIGN(self->teams,         nil);
  
  self->selectedTeams = [[self runCommand:@"account::teams",
                               @"account", obj, nil] mutableCopy];
  self->categories    = [[NSMutableArray alloc] init];
  self->teams         = [[NSMutableArray alloc] init];
  {
    NSArray *c;
    int     i, cnt;

    c   = [s categories];
    cnt = [c count];

    for (i = 0; i < cnt; i++) {
      NSString *cName;

      cName = [[[c objectAtIndex:i] valueForKey:@"category"] copy];
      [self->categories addObject:[cName autorelease]];
    }
  }
  {
    NSArray *ts;
    int     i, cnt;

    ts  = [s teams];
    cnt = [ts count];

    for (i = 0; i < cnt; i++) {
      id   t;
      BOOL isLT;

      t    = [ts objectAtIndex:i];
      isLT = [[t valueForKey:@"isLocationTeam"] boolValue];

      if (!isLT)
        [self->teams addObject:t];
    }
  } 
  // copy extended attribute email1 to snapshot
  {
    id value;

    value = [obj valueForKey:@"email1"];
    
    if (value == nil) {
      value = [[self runCommand:
                       @"companyvalue::new",
                       @"companyId", [obj valueForKey:@"companyId"],
                       @"attribute", @"email1", nil]
                     valueForKey:@"value"];
    }
    [[self snapshot] takeValue:value forKey:@"email1"];
  }
  ASSIGN(self->defaults, nil);
  self->defaults =   obj 
    ? [self runCommand:@"userdefaults::get", @"user", obj, nil]
    : [self runCommand:@"userdefaults::get", nil];

  [self->defaults retain];
  return YES;
}

/* accessors */

- (void)setData:(id)_data { // TODO: probably unused now
  ASSIGN(self->data, _data);
}
- (id)data { // TODO: probably unused now
  return self->data;
}

- (void)setFilePath:(id)_path {  // TODO: probably unused now
  ASSIGN(self->filePath, _path);
}
- (id)filePath { // TODO: probably unused now
  return self->filePath;
}
 
- (void)setCategoryList:(NSString *)_categoryList {
  NSArray *c;
  int     i, cnt;
  
  [self->categories removeAllObjects];

  if (![_categoryList isNotNull])
    _categoryList = nil;
  
  if (_categoryList == nil)
    return;
    
  c = [_categoryList componentsSeparatedByString:@"\n"];
  for (i = 0, cnt = [c count]; i < cnt; i++) {
    NSString *cName;

    cName = [c objectAtIndex:i];      

    if ([cName hasSuffix:@"\r"]) {
      // TODO: Unicode?
      cName = [NSString stringWithCString:[cName cString]
			length:([cName length] - 1)];
    }
    if ([cName length] > 0)
      [self->categories addObject:cName];
  }
}

- (NSString *)categoryList {
  return [self->categories componentsJoinedByString:@"\n"];
}

- (NSArray *)teams {
  return self->teams;
}

- (id)item {
  return self->item;
}
- (void)setItem:(id)_itm {
  ASSIGN(self->item, _itm);
}

- (int)idx {
  return self->idx;
}
- (void)setIdx:(int)_idx {
  self->idx = _idx;
}

- (NSString *)preferencesLabel {
  NSString *label;

  label = [self->item objectForKey:@"DefaultName"];
  label = [[self labels] valueForKey:label];
  if (label == nil)
    label = [self->item objectForKey:@"DefaultName"];
  
  return label;
}

- (id)popupItem {
  return self->popupItem;
}
- (void)setPopupItem:(id)_itm {
  ASSIGN(self->popupItem, _itm);
}

- (NSString *)loginName {
  NSDictionary *snp;
  NSString     *firstname, *userName;
  
  snp       = [self snapshot];
  firstname = [snp valueForKey:@"firstname"];
  userName  = [snp valueForKey:@"name"];
  
  if ([self isInNewMode])
    return [[self labels] valueForKey:@"newAccount"];

  return (firstname == nil)
    ? userName
    : [NSString stringWithFormat:@"%@ %@", firstname, userName];
}

- (NSString *)rootOnlyLabel {
  NSString *prefLabel;

  prefLabel = [self preferencesLabel];
  return [NSString stringWithFormat:@"<%@>", prefLabel];
}

- (id)cancel {
  [self leavePage];
  return nil;
}

- (NSDictionary *)account {
  return [self snapshot];
}

- (void)setLocationTeam:(id)_team {
  [self->selectedTeams removeObjectsInArray:[[self session] locationTeams]];
  if (_team)
    [self->selectedTeams addObject:_team];
}
- (id)locationTeam {
  NSArray      *myTeams;
  int          i, cnt;
  unsigned int tidx;
  id           myTeam;
  
  myTeams = [[self session] locationTeams];
  cnt     = [myTeams count];
  tidx    = NSNotFound;
  myTeam  = nil;
  
  for (i = 0; i < cnt; i++) {
    myTeam = [myTeams objectAtIndex:i];
    
    tidx = [self->selectedTeams indexOfObject:myTeam];
    if (tidx != NSNotFound)
      break;
  }
  return (tidx != NSNotFound) ? myTeam : nil;
}

- (BOOL)isInGroup {
  return [self->selectedTeams containsObject:self->item];
}

- (NSMutableArray*)selectedTeams {
  return  self->selectedTeams ;
}

- (void)setSelectedTeams:(NSMutableArray*)_team {
  ASSIGN(self->selectedTeams,_team);
}

- (void)setIsInGroup:(BOOL)_value { 
  if (_value == YES) {
    if (![self->selectedTeams containsObject:self->item])
      [self->selectedTeams addObject:self->item];
  }
  else
    [self->selectedTeams removeObject:self->item];
}

- (void)setIsExtraAccount:(BOOL)_acc {
  [[self snapshot] takeValue:[NSNumber numberWithBool:_acc]
                   forKey:@"isExtraAccount"];
}
- (BOOL)isExtraAccount {
  return [[[self snapshot] valueForKey:@"isExtraAccount"] boolValue];
}

- (void)setIsLocked:(BOOL)_lck {
  [[self snapshot] takeValue:[NSNumber numberWithBool:_lck]
                   forKey:@"isLocked"];
}
- (BOOL)isLocked {
  return [[[self snapshot] valueForKey:@"isLocked"] boolValue];
}
- (void)setIsTemplateUser:(BOOL)_lck {
  [[self snapshot] takeValue:[NSNumber numberWithBool:_lck]
                   forKey:@"isTemplateUser"];
}
- (BOOL)isTemplateUser {
  return [[[self snapshot] valueForKey:@"isTemplateUser"] boolValue];
}

- (BOOL)isRootEdited {
  WOSession *sn;

  sn = [self session];
  
  return [sn activeAccountIsRoot] &&
    [[self object] isEqual:[sn activeAccount]];
}

- (BOOL)isLoginEditable {
  NSString *login;

  if ([self isTemplateUser])
    return YES;
  
  if ([LSCommandContext useLDAPAuthorization])
    return NO;
  
  login = [[self account] valueForKey:@"login"];
  
  return ([login isEqualToString:@"nobody"]) ? NO : YES;
}

- (BOOL)isAccountErasable {
  NSString *login;

  login = [[self account] valueForKey:@"login"];
  
  return ([login isEqualToString:@"nobody"] ||
          [[[self account] valueForKey:@"isTemplateUser"] boolValue])
    ? NO : YES;
}

- (BOOL)isAccountLoggedIn {
  return [[self object] isEqual:[[self session] activeAccount]];
}

- (BOOL)useLDAPAuthorization {
  return [LSCommandContext useLDAPAuthorization];
}

- (BOOL)showDeleteButton {
  /*
              <#IsAccountErasable>
  */
  if ([self isInNewMode])                    return NO;
  if (![[self session] activeAccountIsRoot]) return NO;
  if ([self isRootEdited])                   return NO;
  return [self isAccountErasable];
}

- (NSString *)windowTitle {
  WOSession *sn;
  id        l;

  sn = [self session];
  l  = [self labels];

  if ([sn activeAccountIsRoot] &&
      ![[self object] isEqual:[sn activeAccount]]) {
    return [l valueForKey:@"accountEditor"];
  }
  return [l valueForKey:@"preferencesEditor"];
}

/* notification */

- (NSString *)insertNotificationName {
  return LSWNewAccountNotificationName;
}
- (NSString *)updateNotificationName {
  return LSWUpdatedAccountNotificationName;
}
- (NSString *)deleteNotificationName {
  return LSWDeletedAccountNotificationName;
}

/* actions */

- (BOOL)checkConstraints {
  NSMutableString *error;
  NSString        *login, *lname;
  BOOL            tmpl;
  id              l;

  l     = [self labels];
  error = [NSMutableString stringWithCapacity:128];
  login = [[self snapshot] valueForKey:@"login"];
  lname = [[self snapshot] valueForKey:@"name"];
  tmpl  = [[[self snapshot] valueForKey:@"isTemplateUser"] boolValue];
  
  if (![login isNotNull] || [login length] == 0)
    [error appendFormat:@" %@.", [l valueForKey:@"No login set"]];

  if ((![lname isNotNull] || [lname length] == 0) && (tmpl == NO))
    [error appendFormat:@" %@.", [l valueForKey:@"No last name set"]];

  if ([error length] > 0) {
    [self setErrorString:error];
    return YES;
  }
  {
    id a;

    a = [self runCommand:@"account::get-by-login", @"login", login, nil];

    if ([self isInNewMode]) {
      if (a != nil) {
        [self setErrorString:
              [NSString stringWithFormat:
                        [l valueForKey:@"Account with login '%@' "                           @"already exists."], login]];
        return YES;
      }
    }
    else if ([a isNotNull]) {
      if (![[a valueForKey:@"companyId"]
               isEqual:[[self object] valueForKey:@"companyId"]]) {
	NSString *s;
	
	// TODO: rather weird label-key!
	s = [l valueForKey:
		 @"Couldn`t edit login. "
	         @"Account with login '%@' already exists."];
	s = [NSString stringWithFormat:s, login];
	[self setErrorString:s];
        return YES;
      }
    }
  }
  [self setErrorString:nil];
  return NO;
}

- (BOOL)checkConstraintsForSave {
  return ![self checkConstraints];
}

- (id)insertObject {
  id       account;
  NSNumber *ownerId;
  
  account = [self snapshot];
  ownerId = [[[self session] activeAccount] valueForKey:@"companyId"];
  
  if ([[account valueForKey:@"isTemplateUser"] boolValue]) {
    [account takeValue:yesNum  forKey:@"isLocked"];
    [account takeValue:yesNum  forKey:@"isReadonly"];
    [account takeValue:yesNum  forKey:@"isPrivate"];
    [account takeValue:[account valueForKey:@"login"] forKey:@"name"];
    [account takeValue:@"template"                    forKey:@"description"];
  }
  
  [account takeValue:ownerId             forKey:@"ownerId"];
  [account takeValue:self->selectedTeams forKey:@"groups"];

  if (self->data != nil && self->filePath != nil && [self->data length] > 0) {
    [account takeValue:self->data     forKey:@"data"];
    [account takeValue:self->filePath forKey:@"filePath"];
  }
  
  account = [self runCommand:@"account::new" arguments:account];
  [self _logChangesOnAccount:account];
  return account;
}

- (id)updateObject {
  id account;
  id obj, groups;

  obj    = [self object];
  groups = [obj valueForKey:@"groups"];
    
  if ([groups isNotNull]) {
    NSEnumerator *enumerator;
    id           o;

    enumerator = [groups objectEnumerator];
    while ((o = [enumerator nextObject])) {
      NSArray *mem;

      mem = [o valueForKey:@"members"];
      if (![mem isNotNull])
	continue;
      
      if ([mem containsObject:obj] &&
	  ![self->selectedTeams containsObject:mem]) {
	[o takeValue:[NSNull null] forKey:@"members"];
      }
    }
  }
  account = [self snapshot];
  
  [account takeValue:self->selectedTeams forKey:@"groups"];

  if ([[account valueForKey:@"isTemplateUser"] boolValue]) {
    [account takeValue:[account valueForKey:@"login"] forKey:@"name"];
    [account takeValue:@"template"                    forKey:@"description"];
    [account takeValue:[NSArray array]                forKey:@"groups"];
  }

  if (self->data != nil && self->filePath != nil && [self->data length] > 0) {
    [account takeValue:self->data     forKey:@"data"];
    [account takeValue:self->filePath forKey:@"filePath"];
  }
  if ([[self session] activeAccountIsRoot])
    account = [self runCommand:@"account::set" arguments:account];
  else
    account = [self runCommand:@"person::set" arguments:account];

  [account takeValue:self->selectedTeams forKey:@"groups"];
  [self _logChangesOnAccount:account];
  return account;
}

- (BOOL)_saveCategories {
  WOSession *sn;
  
  if (![self isRootEdited])
    return YES;
  
  sn = [self session];
  [self runCommand:
            @"companycategory::set-all",
            @"oldCategories", [sn categories],
            @"newCategories", self->categories, nil];
  [sn fetchCategories];
  return YES;
}

- (id)save {
  id result;
  
  if (![self _saveCategories])
    return nil;
  
  if ((result = [super save]) == nil)
    return nil;
  
  if ([self isInNewMode]) {
    // TODO: explain this
    id           obj, def, key, oldDef;
    NSEnumerator *enumerator;
      
    oldDef = [self runCommand:@"userdefaults::get", nil];
    obj    = [self object];
    def    = [self runCommand:@"userdefaults::get", @"user", obj, nil];
      
    enumerator = [UserDefKeys objectEnumerator];
    while ((key = [enumerator nextObject]) != nil) {
        id value;

        value = [self->defaults objectForKey:key];
        
        if ([self isTemplateUser]) {
          [def setObject:value forKey:key];
        }
        else {
          if (![[oldDef objectForKey:key] isEqual:value])
            [def setObject:value forKey:key];
        }
    }
    ASSIGN(self->defaults, def);
  }
  [self->defaults synchronize];
  return result;
}

- (id)deleteObject {
  return [[self object] run:@"account::delete", @"reallyDelete", yesNum, nil];
}

- (id)changePassword {
  [self save];
  return [self activateObject:[self object] withVerb:@"editAccountPassword"];
}

- (NSArray *)templateUserNames {
  return [self->templateUsers allKeys];
}

- (id)templateUserId {
  NSNumber *n;
  
  n = [[self snapshot] valueForKey:@"templateUserId"];
  
  if (![n isNotNull]) 
    n = tmplUserID;
  
  return [[self->templateUsers allKeysForObject:n] lastObject]; 
}

- (void)setTemplateUserId:(id)_id {
  [[self snapshot] takeValue:[self->templateUsers objectForKey:_id]
                   forKey:@"templateUserId"];
}

- (id)defaults {
  if (self->defaults == nil)
    [self logWithFormat:@"WARNING: no defaults available!"];
  return self->defaults;
}

- (NSArray *)localDomains {
  NSDictionary   *dict;
  NSUserDefaults *ud;
  
  if (self->localDomains)
    return self->localDomains;

  ud = [NSUserDefaults standardUserDefaults];
  [ud removePersistentDomainForName:@"MTA"]; /* prevent caching */
  
  dict = [ud persistentDomainForName:@"MTA"];
  self->localDomains = [[[dict objectForKey:@"administrated domains"]
			       componentsSeparatedByString:@"; "] copy];
  return self->localDomains;
}

- (BOOL)isMailConfigEnabled {
  return IsMailConfigEnabled;
}

@end /* LSWPreferencesEditor */
