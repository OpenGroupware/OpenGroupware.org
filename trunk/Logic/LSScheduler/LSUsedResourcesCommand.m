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

#include <LSFoundation/LSDBObjectBaseCommand.h>

/*
  This command returns the used resources in the given time interval.
  The search could be restricted by a category.
*/

@class NSCalendarDate, NSString;

@interface LSUsedResourcesCommand : LSDBObjectBaseCommand
{
  NSCalendarDate *startDate;
  NSCalendarDate *endDate;
  NSString       *category;
}

@end

#include "common.h"

@implementation LSUsedResourcesCommand

- (void)dealloc {
  [self->startDate release];
  [self->endDate   release];
  [self->category  release];
  [super dealloc];
}

/* preparation */

- (void)_prepareForExecutionInContext:(id)_context {
  /* check date range */
  if ((self->startDate != nil) && (self->endDate != nil))
    [self assert:
	    ([self->startDate compare:self->endDate] != NSOrderedDescending)
          reason:@"invalid date range"];
  else
    [self assert:YES
          reason:@"missing arguments"];
}

/* execute query */

- (EOSQLQualifier *)_qualifierForStartDate:(NSCalendarDate *)_startDate
  endDate:(NSCalendarDate *)_endDate
  entity:(EOEntity *)_entity adaptor:(EOAdaptor *)_adaptor
{
  EOSQLQualifier *qualifier;
  EOAttribute    *fmtAttribute;
  NSString *fmtStart  = nil;
  NSString *fmtEnd    = nil;

  /* can be any date-attr */
  fmtAttribute = [_entity attributeNamed:@"startDate"];
  
  fmtStart = [_adaptor formatValue:_startDate forAttribute:fmtAttribute];
  fmtEnd   = [_adaptor formatValue:_endDate   forAttribute:fmtAttribute];
  
  qualifier = [[EOSQLQualifier alloc] initWithEntity:_entity
                                      qualifierFormat:
                                      @"((%A >= %@) AND (%A < %@)) OR "
                                      @"((%A > %@) AND (%A <= %@)) OR "
                                      @"((%A <= %@) AND (%A >= %@))",
                                      @"startDate", fmtStart,
                                      @"startDate", fmtEnd,
                                      @"endDate",   fmtStart,
                                      @"endDate",   fmtEnd,
                                      @"startDate", fmtStart,
                                      @"endDate",   fmtEnd];
  return [qualifier autorelease];
}

- (EOSQLQualifier *)_qualifierForResourceNames:(id)_r
  entity:(EOEntity *)_entity
{
  // Note: returns retained qualifier
  EOSQLQualifier *resQual;

  resQual = [[EOSQLQualifier alloc]
	      initWithEntity:_entity
	      qualifierFormat:
		@"((%A LIKE '%@') OR (%A LIKE '%@,%%') "
	        @"OR (%A LIKE '%%, %@') OR (%A LIKE '%%, %@,%%'))",
	        @"resourceNames", _r, @"resourceNames", _r,
	        @"resourceNames", _r, @"resourceNames", _r, nil];
  return resQual;
}

- (NSArray *)_fetchResourcesForCategory:(NSString *)_cat inContext:(id)_ctx {
  return LSRunCommandV(_ctx, @"appointmentresource", @"categories",
		       @"category", _cat, nil);
}

- (void)_executeInContext:(id)_ctx {
  EOSQLQualifier   *qualifier = nil;
  EOEntity         *entity    = nil;
  EOAdaptorChannel *channel   = nil;
  NSArray          *attrs     = nil;
  NSMutableSet     *result    = nil;
  NSDictionary     *dict      = nil;
  EOAdaptor        *adaptor      = nil;
  NSArray          *resolvedCat  = nil;

  adaptor = [[_ctx valueForKey:LSDatabaseKey] adaptor];
  entity  = [[adaptor model] entityNamed:@"Date"];
  
  qualifier = [self _qualifierForStartDate:self->startDate 
		    endDate:self->endDate entity:entity adaptor:adaptor];
  
  if (self->category != nil) {
    resolvedCat = [self _fetchResourcesForCategory:self->category 
			inContext:_ctx];
    if (resolvedCat != nil) {
      EOSQLQualifier *andQual = nil;
      NSEnumerator   *resEnum = nil;
      id           r         = nil;
      resEnum = [resolvedCat objectEnumerator];
      
      andQual = [[EOSQLQualifier alloc] initWithEntity:entity
                                        qualifierFormat:@"1=1"];        
      while ((r = [resEnum nextObject])) {
        EOSQLQualifier *resQual = nil;
	
	resQual = [self _qualifierForResourceNames:r entity:entity];
        [andQual disjoinWithQualifier:resQual];
        [resQual release]; resQual = nil;
      }
      [qualifier conjoinWithQualifier:andQual];
      [andQual release]; andQual = nil;
    }
  }
  [qualifier setUsesDistinct:YES];
  
  channel = [[_ctx valueForKey:LSDatabaseChannelKey] adaptorChannel];
  attrs   = [NSArray arrayWithObject:[entity attributeNamed:@"resourceNames"]];
  
  if (![channel selectAttributes:attrs describedByQualifier:qualifier
		fetchOrder:nil lock:NO])
    // TODO: log some error?
    return;

  result = [NSMutableSet setWithCapacity:64];
    
  while ((dict = [channel fetchAttributes:attrs withZone:NULL])) {
      id rN; // TODO: what type?
      NSEnumerator *res = nil;
      id           r    = nil;
      
      rN = [dict valueForKey:@"resourceNames"];
      if (!(rN != nil && rN  != [EONull null]))
	continue;

      res = [[rN componentsSeparatedByString:@", "] objectEnumerator];
      while ((r = [res nextObject])) {
	if (resolvedCat != nil) {
	  if ([resolvedCat containsObject:r])
	    [result addObject:r];
	}
	else
	  [result addObject:r];
      }
  }
  [self setReturnValue:result];
}

/* key-value coding */

- (void)takeValue:(id)_value forKey:(id)_key {
  if ([_key isEqualToString:@"startDate"])
    ASSIGN(self->startDate, _value);
  else if ([_key isEqualToString:@"endDate"])
    ASSIGN(self->endDate, _value);
  else if ([_key isEqualToString:@"category"])
    ASSIGN(self->category, _value);
  else
    [super takeValue:_value forKey:_key];
}

- (id)valueForKey:(id)_key {
  id v = nil;
  if ([_key isEqualToString:@"startDate"])
    v = self->startDate;
  else if ([_key isEqualToString:@"endDate"])
    v = self->endDate;
  else if ([_key isEqualToString:@"category"])
    v = self->category;
  else 
    v = [super valueForKey:_key];
  return v;
}

@end /* LSQueryAppointments */
