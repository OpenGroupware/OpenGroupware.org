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

#include <LSFoundation/LSDBObjectNewCommand.h>
#include <LSFoundation/LSCommandKeys.h>
#include <LSFoundation/LSFoundation.h>
#include "common.h"


//**************************************************************************
// Hack made by GLC
//
//
//
//**************************************************************************
#define GLC_DEBUG 1

@interface LSAddDelegationCommand : LSDBObjectNewCommand
{
	NSString * rdvType;
	NSNumber * idToAdd;
}	
+ (void)initialize;
- (void)setRdvType:(NSString *)aString;
- (id)initForOperation:(NSString*)anOperation inDomain:(NSString *)aDomain;
- (NSString *)entityName;
- (void)dealloc;
- (void)_prepareForExecutionInContext:(id)_ctx;
- (NSString *)getRdvType;
- (void)setIDToAdd:(NSNumber *)aNumber;
- (NSNumber*)getIDToAdd;
- (void)_executeInContext:(id)_ctx;
- (void)takeValue:(id)_value forKey:(id)_key;
- (id)valueForKey:(id)_key;
@end


@implementation LSAddDelegationCommand

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
		idToAdd = nil;
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
	[idToAdd release];

	[super dealloc];
}	
///**************************************************************************
// 
//
//
//
//**************************************************************************
- (void)_prepareForExecutionInContext:(id)_ctx
{
	id obj;
	// [self setReturnValueToCopyOfValue:accessRights];
    
	[self logWithFormat:@"***** _prepareForExecutionInContext" ];

	id login = [_ctx valueForKey:LSAccountKey];
	NSNumber * aCompanyID = [login  valueForKey:@"companyId"];
	[super _prepareForExecutionInContext:_ctx];

	obj = [self object];

	[obj takeValue:[self getIDToAdd]  forKey:@"delegateCompanyId"];
	[obj takeValue:[self getRdvType] forKey:@"rdvType"];
	[obj takeValue:aCompanyID forKey:@"companyId"];
	[self logWithFormat:@"***** _prepareForExecutionInContext ======> recordDict : %@",self->recordDict];
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

///**************************************************************************
// 
//
//
//
//**************************************************************************
- (void)setIDToAdd:(NSNumber *)aNumber
{
	if(idToAdd)
		[idToAdd release];

	idToAdd = [aNumber copy];
}

- (NSNumber*)getIDToAdd
{
	return idToAdd;
}
///**************************************************************************
// 
//
//
//
//**************************************************************************
- (void)_executeInContext:(id)_ctx
{
    // [self setReturnValueToCopyOfValue:accessRights];
   

	[self logWithFormat:@"***** _executeInContext" ];
	[self logWithFormat:@"***** _executeInContext ======> recordDict : %@",self->recordDict];
	[super _executeInContext:_ctx];
}
///**************************************************************************
// 
//
//
//
//**************************************************************************
-(void)takeValue:(id)_value forKey:(id)_key
{
	[self logWithFormat:@"***** takevalue : keys are %@ and values : %@",_key,_value ];
	if([_key isEqualToString:@"idConfidential"])
	{
		[self setRdvType:@"Confidential"];
		[self setIDToAdd:_value];
	}
	else if ([_key isEqualToString:@"idPrivate"])
	{
		[self setRdvType:@"Private"];
		[self setIDToAdd:_value];
	}
	else if ([_key isEqualToString:@"idNormal"])
	{
		[self setRdvType:@"Normal"];
		[self setIDToAdd:_value];
	}
	else if ([_key isEqualToString:@"idPublic"])
	{
		[self setRdvType:@"Public"];
		[self setIDToAdd:_value];
	}
	else
	{
		[super takeValue:_value forKey:_key];
	}
}
///**************************************************************************
// 
//
//
//
//**************************************************************************
-(id)valueForKey:(id)_key
{
	id value;

	[self logWithFormat:@"***** valueForKey : keys are %@ ",_key ];

	value = [ super valueForKey:_key ];

        [self logWithFormat:@"***** valueForKey : key %@, value : %@",_key,value ];
	return value;
}
@end
