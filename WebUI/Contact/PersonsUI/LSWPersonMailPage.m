/*
  Copyright (C) 2000-2004 SKYRIX Software AG

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

#include <OGoFoundation/OGoObjectMailPage.h>

@interface LSWPersonMailPage : OGoObjectMailPage
@end

@interface LSWPersonHtmlMailPage : LSWPersonMailPage
@end

@interface LSWPersonTextMailPage : LSWPersonMailPage
@end

#include "common.h"

@implementation LSWPersonMailPage

- (NSString *)entityName {
  return @"Person";
}

- (NSString *)getCmdName {
  return @"person::get";
}

- (NSString *)objectUrlKey {
  id s;
  
  s = [[self object] valueForKey:@"companyId"];
  if (![s isNotNull]) return nil;
  
  s = [s stringValue];
  if ([s length] == 0) return nil;
  
  return [@"wa/LSWViewAction/viewPerson?companyId=" stringByAppendingString:s];
}

@end /* LSWPersonMailPage */

@implementation LSWPersonHtmlMailPage
@end /* LSWPersonHtmlMailPage */

@implementation LSWPersonTextMailPage
@end /* LSWPersonTextMailPage */
