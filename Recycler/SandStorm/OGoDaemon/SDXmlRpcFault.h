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

#ifndef __SDXmlRpcFault_H__
#define __SDXmlRpcFault_H__

#import <Foundation/NSObject.h>

#define XMLRPC_FAULT_DATABASE_DOWN          1
#define XMLRPC_FAULT_INVALID_LICENSE_KEY    2
#define XMLRPC_FAULT_INVALID_OBJECT         10
#define XMLRPC_FAULT_MISSING_VALUE          11
#define XMLRPC_FAULT_COMMIT_FAILED          12
#define XMLRPC_FAULT_INVALID_OBJECT_VERSION 13
#define XMLRPC_FAULT_INVALID_VALUE          14
#define XMLRPC_FAULT_COMMAND_FAILED         15

@class NSException, NSString;

@interface SDXmlRpcFault

+ (NSException *)invalidObjectFaultForId:(NSString *)_aid
  entity:(NSString *)_entity;
+ (NSException *)databaseConnectionFault;
+ (NSException *)invalidLicenseKeyFault;
+ (NSException *)missingValueFaultForArgument:(NSString *)_argument;
+ (NSException *)invalidValueFaultForArgument:(NSString *)_argument
  ofComponent:(NSString *)_component;
+ (NSException *)couldntCommitTransactionFault;
+ (NSException *)invalidObjectVersionFault;
+ (NSException *)commandFailedFault:(NSString *)_command;

@end /* SDXmlRpcFault */

#endif /* __SDXmlRpcFault_H__ */
