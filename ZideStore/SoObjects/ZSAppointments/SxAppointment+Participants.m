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

#include "SxAppointment.h"
#include "common.h"
#include <ZSBackend/SxContactManager.h>
#include <ZSBackend/SxAptManager.h>

/* clean up, looks messy */

@implementation SxAppointment(Participants)

- (EOGlobalID *)globalIDFromAccountInfo:(id)_info {
  id   pkey;
  BOOL isTeam = NO;
  
  pkey   = [_info valueForKey:@"pkey"];
  if ([[_info valueForKey:@"isTeam"] boolValue] ||
      [[_info valueForKey:@"isteam"] boolValue])
    isTeam = YES;
  return [EOKeyGlobalID globalIDWithEntityName:(isTeam) ? @"Team" : @"Person"
                        keys:&pkey keyCount:1 zone:NULL];
}

- (NSArray *)accountsForLogin:(NSString *)_login commandContext:(id)_cmdctx {
  return [_cmdctx runCommand:@"account::get",
                  @"login", _login,
                  @"returnType",
                  [NSNumber numberWithInt:LSDBReturnType_ManyObjects],
                  nil];
}

- (NSArray *)teamsForDescription:(NSString *)_desc commandContext:(id)_cmdctx {
  return [_cmdctx runCommand:@"team::get",
                  @"description", _desc,
                  @"returnType",
                  [NSNumber numberWithInt:LSDBReturnType_ManyObjects],
                  nil];
}

- (NSArray *)teamsForLogin:(NSString *)_login commandContext:(id)_cmdctx {
  return [_cmdctx runCommand:@"team::get",
                  @"login", _login,
                  @"returnType",
                  [NSNumber numberWithInt:LSDBReturnType_ManyObjects],
                  nil];
}

- (NSArray *)teamsForNumber:(NSString *)_number commandContext:(id)_cmdctx {
  return [_cmdctx runCommand:@"team::get",
                  @"number", _number,
                  @"returnType",
                  [NSNumber numberWithInt:LSDBReturnType_ManyObjects],
                  nil];
}

- (NSArray *)personFullSearch:(NSString *)_search commandContext:(id)_cmdctx {
  return [_cmdctx runCommand:@"person::full-search",
                  @"maxSearchCount", [NSNumber numberWithInt:20],
                  @"searchString", _search, nil];
}

- (BOOL)classifyParticipant:(id)_participant
  map:(NSMutableDictionary *)_map
  emails:(NSMutableArray *)_emails
  persons:(NSMutableArray *)_persons
  unknown:(NSMutableArray *)_unknown
  commandContext:(id)_cmdctx
{
  id tmp;

  if (([(tmp = [_participant valueForKey:@"email"]) isNotNull]) &&
      ([tmp length]) && (![tmp isEqualToString:@"MAILTO:"])) {
    
    if ([(NSString *)tmp hasPrefix:@"MAILTO:"])
      tmp = [tmp substringFromIndex:7];

    [_emails addObject:tmp];
    [_map setObject:_participant forKey:tmp];
    return YES;
  }
  
  if (([(tmp = [_participant valueForKey:@"cn"]) isNotNull]) &&
      ([tmp length])) {
    NSArray *contacts;
    // try login first
    tmp      = [tmp stringByTrimmingWhiteSpaces];
    
    contacts = [self accountsForLogin:tmp commandContext:_cmdctx];
    
    if ([contacts count] == 0) // try team description
      contacts = [self teamsForDescription:tmp commandContext:_cmdctx];
    if ([contacts count] == 0) // try team login
      contacts = [self teamsForLogin:tmp commandContext:_cmdctx];      
    if ([contacts count] == 0) // try team number
      contacts = [self teamsForNumber:tmp commandContext:_cmdctx];      
    if ([contacts count] == 0) // try full search
      contacts = [self personFullSearch:tmp commandContext:_cmdctx];
    
    if ([contacts count] == 0) {
      [self logWithFormat:
            @"WARNING[%s]: didn't find person for entry: %@",
            __PRETTY_FUNCTION__, tmp];
      [_unknown addObject:_participant];
    }
    else {
      id contact;
      if ([contacts count] > 1)
        [self logWithFormat:
              @"WARNING[%s] found more than one person for entry: %@",
              __PRETTY_FUNCTION__, tmp];
      contact = [contacts objectAtIndex:0];
      tmp = [contact valueForKey:@"globalID"];
      if (tmp == nil) {
        tmp = [contact valueForKey:@"companyId"];
        if ([[contact valueForKey:@"isTeam"] boolValue])
          tmp = [EOKeyGlobalID globalIDWithEntityName:@"Team"
                               keys:&tmp keyCount:1 zone:NULL];
        else
          tmp = [EOKeyGlobalID globalIDWithEntityName:@"Person"
                               keys:&tmp keyCount:1 zone:NULL];
      }
      if (tmp != nil) {
        [_persons addObject:tmp];
        [_map setObject:_participant forKey:[tmp keyValues][0]];
      }
      else if ((([(tmp = [contact valueForKey:@"email"]) isNotNull]) &&//teams
           ([tmp length])) || 
          (([(tmp = [contact valueForKey:@"email1"]) isNotNull]) &&//persons
           ([tmp length]))) {
        [_emails addObject:tmp];
        [_map setObject:_participant forKey:tmp];
      }
    }
    return YES;
  }
  // this seems to be an invalid participant: %@",
  [_unknown addObject:_participant];
  return YES; // NO;
}

- (void)addAccountInfos:(NSEnumerator *)_accountInfos 
  toGIDList:(NSMutableArray *)_gids
{
  id tmp;
  
  while ((tmp = [_accountInfos nextObject])) {
    EOGlobalID *gid;
    
    gid = [self globalIDFromAccountInfo:tmp];
    if (gid != nil && (![_gids containsObject:gid])) 
      [_gids addObject:gid];
    else {
      [self logWithFormat:
            @"WARNING[%s] failed to build gid from account info %@",
            __PRETTY_FUNCTION__, tmp];
    }
  }
}

- (void)findAccountsForGIDs:(NSEnumerator *)_gids
  accounts:(NSMutableArray *)_accounts
  nonAccounts:(NSMutableArray *)_nonAccounts
  contactManager:(id)_cm
{
  EOGlobalID *gid;
  
  while ((gid = [_gids nextObject])) {
    id tmp;
    
    tmp = [_cm accountForGlobalID:gid];
    if (tmp) {
      [_accounts addObject:tmp];
    }
    else {
      // found no account for gid, so may be just a person
      [_nonAccounts addObject:gid];
    }
  }
}

- (NSArray *)fetchStaffForGIDs:(NSArray *)_gids commandContext:(id)_cmdctx {
  return [_cmdctx runCommand:@"staff::get-by-globalid", @"gids", _gids, nil];
}

/* returns participants with map entry, removes matching entries from map */
- (NSMutableArray *)mapParticipants:(NSArray *)_parts
  backWithMap:(NSMutableDictionary *)_map
{
  id person;
  id mapped;
  id key;
  id tmp;
  NSMutableArray *success;
  unsigned int i, max;
  
  max     = [_parts count];
  success = [NSMutableArray arrayWithCapacity:max+1];

  for (i = 0; i < max; i++) {
    person = [_parts objectAtIndex:i];
    mapped = nil;
    key    = nil;

    //if ([SxAppointment usePKeyEmails]) {
    // search for pkey-emails anyway, cause this is used
    // if a person/team has no email set
    key = [SxAppointment pKeyEmailForParticipant:person];
    mapped = [_map objectForKey:key];
    //}

    if (mapped == nil) {
      if ([(key = [person valueForKey:@"email"]) length])
        mapped = [_map objectForKey:key];
      else if ([(key = [person valueForKey:@"email1"]) length])
        mapped = [_map objectForKey:key];
    }
    
    if (mapped == nil) {
      if ((key = [person valueForKey:@"companyId"]))
        mapped = [_map objectForKey:key];
    }
    
    if (mapped != nil) {
      if ((tmp = [(NSDictionary *)mapped objectForKey:@"rsvp"]))
        [person takeValue:tmp forKey:@"rsvp"];
      if ((tmp = [(NSDictionary *)mapped objectForKey:@"partStat"]))
        [person takeValue:tmp forKey:@"partStatus"];
      if ((tmp = [(NSDictionary *)mapped objectForKey:@"role"]))
        [person takeValue:tmp forKey:@"role"];
      
      [_map removeObjectForKey:key];
      [success addObject:person];
    }
    else {
      NSLog(@"%s found no mapping for participant:%@(%@,%@,%@)",
            __PRETTY_FUNCTION__,
            [person valueForKey:@"companyId"],
            [person valueForKey:@"name"],
            [person valueForKey:@"firstname"],
            [person valueForKey:@"description"]);
    }
  }

  return success;
}

- (void)createEntriesForUnknown:(NSArray *)_unknown
  addToResult:(NSMutableArray *)_result
  commandContext:(id)_cmdctx
{
  static int StoreUnkownPerson = -1;
    
  NSEnumerator *e;
  id person;
  id name, email, newPerson, tmp;

  if (StoreUnkownPerson == -1) {
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    StoreUnkownPerson = [ud boolForKey:@"StoreUnkownPerson"]? 1 : 0;
  }
  
  NSLog(@"WARNING[%s]: creating entries for unknown participants: %@",
        __PRETTY_FUNCTION__,
        [[_unknown valueForKey:@"cn"] componentsJoinedByString:@", "]);
    
  e = [_unknown objectEnumerator];
  // unknown participants
  while ((person = [e nextObject])) {
    name  = [person objectForKey:@"cn"];
    email = [person objectForKey:@"email"];

    if (!StoreUnkownPerson && [name isEqualToString:@"Unknown"])
      continue;

    if ([name length]) {
      newPerson =
        [_cmdctx runCommand:@"person::new",
                 @"name",      name,
                 @"comment",
                 @"Created by ZideStore during editing of appointment",
                 @"isPrivate", [NSNumber numberWithBool:YES],
                 @"email1",    email,
                 nil];
        
      if (newPerson) {
        if ((tmp = [person objectForKey:@"rsvp"]))
          [newPerson takeValue:tmp forKey:@"rsvp"];
        if ((tmp = [person objectForKey:@"partStat"]))
          [newPerson takeValue:tmp forKey:@"partStatus"];
        if ((tmp = [person objectForKey:@"role"]))
          [newPerson takeValue:tmp forKey:@"role"];

        [_result addObject:newPerson];
      }
    }
    else {
      [self logWithFormat:
            @"cannot create entry for unknown participant: %@",
            [person valueForKey:@"cn"]];
    }
  }
}

- (void)addPKeyEmails:(NSMutableArray *)_emails 
  toGIDList:(NSMutableArray *)_gids
{
  unsigned int idx;
  id       entry;

  for (idx = [_emails count]; idx != 0; ) {
    entry = [_emails objectAtIndex:--idx];
    if ((entry = [SxAppointment gidForPKeyEmail:entry]) == nil)
      continue;

    [_gids addObject:entry];
    [_emails removeObjectAtIndex:idx];
  }
}

- (NSArray *)fetchParticipantsForPersons:(NSArray *)_persons
  inContext:(id)_ctx
{
  /*
   * format of persons:
   *  {
   *    cn    = "Martin Hoerning";
   *    email = "mh@in.skyrix.com"; 
   *    role  = "REQ-PARTICIPANT";
   *    emailType = "SMTP"; // zidelook
   *    rsvp  = YES; // only supported by evo
   *    partStat = NEEDS-ACTION; 
   *    xuid = "something"; // evo
   *  }
   *
   */  
  static int      usePKeyMails = -1;
  
  LSCommandContext    *cmdctx;
  SxContactManager    *cm;
  NSEnumerator        *e;
  NSMutableArray      *emails;
  NSMutableArray      *persons;
  NSMutableArray      *unknown;
  id                  person;
  id                  tmp;
  NSMutableDictionary *map;
  BOOL                createNewEntriesForUnknownParticipants;

  if ([_persons count] == 0)
    return [NSArray array];

  if (usePKeyMails == -1) {
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    usePKeyMails = [ud boolForKey:@"SxUsePKeyMailRecipients"];
  }
  
  cmdctx = [self commandContextInContext:_ctx];
  cm     = [SxContactManager managerWithContext:cmdctx];
  map    = [NSMutableDictionary dictionaryWithCapacity:[_persons count]];

  createNewEntriesForUnknownParticipants = YES;

  emails  = [NSMutableArray arrayWithCapacity:[_persons count]];
  persons = [NSMutableArray array];
  unknown = [NSMutableArray array];
  
  e      = [_persons objectEnumerator];
  while ((person = [e nextObject])) {
    if (![self classifyParticipant:person
               map:map
               emails:emails
               persons:persons
               unknown:unknown
               commandContext:cmdctx]) {
      [self logWithFormat:@"failed to classify participant: %@",
            [[person allValues] componentsJoinedByString:@","]];
    }
  }

  // try to get accounts for the listed emails
  if ([emails count]) {
    if (usePKeyMails) {
      [self addPKeyEmails:emails toGIDList:persons];
    }
    if ([emails count]) {
      [self addAccountInfos:[cm listAccountsWithEmails:emails]
            toGIDList:persons];
      [self addAccountInfos:[cm listPublicPersonsWithEmails:emails]
            toGIDList:persons];
      [self addAccountInfos:[cm listPrivatePersonsWithEmails:emails]
            toGIDList:persons];
      [self addAccountInfos:[cm listGroupsWithEmails:emails]
            toGIDList:persons];
    }
  }
  
  // try to get accounts for collected cns
  e       = [persons objectEnumerator];
  persons = [NSMutableArray array];
  [emails removeAllObjects];
  [self findAccountsForGIDs:e
        accounts:emails nonAccounts:persons
        contactManager:cm];
  
  // get persons for collected gids
  if ([persons count]) { // got participants, who are not accounts
    if ((tmp = [self fetchStaffForGIDs:persons commandContext:cmdctx]))
      [emails addObjectsFromArray:tmp];
  }

  // append additional apt attributes
  emails = [self mapParticipants:emails backWithMap:map];

  if ([map count])
    // unmatched entries cannot be found in the database
    // so there are unknown
    [unknown addObjectsFromArray:[map allValues]];

  if ([unknown count]) 
    [self createEntriesForUnknown:unknown
          addToResult:emails
          commandContext:cmdctx];
  
  return emails;
}


// returns the newParts if the participants changed 
- (NSArray *)checkChangedParticipants:(NSArray *)_newParts
  forOldParticipants:(NSArray *)_oldParts
  inContext:(id)_ctx
{
  // TODO: detailed changed participants check
  NSMutableDictionary *map;
  NSMutableArray      *oldIds;
  NSEnumerator        *e;
  id                  tmp, pkey;
  unsigned            i, max;
  BOOL               isZideLook = NO;
  WEClientCapabilities *cc;
  
  cc = [[(WOContext *)_ctx request] clientCapabilities];
  if ([[cc userAgentType] isEqualToString:@"ZideLook"])
    isZideLook = YES;
  
  if ([_newParts count] != (max = [_oldParts count]))
    return _newParts;

  if (max == 0)
    return nil;

  map    = [NSMutableDictionary dictionaryWithCapacity:max];
  oldIds = [NSMutableArray arrayWithCapacity:max];
  for (i = 0; i < max; i++) {
    tmp = [_oldParts objectAtIndex:i];
    pkey = [tmp valueForKey:@"companyId"];
    if (pkey) {
      [map setObject:tmp forKey:pkey];
      [oldIds addObject:pkey];
    }
  }

  e      = [_newParts objectEnumerator];
  while ((tmp = [e nextObject])) {
    id mapped;
    id newVal, oldVal;
    pkey = [tmp valueForKey:@"companyId"];
    if (![oldIds containsObject:pkey])
      return _newParts;

    // check for changed participant attributes
    mapped = [map objectForKey:pkey];

    newVal = [tmp valueForKey:@"rsvp"];
    oldVal = [mapped valueForKey:@"rsvp"];
    if (([newVal isNotNull] || [oldVal isNotNull]) &&
        (![newVal isEqual:oldVal])) {
      if ([SxAppointment logAptChange])
        NSLog(@"%s: %@ has changed rsvp '%@' -> '%@'",
              __PRETTY_FUNCTION__, pkey, oldVal, newVal);
      return _newParts;
    }

    newVal = [tmp valueForKey:@"role"];
    oldVal = [mapped valueForKey:@"role"];
    if (([newVal isNotNull] || [oldVal isNotNull]) &&
        (![newVal isEqual:oldVal])) {
      if ([SxAppointment logAptChange])
        NSLog(@"%s: %@ has changed role '%@' -> '%@'",
              __PRETTY_FUNCTION__, pkey, oldVal, newVal);
      return _newParts;
    }
    
    newVal = [tmp valueForKey:@"partStatus"];
    oldVal = [mapped valueForKey:@"partStatus"];
    if (([newVal isNotNull] || [oldVal isNotNull]) &&
        (![newVal isEqual:oldVal])) {
      if ([SxAppointment logAptChange])
        NSLog(@"%s: %@ has changed partStatus '%@' -> '%@'",
              __PRETTY_FUNCTION__, pkey, oldVal, newVal);
      return _newParts;
    }
    
  }
  return nil;
}

// Primary Key Emails

+ (BOOL)usePKeyEmails {
  static int usePKeyMails = -1;
  if (usePKeyMails == -1) {
    usePKeyMails =
      [[NSUserDefaults standardUserDefaults]
                       boolForKey:@"SxUsePKeyMailRecipients"];
  }
  return usePKeyMails;
}

+ (NSString *)pKeyEmailForParticipant:(id)_participant {
  static NSString *personTemplate = nil;
  static NSString *teamTemplate   = nil;
  NSString *template;
  BOOL     isTeam;
  NSString *result;
  id       pkey;

  if (personTemplate == nil) {
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    NSString *def;
    NSString *tmp;
    
    def = [NSString stringWithFormat:@"@%@",
                    [[NSHost currentHost] name]];
    
    tmp = [ud objectForKey:@"SxPKeyMailRecipientsPersonTemplate"];
    if (tmp == nil) tmp = def;
    personTemplate = [tmp copy];
    
    tmp = [ud objectForKey:@"SxPKeyMailRecipientsTeamTemplate"];
    if (tmp == nil) tmp = def;
    teamTemplate = [tmp copy];
  }
  
  isTeam   = [[_participant valueForKey:@"isTeam"] boolValue];
  template = (isTeam ? teamTemplate : personTemplate);
  result   = [template stringByReplacingVariablesWithBindings:_participant
                       stringForUnknownBindings:@""];
  pkey   = [_participant valueForKey:@"companyId"];
  
  if (![pkey isNotNull])
    pkey = [[_participant valueForKey:@"globalID"] keyValues][0];
  
  return [NSString stringWithFormat:
                   (isTeam ? @"skyrix-team-%@%@" : @"skyrix-%@%@"),
                   pkey, result];
}
+ (NSString *)emailForParticipant:(id)_participant {
  NSString *email;
  
  if ([SxAppointment usePKeyEmails])
    return [SxAppointment pKeyEmailForParticipant:_participant];
  
  email = [_participant valueForKey:@"email"];
  if ([email length] == 0) email = [_participant valueForKey:@"email1"];
  return email;
}

+ (NSNumber *)pKeyForPKeyEmail:(NSString *)_email isTeam:(BOOL *)_isTeamFlag {
  if (_isTeamFlag != NULL) (*_isTeamFlag) = NO;
  
  if ([_email hasPrefix:@"skyrix-"]) {
    int pkey;
    
    _email = [_email substringFromIndex:7];
    if ([_email hasPrefix:@"team-"]) {
      if (_isTeamFlag != NULL) (*_isTeamFlag) = YES;
      _email = [_email substringFromIndex:5];
    }
    if ((pkey = [_email intValue]) > 1000) {
      return [NSNumber numberWithInt:pkey];
    }
  }
  return nil;
}

+ (EOGlobalID *)gidForPKeyEmail:(NSString *)_email {
  id   pkey;
  BOOL isTeam;
  
  if ((pkey = [SxAppointment pKeyForPKeyEmail:_email isTeam:&isTeam]) != nil) {
    return [EOKeyGlobalID globalIDWithEntityName:
                          (isTeam ? @"Team" : @"Person")
                          keys:&pkey keyCount:1 zone:NULL];
  }
  return nil;
}

@end /* SxAppointment(Participants) */
