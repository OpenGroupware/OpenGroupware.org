/*
  Copyright (C) 2000-2003 SKYRIX Software AG

  This file is part of OGo

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
// $Id$

#include "SkySchedulerConflictPage.h"

#import <Foundation/Foundation.h>
#import <EOControl/EOQualifier.h>
#import <EOControl/EOKeyGlobalID.h>
#import <NGExtensions/NGExtensions.h>
#import <LSFoundation/LSCommandContext.h>
#import <OGoFoundation/OGoSession.h>
#import <OGoFoundation/LSWMailEditorComponent.h>
#import <NGMime/NGMime.h>
#include <NGExtensions/EOFilterDataSource.h>
#include <OGoFoundation/OGoFoundation.h>
#include <OGoFoundation/LSWNotifications.h>
#include <OGoScheduler/SkySchedulerConflictDataSource.h>

@implementation SkySchedulerConflictPage

static NGMimeType *eoDateType = nil;
static NSNumber   *yesNum     = nil;
static NSNumber   *noNum      = nil;

+ (void)initialize {
  static BOOL didInit = NO;
  if (didInit) return;
  didInit = YES;

  eoDateType = [[NGMimeType mimeType:@"eo" subType:@"date"] retain];
  yesNum     = [[NSNumber numberWithBool:YES] retain];
  noNum      = [[NSNumber numberWithBool:NO]  retain];
}

- (id)init {
  if ((self = [super init])) {
    NGBundleManager *bm = [NGBundleManager defaultBundleManager];

    if ([bm bundleProvidingResource:@"LSWImapMailEditor"
            ofType:@"WOComponents"] != nil)
      self->isMailEnabled = YES;
    else
      self->isMailEnabled = NO;
    self->participantIds = nil;
    self->participantConflicts = nil;
    self->resourceConflicts = nil;
    self->sendMail = NO;
    self->action   = [[NSString alloc] initWithString:@"edited"];
    self->timeZone = nil;
  }
  return self;
}

- (void)dealloc {
  RELEASE(self->conflictDataSource);
  RELEASE(self->action);
  RELEASE(self->mailContent);
  RELEASE(self->conflict);
  RELEASE(self->participantConflicts);
  RELEASE(self->resourceConflicts);
  RELEASE(self->timeZone);
  [super dealloc];
}

/* accessors */

- (id)appointment {
  return [self->conflictDataSource appointment];
}

- (void)setConflictDataSource:(id)_ds {
  ASSIGN(self->conflictDataSource, _ds);
}
- (id)conflictDataSource {
  return self->conflictDataSource;
}

- (void)setAction:(NSString *)_action {
  ASSIGN(self->action, _action);
}
- (NSString *)action {
  return self->action;
}

- (void)setTimeZone:(NSTimeZone *)_tz {
  ASSIGN(self->timeZone, _tz);
}
- (NSTimeZone *)timeZone {
  return self->timeZone;
}

- (void)setMailContent:(NSString *)_mailContent {
  ASSIGN(self->mailContent, _mailContent);
}
- (NSString *)mailContent {
  return self->mailContent;
}

- (void)setSendMail:(NSNumber *)_send {
  self->sendMail = [_send boolValue];
}
- (NSNumber *)sendMail {
  return [NSNumber numberWithBool:self->sendMail];
}

- (void)setConflict:(id)_conflict {
  ASSIGN(self->conflict,_conflict);
}
- (id)conflict {
  return self->conflict;
}

- (void)setIndex:(unsigned)_idx {
  self->index = _idx;
}
- (unsigned)index {
  return self->index;
}

- (BOOL)isEditorPage {
  return YES;
}

- (NSArray *)participantIds {
  if (self->participantIds == nil) {
    NSMutableSet   *ms;
    id             teams;
    id             accounts;
    NSEnumerator   *partEnum;
    id             part;
    id             parts;

    ms       = [NSMutableSet set];
    teams    = [NSMutableArray array];
    accounts = [NSMutableArray array];
    partEnum =
      [[[self appointment] valueForKey:@"participants"] objectEnumerator];

    while ((part = [partEnum nextObject])) {
      if ([[part valueForKey:@"isTeam"] boolValue])
        [teams addObject:[part valueForKey:@"globalID"]];
      else if ([[part valueForKey:@"isAccount"] boolValue])
        [accounts addObject:[part valueForKey:@"globalID"]];
    }

    /* getting teams */
    if ([teams count] > 0) {
      NSArray *keys;
      int     i, cnt;

      cnt   = [teams count];
      [ms addObjectsFromArray:teams];
      teams = [self runCommand:@"team::members",
                    @"groups", teams,
                    @"fetchGlobalIDs", [NSNumber numberWithBool:YES],
                    nil];
      if (cnt == 1) {
        [ms addObjectsFromArray:teams];
      }
      else {
        keys = [teams allKeys];
        //      [ms addObjectsFromArray:keys];
        for (i = 0, cnt = [keys count]; i < cnt; i++) {
          [ms addObjectsFromArray:[teams valueForKey:[keys objectAtIndex:i]]];
        }
      }
    }
    if ([accounts count] > 0) {
      NSArray *keys;
      int     i, cnt;

      cnt = [accounts count];
      [ms addObjectsFromArray:accounts];
      accounts = [self runCommand:@"account::teams",
                       @"accounts", accounts,
                       @"fetchGlobalIDs", [NSNumber numberWithBool:YES],
                       nil];
      if (cnt == 1) {
        [ms addObjectsFromArray:accounts];
      }
      else {
        keys = [accounts allKeys];
        //      [ms addObjectsFromArray:keys];
        for (i = 0, cnt = [keys count]; i < cnt; i++) {
          [ms addObjectsFromArray:
              [accounts valueForKey:[keys objectAtIndex:i]]];
        }
      }
    }

    parts = [NSMutableArray array];
    // getting primary key values
    if ([ms count] > 0) {
      partEnum = [ms objectEnumerator];
      while ((part = [partEnum nextObject])) {
        [parts addObject:[(EOKeyGlobalID*)part keyValues][0]];
      }
    }
    parts = [parts copy];
    AUTORELEASE(parts);
    ASSIGN(self->participantIds, parts);
  }
  return self->participantIds;
}

/* filter qualifier */

- (NSString *)resourceQualifierString {
  NSString    *in;
  NSArray     *resources;
  NSString    *resourceNames;
  int         i, cnt;

  
  resourceNames = [[self appointment] valueForKey:@"resourceNames"];
  in = nil;

  resources = (![resourceNames isNotNull])
    ? [NSArray array]
    : [resourceNames componentsSeparatedByString:@", "];
  
  for (i = 0, cnt = [resources count]; i < cnt; i++) {
    NSString *res;
    
    res = [resources objectAtIndex:i];
    in = (i != 0)
      ? [in stringByAppendingString:@" OR "]
      : @"";
    
    in = [in stringByAppendingFormat:
             @"(resourceNames like '%@*\' "
             @"OR resourceNames like '*%@*' "
             @"OR resourceNames like '%@*' "
             @"OR resourceNames = '%@')", res, res, res, res];
  }
  if (in == nil) {
    // no resources -> no conflicts
    in = @"dateId = 1";
  }
  return in;
}

- (EOQualifier *)participantQualifier {
  NSString    *in = [self resourceQualifierString];

  if (in == nil)
    return nil;
  in = [NSString stringWithFormat:@"NOT (%@)", in];
  return [EOQualifier qualifierWithQualifierFormat:in];
}

- (EOQualifier *)resourceQualifier {
  EOQualifier *q;
  NSString    *in = [self resourceQualifierString];
  if (in == nil)
    return nil;
  q = [EOQualifier qualifierWithQualifierFormat:in];
  return q;
}

/* caching */

- (void)setParticipantConflicts:(NSArray *)_cfls {
  ASSIGN(self->participantConflicts,_cfls);
}
- (NSArray *)participantConflicts {
  if (self->participantConflicts == nil) {
    EOFilterDataSource *participantDs;
    EOQualifier        *q;

    participantDs =
      [[EOFilterDataSource alloc] initWithDataSource:self->conflictDataSource];
    q = [self participantQualifier];
    [participantDs setAuxiliaryQualifier:q];

    [self setParticipantConflicts:[participantDs fetchObjects]];
    RELEASE(participantDs);
  }
  return self->participantConflicts;
}

- (void)setResourceConflicts:(NSArray *)_cfls {
  ASSIGN(self->resourceConflicts,_cfls);
}
- (NSArray *)resourceConflicts {
  if (self->resourceConflicts == nil) {
    EOFilterDataSource *resourceDs;
    EOQualifier *q;

    resourceDs =
      [[EOFilterDataSource alloc] initWithDataSource:self->conflictDataSource];
    q = [self resourceQualifier];
    [resourceDs setAuxiliaryQualifier:q];

    [self setResourceConflicts:[resourceDs fetchObjects]];
    RELEASE(resourceDs);
  }
  return self->resourceConflicts;
}

- (NSString *)description {
  return [NSString stringWithFormat:
                   @"%@|SkySchedulerConflictPage:<action:%@>",
                   [super description], self->action];
}

/* conditional */
- (BOOL)isNotLastParticipantConflict {
  return (self->index == ([self->participantConflicts count] - 1))
    ? NO : YES;
}
- (BOOL)isNotLastResourceConflict {
  return (self->index == ([self->resourceConflicts count] - 1))
    ? NO : YES;
}

- (BOOL)hasParticipantConflicts {
  return ([[self participantConflicts] count] > 0)
    ? YES : NO;
}
- (BOOL)hasResourceConflicts {
  return ([[self resourceConflicts] count] > 0)
    ? YES : NO;
}
- (BOOL)hideIgnoreButtons {
  BOOL hide = NO;

  hide = ([self hasResourceConflicts] &&
         [[[self session] userDefaults]
                 boolForKey:@"scheduler_hide_ignore_conflicts"]);
  return hide;
}

/* mail helper */

- (BOOL)isMailLicensed {
  return YES;
}

- (NSArray *)expandedParticipants:(NSArray *)_part {
  int      i, cnt   = [_part count];
  id       staffSet = [NSMutableSet set];
        
  for (i = 0; i < cnt; i++) {
    id staff = [_part objectAtIndex:i];

    if ([[staff valueForKey:@"isTeam"] boolValue]) {
      NSArray *members = [staff valueForKey:@"members"];

      if (members == nil) {
        [self run:@"team::members", @"object", staff, nil];
        members = [staff valueForKey:@"members"];
      }
      [staffSet addObjectsFromArray:members];
    }
    else {
      [staffSet addObject:staff]; 
    }
  }
  staffSet = [staffSet allObjects];

  return staffSet;
}

/* actions */

- (id)back {
  OGoNavigation *nav;
  
  nav = [[self session] navigation];
  [nav leavePage];
  return [nav activePage];
}

- (BOOL)shouldAttachAppointmentsToMails {
  return [[[[self session]
	     userDefaults]
             valueForKey:@"scheduler_attach_apts_to_mails"]
             boolValue];
}

- (id)createMail:(id)_apt {
  /* TODO: split up into smaller methods */
  id<LSWMailEditorComponent,LSWContentPage> mailEditor;
  NSString     *str     = nil;
  NSArray      *ps      = nil;
  NSString     *title, *cc, *subject;
  BOOL         attach;
  NSEnumerator *recEn;
  id           rec    = nil;
  BOOL         first  = YES;
  
  if (!self->isMailEnabled) {
    [self setErrorString:@"mail module is not enabled !"];
    return nil;
  }

  if ((mailEditor = (id)[self pageWithName:@"LSWImapMailEditor"]) == nil)
    return nil;
    
  title   = [_apt valueForKey:@"title"];

  [self runCommand:@"appointment::get-participants",@"appointment",_apt,nil];
  ps  = [_apt valueForKey:@"participants"];
  ps  = [self expandedParticipants:ps];
  str = [self action];

  /* set default cc */

  cc = [[[self session] userDefaults]
	       objectForKey:@"scheduler_ccForNotificationMails"];
  if (cc) [mailEditor addReceiver:cc type:@"cc"];
  
  subject = [NSString stringWithFormat:@"%@: '%@' %@",
		        [[self labels] valueForKey:@"appointment"],
		        title,
		        [[self labels] valueForKey:str]];
  [mailEditor setSubject:subject];
  
  attach = [self shouldAttachAppointmentsToMails];
  [mailEditor addAttachment:_apt type:eoDateType
	      sendObject:(attach ? yesNum : noNum)];

  if (self->mailContent == nil) self->mailContent = @"";
  [mailEditor setContentWithoutSign:self->mailContent];

  recEn = [ps objectEnumerator];
  first  = YES;
        
  while ((rec = [recEn nextObject])) {
    if (first) {
      [mailEditor addReceiver:rec];
      first = NO;
    }
    else 
      [mailEditor addReceiver:rec type:@"cc"];
  }

  return mailEditor;
}

- (id)backToNonEditorPage {
  OGoNavigation *nav;
  nav = [[self session] navigation];
  do {
    [nav leavePage];
  } while ([[nav activePage] isEditorPage]);
  return [nav activePage];
}

- (id)save {
  BOOL     isNew;
  id       result;
  NSString *notificationName;
  id       apt;
  
  apt   = [self appointment];

  if (self->timeZone) {
    [[apt valueForKey:@"startDate"] setTimeZone:self->timeZone];
    [[apt valueForKey:@"endDate"] setTimeZone:self->timeZone];
  }
  
  isNew = ([apt valueForKey:@"dateId"] == nil)
    ? YES : NO;
  if (isNew) {
    result           = [self runCommand:@"appointment::new" arguments:apt];
    notificationName = LSWNewAppointmentNotificationName;
  }
  else {
    result = [self runCommand:@"appointment::set" arguments:apt];
    notificationName = LSWUpdatedAppointmentNotificationName;
  }
  if (result == nil)
    return nil;
  
  [self postChange:notificationName onObject:result];
  [self backToNonEditorPage];
  if (self->sendMail)
    return [self createMail:result];
  
  return [[[self session] navigation] activePage];
}

- (id)ignoreConflicts {
  id  apt;
  id  tmp;

  apt   = [self appointment];
  [apt takeValue:yesNum forKey:@"isWarningIgnored"];
  tmp = [self save];
  [apt takeValue:noNum forKey:@"isWarningIgnored"];
  return tmp;
}

- (id)ignoreAlwaysConflicts {
  id apt, tmp;
  
  apt = [self appointment];
  [apt takeValue:yesNum forKey:@"isWarningIgnored"];
  [apt takeValue:yesNum forKey:@"isConflictDisabled"];
  tmp = [self save];
  
  [apt takeValue:noNum forKey:@"isWarningIgnored"];
  return tmp;
}

/* k/v coding */

- (void)takeValue:(id)_val forKey:(id)_key {
  if ([_key isEqualToString:@"dataSource"])
    [self setConflictDataSource:_val];
  else if ([_key isEqualToString:@"action"])
    [self setAction:_val];
  else if ([_key isEqualToString:@"mailContent"])
    [self setMailContent:_val];
  else if ([_key isEqualToString:@"sendMail"])
    [self setSendMail:_val];
  else if ([_key isEqualToString:@"timeZone"])
    [self setTimeZone:_val];
  else
    [super takeValue:_val forKey:_key];
}

@end /* SkySchedulerConflictPage */
