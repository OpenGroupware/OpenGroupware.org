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

#ifndef __SkyXmlRpcServer__DirectAction_H__
#define __SkyXmlRpcServer__DirectAction_H__

#include <NGObjWeb/WODirectAction.h>

@class EODataSource, SkyDocument, SkyCompanyDocument;
@class NSException, NSMutableDictionary;

#define XMLRPC_FAULT_INVALID_PARAMETER 1
#define XMLRPC_FAULT_MISSING_PARAMETER 2
#define XMLRPC_FAULT_MISSING_CONTEXT   3
#define XMLRPC_FAULT_INVALID_RESULT    4
#define XMLRPC_FAULT_INTERNAL_ERROR    5
#define XMLRPC_FAULT_LOCK_ERROR        6
#define XMLRPC_MISSING_PERMISSIONS     7
#define XMLRPC_FAULT_FS_NOVERSIONING   8
#define XMLRPC_FAULT_TOOMANY_ARGS      9
#define XMLRPC_FAULT_NOT_FOUND         404

@interface DirectAction : WODirectAction

- (EODataSource *)personDataSource;
- (EODataSource *)enterpriseDataSource;
- (EODataSource *)accountDataSource;
- (EODataSource *)appointmentDataSource;
- (EODataSource *)teamDataSource;
- (EODataSource *)projectDataSource;
- (id)fileManagerForCode:(NSString *)_code;

- (id)commandContext;
- (SkyDocument *)getDocumentByArgument:(id)_arg;
- (id)getDocumentById:(id)_arg
  dataSource:(EODataSource *)_dataSource
  entityName:(NSString *)_entityName
  attributes:(NSArray *)_attributes;

- (NSDictionary *)_dictionaryForEOGenericRecord:(id)_record
  withKeys:(NSArray *)_keys;

- (void)substituteIdsWithURLsInDictionary:(NSMutableDictionary *)_dict
  forKeys:(NSArray *)_keys;

- (BOOL)isCurrentUserRoot;

@end /* DirectAction */

@interface DirectAction(Context)
- (id)context;
@end /* DirectAction(Context) */

@interface DirectAction(Addresses)
- (void)saveAddresses:(NSDictionary *)_addr company:(SkyCompanyDocument *)_com;
@end /* DirectAction(Addresses) */

@interface DirectAction(Fault)
- (NSException *)faultWithFaultCode:(int)_code  reason:(NSString *)_reason;

- (NSException *)invalidCommandContextFault;
- (NSException *)invalidResultFault;
- (NSException *)faultWithFaultCode:(int)_code format:(NSString *)_format,...;

@end /* DirectAction(Fault) */

#endif /* __SkyXmlRpcServer__DirectAction_H__ */
