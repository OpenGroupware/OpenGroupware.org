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

#include "DirectAction.h"
#include "common.h"

@implementation DirectAction(Fault)

- (NSException *)faultWithFaultCode:(int)_code
  format:(NSString *)_format,...
{
  NSString *reason;
  va_list  ap;
    
  va_start(ap, _format);
  reason = [[[NSString alloc] initWithFormat:_format arguments:ap]
                       autorelease];
  va_end(ap);
                               
  return [self faultWithFaultCode:_code reason:reason];
}

- (NSException *)faultWithFaultCode:(int)_code
  reason:(NSString *)_reason
{
  [self logWithFormat:@"Fault[%d] occured: %@", _code, _reason];

  return [[[NSException alloc] initWithName:
                               [[NSNumber numberWithInt:_code] stringValue]
                               reason:_reason userInfo:nil] autorelease];
}

- (NSException *)invalidCommandContextFault {
  return [self faultWithFaultCode:XMLRPC_FAULT_MISSING_CONTEXT
               reason:@"Missing command context"];
}

- (NSException *)invalidResultFault {
  return [self faultWithFaultCode:XMLRPC_FAULT_INVALID_RESULT
               reason:@"Invalid result for command"];
}

@end /* DirectAction(Fault) */
