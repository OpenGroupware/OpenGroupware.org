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

#include <OGoFoundation/OGoComponent.h>

@interface SkyCalendarScript : OGoComponent
{
  NSString *scriptPath; // > optional: scriptPath, default: skycalendar.js
}

@end /* SkyCalendarScript */

#include "common.h"

@implementation SkyCalendarScript

static NSNumber *yesNum = nil;

+ (void)initialize {
  if (yesNum == nil) yesNum = [[NSNumber numberWithBool:YES] retain];
}

- (void)dealloc {
  [self->scriptPath release];
  [super dealloc];
}

/* accessors */

- (void)setScriptPath:(NSString *)_path {
  ASSIGNCOPY(self->scriptPath, _path);
}
- (NSString *)scriptPath {
  return self->scriptPath;
}

- (NSString *)scriptURL {
  WOResourceManager *rm;
  NSString  *url;
  WOSession *s;
  
  if ([self->scriptPath length] > 0) 
    return scriptPath;
  
  s  = [self session];
  rm = [[WOApplication application] resourceManager];
  
  url = [rm urlForResourceNamed:@"skycalendar.js"
            inFramework:nil
            languages:[s languages]
            request:[[self context] request]];
  
  if (url == nil) {
    NSLog(@"WARNING[%s]: could not locate calendar script",
          __PRETTY_FUNCTION__);
    url = @"/OpenGroupware.woa/WebServerResources/skycalendar.js";
  }

  return url;
}

/* generating response */

- (void)appendToResponse:(WOResponse *)_response inContext:(WOContext *)_ctx {
  if ([[_ctx valueForKey:@"SkyCalendarScriptIncluded"] boolValue])
    return;
  
  [super appendToResponse:_response inContext:_ctx];
  [_ctx takeValue:yesNum forKey:@"SkyCalendarScriptIncluded"];
}

@end /* SkyCalendarScript */
