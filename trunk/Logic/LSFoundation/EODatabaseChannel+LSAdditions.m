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

#include <LSFoundation/EODatabaseChannel+LSAdditions.h>
#include "common.h"
#include <EOControl/EOKeyGlobalID.h>
#include <GDLAccess/EOSQLQualifier.h>
#include <GDLAccess/EOEntity.h>
#include <GDLAccess/EOAdaptorChannel.h>

@implementation EODatabaseChannel(LSAdditions)

- (NSArray *)globalIDsForSQLQualifier:(EOSQLQualifier *)_qualifier
  sortOrderings:(NSArray *)_sortOrderings
{
  EOAdaptorChannel *adChannel;
  EOEntity         *entity;
  NSArray          *pkeyAttrs;
  NSDictionary     *row;
  NSMutableArray   *gids;
  NSArray          *result;
  NSException      *error;
  
  NSAssert(_qualifier, @"missing qualifier ..");

  adChannel = [self adaptorChannel];
#if DEBUG
  NSAssert(adChannel, @"missing adaptor channel ..");
#endif

  /* get entity information from qualifier */

  entity    = [_qualifier entity];
  pkeyAttrs = [entity primaryKeyAttributes];
  
  /* select primary key attributes */
  
  error = [adChannel selectAttributesX:pkeyAttrs
		     describedByQualifier:_qualifier
		     fetchOrder:_sortOrderings
		     lock:NO];
  if (error != nil)
    return nil;
  
  /* perform fetch */
  
  gids = [[NSMutableArray alloc] initWithCapacity:16];
  while ((row = [adChannel fetchAttributes:pkeyAttrs withZone:NULL])) {
    EOGlobalID *gid;

    gid = [entity globalIDForRow:row];
    [gids addObject:gid];
  }
  
  result = [[gids copy] autorelease];
  [gids release];
  return result;
}
- (NSArray *)globalIDsForSQLQualifier:(EOSQLQualifier *)_qualifier {
  return [self globalIDsForSQLQualifier:_qualifier sortOrderings:nil];
}

@end /* EODatabaseChannel(LSAdditions) */

@implementation EOSQLQualifier(SpecialQualifierFormats)

- (id)initWithEntity:(EOEntity *)_entity
  keyAttributeName:(NSString *)_keyName
  globalIDs:(NSArray *)_gids
{
  unsigned count;
  
  count = [_gids count];
  
  if (count == 0) {
    /* invalid query .. */
    return [self initWithEntity:_entity qualifierFormat:@"1=2"];
  }

  if (count == 1) {
    /* single attribute query */
    EOKeyGlobalID *gid;
    
    gid = [_gids objectAtIndex:0];
    
    return [self initWithEntity:_entity
                 qualifierFormat:@"%A = %@", _keyName, [gid keyValues][0]];
  }
  
  {
    /* in query */
    NSMutableString *s;
    unsigned i;
    
    s = [[NSMutableString alloc] initWithCapacity:(count * 5)];
    for (i = 0; i < count; i++) {
      EOKeyGlobalID *gid;

      gid = [_gids objectAtIndex:i];
      
      if (i != 0) [s appendString:@","];
      [s appendString:[[gid keyValues][0] stringValue]];
    }
    
    self = [self initWithEntity:_entity
                 qualifierFormat:@"%A IN (%@)", _keyName, s];
    [s release];
    return self;
  }
}

@end /* EOSQLQualifier(SpecialQualifierFormats) */
