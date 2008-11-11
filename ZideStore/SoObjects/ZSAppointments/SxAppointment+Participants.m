/*
  Copyright (C) 2000-2007 SKYRIX Software AG
  Copyright (C) 2006-2007 Helge Hess

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

#if 0
#warning DEBUG CODE
static BOOL debugOn = YES;
#else
static BOOL debugOn = NO;
#endif

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

- (NSString *)stripMailToPrefix:(NSString *)_email {
  /* mailto:hh@oo.zz (length: 7) */
  static unichar cl[7] = { 'm', 'a', 'i', 'l', 't', 'o', ':' };
  static unichar cu[7] = { 'M', 'A', 'I', 'L', 'T', 'O', ':' };
  int i;
  
  if ((i = [_email length]) < 7)
    return _email;

  for (i = 6; i >= 0; i--) {
    register unichar c;
    
    c = [_email characterAtIndex:i];
    if (c != cl[i] && c != cu[i])
      return _email; /* does not have mailto prefix */
  }
  return [_email substringFromIndex:7]; /* cut off prefix */
}

- (BOOL)classifyParticipant:(id)_participant
  map:(NSMutableDictionary *)_map
  emails:(NSMutableArray *)_emails
  persons:(NSMutableArray *)_persons
  unknown:(NSMutableArray *)_unknown
  commandContext:(id)_cmdctx
{
  NSArray  *contacts;
  NSString *cn, *email;
  id contact;
  id tmp;
  
  /* first check whether the iCal contained an email */
  
  if ([(email = [_participant valueForKey:@"email"]) isNotEmpty]) {
    email = [self stripMailToPrefix:email];
    if ([email isNotEmpty]) {
      [_emails addObject:email];
      [_map setObject:_participant forKey:email];
      return YES;
    }
  }
  
  /* check whether the iCal contained a CN */
  
  if (!([(cn = [_participant valueForKey:@"cn"]) isNotEmpty])) {
    // this seems to be an invalid participant: %@",
    [_unknown addObject:_participant];
    return YES; // NO;
  }
  
  // try login first
  cn       = [cn stringByTrimmingWhiteSpaces];
  contacts = [self accountsForLogin:cn commandContext:_cmdctx];
  
  if (![contacts isNotEmpty]) // try team description
    contacts = [self teamsForDescription:cn commandContext:_cmdctx];
  if (![contacts isNotEmpty]) // try team login
    contacts = [self teamsForLogin:cn commandContext:_cmdctx];      
  if (![contacts isNotEmpty]) // try team number
    contacts = [self teamsForNumber:cn commandContext:_cmdctx];      
  if (![contacts isNotEmpty]) // try full search
    contacts = [self personFullSearch:cn commandContext:_cmdctx];
  
  if (![contacts isNotEmpty]) {
    [self warnWithFormat:
            @"%s: did not find person for CN: %@",
          __PRETTY_FUNCTION__, cn];
    [_unknown addObject:_participant];
    return YES;
  }
  
  if ([contacts count] > 1) {
    [self warnWithFormat:
            @"%s: found more than one person for CN (using first): %@",
            __PRETTY_FUNCTION__, cn];
  }
  contact = [contacts objectAtIndex:0];
  tmp     = [contact valueForKey:@"globalID"];
  if (tmp == nil) {
      tmp = [contact valueForKey:@"companyId"];
        
      tmp = [EOKeyGlobalID globalIDWithEntityName:
                             [[contact valueForKey:@"isTeam"] boolValue]
                           ? @"Team" : @"Person"
                           keys:&tmp keyCount:1 zone:NULL];
  }
  if (tmp != nil) {
      [_persons addObject:tmp];
      [_map setObject:_participant forKey:[tmp keyValues][0]];
  }
  else if ([(tmp = [contact valueForKey:@"email"])  isNotEmpty]) { // teams
      [_emails addObject:tmp];
      [_map setObject:_participant forKey:tmp];
  }
  else if ([(tmp = [contact valueForKey:@"email1"]) isNotEmpty]) { // persons
      [_emails addObject:tmp];
      [_map setObject:_participant forKey:tmp];
  }
  return YES;
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
      if ([(key = [person valueForKey:@"email"]) isNotEmpty])
        mapped = [_map objectForKey:key];
      else if ([(key = [person valueForKey:@"email1"]) isNotEmpty])
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
      [self errorWithFormat:
	      @"%s found no mapping for participant:%@(%@,%@,%@)",
            __PRETTY_FUNCTION__,
            [person valueForKey:@"companyId"],
            [person valueForKey:@"name"],
            [person valueForKey:@"firstname"],
            [person valueForKey:@"description"]];
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
  NSDictionary *person;
  
  if (StoreUnkownPerson == -1) {
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    StoreUnkownPerson = [ud boolForKey:@"StoreUnkownPerson"] ? 1 : 0;
  }
  
  [self warnWithFormat:
          @"%s: creating entries for unknown participants: %@",
          __PRETTY_FUNCTION__,
          [[_unknown valueForKey:@"cn"] componentsJoinedByString:@", "]];
  
  e = [_unknown objectEnumerator];
  // unknown participants
  while ((person = [e nextObject]) != nil) {
    NSString *name, *email, *firstname;
    id       newPerson, tmp;
    NSRange  r;
    
    name  = [person objectForKey:@"cn"];
    email = [person objectForKey:@"email"];
    
    // TODO: explain that
    if (!StoreUnkownPerson && [name isEqualToString:@"Unknown"])
      continue;
    
    if (![name isNotEmpty]) {
      [self warnWithFormat:
            @"cannot create entry for unknown participant (missing CN): %@",
            email];
      continue;
    }
    if (![email isNotEmpty]) {
      [self warnWithFormat:
            @"cannot create entry for unknown participant (missing email): %@",
            email];
      continue;
    }
    
    /* try to extract firstname from name */
    
    if ((r = [name rangeOfString:@" "]).length > 0) {
      firstname = [name substringToIndex:r.location];
      name      = [name substringFromIndex:(r.location + r.length)];
    }
    else
      firstname = @"";
    
    /* create person */
    
    newPerson =
        [_cmdctx runCommand:@"person::new",
                 @"name",      name,
                 @"firstname", firstname,
                 @"comment",
                   @"Created by ZideStore during editing of appointment",
                 @"isPrivate", [NSNumber numberWithBool:YES],
                 @"email1",    email,
                 nil];
    
    if (![newPerson isNotEmpty]) {
      [self errorWithFormat:
              @"could not auto-create attendee person (%@/%@)", name, email];
      continue;
    }
    
    if ((tmp = [person objectForKey:@"rsvp"]))
      [newPerson takeValue:tmp forKey:@"rsvp"];
    if ((tmp = [person objectForKey:@"partStat"]))
      [newPerson takeValue:tmp forKey:@"partStatus"];
    if ((tmp = [person objectForKey:@"role"]))
      [newPerson takeValue:tmp forKey:@"role"];
    
    [_result addObject:newPerson];
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
   *    cn        = "Martin Hoerning";
   *    email     = "mh@in.skyrix.com"; 
   *    role      = "REQ-PARTICIPANT";
   *    emailType = "SMTP"; // zidelook
   *    rsvp      = YES; // only supported by evo
   *    partStat  = NEEDS-ACTION; 
   *    xuid      = "something"; // evo
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

  if (![_persons isNotEmpty])
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
  persons = [NSMutableArray arrayWithCapacity:8];
  unknown = [NSMutableArray arrayWithCapacity:4];
  
  e = [_persons objectEnumerator];
  while ((person = [e nextObject]) != nil) {
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

  /* try to get accounts for the listed emails */
  if ([emails isNotEmpty]) {
    if (usePKeyMails)
      [self addPKeyEmails:emails toGIDList:persons];
    
    if ([emails isNotEmpty]) {
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
  
  /* try to get accounts for collected cns */
  e       = [persons objectEnumerator];
  persons = [NSMutableArray arrayWithCapacity:8];
  [emails removeAllObjects];
  [self findAccountsForGIDs:e
        accounts:emails nonAccounts:persons
        contactManager:cm];
  
  /* get persons for collected gids */
  if ([persons isNotEmpty]) { /* got participants, who are not accounts */
    if ((tmp = [self fetchStaffForGIDs:persons commandContext:cmdctx]) != nil)
      [emails addObjectsFromArray:tmp];
  }
  
  /* append additional apt attributes */
  emails = [self mapParticipants:emails backWithMap:map];
  
  if ([map isNotEmpty]) {
    /*
      unmatched entries cannot be found in the database
      so they are unknown
    */
    [unknown addObjectsFromArray:[map allValues]];
  }
  
  if ([unknown isNotEmpty]) {
    [self createEntriesForUnknown:unknown
          addToResult:emails
          commandContext:cmdctx];
  }
  
  return emails;
}


- (BOOL)checkWhetherParticipantChanged:(id)mapped new:(id)tmp {
  NSNumber *pkey;
  id newVal, oldVal;

  pkey = [mapped valueForKey:@"companyId"];

  if ([(newVal = [tmp valueForKey:@"rsvp"]) isNotNull]) {
      oldVal = [mapped valueForKey:@"rsvp"];
      if (![oldVal isNotNull]) /* default value (OGo WebUI) */
	oldVal = [NSNumber numberWithInt:0]; /* rsvp: false */
      
      if (![newVal isEqual:oldVal]) {
	if ([SxAppointment logAptChange]) {
	  [self logWithFormat:@"%s: %@ has changed rsvp '%@' -> '%@'",
		__PRETTY_FUNCTION__, pkey, oldVal, newVal];
	}
	if (debugOn) {
	  [self logWithFormat:@"   rsvp changed: %@ (%@ => %@)", 
	          pkey, oldVal, newVal];
	}
	return YES;
      }
  }

  if ([(newVal = [tmp valueForKey:@"role"]) isNotNull]) {
      oldVal = [mapped valueForKey:@"role"];
      if (![oldVal isNotNull]) /* default value (OGo WebUI) */
	oldVal = @"OPT-PARTICIPANT";
      
      if (![newVal isEqual:oldVal]) {
	if ([SxAppointment logAptChange]) {
	  [self logWithFormat:@"%s: %@ has changed role '%@' -> '%@'",
		__PRETTY_FUNCTION__, pkey, oldVal, newVal];
	}
	if (debugOn) {
	  [self logWithFormat:@"   role changed: %@ (%@ => %@)", pkey,
		oldVal, newVal];
	}
	return YES;
      }
  }
    
  if ([(newVal = [tmp valueForKey:@"partStatus"]) isNotNull]) {
      oldVal = [mapped valueForKey:@"partStatus"];
      if (![oldVal isNotNull]) /* default value (OGo WebUI) */
	oldVal = @"NEEDS-ACTION";
      
      if (![newVal isEqual:oldVal]) {
	if ([SxAppointment logAptChange])
	  [self logWithFormat:@"%s: %@ has changed partStatus '%@' -> '%@'",
		__PRETTY_FUNCTION__, pkey, oldVal, newVal];
	if (debugOn) {
	  [self logWithFormat:@"   partstat changed: %@ (%@ => %@)", pkey,
		oldVal, newVal];
	}
	return YES;
      }
  }
  return NO;
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
  id                  newPart;
  unsigned            i, max;
  
  if (debugOn) {
    [self logWithFormat:@"COMPARE: new %@ with old %@",
	    [_newParts valueForKey:@"email1"],
	    [_oldParts valueForKey:@"email1"]];
  }
  
  if ([_newParts count] != (max = [_oldParts count]))
    return _newParts;
  
  if (max == 0)
    return nil;

  map    = [NSMutableDictionary dictionaryWithCapacity:max];
  oldIds = [NSMutableArray arrayWithCapacity:max];
  for (i = 0; i < max; i++) {
    NSNumber *pkey;
    id oldPart;
    
    oldPart  = [_oldParts objectAtIndex:i];
    pkey = [oldPart valueForKey:@"companyId"];
    if (pkey != nil) {
      [map setObject:oldPart forKey:pkey];
      [oldIds addObject:pkey];
    }
  }
  
  if (debugOn)
    [self logWithFormat:@"  iterate over all news participants ..."];
  
  e = [_newParts objectEnumerator];
  while ((newPart = [e nextObject]) != nil) {
    NSNumber *pkey;
    
    pkey = [newPart valueForKey:@"companyId"];
    if (![oldIds containsObject:pkey]) {
      if (debugOn) [self logWithFormat:@"   new pkey: %@", pkey];
      return _newParts;
    }
    if (debugOn) [self logWithFormat:@"   old pkey: %@", pkey];
    
    /* check for changed participant attributes */
    if ([self checkWhetherParticipantChanged:[map objectForKey:pkey]
	      new:newPart])
      return _newParts;
  }
  if (debugOn) [self logWithFormat:@"  participants stayed the same."];
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
  if (![email isNotEmpty]) email = [_participant valueForKey:@"email1"];
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
