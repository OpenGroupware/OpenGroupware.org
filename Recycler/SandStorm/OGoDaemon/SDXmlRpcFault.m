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

#include "SDXmlRpcFault.h"
#include "common.h"

@implementation SDXmlRpcFault

+ (NSException *)_buildExceptionWithNumber:(int)_number
  reason:(NSString *)_reason
  command:(char *)_function
{
  NSLog(@"WARNING[%s]: exception[%d]: %@",
        _function, _number, _reason);
  return AUTORELEASE([[NSException alloc] initWithName:
                                          [[NSNumber numberWithInt:_number]
                                                     stringValue]
                                          reason:_reason userInfo:nil]);
}

+ (NSException *)invalidObjectFaultForId:(NSString *)_aid
  entity:(NSString *)_entity
{
  NSString *reason;

  reason = [NSString stringWithFormat:@"No %@ with gid '%@' found",
                     _entity, _aid];

  return [self _buildExceptionWithNumber:XMLRPC_FAULT_INVALID_OBJECT
               reason:reason
               command:__PRETTY_FUNCTION__];
}

+ (NSException *)databaseConnectionFault {
  return [self _buildExceptionWithNumber:XMLRPC_FAULT_DATABASE_DOWN
               reason:@"Can't connect to database"
               command:__PRETTY_FUNCTION__];
}

+ (NSException *)invalidLicenseKeyFault {
  return [self _buildExceptionWithNumber:XMLRPC_FAULT_INVALID_LICENSE_KEY
               reason:@"No valid license key found"
               command:__PRETTY_FUNCTION__];
}

+ (NSException *)missingValueFaultForArgument:(NSString *)_argument {
  NSString *reason;

  reason = [NSString stringWithFormat:@"Argument '%@' is missing",
                     _argument];

  return [self _buildExceptionWithNumber:XMLRPC_FAULT_MISSING_VALUE
               reason:reason
               command:__PRETTY_FUNCTION__];
}

+ (NSException *)invalidValueFaultForArgument:(NSString *)_argument
  ofComponent:(NSString *)_component
{
  NSString *reason;

  reason = [NSString stringWithFormat:
                     @"Argument '%@' of component '%@' has an invalid format",
                     _argument, _component];

  return [self _buildExceptionWithNumber:XMLRPC_FAULT_INVALID_VALUE
               reason:reason
               command:__PRETTY_FUNCTION__];
}

+ (NSException *)couldntCommitTransactionFault {
  return [self _buildExceptionWithNumber:XMLRPC_FAULT_COMMIT_FAILED
               reason:@"Database transaction commit failed"
               command:__PRETTY_FUNCTION__];
}

+ (NSException *)invalidObjectVersionFault {
  return [self _buildExceptionWithNumber:XMLRPC_FAULT_INVALID_OBJECT_VERSION
               reason:@"Object edited by another user"
               command:__PRETTY_FUNCTION__];
}

+ (NSException *)commandFailedFault:(NSString *)_command {
  NSString *reason;

  reason = [NSString stringWithFormat:
                     @"Command '%@' failed", _command];

  return [self _buildExceptionWithNumber:XMLRPC_FAULT_COMMAND_FAILED
               reason:reason
               command:__PRETTY_FUNCTION__];
}

@end /* SDXmlRpcFault */


