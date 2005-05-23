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


//**************************************************************************
// Hack made by GLC
//
//
//
//**************************************************************************
// #define GLC_DEBUG 0

@interface LSGetDelegationCommand : LSDBObjectBaseCommand
{
	NSArray * idsForPrivatesFromDB;
	NSArray * idsForConfidentialsFromDB;
	NSArray * idsForNormalsFromDB;
	NSArray * idsForPublicsFromDB;
}
@end

#include <LSFoundation/LSCommandKeys.h>
#include <LSFoundation/LSFoundation.h>
#include "common.h"

@implementation LSGetDelegationCommand

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
- (void)dealloc
{
	[idsForPrivatesFromDB release];
	[idsForConfidentialsFromDB release];
	[idsForNormalsFromDB release];
	[idsForPublicsFromDB release];
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
	
	idsForPrivatesFromDB = nil;
	idsForConfidentialsFromDB = nil;
	idsForNormalsFromDB = nil;
	idsForPublicsFromDB = nil;
	// call to super
	[super _prepareForExecutionInContext:_ctx];
	
}
///**************************************************************************
// 
//
//
//
//**************************************************************************
- (void)_executeInContext:(id)_ctx
{
	
	EOEntity *sqlEntity = nil;
	EOAdaptorChannel *channel = nil;
	EOSQLQualifier * sqlQualifier = nil;
	NSMutableArray *attributes = nil;
	NSMutableArray *results = nil;
	NSDictionary *dictionary = nil;

	NSMutableArray *privateIDs = nil;
	NSMutableArray *confidentialIDs = nil;
	NSMutableArray *normalIDs = nil;
	NSMutableArray *publicIDs = nil;
	id anObject;
	id login;

	// first we retrieve the company_id of the login person

	// Entity

	sqlEntity = [[self databaseModel] entityNamed:[self entityName]];

	// Channel

	channel = [[_ctx valueForKey:LSDatabaseChannelKey] adaptorChannel];

	// sqlQualifier
	login = [_ctx valueForKey:LSAccountKey];
	
	sqlQualifier = [[EOSQLQualifier alloc] initWithEntity:sqlEntity qualifierFormat:@"company_id = '%@'",[login valueForKey:@"companyId"]]; 
	[sqlQualifier setUsesDistinct:YES];


	

	// Attributes

	attributes = [[NSMutableArray alloc] init];
	[attributes addObject:[sqlEntity attributeNamed:@"companyId"]];
	[attributes addObject:[sqlEntity attributeNamed:@"rdvType"]];
	[attributes addObject:[sqlEntity attributeNamed:@"delegateCompanyId"]];

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
			[privateIDs addObject:[anObject valueForKey:@"delegateCompanyId"]];
		}

		if([delegationType isEqualToString:@"Confidential"] == YES )
		{
			// confidential ? so add it in confidentialIDs
			[confidentialIDs addObject:[anObject valueForKey:@"delegateCompanyId"]];
		}

		if([delegationType isEqualToString:@"Normal"] == YES )
		{
			// normal ? so add it in normalIDs
			[normalIDs addObject:[anObject valueForKey:@"delegateCompanyId"]];
		}

		if([delegationType isEqualToString:@"Public"] == YES )
		{
			// public ? so add it in publicIDs
			[publicIDs addObject:[anObject valueForKey:@"delegateCompanyId"]];
		}
	}

	// finaly prepare the return dictionary
	NSMutableDictionary *returnDictionary = [[NSMutableDictionary alloc] initWithCapacity:4];

	[returnDictionary setObject:privateIDs forKey:@"idPrivate"];
	[returnDictionary setObject:confidentialIDs forKey:@"idConfidential"];
	[returnDictionary setObject:normalIDs forKey:@"idNormal"];
	[returnDictionary setObject:publicIDs forKey:@"idPublic"];

	[self setReturnValue:returnDictionary];
// 	[self logWithFormat:@"***** returnDictionary = %@",returnDictionary ];

	[returnDictionary autorelease];
	[sqlQualifier autorelease];
	[privateIDs autorelease];
	[confidentialIDs autorelease];
	[normalIDs autorelease];
	[publicIDs autorelease];
	[attributes autorelease];

	
}

@end
