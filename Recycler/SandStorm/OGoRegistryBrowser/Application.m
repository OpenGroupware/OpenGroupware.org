/*
  Copyright (C) 2000-2003 SKYRIX Software AG

  This file is part of OGo

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
// $Id$

#import <Foundation/Foundation.h>
#include <NGObjWeb/NGObjWeb.h>

@interface Application : WOApplication
{
}
@end

@implementation Application

- (id)init {
  if ((self = [super init])) {
    WORequestHandler *rh;
    
    rh = [[NSClassFromString(@"OWViewRequestHandler") alloc] init];
    [self setDefaultRequestHandler:rh];
    [self registerRequestHandler:rh
          forKey:[WOApplication componentRequestHandlerKey]];
    RELEASE(rh); rh = nil;
  }
  return self;
}

- (WOResponse *)handleException:(NSException *)_exc inContext:(id)_ctx {
  if ([[NSUserDefaults standardUserDefaults]
                       boolForKey:@"CoreOnException"] == NO)
    return [super handleException:_exc inContext:_ctx];
  
  NSLog(@"%@", _exc);
  abort();
  return nil;
}

@end /* Application */

int main(int argc, char **argv) {
  return WOApplicationMain(@"Application", argc, (void*)argv);
}
