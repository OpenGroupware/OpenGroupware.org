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

#include "SxEnterprise.h"
#include "SxEnterpriseFolder.h"
#include "SxVCardEnterpriseRenderer.h"
#include <ZSBackend/SxContactManager.h>
#include <ZSBackend/SxUpdateEnterprise.h>
#include <ZSFrontend/SxFolder.h>
#include <ZSFrontend/SxRendererFactory.h>
#include <ZSFrontend/SxRenderer.h>
#include <ZSFrontend/NSObject+ExValues.h>
#include "common.h"


@implementation SxEnterprise

/* updating/inserting */

- (NSString *)entityName {
  return @"Enterprise";
}
- (NSString *)updateCommandName {
  return @"enterprise::set";
}
- (NSString *)newCommandName {
  return @"enterprise::new";
}
+ (NSString *)getCommandName {
  return @"enterprise::get";
}
+ (NSString *)deleteCommandName {
  return @"enterprise::delete";
}

/* updates */

- (BOOL)fillCompanyRecord:(NSMutableDictionary *)values
  from:(NSDictionary *)_setProps
  keySet:(NSMutableArray *)keys
{
  NSMutableArray *ma;
  id       value;
  NSString *gn, *sn, *mn, *o;
  NSString *ename = nil;
  
  /* calculate description */
  
  if ((o = [_setProps objectForKey:@"o"]))
    [keys removeObject:@"o"];
  
  ma = [NSMutableArray arrayWithCapacity:4];
  if ((gn = [_setProps objectForKey:@"givenName"])) {
    if (o != nil && [o rangeOfString:gn].length != 0)
      /* givenname is contained in organization */
      gn = nil;
    else if ([gn length] == 0)
      gn = nil;
    if (gn != nil) [ma addObject:gn];
    [keys removeObject:@"givenName"];
  }
  if ((mn = [_setProps objectForKey:@"middleName"])) {
    if (o != nil && [o rangeOfString:mn].length != 0)
      /* middlename is contained in organization */
      mn = nil;
    else if ([mn length] == 0)
      mn = nil;
    if (mn != nil) [ma addObject:mn];
    [keys removeObject:@"middleName"];
  }
  if ((sn = [_setProps objectForKey:@"sn"])) {
    if (o != nil && [o rangeOfString:sn].length != 0)
      /* surname is contained in organization */
      sn = nil;
    else if ([sn length] == 0)
      sn = nil;
    if (sn != nil) [ma addObject:sn];
    [keys removeObject:@"sn"];
  }
  
  if ([o length] == 0) {
    /* need to calc organization */
    ename = [ma componentsJoinedByString:@" "];
  }
  else if ([ma count] > 0) {
    /* got an organization, add other attributes */
    ename = [NSString stringWithFormat:@"%@ (%@)", ename,
		        [ma componentsJoinedByString:@" "]];
  }
  else
    ename = o;

  /* apply cname */
  [values setObject:ename forKey:@"description"];
  
  /* map 'nickname' to 'number' */
  if ((value = [_setProps objectForKey:@"nickname"])) {
    [values setObject:value forKey:@"number"];
    [keys removeObject:@"nickname"];
  }
  if ((value = [_setProps objectForKey:@"businesshomepage"])) {
    [values setObject:value forKey:@"url"];
    [keys removeObject:@"businesshomepage"];
  }
  
  if ((value = [_setProps objectForKey:@"bday"])) {
    NSCalendarDate *cdate;
    
    cdate = [NSCalendarDate dateWithExDavString:[value stringValue]];
    [self logWithFormat:@"got date: %@ for string: '%@'", cdate, value];
    /* TODO: add to values */
    
    [keys removeObject:@"bday"];
  }
  return YES;
}

- (Class)selfRendererClass {
  static Class RendererClass = Nil;
  static BOOL didInit = NO;
  if (!didInit) {
    NSString *className = @"SxZLFullEnterpriseRenderer";
    didInit = YES;
    
    if ((RendererClass = NSClassFromString(className)) == Nil)
      [self logWithFormat:@"Note: attempt to access '%@'", className];
    // TODO: need a fallback renderer
  }
  return RendererClass;
}

- (NSArray *)davQueryOnSelf:(EOFetchSpecification *)_fs inContext:(id)_ctx {
  /* Note: this is also called for bulk fetches */
  NSDictionary               *res;
  SxContactManager           *manager;
  id                         render;
  
  manager =
    [SxContactManager managerWithContext:[self commandContextInContext:_ctx]];
  
  res = [[manager fullObjectInfosForPrimaryKeys:
		    [NSArray arrayWithObject:[self primaryKey]]
		  withSetIdentifier:
                    [(SxEnterpriseFolder *)[self container] contactSetID]]
                  lastObject];
  
  if (res == nil) {
    [self logWithFormat:@"enterprise does not exist: %@", 
            [self nameInContainer]];
    return [NSException exceptionWithHTTPStatus:404 /* not found */
                        reason:@"tried to lookup invalid enterprise key"];
  }
  
  if ((render = [self selfRendererClass]) != Nil) {
    render = [render  rendererWithContext:_ctx
		      baseURL:[(SxFolder *)[self container] baseURL]];
    res    = [render renderEntry:res];
  }
  else /* fallback, return SoObject to SOPE WebDAV layer */
    res = (id)self;

  return (res != nil) ? [NSArray arrayWithObject:res] : nil;
}

- (Class)updateClass {
  static Class SxUpdateEnterpriseClass = NULL;

  if (SxUpdateEnterpriseClass == NULL) {
   SxUpdateEnterpriseClass =
      NSClassFromString(@"SxUpdateEnterprise");
  }
  return SxUpdateEnterpriseClass;
}

- (Class)zideLookParserClass {
  static Class SxZLFullEnterpriseParserClass = NULL;

  if (SxZLFullEnterpriseParserClass == NULL) {
    SxZLFullEnterpriseParserClass =
      NSClassFromString(@"SxZLFullEnterpriseParser");
  }
  return SxZLFullEnterpriseParserClass;
}

- (Class)evolutionParserClass {
  static Class SxEvoFullEnterpriseParserClass = NULL;

  if (SxEvoFullEnterpriseParserClass == NULL) {
    SxEvoFullEnterpriseParserClass =
      NSClassFromString(@"SxEvoFullEnterpriseParser");
  }
  return SxEvoFullEnterpriseParserClass;
}

@end /* SxEnterprise */
