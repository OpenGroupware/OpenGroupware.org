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

#include "SkyAptAction.h"
#import <Foundation/Foundation.h>
#include <OGoDaemon/SDXmlRpcFault.h>

@implementation SkyAptAction(LastError)

- (void)setLastError:(NSString *)_name
           errorCode:(int)_errorCode
         description:(NSString *)_desc
{
  NSDictionary *ui = [NSDictionary dictionaryWithObject:
                                   [self->lastError valueForKey:@"faultCode"]
                                   forKey:@"faultCode"];
  RELEASE(self->lastError);
  self->lastError =
    [[NSException alloc] initWithName:_name reason:_desc userInfo:ui];
}

- (NSException *)invalidArgument:(NSString *)_argName {
  id err = [SDXmlRpcFault missingValueFaultForArgument:_argName];
  ASSIGN(self->lastError, err);
  return err;
}

- (NSException *)editedByAnotherUserError {
  id err = [SDXmlRpcFault invalidObjectVersionFault];
  ASSIGN(self->lastError, err);
  return err;
}

- (NSException *)invalidAppointmentId:(NSString *)_aptId {
  id err = [SDXmlRpcFault invalidObjectFaultForId:_aptId
                          entity:@"appointment"];
  ASSIGN(self->lastError, err);
  return err;
}

- (NSException *)lastError {
  return self->lastError;
}

@end /* SkyAptAction(LastError) */

