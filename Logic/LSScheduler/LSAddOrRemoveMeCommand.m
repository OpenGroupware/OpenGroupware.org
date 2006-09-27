/*
  Copyright (C) 2006 Helge Hess

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

#include <LSFoundation/LSDBObjectBaseCommand.h>

/*
  appointment::add-me
  appointment::remove-me

  TODO: document
*/

@class NSString, NSNumber, NSArray, NSDictionary;

@interface LSAddOrRemoveMeCommand : LSDBObjectBaseCommand
{
  NSString *mode; /* 'add' or 'remove' */
  NSArray  *apts;
  NSString *logText;
  NSString *comment;
  NSString *role;
  NSString *partstatus;
  NSNumber *rsvp;
}

@end

#include "common.h"

@implementation LSAddOrRemoveMeCommand

- (id)initForOperation:(NSString *)_operation inDomain:(NSString *)_domain
  initDictionary:(NSDictionary *)_init
{
  self = [super initForOperation:_operation inDomain:_domain 
		initDictionary:_init];
  if (self != nil) {
    self->mode = [[_init objectForKey:@"mode"] copy];
  }
  return self;
}

- (void)dealloc {
  [self->apts       release];
  [self->logText    release];
  [self->comment    release];
  [self->role       release];
  [self->partstatus release];
  [self->rsvp       release];
  [self->mode       release];
  [super dealloc];
}

/* running the command */

- (void)_executeInContext:(LSCommandContext *)_cmdctx {
  NSMutableDictionary *newValues;
  NSArray             *aptPKeys;
  NSEnumerator        *e;
  NSNumber            *pkey, *loginId;
  
  loginId = [[_cmdctx valueForKey:LSAccountKey] valueForKey:@"companyId"];
  
  /* calculate the changeset */
  
  newValues = [NSMutableDictionary dictionaryWithCapacity:8];
  
  // values can null or an empty string to reset the stored value
  
  if (self->comment != nil)
    [newValues setObject:self->comment forKey:@"comment"];
  if (self->role != nil)
    [newValues setObject:self->role forKey:@"role"];
  if (self->partstatus != nil)
    [newValues setObject:self->partstatus forKey:@"partStatus"];
  if (self->rsvp != nil)
    [newValues setObject:self->rsvp forKey:@"rsvp"];
  
  /* extract the pkeys of the appointments we shall update */
  
  aptPKeys = [self extractPrimaryKeysNamed:@"dateId"
		   fromObjectArray:self->apts
		   inContext:_cmdctx];
  if (![aptPKeys isNotEmpty]) {
    [self debugWithFormat:@"got no appointments to work on ..."];
    return;
  }

  /* add command arguments */

  [newValues setObject:loginId forKey:@"companyId"]; // used as args
  [newValues setObject:[NSNumber numberWithBool:NO]  forKey:@"checkAccess"];
  [newValues setObject:[NSNumber numberWithBool:YES] forKey:@"isStaff"];
  
  if ([self->logText isNotEmpty])
    [newValues setObject:self->logText forKey:@"logText"];
  
  /* perform update */
  // TODO: not efficient for many entries yet ...

  e = [aptPKeys objectEnumerator];
  while ((pkey = [e nextObject]) != nil) {
    id assignment;

    /* check whether we are an attendee */
    
    assignment = LSRunCommandV(_cmdctx, @"datecompanyassignment", @"get",
			       @"operator",    @"AND",
			       @"dateId",      pkey,
			       @"companyId",   loginId,
			       /* we just operate on the login */
			       @"checkAccess", [NSNumber numberWithBool:NO],
			       nil);
    if ([assignment isKindOfClass:[NSArray class]])
      assignment = [assignment isNotEmpty] ? [assignment lastObject] : nil;

    /* add necessary arguments */
    if (assignment != nil)
      [newValues setObject:assignment forKey:@"object"];
    else
      [newValues removeObjectForKey:@"object"];
    
    [newValues setObject:pkey forKey:@"dateId"];

    /* perform add or remove */
    
    if ([self->mode isEqualToString:@"add"]) {
      if ([assignment isNotNull]) {
	/* we are already an attendee */
	// Note: we do not update role information
	continue;
      }
      
      [_cmdctx runCommand:@"datecompanyassignment::new"
	       arguments:newValues];
    }
    else {
      LSDBObjectDeleteCommand *dCmd;
      
      if (![assignment isNotNull]) {
	/* we are not an attendee, no need to remove us */
	continue;
      }
      
      dCmd = LSLookupCommandV(@"DateCompanyAssignment", @"delete",
			      @"object", assignment, nil);
      [dCmd setReallyDelete:YES];
      [dCmd runInContext:_cmdctx];
    }
    
    /* cleanup temporary state */
    [newValues removeObjectForKey:@"dateId"];
    [newValues removeObjectForKey:@"object"];
    
    //[self logWithFormat:@"O: %@", assignment];
    //[self logWithFormat:@"VALS: %@", newValues];
    //[_cmdctx runCommand:@"datecompanyassignment::set" arguments:newValues];
    
    
    /* add the log (to the appointment, not the relationship!!) */
    
    if ([self->logText isNotEmpty]) {
      LSRunCommandV(_cmdctx, @"object", @"add-log",
		    @"objectId", pkey,
		    @"logText",  self->logText,
		    @"action",   @"05_changed",
		    nil);
    }
  }
  
  [newValues removeAllObjects];
  
  /* post change notifications */
  
  // currently done at UI level
  // we would probably want to post just GIDs?
  //   [self postChange:LSWUpdatedAppointmentNotificationName
  //         onObject:_eo];
  
  [self setReturnValue:[NSNumber numberWithBool:YES]];
}

/* accessors */

- (void)setAppointments:(NSArray *)_apts {
  ASSIGN(self->apts, _apts);
}
- (NSArray *)appointments {
  return self->apts;
}

- (void)setLogText:(NSString *)_value {
  ASSIGNCOPY(self->logText, _value);
}
- (NSString *)logText {
  return self->logText;
}

- (void)setComment:(NSString *)_value {
  ASSIGNCOPY(self->comment, _value);
}
- (NSString *)comment {
  return self->comment;
}

- (void)setRole:(NSString *)_value {
  ASSIGNCOPY(self->role, _value);
}
- (NSString *)role {
  return self->role;
}

- (void)setPartstatus:(NSString *)_value {
  ASSIGNCOPY(self->partstatus, _value);
}
- (NSString *)partstatus {
  return self->partstatus;
}

- (void)setRsvp:(NSNumber *)_value {
  ASSIGNCOPY(self->rsvp, _value);
}
- (NSNumber *)rsvp {
  return self->rsvp;
}

/* KVC */

- (void)takeValue:(id)_value forKey:(NSString *)_key {
  if ([_key isEqualToString:@"gids"])
    [self setAppointments:_value];
  else if ([_key isEqualToString:@"gid"]) {
    [self setAppointments:
	    [_value isNotNull] ? [NSArray arrayWithObject:_value] : nil];
  }
  else if ([_key isEqualToString:@"appointments"])
    [self setAppointments:_value];
  else if ([_key isEqualToString:@"appointment"]) {
    [self setAppointments:
	    [_value isNotNull] ? [NSArray arrayWithObject:_value] : nil];
  }
  else if ([_key isEqualToString:@"comment"])
    [self setComment:_value];
  else if ([_key isEqualToString:@"role"])
    [self setRole:_value];
  else if ([_key isEqualToString:@"partstatus"] || 
	   [_key isEqualToString:@"partStatus"])
    [self setPartstatus:_value];
  else if ([_key isEqualToString:@"rsvp"])
    [self setRsvp:_value];
  else if ([_key isEqualToString:@"logText"])
    [self setLogText:_value];
  else
    [super takeValue:_value forKey:_key];
}

- (id)valueForKey:(NSString *)_key {
  if ([_key isEqualToString:@"gids"])
    return [self appointments];
  
  if ([_key isEqualToString:@"gid"])
    return [[self appointments] lastObject];
  
  if ([_key isEqualToString:@"appointments"])
    return [self appointments];

  if ([_key isEqualToString:@"appointment"])
    return [[self appointments] lastObject];

  if ([_key isEqualToString:@"comment"])
    return [self comment];
  if ([_key isEqualToString:@"role"])
    return [self role];
  if ([_key isEqualToString:@"partstatus"] || 
      [_key isEqualToString:@"partStatus"])
    return [self partstatus];
  if ([_key isEqualToString:@"rsvp"])
    return [self rsvp];
  if ([_key isEqualToString:@"logText"])
    return [self logText];
  
  return [super valueForKey:_key];
}

@end /* LSAddOrRemoveMeCommand */
