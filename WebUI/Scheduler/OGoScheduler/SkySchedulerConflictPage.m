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

#include <OGoFoundation/OGoContentPage.h>

/*
  SkySchedulerConflictPage
  
  Required arguments:
    'dataSource' - a SkySchedulerConflictDataSource focused on an appointment
  
  TODO: document
*/

@class NSString, NSArray, NSTimeZone;
@class EODataSource;
@class OGoAptMailOpener;

@interface SkySchedulerConflictPage : OGoContentPage
{
  id       conflictDataSource;
  NSString *action;
  OGoAptMailOpener *mailOpener;
  NSArray  *participantIds;
  id       conflict;
  unsigned index;
  
  NSTimeZone *timeZone;
  struct {
    int sendMail:1;
    int reserved:31;
  } sscFlags;

  // cache
  NSArray  *participantConflicts;
  NSArray  *resourceConflicts;
}

@end

#include "OGoAptMailOpener.h"
#include <OGoFoundation/LSWMailEditorComponent.h>
#include <OGoFoundation/LSWNotifications.h>
#include <OGoFoundation/NSObject+Commands.h>
#include <OGoFoundation/OGoNavigation.h>
#include <OGoFoundation/OGoSession.h>
#include <NGExtensions/EOFilterDataSource.h>
#include "common.h"

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
  if ((self = [super init]) != nil) {
    self->action = @"edited";
  }
  return self;
}

- (void)dealloc {
  [self->conflictDataSource release];
  [self->action             release];
  [self->mailOpener         release];
  [self->conflict           release];
  [self->participantConflicts release];
  [self->resourceConflicts  release];
  [self->timeZone           release];
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

- (void)setDataSource:(EODataSource *)_ds {
  /* Note: used in KVC */
  [self setConflictDataSource:_ds];
}

- (void)setAction:(NSString *)_action {
  ASSIGNCOPY(self->action, _action);
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

- (void)setMailOpener:(OGoAptMailOpener *)_opener {
  ASSIGN(self->mailOpener, _opener);
}
- (OGoAptMailOpener *)mailOpener {
  return self->mailOpener;
}

- (void)setSendMail:(BOOL)_send {
  self->sscFlags.sendMail = _send ? 1 : 0;
}
- (BOOL)sendMail {
  return self->sscFlags.sendMail ? YES : NO;
}

- (void)setConflict:(id)_conflict {
  ASSIGN(self->conflict, _conflict);
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

/* collecting participants */

- (void)_collectTeamGIDs:(NSMutableArray *)teams
  andAccountGIDs:(NSMutableArray *)accounts
  fromParticipantsArray:(NSArray *)_parts
{
  /* 
     Scan participants, sort teams into 'teams' and accounts into 'accounts'.
     
     Note: does not add non-account contacts!
  */
  NSEnumerator *partEnum;
  id           part;

  partEnum =
    [_parts objectEnumerator];
  
  while ((part = [partEnum nextObject]) != nil) {
    if ([[part valueForKey:@"isTeam"] boolValue])
      [teams addObject:[part valueForKey:@"globalID"]];
    else if ([[part valueForKey:@"isAccount"] boolValue])
      [accounts addObject:[part valueForKey:@"globalID"]];
  }
}

- (void)_addTeamGIDsAndMembers:(NSArray *)teams toGIDsSet:(NSMutableSet *)ms {
  unsigned cnt;
  id rteams;
  
  if ([teams count] == 0)
    return;

  cnt   = [teams count];
  [ms addObjectsFromArray:teams];
  rteams = [self runCommand:@"team::members",
                    @"groups", teams,
                    @"fetchGlobalIDs", [NSNumber numberWithBool:YES],
                nil];
  if (cnt == 1) { // TODO: this is a hack to deal with single-value inconsist.?
    [ms addObjectsFromArray:rteams];
  }
  else {
    NSArray  *keys;
    unsigned i;
        
    keys = [rteams allKeys];
    // [ms addObjectsFromArray:keys];
    for (i = 0, cnt = [keys count]; i < cnt; i++)
      [ms addObjectsFromArray:[rteams valueForKey:[keys objectAtIndex:i]]];
  }
}

- (void)_addAccountGIDsAndTeams:(NSArray *)accounts
  toGIDsSet:(NSMutableSet *)ms
{
  unsigned i, cnt;
  id teams;
  
  if ([accounts count] == 0)
    return;

  cnt = [accounts count];
  [ms addObjectsFromArray:accounts];
  teams = [self runCommand:@"account::teams",
                    @"accounts", accounts,
                    @"fetchGlobalIDs", yesNum,
                nil];
  if (cnt == 1) {
      [ms addObjectsFromArray:teams];
  }
  else {
    NSArray *keys;
    
    keys = [teams allKeys];
    //      [ms addObjectsFromArray:keys];
    for (i = 0, cnt = [keys count]; i < cnt; i++) {
      [ms addObjectsFromArray:
            [teams valueForKey:[keys objectAtIndex:i]]];
    }
  }
}

- (NSArray *)primaryKeysFromGIDs:(NSSet *)ms {
  NSMutableArray *parts;
  NSEnumerator   *partEnum;
  id part;

  parts = [NSMutableArray arrayWithCapacity:16];
  if ([ms count] == 0)
    return parts;
  
  partEnum = [ms objectEnumerator];
  while ((part = [partEnum nextObject]) != nil)
    [parts addObject:[(EOKeyGlobalID*)part keyValues][0]];
  
  return parts;
}

- (NSArray *)participantIds {
  // TODO: move to a command! (appointment::get-all-participant-ids?)
  NSMutableSet   *ms;
  NSMutableArray *teams;
  NSMutableArray *accounts;
  NSArray        *parts;
  
  if (self->participantIds != nil)
    return self->participantIds;
  
  teams    = [[NSMutableArray alloc] initWithCapacity:4];
  accounts = [[NSMutableArray alloc] initWithCapacity:4];
  
  [self _collectTeamGIDs:teams andAccountGIDs:accounts 
        fromParticipantsArray:[[self appointment]valueForKey:@"participants"]];
  
  ms = [[NSMutableSet alloc] initWithCapacity:16];
  [self _addTeamGIDsAndMembers:teams     toGIDsSet:ms];
  [self _addAccountGIDsAndTeams:accounts toGIDsSet:ms];
  [teams    release]; teams    = nil;
  [accounts release]; accounts = nil;
  
  /* transform GIDs to primary keys */
  
  parts = [[self primaryKeysFromGIDs:ms] copy];
  [ms release]; ms = nil;
  
  [self->participantIds release];
  self->participantIds = parts;
  
  return self->participantIds;
}


/* filter qualifier */

- (NSString *)resourceQualifierString {
  // used by qualifiers
  NSString *in;
  NSArray  *resources;
  NSString *resourceNames;
  int      i, cnt;

  
  resourceNames = [[self appointment] valueForKey:@"resourceNames"];
  in = nil;

  resources = (![resourceNames isNotNull])
    ? (NSArray *)[NSArray array]
    : [resourceNames componentsSeparatedByString:@", "];
  
  for (i = 0, cnt = [resources count]; i < cnt; i++) {
    NSString *res;
    
    res = [resources objectAtIndex:i];
    in = (i != 0)
      ? [in stringByAppendingString:@" OR "]
      : (NSString *)@"";
    
    in = [in stringByAppendingFormat:
             @"((resourceNames LIKE '%@*\') "
             @"OR (resourceNames LIKE '*%@*') "
             @"OR (resourceNames LIKE '%@*') "
             @"OR (resourceNames = '%@'))", res, res, res, res];
  }
  if (in == nil) {
    // no resources -> no conflicts
    in = @"dateId = 1";
  }
  return in;
}

- (EOQualifier *)participantQualifier {
  NSString *in;

  // TODO: this is apparently correct, though I do not understand what this is
  //       supposed to do
  
  if ((in = [self resourceQualifierString]) == nil)
    return nil;
  
  in = [NSString stringWithFormat:@"NOT (%@)", in];
  return [EOQualifier qualifierWithQualifierFormat:in];
}

- (EOQualifier *)resourceQualifier {
  NSString *in;
  
  if ((in = [self resourceQualifierString]) == nil)
    return nil;
  
  return [EOQualifier qualifierWithQualifierFormat:in];
}

/* caching */

- (void)setParticipantConflicts:(NSArray *)_cfls {
  ASSIGN(self->participantConflicts,_cfls);
}
- (NSArray *)participantConflicts {
  EOFilterDataSource *participantDs;
  EOQualifier        *q;
  
  if (self->participantConflicts != nil)
    return self->participantConflicts;

  /* wrap conflict-datasource in a filter-datasource */
  
  participantDs =
    [[EOFilterDataSource alloc] initWithDataSource:self->conflictDataSource];
  q = [self participantQualifier];
  [participantDs setAuxiliaryQualifier:q];
  
  [self setParticipantConflicts:[participantDs fetchObjects]];
  [participantDs release];
  return self->participantConflicts;
}

- (void)setResourceConflicts:(NSArray *)_cfls {
  ASSIGN(self->resourceConflicts,_cfls);
}
- (NSArray *)resourceConflicts {
  EOFilterDataSource *resourceDs;
  EOQualifier *q;
  
  if (self->resourceConflicts != nil)
    return self->resourceConflicts;

  resourceDs =
    [[EOFilterDataSource alloc] initWithDataSource:self->conflictDataSource];
  q = [self resourceQualifier];
  [resourceDs setAuxiliaryQualifier:q];
  
  [self setResourceConflicts:[resourceDs fetchObjects]];
  [resourceDs release];
  return self->resourceConflicts;
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

- (BOOL)hideIgnoreButtons {
  BOOL hide = NO;

  hide = ([[self resourceConflicts] isNotEmpty] &&
          [[[self session] userDefaults]
                  boolForKey:@"scheduler_hide_ignore_conflicts"]);
  return hide;
}

/* mail helper */

- (BOOL)isMailLicensed {
  [self errorWithFormat:@"Called deprecated method: %s", __PRETTY_FUNCTION__];
  return YES;
}

- (NSArray *)expandedParticipants:(NSArray *)_part {
  NSMutableSet *staffSet;
  unsigned i, cnt;

  cnt      = [_part count];
  staffSet = [NSMutableSet setWithCapacity:cnt];
  
  /* flatten teams to their members */
  for (i = 0; i < cnt; i++) {
    id staff;
    
    staff = [_part objectAtIndex:i];
    if ([[staff valueForKey:@"isTeam"] boolValue]) {
      // TODO: shouldn't we use team::expand or something?
      NSArray *members;
      
      if ((members = [staff valueForKey:@"members"]) == nil) {
        [self run:@"team::members", @"object", staff, nil];
        members = [staff valueForKey:@"members"];
      }
      [staffSet addObjectsFromArray:members];
    }
    else
      [staffSet addObject:staff]; 
  }
  return [staffSet allObjects];
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
- (id)ccForNotificationMails {
  return [[[self session] userDefaults]
	         objectForKey:@"scheduler_ccForNotificationMails"];
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
  
  apt = [self appointment];
  if ([self->timeZone isNotNull]) {
    [[apt valueForKey:@"startDate"] setTimeZone:self->timeZone];
    [[apt valueForKey:@"endDate"]   setTimeZone:self->timeZone];
  }
  
  if ((isNew = [[apt valueForKey:@"dateId"] isNotNull] ? NO : YES)) {
    result           = [self runCommand:@"appointment::new" arguments:apt];
    notificationName = LSWNewAppointmentNotificationName;
  }
  else {
    result           = [self runCommand:@"appointment::set" arguments:apt];
    notificationName = LSWUpdatedAppointmentNotificationName;
  }
  if (result == nil)
    return nil; /* stay on page */
  
  [self postChange:notificationName onObject:result];
  [self backToNonEditorPage];
  
  if (self->sscFlags.sendMail) {
    /* Note: we must call -enterPage:, otherwise it doesn't work (#138) */
    /* Note: the opener uses the editor page! */
    [[[self session] navigation] enterPage:[self->mailOpener mailEditor]];
  }
  
  /* reset as early as possible */
  [self->mailOpener release]; self->mailOpener = nil;
  
  return [[[self session] navigation] activePage];
}

- (id)ignoreConflicts {
  OGoContentPage *page;
  id apt;
  
  apt = [self appointment];
  [apt takeValue:yesNum forKey:@"isWarningIgnored"];

  page = [self save];

  [apt takeValue:noNum forKey:@"isWarningIgnored"];

  return page;
}

- (id)ignoreAlwaysConflicts {
  OGoContentPage *page;
  id apt;
  
  apt = [self appointment];
  [apt takeValue:yesNum forKey:@"isWarningIgnored"];
  [apt takeValue:yesNum forKey:@"isConflictDisabled"];
  
  page = [self save];
  
  [apt takeValue:noNum forKey:@"isWarningIgnored"];
  
  return page;
}

/* description */

- (NSString *)description {
  return [NSString stringWithFormat:
                   @"%@|SkySchedulerConflictPage:<action:%@>",
                   [super description], self->action];
}

@end /* SkySchedulerConflictPage */
