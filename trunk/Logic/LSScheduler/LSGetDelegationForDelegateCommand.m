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
#define GLC_DEBUG 1

@interface LSGetDelegationForDelegateCommand : LSDBObjectBaseCommand
{
	NSNumber * delegateID;	
}
@end


@implementation LSGetDelegationForDelegateCommand

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
- (id)initForOperation:(NSString*)anOperation inDomain:(NSString *)aDomain
{
	self = [super initForOperation:anOperation inDomain:aDomain];
	if(self)
	{
		delegateID = nil;
		[[[self databaseChannel] adaptorChannel] setDebugEnabled:YES];
	}
	return self;
}

//**************************************************************************
// 
//
//
//
//**************************************************************************
- (void)dealloc
{
	[delegateID release];
	[super dealloc];
}
//**************************************************************************
// 
//
//
//
//**************************************************************************
-(void)setDelegateId:(NSNumber*)anID
{
	long value = [anID longValue];
	// self->delegateID = [NSNumber numberWithLong:[anID longValue]];
	self->delegateID = [[NSNumber alloc] initWithLong:value];
}
//**************************************************************************
// 
//
//
//
//**************************************************************************
- (NSNumber*) delegateId
{
	return self->delegateID;
}
//**************************************************************************
// 
//
//
//
//**************************************************************************
- (void)takeValue:(id)_value forKey:(id)_key
{
	[self logWithFormat:@"***** takeValue : keys are %@ and values : %@",_key,_value ];
	if([_key isEqualToString:@"withDelegateId"])
	{
		[self setDelegateId:_value];
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
- (void)_prepareForExecutionInContext:(id)_ctx
{
	[self logWithFormat:@"***** _prepareForExecutionInContext (DEBUT)" ];
	// call to super
	[super _prepareForExecutionInContext:_ctx];
	[self logWithFormat:@"***** _prepareForExecutionInContext (FIN)" ];
}
///**************************************************************************
// 
//
//
//
//**************************************************************************
- (void)_executeInContext:(id)_ctx
{
	[self logWithFormat:@"***** _executeInContext (DEBUT)" ];
	EOEntity *sqlEntity = nil;
	EOAdaptorChannel *channel = nil;
	EOSQLQualifier * sqlQualifier = nil;
	NSMutableArray *attributes = nil;
	NSMutableArray *results = nil;
	NSDictionary *dictionary = nil;
	EOModel *myModel = nil;

	NSMutableArray *privateIDs = nil;
	NSMutableArray *confidentialIDs = nil;
	NSMutableArray *normalIDs = nil;
	NSMutableArray *publicIDs = nil;
	id anAttribute = nil;
	id anObject;
	id login;
	

	// first we retrieve the company_id of the login person

	// Entity

	myModel = [self databaseModel];
	[self logWithFormat:@"**** myModel : %@",myModel];

	sqlEntity = [myModel entityNamed:[self entityName]];
	if(sqlEntity == nil)
	{
		[self logWithFormat:@"***** entity %@ is not defined in OGoModel !!!",[self entityName]];
		[self setReturnValue:nil];
		return;
	}

	// Channel

	channel = [[_ctx valueForKey:LSDatabaseChannelKey] adaptorChannel];

	// sqlQualifier
	login = [_ctx valueForKey:LSAccountKey];
	
	sqlQualifier = [[EOSQLQualifier alloc] initWithEntity:sqlEntity qualifierFormat:@"delegate_company_id = '%@'",[self delegateId]]; 
	[sqlQualifier setUsesDistinct:YES];


	[self logWithFormat:@"sqlQualifier = %@",sqlQualifier];

	// Attributes

	attributes = [[NSMutableArray alloc] init];
	
	// here we should assume that [sqlEntity attributeNamed:x] will
	// allways return a value (different of nil), but in case a Model problem arrive those
	// assumptions will failed. So we handle the problem !
	
	anAttribute = [sqlEntity attributeNamed:@"companyId"];
	if (anAttribute != nil)
		[attributes addObject:anAttribute];
	
	anAttribute = [sqlEntity attributeNamed:@"rdvType"];
	if (anAttribute != nil)
		[attributes addObject:anAttribute];

	anAttribute = [sqlEntity attributeNamed:@"delegateCompanyId"];
	if (anAttribute != nil)
		[attributes addObject:anAttribute];
	
	// now we play the request
	if(![channel selectAttributes:attributes describedByQualifier:sqlQualifier fetchOrder:nil lock:NO])
	{
		[self logWithFormat:@"ERROR=database select failed : attributes %@, qualifier %@",attributes,sqlQualifier];
		[self setReturnValue:nil];
		return;
	}

	// now we will fetch row by row and add those to results NSMutableArray
	results = [NSMutableArray arrayWithCapacity:16];
	while((dictionary = [channel fetchAttributes:attributes withZone:NULL]))
	{
		[results addObject:dictionary];
	}

	// ok , now we will prepare data for return
	privateIDs = [[NSMutableArray alloc] init];
	confidentialIDs = [[NSMutableArray alloc] init];
	normalIDs = [[NSMutableArray alloc] init];
	publicIDs = [[NSMutableArray alloc] init];
	
	NSEnumerator *enumerator = [results objectEnumerator];
	while((anObject = [enumerator nextObject ]))
	{
		// what type the record is ?
		NSString *delegationType = [anObject valueForKey:@"rdvType"];
		if([delegationType isEqualToString:@"Private"] == YES )
		{
			// Private ? so add it in privateIDs
			[privateIDs addObject:[anObject valueForKey:@"companyId"]];
		}

		if([delegationType isEqualToString:@"Confidential"] == YES )
		{
			// confidential ? so add it in confidentialIDs
			[confidentialIDs addObject:[anObject valueForKey:@"companyId"]];
		}

		if([delegationType isEqualToString:@"Normal"] == YES )
		{
			// normal ? so add it in normalIDs
			[normalIDs addObject:[anObject valueForKey:@"companyId"]];
		}

		if([delegationType isEqualToString:@"Public"] == YES )
		{
			// public ? so add it in publicIDs
			[publicIDs addObject:[anObject valueForKey:@"companyId"]];
		}
	}

	// finaly prepare the return dictionary
	NSMutableDictionary *returnDictionary = [[NSMutableDictionary alloc] initWithCapacity:4];

	[returnDictionary setObject:privateIDs forKey:@"idPrivate"];
	[returnDictionary setObject:confidentialIDs forKey:@"idConfidential"];
	[returnDictionary setObject:normalIDs forKey:@"idNormal"];
	[returnDictionary setObject:publicIDs forKey:@"idPublic"];

	[self setReturnValue:returnDictionary];
	[self logWithFormat:@"***** returnDictionary = %@",returnDictionary ];

	[returnDictionary autorelease];
	[sqlQualifier autorelease];
	[privateIDs autorelease];
	[confidentialIDs autorelease];
	[normalIDs autorelease];
	[publicIDs autorelease];
	[attributes autorelease];

	[self logWithFormat:@"***** _executeInContext (FIN)" ];
}

@end
