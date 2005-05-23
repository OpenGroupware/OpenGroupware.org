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

#include <LSFoundation/LSDBObjectBaseCommand.h>
#include <LSFoundation/LSCommandKeys.h>
#include <LSFoundation/LSFoundation.h>
#include "common.h"


//**************************************************************************
// Hack made by GLC
//
//
//
//**************************************************************************
// #define GLC_DEBUG 1

@interface LSDelDelegationCommand : LSDBObjectBaseCommand
{
	NSString * rdvType;
	NSNumber * idToDelete;
	NSNumber * companyID;
	BOOL reallyDelete;
}
+ (void)initialize;
- (void)setRdvType:(NSString *)aString;
- (id)initForOperation:(NSString*)anOperation inDomain:(NSString *)aDomain;
- (NSString *)entityName;
- (void)dealloc;
- (void)_prepareForExecutionInContext:(id)_ctx;
- (NSString *)getRdvType;
- (void)setIDToDelete:(NSNumber *)aNumber;
- (NSNumber*)getIDToDelete;
- (void)_executeInContext:(id)_ctx;
- (void)takeValue:(id)_value forKey:(id)_key;
- (id)valueForKey:(id)_key;
- (void)setCompanyID:(NSNumber *)aNumber;
- (NSNumber*)getCompanyID;
- (BOOL)_fetchRecord;
@end


@implementation LSDelDelegationCommand

- (void)setReallyDelete:(BOOL)_reallyDelete
{
	self->reallyDelete = _reallyDelete;
}

- (BOOL)reallyDelete
{
	return self->reallyDelete;
}

//**************************************************************************
// 
//
//
//
//**************************************************************************
+ (void)initialize
{
}
//**************************************************************************
// 
//
//
//
//**************************************************************************
- (id)initForOperation:(NSString*)anOperation inDomain:(NSString *)aDomain
{
        self = [super initForOperation:anOperation inDomain:aDomain];
        if(self)
        {       
		NSLog(@"**** LSAddDelegation : initForOperation with operation %@ and domain %@",anOperation, aDomain);
		rdvType = nil;
		idToDelete = nil;
		companyID = nil;
		reallyDelete = YES;	
// 		[[[self databaseChannel] adaptorChannel] setDebugEnabled:YES];
	}       
	return self;
}
//**************************************************************************
// 
//
//
//
//**************************************************************************
- (NSString *)entityName
{
  return @"SchedulerDelegation";
}

//**************************************************************************
// 
//
//
//
//**************************************************************************
- (void)dealloc
{
	[rdvType release];
	[idToDelete release];
	[companyID release];
	[super dealloc];
}	
//**************************************************************************
// 
//
//
//
//**************************************************************************
- (void) _prepareForExecutionInContext:(id)_ctx
{
	id anObject;

//	[self logWithFormat:@"**** _prepareForExecutionInContext"];
//	[[[self databaseChannel] adaptorChannel] setDebugEnabled:YES];

	id login = [_ctx valueForKey:LSAccountKey];
	NSNumber* aCompanyID = [login valueForKey:@"companyId"];

	[self setCompanyID:aCompanyID];

	if((anObject = [self object]) == nil)
	{
		[self _fetchRecord];
		anObject = [self object];
	}

	if(!self->reallyDelete)
		[anObject takeValue:@"archived" forKey:@"dbStatus"];
}
///**************************************************************************
// 
//
//
//
//**************************************************************************
- (void)setRdvType:(NSString *)aString
{
        if(rdvType)
                [rdvType release];

        rdvType = [aString copy];
}
- (NSString *)getRdvType
{
        return rdvType;
}
//**************************************************************************
// 
//
//
//
//**************************************************************************

- (void)setIDToDelete:(NSNumber *)aNumber
{
	if(idToDelete)
		[idToDelete release];

	idToDelete = [aNumber copy];
}

- (NSNumber*)getIDToDelete
{
	return idToDelete;
}

- (void)setCompanyID:(NSNumber *)aNumber
{
	if(companyID)
		[companyID release];

	companyID = [aNumber copy];
}

- (NSNumber*)getCompanyID
{
	return companyID;
}
//**************************************************************************
// 
//
//
//
//**************************************************************************
- (void)_executeInContext:(id)_ctx
{
//	[self logWithFormat:@"***** _executeInContext (DEBUT)"];
	EODatabaseChannel	*dbChannel;
	EOSQLQualifier		*dbQualifier;
	NSException		*exception = nil;
	NSMutableString		*format = [NSMutableString stringWithCapacity:128];

	[format appendString:@"delegate_company_id = %@ AND company_id = %@ AND rdv_type='%@' "];
//	[self logWithFormat:@"##### _fetchRecord : [self getIDToDelete] = '%@'  ",[self getIDToDelete] ];


  
//	[self logWithFormat:@"##### _fetchRecord : format = %@ ",format];

	dbQualifier = [[EOSQLQualifier alloc] initWithEntity:[self entity]
						qualifierFormat:format,
						[self getIDToDelete],
						[self primaryKeyValue],
						[self getRdvType]];

//	[self logWithFormat:@"##### _fetchRecord : dbQualifier = %@ ",dbQualifier];

	dbChannel = [self databaseChannel];
	EOAdaptorChannel *adaptorChannel = [[self databaseChannel] adaptorChannel];
	exception = [adaptorChannel deleteRowsDescribedByQualifierX:dbQualifier];
	[dbQualifier release];
	dbQualifier = nil;
	if(exception != nil)
	{
		[self logWithFormat:@"Exception raise"]; 
		[exception raise];
	}

//	[self logWithFormat:@"***** _executeInContext (FIN)"];
}

//**************************************************************************
// 
//
//
//
//**************************************************************************

-(void)takeValue:(id)_value forKey:(id)_key
{
//	[self logWithFormat:@"***** takevalue : keys are %@ and values : %@",_key,_value ];
	if([_key isEqualToString:@"idConfidential"])
	{
		[self setRdvType:@"Confidential"];
		[self setIDToDelete:_value];
	}
	else if ([_key isEqualToString:@"idPrivate"])
	{
		[self setRdvType:@"Private"];
		[self setIDToDelete:_value];
	}
	else if ([_key isEqualToString:@"idNormal"])
	{
		[self setRdvType:@"Normal"];
		[self setIDToDelete:_value];
	}
	else if ([_key isEqualToString:@"idPublic"])
        {
		[self setRdvType:@"Public"];
                [self setIDToDelete:_value];
	}
	else if ([_key isEqualToString:@"object"])
	{
		[self setObject:_value];
	}
	else if ([_key isEqualToString:@"primaryKey"])
	{
		[self setPrimaryKeyValue:_value];
	}
	else if ([_key isEqualToString:@"reallyDelete"])
	{
		[self setReallyDelete:[_value boolValue]];
	}
	else
	{
		if(_key == nil)
			return;
		if(_value == nil)
			return;
		[self assert:(self->recordDict != nil) reason:@"no record dictionary available"];
		[self->recordDict setObject:_value forKey:_key];
	}
}

//**************************************************************************
// 
//
//
//
//**************************************************************************
-(id)valueForKey:(id)_key
{
	id value;
	
//	[self logWithFormat:@"***** valueForKey : keys are %@ ",_key ];

	if([_key isEqualToString:@"companyId"])
	{
		return [self getCompanyID];
	}
	else if ([_key isEqualToString:@"rdvType"])
	{
		return [self getRdvType];
	}
	else if ([_key isEqualToString:@"delegateCompanyId"])
	{
		return [self getIDToDelete];
	}
	else if ([_key isEqualToString:@"object"])
	{
		return [self object];
	}
	else if ([_key isEqualToString:@"primaryKey"])
	{
		return [self primaryKeyValue];
	}
	else if ([_key isEqualToString:@"reallyDelete"])
	{
		return [NSNumber numberWithBool:[self reallyDelete]];
	}
	else
	{
		value = [self->recordDict objectForKey:_key];
//		[self logWithFormat:@"***** valueForKey : key %@ => value : %@ ",_key, value ];
		return value;
	}
}

- (BOOL)_fetchRecord 
{
	EODatabaseChannel *dbChannel;
	EOSQLQualifier    *dbQualifier;
	id                obj          = nil;
	NSMutableString*  format = [NSMutableString stringWithCapacity:128];
	[format appendString:@"delegate_company_id = %@ AND company_id = %@ AND rdv_type='%@' "];
//	[self logWithFormat:@"##### _fetchRecord : [self getIDToDelete] = '%@'  ",[self getIDToDelete] ];
  
//	[self logWithFormat:@"##### _fetchRecord : format = %@ ",format];

	dbQualifier = [[EOSQLQualifier alloc] initWithEntity:[self entity] qualifierFormat:format,
					[self getIDToDelete],
					[self primaryKeyValue],
					[self getRdvType]];

//	[self logWithFormat:@"##### _fetchRecord : dbQualifier = %@ ",dbQualifier];

	dbChannel = [self databaseChannel];
	[dbChannel selectObjectsDescribedByQualifier:dbQualifier fetchOrder:nil];
	[dbQualifier release]; dbQualifier = nil;
  
	if ((obj = [dbChannel fetchWithZone:NULL]))
	{
		[self setObject:obj];
		if ([dbChannel fetchWithZone:NULL]) 
		{
			[self logWithFormat:@"! got more than one object for primary key !"];
			[dbChannel cancelFetch];
		}

//		[self logWithFormat:@"fetchRecord return YES"];
		return YES;
	}

//	[self logWithFormat:@"fetchRecord return NO"];
	return NO;
}



@end
