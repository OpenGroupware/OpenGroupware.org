/*
  Copyright (C) 2000-2006 SKYRIX Software AG
  Copyright (C) 2006      Helge Hess

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

#include "LSNewAppointmentCommand.h"
#include "OGoCycleDateCalculator.h"
#include "common.h"

@interface LSNewAppointmentCommand(UsedCommands)

- (NSArray *)fetchConflictGIDsOfParticipants:(NSArray *)_parts
  andResources:(NSArray *)_resources
  from:(NSCalendarDate *)_startDate to:(NSCalendarDate *)_endDate
  inContext:(id)_context;

- (void)_newCyclicDatesInContext:(id)_context;
- (void)_assignParticipantsInContext:(id)_context;
- (void)_addLogInContext:(id)_context;

@end /* LSNewAppointmentCommand(UsedCommands) */

@implementation LSNewAppointmentCommand

static NSNumber *yesNum = nil;
static NSNumber *noNum  = nil;
static NSNull   *null   = nil;
static NSArray  *startDateOrderings = nil;

+ (void)initialize {
  static BOOL didInit = NO;
  if (didInit) return;
  didInit = YES;
  // TODO: check parent class version!
  
  if (yesNum == nil) yesNum = [[NSNumber numberWithBool:YES] retain];
  if (noNum  == nil) noNum  = [[NSNumber numberWithBool:NO]  retain];
  if (null   == nil) null   = [[NSNull null] retain];
  
  if (startDateOrderings == nil) {
    EOSortOrdering *o;
    
    o = [EOSortOrdering sortOrderingWithKey:@"startDate"
                        selector:EOCompareAscending];
    startDateOrderings = [[NSArray alloc] initWithObjects:&o count:1];
  }
}

- (id)initForOperation:(NSString *)_operation inDomain:(NSString *)_domain {
  if ((self = [super initForOperation:_operation inDomain:_domain])) {
    [self setIsWarningIgnored:noNum];
    
    [self takeValue:@"00_created"          forKey:@"logAction"];
    [self takeValue:@"Appointment created" forKey:@"logText"];
  }
  return self;
}

- (void)dealloc {
  [self->customAttributes release];
  [self->comment          release];
  [self->isWarningIgnored release];
  [self->participants     release];
  [super dealloc];
}

/* command methods */

- (NSString *)_stringForParticipant:(id)_part andIsViewAllowed:(BOOL)_flag {
  id label = nil;
  
  if ([[_part valueForKey:@"isTeam"] boolValue])
    label = [_part valueForKey:@"description"];
  else if ([[_part valueForKey:@"isAccount"] boolValue])
    label = [_part valueForKey:@"login"];
  else if (_flag)
    label = [_part valueForKey:@"name"];
  
  if (![label isNotNull])
    label = @"*";

  return label;
}

- (void)_checkAndPrepareAddedCommands {
  // TODO: is this actually used?
  id<NSObject,LSCommand> cmd;
  NSEnumerator *cmds;
  NSNumber     *pkey;

  cmds = [[self commands] objectEnumerator];
  pkey = [[self object] valueForKey:[self primaryKeyName]];

  while ((cmd = [cmds nextObject]) != nil) {
    if ([cmd isKindOfClass:[LSDBObjectBaseCommand class]])
      [cmd takeValue:pkey forKey:@"dateId"];
  }
}

- (void)_checkStartDateIsBeforeEndDate {
  NSCalendarDate *startDate, *endDate;
  
  startDate = LSCommandGet(self, @"startDate");
  endDate   = LSCommandGet(self, @"endDate");
  if (![startDate isNotNull] || ![endDate isNotNull])
    return;
  
  if ([startDate compare:endDate] == NSOrderedDescending) {
    [self warnWithFormat:@"enddate before startdate, reversing!"];
    LSCommandSet(self, @"endDate",   startDate);
    LSCommandSet(self, @"startDate", endDate);
  }
}

- (void)_appendConflict:(id)ap toString:(NSMutableString *)conflictString
  inContext:(id)_context 
{
  // TODO: duplicate conflict code in new-command! DUP
  // TODO: better use some structure conflict reporting?
  NSString *title;
  NSString *resN  = nil;
  id       sD, eD;
  NSArray  *ps    = nil;
  NSMutableString *p = nil;
  int      j, psCnt;
  
  if (![[ap valueForKey:@"isViewAllowed"] boolValue] &&
      [ap valueForKey:@"accessTeamId"] == nil) {
    title = @"*";          
  } 
  else
    title = [ap valueForKey:@"title"];
  
  sD = [ap valueForKey:@"startDate"];
  eD = [ap valueForKey:@"endDate"];

  ps = [ap valueForKey:@"participants"]; 
  p  = [[NSMutableString alloc] initWithCapacity:64];
  
  for (j = 0, psCnt = [ps count]; j < psCnt; j++) {
    NSString *s;
    
    if (j > 0)
      [p appendString:@", "];
    
    s = [self _stringForParticipant:[ps objectAtIndex:j]
              andIsViewAllowed:[[ap valueForKey:@"isViewAllowed"] boolValue]];
    [p appendString:s];
  }
  
  sD = [sD descriptionWithCalendarFormat:@"%Y-%m-%d %H:%M"];
  eD = [eD descriptionWithCalendarFormat:@"%Y-%m-%d %H:%M"];
  resN = [ap valueForKey:@"resourceNames"];
  
  resN = [resN isNotEmpty]
    ? [NSString stringWithFormat:@"(%@)", resN]
    : (id)@"";
  
  [conflictString appendFormat:@"%@ - %@, %@: %@ %@\n", 
                    sD, eD, p, title, resN];
  [p release]; p = nil;
}

- (void)_processConflicts:(NSArray *)conflicts timeZone:(NSTimeZone *)_tz
  inContext:(id)_context 
{
  NSMutableString *conflictString;
  unsigned int i, cnt;
  
  conflicts =
      LSRunCommandV(_context, @"appointment", @"get-by-globalid",
                    @"gids",          conflicts,
                    @"sortOrderings", startDateOrderings,
                    @"timeZone",     _tz,
                    nil);
  cnt = [conflicts count];
    
  conflictString = [NSMutableString stringWithCapacity:256];
  [conflictString setString:@"There are conflicts:\n"]; 
  
  for (i = 0; i < cnt; i++) {
    id ap;
    
    ap = [conflicts objectAtIndex:i];
    [self _appendConflict:ap toString:conflictString inContext:_context];
  }
  
  [_context rollback];
  
  // TODO: fix command not to signal conflicts using an exception!
  [self assert:NO reason:conflictString];
}

- (void)_checkConflictsInContext:(id)_context {
  NSCalendarDate *startDate, *endDate;
  NSString       *resNames;
  NSArray        *res        = nil;
  NSArray        *conflicts  = nil;
  int            cnt;

  startDate  = [self valueForKey:@"startDate"];
  endDate    = [self valueForKey:@"endDate"];
  resNames   = [self valueForKey:@"resourceNames"];
  
  if ([resNames isNotEmpty])
    res = [resNames componentsSeparatedByString:@", "];
  
  conflicts = [self fetchConflictGIDsOfParticipants:self->participants
                    andResources:res
                    from:startDate to:endDate
                    inContext:_context];
  
  if ((cnt = [conflicts count]) > 0) {
    [self _processConflicts:conflicts timeZone:[startDate timeZone] 
          inContext:_context];
  }
}

- (BOOL)_hasParent {
  return [[[self object] valueForKey:@"parentDateId"] isNotNull];
}
- (BOOL)_dateIsCyclic {
  return [[[self object] valueForKey:@"type"] isNotEmpty];
}

- (BOOL)_newDateInfoInContext:(id)_context {
  /* Note: date_info contains the comment 'blob' (was required for Sybase) */
  id           dateInfo;
  NSDictionary *pk;
  EOEntity     *myEntity;
  NSNumber     *pkey;
  
  myEntity = [[self databaseModel] entityNamed:@"DateInfo"];
  pkey     = [[self object] valueForKey:[self primaryKeyName]];
  
  pk       = [self newPrimaryKeyDictForContext:_context keyName:@"dateId"];
  dateInfo = [self produceEmptyEOWithPrimaryKey:pk entity:myEntity];
  [dateInfo takeValue:[dateInfo valueForKey:@"dateId"] forKey:@"dateInfoId"];

  [dateInfo takeValue:null forKey:@"dateId"];
  
  if ([self comment] != nil)
    [dateInfo takeValue:[self comment] forKey:@"comment"];

  [dateInfo takeValue:pkey        forKey:@"dateId"];
  [dateInfo takeValue:@"inserted" forKey:@"dbStatus"];
  return [[self databaseChannel] insertObject:dateInfo];
}

- (BOOL)isRootCompanyId:(NSNumber *)_companyId {
  return [_companyId unsignedIntValue] == 10000 ? YES : NO;
}

/* prepare */

- (void)_fixupICalRecurrenceInMaster {
  /*
    This is required because the first instances of an iCalendar recurrence
    is NOT required to match the given startdate/enddate!
    
    So we adjust the start/enddate of the master appointment to the actual 
    first instance.
    
    Sample: rrule is "every thursday till christmas" but the given startDate
            is a monday. This will "correct" the startdate to the first
            thursday after the monday.
  */
  NSString *recType;
  NSArray  *cycles;
  id firstInstance;
  
  recType = [self valueForKey:@"type"];
  if (![recType isNotEmpty])
    return;
  
  /* check cycleEndDate */
  
  if (![[self valueForKey:@"cycleEndDate"] isNotNull]) {
    [self warnWithFormat:@"missing a cycle enddate for recurrence: %@",
            recType];
  }
  
  /* fixup rrule */
  
  if (![recType hasPrefix:@"RRULE:"])
    return;
  
  
  cycles =
    [OGoCycleDateCalculator cycleDatesForStartDate:
                              [self valueForKey:@"startDate"]
                            endDate:[self valueForKey:@"endDate"]
                            type:recType
                            maxCycles:2 startAt:1
                            endDate:[self valueForKey:@"cycleEndDate"]
                            keepTime:YES];
  if ([cycles count] == 0) {
    [self errorWithFormat:@"calculation returned no cycles for rrule: '%@'",
            recType];
    return;
  }
  
  firstInstance = [cycles objectAtIndex:0];
  
  LSCommandSet(self, @"startDate", [firstInstance valueForKey:@"startDate"]);
  LSCommandSet(self, @"endDate",   [firstInstance valueForKey:@"endDate"]);
}

- (void)_prepareForExecutionInContext:(id)_context {
  id acl;
  id owner = nil;
  NSNumber *pId;
  
  [self assert:[[self valueForKey:@"title"] isNotEmpty]
        reason:@"missing title attribute"];
  
  pId   = [self valueForKey:@"parentDateId"];
  owner = [self valueForKey:@"ownerId"];
  
  /* set owner of appointment */

  if (![pId isNotNull]) {
    NSNumber *loginId;
    
    loginId = [[_context valueForKey:LSAccountKey] valueForKey:@"companyId"];
    if ([owner isNotNull]) {
      if (!([owner isEqual:loginId] || [self isRootCompanyId:loginId])) {
	[self errorWithFormat:
		@"Attempt to create apt with owner (owner=%@, login=%@)",
	        loginId, owner];
        [self assert:NO
              reason:
		@"Only root is allowed to explicitly set an owner for "
                @"appointments!"];
      }
    }
    else {
      owner = loginId;
      [self assert:[owner isNotNull] reason:@"No owner for appointment!"];
      [self takeValue:owner forKey:@"ownerId"];
    }
  }
  [self takeValue:[NSNumber numberWithInt:1] forKey:@"objectVersion"];
  
  [self assert:[self->participants isNotEmpty]
        reason:@"no participants set !"];

  if (![pId isNotNull])
    [self _fixupICalRecurrenceInMaster];
  
  [self _checkStartDateIsBeforeEndDate];
  
  if (![self->isWarningIgnored boolValue])
    [self _checkConflictsInContext:_context];
  
  
  /* fixup ACL values */

  // TBD: DUP in ::set
  acl = [self valueForKey:@"writeAccessList"];
  if ([acl isKindOfClass:[NSArray class]]) {
    if ([acl isNotEmpty]) {
      NSArray *aclList = acl;
      int i;
      
      acl = [[NSMutableString alloc] initWithCapacity:16];
      for (i = 0; i < [aclList count]; i++) {
	id       obj = [aclList objectAtIndex:i];
	NSNumber *pkey;
	
	if ([obj isKindOfClass:[NSNumber class]])
	  pkey = obj;
	else if ([obj isKindOfClass:[EOKeyGlobalID class]])
	  pkey = [((EOKeyGlobalID *)obj) keyValues][0];
	else if ([obj isKindOfClass:[NSString class]])
	  pkey = obj;
	else
	  pkey = [[aclList objectAtIndex:i] valueForKey:@"companyId"];
	
	if (![pkey isNotNull]) {
	  [self errorWithFormat:
		  @"got object w/o company-id in writeAccessList: %@",aclList];
	  continue;
	}
	
	if ([acl isNotEmpty]) [acl appendString:@","];
	[acl appendString:[pkey stringValue]];
      }
    }
    else
      acl = [[NSNull null] retain];
    
    [self takeValue:acl forKey:@"writeAccessList"];
    [acl release]; acl = nil;
  }
  
  
  /* further checks in super */
  
  [super _prepareForExecutionInContext:_context];
}

/* execute */

- (void)_executeInContext:(id)_context {
  id obj;
  NSCalendarDate *sD, *eD;
  NSTimeZone     *tzsD, *tzeD;
  
  sD = [self valueForKey:@"startDate"];
  eD = [self valueForKey:@"endDate"];
  
  if (![sD isNotNull] || ![eD isNotNull]) {
    [self errorWithFormat:@"got no proper start-date and/or end-date"];
    return;
  }
  
  tzsD = [[[sD timeZoneDetail] retain] autorelease];
  tzeD = [[[eD timeZoneDetail] retain] autorelease];

  [super _executeInContext:_context];
  obj = [self object];
  
  [[obj valueForKey:@"startDate"] setTimeZone:tzsD];
  [[obj valueForKey:@"endDate"]   setTimeZone:tzeD];
  
  [self assert:[self _newDateInfoInContext:_context]];
  
  [self assert:[self->participants isNotEmpty]
        reason:@"no participants set !"];
  [self _assignParticipantsInContext:_context];
  
  if ([self->customAttributes isNotNull]) {
    SkyObjectPropertyManager *pm;
    NSException *ex;
    
    pm = [_context propertyManager];
    ex = [pm takeProperties:self->customAttributes 
	     globalID:[obj valueForKey:@"globalID"]];
    [ex raise]; // TODO: improve cmd error handling ...
  }
  
  if ([self _dateIsCyclic] && ![self _hasParent])
    [self _newCyclicDatesInContext:_context];
  
  [self _addLogInContext:_context];
  [self calculateCTagInContext:_context];
}

/* initialize records */

- (NSString *)entityName {
  return @"Date";
}

/* date info accessors */

- (void)setComment:(NSString *)_comment {
  ASSIGNCOPY(self->comment, _comment);
}
- (NSString *)comment {
  return self->comment;
}

- (void)setCustomAttributes:(NSDictionary *)_dict {
  ASSIGNCOPY(self->customAttributes, _dict);
}
- (NSDictionary *)customAttributes {
  return self->customAttributes;
}

- (void)setIsWarningIgnored:(NSNumber *)_isWarningIgnored {
  ASSIGNCOPY(isWarningIgnored, _isWarningIgnored);
}
- (NSNumber *)isWarningIgnored {
  return isWarningIgnored;
}

- (void)setParticipants:(NSArray *)_participants {
  ASSIGN(self->participants, _participants);
}
- (NSArray *)participants {
  return self->participants;
}

- (void)setCycleEndDateFromString:(NSString *)_cycleEndDateString {
  NSCalendarDate *myDate;

  if (![_cycleEndDateString isNotEmpty]) {
    [super takeValue:nil forKey:@"cycleEndDate"];
    return;
  }
  
  if ([_cycleEndDateString length] < 14) {
    _cycleEndDateString = [_cycleEndDateString stringByAppendingString:
                                                 @" 12:00:00"];
  }
  myDate = [[NSCalendarDate alloc] initWithString:_cycleEndDateString
                                   calendarFormat:@"%Y-%m-%d %H:%M:%S"];
  [super takeValue:myDate forKey:@"cycleEndDate"];
  [myDate release]; myDate = nil;
}

/* key/value coding */

- (void)takeValue:(id)_value forKey:(NSString *)_key {
  if ([_key isEqualToString:@"cycleEndDate"]) {
    if ([_value isKindOfClass:[NSCalendarDate class]])
      [super takeValue:_value forKey:@"cycleEndDate"];
    else 
      [self setCycleEndDateFromString:[_value stringValue]];      
  }
  else if ([_key isEqualToString:@"participants"]) 
    [self setParticipants:_value];
  else  if ([_key isEqualToString:@"comment"]) 
    [self setComment:_value];
  else  if ([_key isEqualToString:@"customAttributes"]) 
    [self setCustomAttributes:_value];
  else if ([_key isEqualToString:@"isWarningIgnored"]) 
    [self setIsWarningIgnored:_value];
  else
    [super takeValue:_value forKey:_key];
}

- (id)valueForKey:(NSString *)_key {
  if ([_key isEqualToString:@"comment"])
    return [self comment];
  if ([_key isEqualToString:@"customAttributes"])
    return [self customAttributes];
  if ([_key isEqualToString:@"participants"])
    return [self participants];
  if ([_key isEqualToString:@"isWarningIgnored"])
    return [self isWarningIgnored];

  return [super valueForKey:_key];
}

/* UsedCommands */

- (NSArray *)fetchConflictGIDsOfParticipants:(NSArray *)_parts
  andResources:(NSArray *)_resources
  from:(NSCalendarDate *)_startDate to:(NSCalendarDate *)_endDate
  inContext:(id)_context
{
  return LSRunCommandV(_context, @"appointment", @"conflicts",
                       @"begin",          [[_startDate copy] autorelease],
                       @"end",            [[_endDate   copy] autorelease],
                       @"staffList",      _parts,
                       @"fetchGlobalIDs", yesNum,
                       @"resourceList",   _resources,
                       nil);
}

- (void)_newCyclicDatesInContext:(id)_context {
  /*res =*/ LSRunCommandV(_context, @"appointment", @"new-cyclic",
                      @"cyclicAppointment", [self object],
                      @"isWarningIgnored",  self->isWarningIgnored,
                      @"participants",      self->participants,
                      @"comment",           [self valueForKey:@"comment"],
		      @"customAttributes",  self->customAttributes,
                      nil);
  // TODO: should check result
}

- (void)_assignParticipantsInContext:(id)_context {
  LSRunCommandV(_context, @"appointment", @"set-participants",
                @"object",       [self object],
                @"participants", self->participants,
                nil);
}

- (void)_addLogInContext:(id)_context {
  LSRunCommandV(_context, @"object", @"add-log",
                @"logText"    , [self valueForKey:@"logText"],
                @"action"     , [self valueForKey:@"logAction"],
                @"objectToLog", [self object],
                nil);
}

@end /* LSNewAppointmentCommand */
