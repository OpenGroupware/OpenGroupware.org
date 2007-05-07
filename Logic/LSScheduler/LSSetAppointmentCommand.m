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

#include "LSSetAppointmentCommand.h"
#include "common.h"

/* TODO: this shares a lot of copy/paste code with LSNewAppointmentCommand! */

@implementation LSSetAppointmentCommand

static NSNull   *null   = nil;
static NSNumber *yesNum = nil;
static NSNumber *noNum  = nil;
static NSArray  *startDateOrderings = nil;

+ (void)initialize {
  static BOOL didInit = NO;
  if (didInit) return;
  didInit = YES;
  // TODO: check parent class version!
  
  if (null   == nil) null   = [[NSNull null] retain];
  if (yesNum == nil) yesNum = [[NSNumber numberWithBool:YES] retain];
  if (noNum  == nil) noNum  = [[NSNumber numberWithBool:NO]  retain];

  if (startDateOrderings == nil) {
    EOSortOrdering *o;
    
    o = [EOSortOrdering sortOrderingWithKey:@"startDate"
                        selector:EOCompareAscending];
    startDateOrderings = [[NSArray alloc] initWithObjects:&o count:1];
  }
}

- (id)initForOperation:(NSString *)_operation inDomain:(NSString *)_domain {
  if ((self = [super initForOperation:_operation inDomain:_domain])) {
    self->isWarningIgnored = NO;
    self->setAllCyclic     = NO;
    [self takeValue:@"05_changed"          forKey:@"logAction"];
    [self takeValue:@"Appointment changed" forKey:@"logText"];
  }
  return self;
}

- (void)dealloc {
  [self->customAttributes release];
  [self->comment      release];
  [self->participants release];
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

- (BOOL)_hasParent {
  return [[[self object] valueForKey:@"parentDateId"] isNotNull];
}
- (BOOL)_appointmentIsCyclic {
  return [[[self object] valueForKey:@"type"] isNotNull];
}

- (void)_checkStartDateIsBeforeEndDate {
  NSCalendarDate *startDate;
  NSCalendarDate *endDate;
  
  startDate = [self valueForKey:@"startDate"];
  endDate   = [self valueForKey:@"endDate"];
  
  if (startDate == nil) startDate = [[self object] valueForKey:@"startDate"];
  if (endDate   == nil) endDate   = [[self object] valueForKey:@"endDate"];
  
  if (endDate == nil || startDate == nil)
    return;
  
  if ([startDate compare:endDate] == NSOrderedDescending) {
    [self takeValue:startDate forKey:@"endDate"];
    [self takeValue:endDate   forKey:@"startDate"];
  }
}

- (void)_checkConflictsInContext:(id)_context {
  /* TODO: split up this big method */
  id             obj;
  NSCalendarDate *startDate, *endDate;
  NSTimeZone     *tz;
  NSString       *resNames;
  NSArray        *res, *conflicts;
  int            cnt;

  obj = [self object];

  if ([[obj valueForKey:@"isConflictDisabled"] boolValue])
    /* this apt never conflicts, no check required */
    return;
  
  startDate  = [self valueForKey:@"startDate"];
  endDate    = [self valueForKey:@"endDate"];
  resNames   = [self valueForKey:@"resourceNames"];
  res        = nil;
  conflicts  = nil;

  if (startDate == nil) startDate = [obj valueForKey:@"startDate"];
  if (endDate   == nil) endDate   = [obj valueForKey:@"endDate"];
  if (resNames  == nil) resNames  = [obj valueForKey:@"resourceNames"];

  tz = [startDate timeZone];

  if ([resNames isNotNull])
    res = [resNames componentsSeparatedByString:@", "];
  
  if ([self->participants count] > 0) {
    conflicts = LSRunCommandV(_context, @"appointment", @"conflicts",
                            @"appointment",    obj,
                            @"begin",          [[startDate copy] autorelease],
                            @"end",            [[endDate   copy] autorelease],
                            @"fetchGlobalIDs", yesNum,
                            @"staffList",      self->participants,
                            @"resourceList",   res,
                            nil);
  }
  else
    conflicts = nil;
  
  /* TODO: duplicate conflict code in new-command! */
  cnt = [conflicts count];
  if (cnt > 0) {
    /* TODO: this seems to be shared with LSNewAppointmentCommand, REUSE! */
    NSMutableString *conflictString;
    int             i;
    
    conflictString = [NSMutableString stringWithCapacity:256];
    [conflictString setString:@"There are conflicts:\n"];

    conflicts =
      LSRunCommandV(_context, @"appointment", @"get-by-globalid",
                    @"gids",          conflicts,
                    @"sortOrderings", startDateOrderings,
                    @"timeZone",      tz,
                    nil);
    cnt = [conflicts count];

    for (i = 0; i < cnt; i++) {
      id       ap     = nil;
      NSString *title = nil;
      NSString *resN  = nil;
      id       sD     = nil;
      id       eD     = nil;
      NSArray  *ps    = nil;
      NSMutableString *p = nil;
      int      j, psCnt;

      ap = [conflicts objectAtIndex:i];
        
      if (![[ap valueForKey:@"isViewAllowed"] boolValue] &&
          [ap valueForKey:@"accessTeamId"] == nil) {
        title = @"*";          
      } else {
        title = [ap valueForKey:@"title"];
      }
      sD = [ap valueForKey:@"startDate"];
      eD = [ap valueForKey:@"endDate"];

      ps = [ap valueForKey:@"participants"]; 
      p  = [[NSMutableString alloc] init];
        
      for (j = 0, psCnt = [ps count]; j < psCnt; j++) {
        NSString *s;
        if (j > 0)
          [p appendString:@", "];
        
        s = [self _stringForParticipant:[ps objectAtIndex:j]
                  andIsViewAllowed:
                    [[ap valueForKey:@"isViewAllowed"] boolValue]];
        [p appendString:s];
      }
      // TODO: replace slow -descriptionWithCalendarFormat:
      sD = [sD descriptionWithCalendarFormat:@"%Y-%m-%d %H:%M"];
      eD = [eD descriptionWithCalendarFormat:@"%Y-%m-%d %H:%M"];
      resN = [ap valueForKey:@"resourceNames"];

      resN = (resN != nil) 
        ? [NSString stringWithFormat:@"(%@)", resN]
        : (id)@"";
      
      [conflictString appendFormat:@"%@ - %@, %@: %@ %@\n", 
                        sD, eD, p, title, resN];
      [p release]; p = nil;
    }
    [_context rollback];
    [self assert:NO reason:conflictString];
  }
}

- (BOOL)_setDateInfo {
  id dateInfo;
  
  if ((dateInfo = [[self object] valueForKey:@"toDateInfo"]) != nil) {
    [dateInfo takeValue:self->comment  forKey:@"comment"];
    [dateInfo takeValue:@"updated"     forKey:@"dbStatus"];
    return [[self databaseChannel] updateObject:dateInfo];
  }
  
  if (self->comment != nil)
    [self warnWithFormat:@"missing 'toDateInfo' to set comment !"];
  
  return NO;
}

- (void)_assignParticipantsInContext:(id)_context {
  if (![self->participants isNotEmpty])
    return;
  
  [_context runCommand:@"appointment::set-participants",
              @"object", [self object],
              @"participants", self->participants,
              nil];
}

- (BOOL)_checkPermissionsInContext:(id)_context {
  EOKeyGlobalID *gid;
  NSNumber      *aid;
  NSString      *t;
  NSString      *permissions;
  
  gid = [[self object] valueForKey:@"globalID"];
  t   = [[self object] valueForKey:@"title"];
    
  if (gid == nil) {
    aid = [self valueForKey:@"dateId"];
    gid = [EOKeyGlobalID globalIDWithEntityName:@"Date" 
                         keys:&aid keyCount:1 zone:NULL];
    t   = [self valueForKey:@"title"];
  }    
  permissions = LSRunCommandV(_context, @"appointment", @"access",
                              @"gid", gid, nil);
  return ([permissions rangeOfString:@"e"].length > 0) ? YES : NO;
}

- (void)_prepareForExecutionInContext:(id)_context {
  id acl;
  
  /* check permissions */
  [self assert:[self _checkPermissionsInContext:_context]
        format:@"no access to edit appointment"];
  
  [self _checkStartDateIsBeforeEndDate];
  
  if (!self->isWarningIgnored)
    [self _checkConflictsInContext:_context];

  
  /* fixup ACL values */
  
  // TBD: DUP in ::new
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

- (id)_newCyclicWithObject:(id)_object
  comment:(NSString *)_comment
  participants:(NSArray *)_participants
  ignoreWarning:(BOOL)_flag
  inContext:(id)_context
{
  if (_object  == nil) return nil;
  if (_comment == nil) _comment = (id)null;
  if (![_participants isNotEmpty])
    [self warnWithFormat:@"%s: got no participants?", __PRETTY_FUNCTION__];
  
  return LSRunCommandV(_context, @"appointment", @"new-cyclic",
                       @"cyclicAppointment", _object,
                       @"isWarningIgnored",  _flag ? yesNum : noNum,
                       @"comment",           _comment,
                       @"participants",      _participants,
		       @"customAttributes",  
		       self->customAttributes
		       ? self->customAttributes
		       : (NSDictionary *)[NSNull null],
                       nil);
}
- (void)addLogText:(NSString *)_t andAction:(NSString *)_a inContext:(id)_ctx {
  LSRunCommandV(_ctx, @"object", @"add-log",
                @"objectToLog", [self object],
                @"logText"    , _t,
                @"action"     , _a,
                nil);
}

- (void)_executeInContext:(id)_context {
  NSCalendarDate *sD, *eD;
  NSTimeZone     *tzsD, *tzeD;
  NSString       *lt, *la;
  id obj;
  
  sD  = [self valueForKey:@"startDate"];
  eD  = [self valueForKey:@"endDate"];
  obj = [self object];
  
  if (![sD isNotNull]) sD = [obj valueForKey:@"startDate"];
  if (![eD isNotNull]) eD = [obj valueForKey:@"endDate"];
  if (![sD isNotNull] || ![eD isNotNull]) {
    [self errorWithFormat:@"got no proper start-date and/or end-date"];
    return;
  }
  
  tzsD = [[[sD timeZoneDetail] retain] autorelease];
  tzeD = [[[eD timeZoneDetail] retain] autorelease];
  
  [self _increaseVersion];

  [super _executeInContext:_context];
  
  [[obj valueForKey:@"startDate"] setTimeZone:tzsD];
  [[obj valueForKey:@"endDate"]   setTimeZone:tzeD];
  
  if (self->comment != nil) [self assert:[self _setDateInfo]];
  
  if ([self->participants isNotEmpty])
    [self _assignParticipantsInContext:_context];
  
  if ([self _appointmentIsCyclic] && self->setAllCyclic) {
    id res;
    
    // IMPORTANT: this deletes all cyclic appointments and creates new ones
    // TODO: we probably want to change that?!
    res = [self _newCyclicWithObject:[self object]
                comment:self->comment
                participants:self->participants
                ignoreWarning:self->isWarningIgnored
                inContext:_context];
    [self setObject:res];
  }
  
  /* extended attributes */
  
  if ([self->customAttributes isNotNull]) {
    SkyObjectPropertyManager *pm;
    NSException *ex;
    
    pm = [_context propertyManager];
    ex = [pm takeProperties:self->customAttributes 
	     globalID:[[self object] valueForKey:@"globalID"]];
    [ex raise]; // TODO: improve cmd error handling ...
  }
  
  /* log */
  
  // first check whether the log is set as a parameter, then whether it
  // is set in the object
  if (![(lt = [self valueForKey:@"logText"]) isNotNull])
    lt = [obj valueForKey:@"logText"];
  if (![(la = [self valueForKey:@"logAction"]) isNotNull])
    la = [obj valueForKey:@"logAction"];
  
  [self addLogText:lt andAction:la inContext:_context];
}

- (void)_increaseVersion {
  id  obj;
  int objVer;
  id  lastMod;
  
  if ((obj = [self object]) == nil)
    [self warnWithFormat:@"missing object !!!"];
  
  objVer = [[obj valueForKey:@"objectVersion"] intValue] + 1;

  lastMod = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970]];

  [self takeValue:[NSNumber numberWithInt:objVer] forKey:@"objectVersion"];
  [obj  takeValue:[NSNumber numberWithInt:objVer] forKey:@"objectVersion"];

  [self takeValue:lastMod forKey:@"lastModified"];
  [obj  takeValue:lastMod forKey:@"lastModified"];
}

/* record initializer */

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

- (void)setParticipants:(NSArray *)_participants {
  ASSIGN(self->participants, _participants);
}
- (NSArray *)participants {
  return self->participants;
}
- (void)setIsWarningIgnored:(BOOL)_isWarningIgnored {
  self->isWarningIgnored = _isWarningIgnored;
}
- (BOOL)isWarningIgnored {
  return self->isWarningIgnored;
}

- (void)setSetAllCyclic:(BOOL)_setAllCyclic {
  self->setAllCyclic = _setAllCyclic;
}
- (BOOL)setAllCyclic {
  return self->setAllCyclic;
}

/* key/value coding */

- (void)takeValue:(id)_value forKey:(NSString *)_key {
  if ([_key isEqualToString:@"comment"])
    [self setComment:_value];
  else if ([_key isEqualToString:@"participants"])
    [self setParticipants:_value];
  else  if ([_key isEqualToString:@"customAttributes"]) 
    [self setCustomAttributes:_value];
  else if ([_key isEqualToString:@"isWarningIgnored"])
    [self setIsWarningIgnored:[_value boolValue]];
  else if ([_key isEqualToString:@"setAllCyclic"])
    [self setSetAllCyclic:[_value boolValue]];
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
    return [NSNumber numberWithBool:[self isWarningIgnored]];
  if ([_key isEqualToString:@"setAllCyclic"])
    return [NSNumber numberWithBool:[self setAllCyclic]];
  return [super valueForKey:_key];
}

@end /* LSSetAppointmentCommand */
