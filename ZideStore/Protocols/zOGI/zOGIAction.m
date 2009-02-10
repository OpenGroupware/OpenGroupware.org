/*
  Copyright (C) 2006-2007 Whitemice Consulting

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

  This class is the core of the zOGI RPC.  This file provides the utility
  methods used throughout zOGI to try and provide both clean looking 
  code and mercilessly consistent results.  The actual RPC calls are
  in zOGIRPCAction and the functions specific to each document type
  are located in categories of this object;  zOGIAction+Project for
  example.  All zOGI RPC actions take a maximum of four arguments.
*/

#include "zOGIAction.h"
#include "zOGIAction+Defaults.h"

@implementation zOGIAction

static int zOGIDebugOn = -1;
static int zOGIProfileOn = -1;

-(id)init
{
  self = [super init];
  if (self)
  {
    eoCache = [NSMutableDictionary dictionaryWithCapacity:128];
  }
  return self;
}

- (void)dealloc 
{
  [self->arg1 release];
  [self->arg2 release];
  [self->arg3 release];
  [self->arg4 release];
  [self->eoCache release];
  [super dealloc];
}

/* accessors */

- (BOOL)isDebug 
{
  if (zOGIDebugOn == -1)
    zOGIDebugOn = [[NSUserDefaults standardUserDefaults]
                      boolForKey:@"zOGIDebugEnabled"];
  return zOGIDebugOn;
}

- (BOOL)isProfile
{
  if (zOGIProfileOn == -1)
    zOGIProfileOn = [[NSUserDefaults standardUserDefaults]
                      boolForKey:@"zOGIProfileEnabled"];
  return zOGIProfileOn;
}

- (void)setArg1:(id)_arg 
{
  ASSIGN(self->arg1, _arg);
}

- (id)arg1 
{
  return self->arg1;
}

- (void)setArg2:(id)_arg 
{
  ASSIGN(self->arg2, _arg);
}

- (id)arg2 
{
  return self->arg2;
}

- (void)setArg3:(id)_arg 
{
  ASSIGN(self->arg3, _arg);
}

- (id)arg3 
{
  return self->arg3;
}

- (void)setArg4:(id)_arg 
{
  ASSIGN(self->arg4, _arg);
}

- (id)arg4 
{
  return self->arg4;
}

- (id)defaultAction
{
  return nil;
}

/************** Helper Methods & Accessors ***********/

/* Turns a nil/NULL value into an NSNull 
   The NSNull can be included in an NSDictionary */
- (id)NIL:(id)_arg 
{
  if (_arg == nil)
    return [NSNull null];
  return _arg;
}

/* Return a zero if the argument is null/nill or
   return the intValue;  this will convert an 
   empty string into a zero value */
- (NSNumber *)ZERO:(id)_arg
{
  if (_arg == nil)
    return [NSNumber numberWithInt:0];
  return [NSNumber numberWithInt:[_arg intValue]];
}

/* Get the current command context */
- (LSCommandContext *)getCTX 
{
  if (ctx == nil) {
    ctx = [[self clientObject] commandContextInContext:[self context]];
   }
  return ctx;
}

/*
  Turn a value into an EOGlobalID if possible
  _arg may be an NSString or an NSNumber
  Returns nil if the PKey is not valid
*/
- (EOGlobalID *)_getEOForPKey:(id)_arg 
{
  EOGlobalID             *gid;
  id                      tmp;

  /* Short circuit; if we go a EOGlobalID just return it */
  if (([_arg isKindOfClass:[EOGlobalID class]]) ||
      ([_arg isKindOfClass:[EOKeyGlobalID class]]))
    return _arg;

  /* Assume gid lookup will fail */
  gid = nil;

  /* Process the argument into a number -> tmp
     If the argument is a string, try to make a number */
  tmp = [NSNumber numberWithInt:[_arg intValue]];
  if ([tmp intValue] == 0)
  {
    [self warnWithFormat:@"Arguement not understood by getEOForPKey"];
    /* TODO: THROW AN EXCEPTION */
    tmp = nil;
  }

  /* Process if we where able to numberfy the argument */
  if (tmp != nil)
  {
    if ([eoCache objectForKey:tmp] == nil)
    {
      /* Lookup and store result in cache */
      gid = [[[self getCTX] typeManager] globalIDForPrimaryKey:tmp];
      if (gid == nil)
        [eoCache setObject:[EONull null] forKey:tmp];
      else
        [eoCache setObject:gid forKey:tmp];
    } else 
      {
        /* Return result from cache */
        gid = [eoCache objectForKey:tmp];
        if ([gid class] == [EONull class])
          gid = nil;
        if ([self isDebug])
          [self logWithFormat:@"Returning EO from cache"];
      }
  } /* End if (tmp != nil) */

  if (gid == nil) 
  {
    [self warnWithFormat:@"unable to generate EOId, returning nil"];
    return nil;
  } 
  return gid;
} /* End _getEOForPKey */

/*
  Returns the primary key for the provided EOGlobalID
*/
- (NSString *)_getPKeyForEO:(EOKeyGlobalID *)_arg 
{
  return [[[_arg keyValuesArray] objectAtIndex: 0] valueForKey:@"stringValue"];
}

/* Get EOs for a collection of PKeys 
   If _arge is a single value (NSNumber or NSString) then an array of
   a single result is returned.  If the _arg is an NSDictionary each
   of the keys is assumed to be a PKey and the keys are enumerated. */
- (NSArray *)_getEOsForPKeys:(id)_arg 
{
  NSMutableArray      *pkeys;
  NSArray             *result;
  id                   tmp;
  int                  i;

  pkeys = nil;

  if (_arg == nil) 
  {
    [self warnWithFormat:@"argument for getEOsForPKeys is nil"];
    return [result initWithObjects: nil]; 
  }

  /* If the _arg is a single value */
  if ([_arg isKindOfClass:[NSString class]] ||
      [_arg isKindOfClass:[EOGlobalID class]] ||
      [_arg isKindOfClass:[NSNumber class]]) 
  {
    result = [NSArray arrayWithObject:[self _getEOForPKey:_arg]];
    return result;
  } /* End if-arg-is-a-string-or-a-number */

  /* _arg is a multiple value */
  pkeys = [NSMutableArray arrayWithCapacity:64];
  if ([_arg isKindOfClass:[NSArray class]]) 
  {
    [pkeys addObjectsFromArray: _arg] ;
  } else if ([_arg isKindOfClass:[NSDictionary class]]) 
    {
      [pkeys addObjectsFromArray:[_arg allKeys]];
    } else 
      {
        [self warnWithFormat:@"Unknown arg type for getEOsForPKeys"];
        return [result initWithObjects: nil]; 
        /* TODO: THROW AN EXCEPTION! */
      }
  
  if ([[pkeys objectAtIndex:0] isKindOfClass:[EOKeyGlobalID class]])
    return pkeys;

  /* Normalize array values to NSNumbers */
  for(i = 0; i < [pkeys count]; i++ ) 
  {
    if ([[pkeys objectAtIndex:i] isKindOfClass:[NSNumber class]]) 
    {
      /* We don't need to do anything, already a number */
    } else if ([[pkeys objectAtIndex:i] isKindOfClass:[NSString class]]) 
      {
         /* Convert any NSString values into NSNumbers */
         tmp = [NSNumber numberWithInt:[[pkeys objectAtIndex:i] intValue]];
         if ([tmp intValue] == 0)
         {
           [self warnWithFormat:@"Discarding %@ in Pk->EO conversion",
              [pkeys objectAtIndex:i]];
         } else
             [pkeys replaceObjectAtIndex:i withObject:tmp];
      } 
         else [self warnWithFormat:@"Discarding %@ in Pk->EO conversion",
                  [pkeys objectAtIndex:i]];
  } /* End of cleaning for */

  result = [[[self getCTX] typeManager] globalIDsForPrimaryKeys:pkeys];
  if ([result containsObject:[NSNull null]]) 
  {
     /* TODO: THROW AN EXCEPTION */
  }
  return result;
} /* End _getEOsForPKeys */


/* Return the Logic Entity name for the specified primary key 
   _arg may be a string id or an EOGlobalId 
   Will return "Unknown" if the primary key is not valid */
- (NSString *)_getEntityNameForPKey:(id)_arg 
{
  EOGlobalID             *gid;

  gid = nil;
  /* If _args is a Number then attempt the lookup */
  if([_arg isKindOfClass:[EOGlobalID class]])
     gid = _arg;
    else
      gid = [self _getEOForPKey:_arg];
  if (gid == nil)
    return @"Unknown";
  return [[gid entityName] valueForKey:@"stringValue"];
} /* End _getEntityNameForPKey */

/* Translate a Logic entity name into a zOGI entity name
   TODO: Can we do this with SOPE rules instead?
   _arg must be a string */
- (NSString *)_izeEntityName:(NSString *)_arg 
{
  NSString               *result;

  if ([_arg isEqualToString:@"Date"])
    result = [NSString stringWithString:@"Appointment"];
  else if ([_arg isEqualToString:@"CompanyValue"])
    result = [NSString stringWithString:@"companyValue"];
  else if ([_arg isEqualToString:@"Telephone"])
    result = [NSString stringWithString:@"telephone"];
  else if ([_arg isEqualToString:@"Person"])
    result = [NSString stringWithString:@"Contact"];
  else if ([_arg isEqualToString:@"JobHistoryInfo"])
    result = [NSString stringWithString:@"taskAnnotation"];
  else if ([_arg isEqualToString:@"Log"])
    result = [NSString stringWithString:@"logEntry"];
  else if ([_arg isEqualToString:@"Job"])
    result = [NSString stringWithString:@"Task"];
  else if ([_arg isEqualToString:@"Doc"])
    result = [NSString stringWithString:@"File"];
  else
    result = _arg;
  return result;
} /* End _izeEntityName */

/*  Check if all the provided pkeys (or EOGlobalIDs) are one of the 
    provided entityNames. 

    _pkey can be an NSString, an NSNumber, an EOGlobalID or an NSArray
       containing any of the previously listed classes.
    _entityName can be either an NSString or an NSArray of NSStrings. */
- (id)_checkEntity:(id)_pkey entityName:(id)_name {
  NSEnumerator *pkeyEnumerator, *entityEnumerator;
  NSArray      *pkeys, *entityNames;
  NSString     *entityName, *en;
  id           pkey;
  int          count;

  /* if _pkey is not an array, make a single entry array */
  if(![_pkey isKindOfClass:[NSArray class]])
     pkeys = [NSArray arrayWithObject:_pkey];
    else
      pkeys = _pkey;

  /* if _name is not an array, make a single entry array */
  if(![_name isKindOfClass:[NSArray class]])
     entityNames = [NSArray arrayWithObject:_name];
    else
      entityNames = _name;

  pkeyEnumerator = [pkeys objectEnumerator];
  while ((pkey = [pkeyEnumerator nextObject]) != nil) 
  {
    entityName = [self _getEntityNameForPKey:pkey];
    count = [entityNames count];
    entityEnumerator = [entityNames objectEnumerator];
    while ((en = [entityEnumerator nextObject]) != nil) 
    {
      if ([entityName isEqualToString:en])
        count--;
    } /* End while-entity-loop */
    if (count == [entityNames count])
      return [NSNumber numberWithBool:NO];
  } /* End while-pkey-loop */
  return [NSNumber numberWithBool:YES];
} /* End _checkEntity */

/* Get the current users companyId value */
- (NSNumber *)_getCompanyId 
{
  return [[[self getCTX] valueForKey:LSAccountKey] valueForKey:@"companyId"];
} /* End _getCompanyId */

/* Get the current users EOGlobalID */
- (id)_getGlobalId 
{
  return [[[self getCTX] valueForKey:LSAccountKey] globalID];
} /* End _getGlobalId */

/* Get the current users default timezone */
- (NSTimeZone *)_getTimeZone 
{
  NSTimeZone     *tz = nil;

  tz = [NSTimeZone timeZoneWithAbbreviation:[self _getDefault:@"timezone"]];
  return tz;
} /* End _getTimeZone */

- (NSCalendarDate *)_makeCalendarDate:(id)_date
{
  return [self _makeCalendarDate:(id)_date withZone:nil];
}

/* Make the specified value into a calendar date
   NOTE: There has got to be a better way to do this
   BUG: What about timezones? */
- (NSCalendarDate *)_makeCalendarDate:(id)_date withZone:(id)_zone {
  NSCalendarDate *dateValue;
  NSTimeZone     *timeZone;
  int             zoneDiff;

  if ([self isDebug])
    [self logWithFormat:@"makeCalendarDate received %@", _date];

  /* if no _zone was provided we assume GMT */
  if ([_zone isNotNull])
    timeZone = _zone;
  else
    timeZone = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];

  /* if _date is a date then we take it as is, otherwise if _date
     is a string we convert it from a string based upon the 
     length;  currently supports 2007-11-09 and 2007-11-09 06:06 */
  dateValue = nil;
  if ([_date isKindOfClass:[NSCalendarDate class]])
    dateValue = _date;
  else if ([_date isKindOfClass:[NSString class]])  {
    if ([_date length] == 10)
      dateValue = [NSCalendarDate dateWithString:_date
                             calendarFormat:@"%Y-%m-%d"];
    else if ([_date length] == 16)
      dateValue = [NSCalendarDate dateWithString:_date
                             calendarFormat:@"%Y-%m-%d %H:%M"];
  }

  /* if we successfuly aquired a date then make an adjustment to
     GMT if a timezone was provided;  GMT values are not changed. */
  if ([dateValue isNotNull]) {
    zoneDiff = [timeZone secondsFromGMTForDate:dateValue];
    if (zoneDiff != 0)
      dateValue = [dateValue dateByAddingYears:0
                                        months:0
                                          days:0
                                         hours:0
                                       minutes:0
                                       seconds:(zoneDiff * -1)];
  } else return nil;

  if ([self isDebug])
    [self logWithFormat:@"makeCalendarDate returned %@", dateValue];

  /* Stamp the time we retun as GMT so that it gets written into 
     the database correctly */
  [dateValue setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"GMT"]];

  return dateValue;
} /* End _makeCalendarDate */

/* Remove keys from the provided dictionary if they begin
   with an asterisk character */
- (void)_stripInternalKeys:(NSMutableDictionary *)_dictionary 
{
  NSEnumerator  *enumerator;
  NSString      *key;

  enumerator = [_dictionary keyEnumerator];
  while ((key = [enumerator nextObject]) != nil)
    if ([[key substringToIndex:1] isEqualToString:@"*"])
      [_dictionary removeObjectForKey:key];
} /* End _stripInternalKeys */

@end /* zOGIAction */
