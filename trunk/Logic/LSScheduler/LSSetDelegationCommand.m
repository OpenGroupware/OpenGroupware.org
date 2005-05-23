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

#include <LSFoundation/LSBaseCommand.h>
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

@interface LSSetDelegationCommand : LSBaseCommand
{
	// Thoses arrays will be used to store values
	// read from Databases
	NSArray * idsForPrivatesFromDB;
	NSArray * idsForConfidentialsFromDB;
	NSArray * idsForNormalsFromDB;
	NSArray * idsForPublicsFromDB;
	// those arrays will be used to update delegations.
	// those result of what the user choose in LSWSchedulerPreferences
	NSArray * arrayForPrivates;
	NSArray * arrayForConfidentials;
	NSArray * arrayForNormals;
	NSArray * arrayForPublics;
	// dictionary containing the new delegations to apply
	NSMutableDictionary *newDelegationsEntries;
}
@end


@implementation LSSetDelegationCommand

//**************************************************************************
// 
//
//
//
//**************************************************************************
//
//+ (void)initialize
//{
//	if (null == nil)
//		null = [[EONull null] retain];
//}
//**************************************************************************
// 
//
//
//
//**************************************************************************
- (void)setNewDelegations:(NSDictionary *)aDictionary
{
//    	[self logWithFormat:@"***** setNewDelegations : aDictionary =  %@",aDictionary ];
	if(newDelegationsEntries)
	{
		[newDelegationsEntries release];
	}

	newDelegationsEntries = [[NSMutableDictionary alloc] init];
	[newDelegationsEntries addEntriesFromDictionary:aDictionary];
}

- (NSMutableDictionary*)delegations
{
	return newDelegationsEntries; 
}

//**************************************************************************
// 
//
//
//
//**************************************************************************
- (void)takeValue:(id)_value forKey:(id)_key
{
//    	[self logWithFormat:@"***** takeValue : keys are %@ and values : %@",_key,_value ];
	if([_key isEqualToString:@"dictDelegation"])
	{
		[self setNewDelegations:_value];
	}
	else
	{
		[super takeValue:_value forKey:_key];
	}
}
//**************************************************************************
// 
//
//
//
//**************************************************************************
- (id)valueForKey:(id)_key
{
	id value;
	
// 	[self logWithFormat:@"***** valueForKey : keys are %@ ",_key ];
	if([_key isEqualToString:@"dictDelegation"])
	{
		return [self delegations];
	}

	value = [ super valueForKey:_key ];

//	[self logWithFormat:@"***** valueForKey : key %@, value : %@",_key,value ];
	return value;
}
//**************************************************************************
// 
//
//
//
//**************************************************************************
- (void)_prepareForExecutionInContext:(id)_context
{
//    	[self logWithFormat:@"***** _PrepareForExecutionInContext" ];
	arrayForPublics 	= nil;
	arrayForPrivates 	= nil;
	arrayForConfidentials 	= nil;
	arrayForNormals 	= nil;
	
	idsForPrivatesFromDB	= nil;
	idsForConfidentialsFromDB	= nil;
	idsForNormalsFromDB 	= nil;
	idsForPublicsFromDB	= nil;
}

//**************************************************************************
// 
//
//
//
//**************************************************************************
- (void)dealloc
{
//    	[self logWithFormat:@"***** _dealloc" ];
	if(arrayForPrivates)
	{
		[arrayForPrivates release];
		arrayForPrivates 	= nil ;
	}

	if(arrayForConfidentials)
	{
		[arrayForConfidentials release];
		arrayForConfidentials 	= nil ;
	}

	if(arrayForNormals)
	{
		[arrayForNormals release];
		arrayForNormals 	= nil ;
	}

	if(arrayForPublics)
	{
		[arrayForPublics 	release];
		arrayForPublics 	= nil ;
	}
	
	// now call our parent
//    	[self logWithFormat:@"***** _dealloc : before super::dealloc" ];

	[super dealloc];
	// Never caal this last line since self have been release . Prefer NSLog 
	// [self logWithFormat:@"***** _dealloc : after super::dealloc" ];
//	NSLog(@"***** _dealloc : after super::dealloc") ;
}

//**************************************************************************
// 
//
//
//
//**************************************************************************
- (void)_executeInContext:(id)_context
{
	NSDictionary * currentDelegations = nil;
	NSArray * arrayOfTargetID = nil;
	NSArray * arrayOfSourceID = nil;
//	[self logWithFormat:@"***** (DEBUT) _executeInContext : ctx = %@",_context ];

	// first get existant delegations for this accounts

	currentDelegations = LSRunCommandV(_context,@"appointment",@"get-delegation",nil);
	// The previous methode return a Dictionary with four keys :
	// - idPrivates
	// - idConfidentials
	// - idNormals
	// - idPublics
	//
	// Keys give access to NSArray's containing "delegateCompanyId".
	// So the Dictionary is never empty or nil. All keys give access
	// to NSArray. NSArray's allways exist (so can't be nil) but could contains nothing : [array count] == 0
	if(currentDelegations == nil)
	{
		//*************************
		// this is mainly a bug !!!
		//*************************
		// since even if no delegation exist for this account
		// appointment::get-delegation allways return a valid dictionary
		// but with 4 (four) empty arrays.
    		[self logWithFormat:@"[appointment::get-delegation failed (BUG) !!!"];
   		[self setReturnValue:nil];
		return;
	}
//    	[self logWithFormat:@"newDelegationsEntries : %@",newDelegationsEntries];
//    	[self logWithFormat:@"currentDelegations : %@",currentDelegations];

	// 
	NSEnumerator * keysEnumerator = [newDelegationsEntries keyEnumerator];
	id key = nil;
	NSMutableArray *idToAdd = nil;
	NSMutableArray *idToDelete = nil;
	BOOL found = NO;
	NSEnumerator *targetEnumerator = nil;
	NSEnumerator *sourceEnumerator = nil;
	long targetValue = 0;
	long sourceValue = 0;


	while((key = [keysEnumerator nextObject]))
	{
		id sourceObject = nil;
		id targetObject = nil;

		idToAdd = [[NSMutableArray alloc] init];
		idToDelete = [[NSMutableArray alloc] init];

//		[self logWithFormat:@"***** while loop : key %@", key];

		// first retrieve target ID 
		arrayOfTargetID = [newDelegationsEntries valueForKey:key];
		if(arrayOfTargetID == nil)
		{
			[self logWithFormat:@"***** %@'s array is null = BUG", key];
		}
		// second, source one	
		arrayOfSourceID = [currentDelegations valueForKey:key];
		if(arrayOfSourceID == nil)
		{
			[self logWithFormat:@"***** %@'s array is null = BUG", key];
		} 
//		else
//		{
//			[self logWithFormat:@"***** %@ dump source : %@", key,arrayOfSourceID];
//		}

		// rules : ID not present in Source but Present in Target need to be add.
		found = NO;
		targetEnumerator = [arrayOfTargetID objectEnumerator];
		while (( targetObject = [ targetEnumerator nextObject] ))
		{
			targetValue = [targetObject longValue];
//			[self logWithFormat:@"***** target value : %ld ", targetValue];
			sourceEnumerator = [arrayOfSourceID objectEnumerator];
			while(( sourceObject = [ sourceEnumerator nextObject ] ))
			{
				sourceValue = [sourceObject longValue];
//				[self logWithFormat:@"***** source value : %ld ", sourceValue];
				if( targetValue == sourceValue )
				{
					found = YES;
					break;
				}
//				[self logWithFormat:@"***** source value : %ld result : %d", sourceValue, found];
			}

			if(found == NO)
			{
//				[self logWithFormat:@"***** found = NO so add %ld", targetValue];
				[idToAdd addObject:targetObject];
			}

			// set found to a known value
			found = NO;
		}

		// rules : ID not present in Target but present in Source need to be delete.
		found = NO;
		sourceEnumerator = [arrayOfSourceID objectEnumerator];
		while (( sourceObject = [ sourceEnumerator nextObject] ))
		{
			sourceValue = [sourceObject longValue];
			targetEnumerator = [arrayOfTargetID objectEnumerator];
			while(( targetObject = [ targetEnumerator nextObject ] ))
			{
				targetValue = [targetObject longValue];
				if( sourceValue == targetValue)
				{
					found = YES;
					break;
				}
//				[self logWithFormat:@"***** source value : %ld target value : %ld result : %d", sourceValue, targetValue, found];
			}
			if(found == NO)
			{
//				[self logWithFormat:@"***** found = NO so add %ld", sourceValue];
				[idToDelete addObject:sourceObject];
			}

			// set found to a known value
			found = NO;
		}

		// now perform add and delete operation
		if ( [idToAdd count] > 0 )
		{
			int i;
			for ( i = 0; i < [idToAdd count]; i++)
			{
				// command to add id
//				[self logWithFormat:@"***** run appointment::add-delegation : key %@ , %@", key,[idToAdd objectAtIndex:i]];
				LSRunCommandV(_context,@"appointment",@"add-delegation",key,[idToAdd objectAtIndex:i],nil);
			}
		}
		else
		{
//			[self logWithFormat:@"***** NO IDS to add !!!"];
		}

		if ( [idToDelete count] > 0 )
		{
			int i;
			for ( i = 0; i < [idToDelete count]; i++)
			{
				// command to delete id
//				[self logWithFormat:@"***** run appointment::del-delegation : key %@ , %@", key,[idToDelete objectAtIndex:i]];
				LSRunCommandV(_context,@"appointment",@"del-delegation",key,[idToDelete objectAtIndex:i],nil);
			}
		}
		else
		{
//			[self logWithFormat:@"***** NO IDS to delete !!!"];
		}
	}
    
//	[self logWithFormat:@"***** (FIN) _executeInContext "];
	[self setReturnValue:nil];
}

@end
