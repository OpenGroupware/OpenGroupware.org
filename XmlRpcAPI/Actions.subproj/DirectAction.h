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
@class LSCommandContext;

/** @name XML-RPC Fault Codes
 *  Standard fault codes returned by DirectAction methods
 *  as XML-RPC fault responses.
 *  @{ */
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
/** @} */

/**
 * @class DirectAction
 *
 * Central WODirectAction subclass for the OGo XML-RPC
 * API. Handles HTTP Basic authentication, session and
 * command context setup, and transaction commit/rollback
 * around each RPC2 request.
 *
 * Provides factory accessors for the standard OGo data
 * sources (person, enterprise, account, appointment,
 * team, project) and project file managers. Also offers
 * helper methods to resolve document URLs/IDs to
 * SkyDocument objects and to convert EOGenericRecords to
 * NSDictionary representations suitable for XML-RPC
 * responses.
 */
@interface DirectAction : WODirectAction

- (EODataSource *)personDataSource;
- (EODataSource *)enterpriseDataSource;
- (EODataSource *)accountDataSource;
- (EODataSource *)appointmentDataSource;
- (EODataSource *)teamDataSource;
- (EODataSource *)projectDataSource;
- (id)fileManagerForCode:(NSString *)_code;

- (LSCommandContext *)commandContext;
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

/**
 * @category DirectAction(Context)
 *
 * Provides access to the WOContext for the current
 * request.
 */
@interface DirectAction(Context)
- (id)context;
@end /* DirectAction(Context) */

/**
 * @category DirectAction(Addresses)
 *
 * Adds address persistence support to DirectAction.
 * Provides -saveAddresses:company: to update address
 * documents on a SkyCompanyDocument from a dictionary
 * of address fields keyed by address type.
 */
@interface DirectAction(Addresses)
- (void)saveAddresses:(NSDictionary *)_addr company:(SkyCompanyDocument *)_com;
@end /* DirectAction(Addresses) */

/**
 * @category DirectAction(Fault)
 *
 * Convenience methods for creating XML-RPC fault
 * exceptions. Wraps fault codes and reason strings into
 * NSException objects suitable for XML-RPC error
 * responses. Includes shortcuts for common faults like
 * invalid command context and invalid result.
 */
@interface DirectAction(Fault)
- (NSException *)faultWithFaultCode:(int)_code  reason:(NSString *)_reason;

- (NSException *)invalidCommandContextFault;
- (NSException *)invalidResultFault;
- (NSException *)faultWithFaultCode:(int)_code format:(NSString *)_format,...;

@end /* DirectAction(Fault) */

#endif /* __SkyXmlRpcServer__DirectAction_H__ */
