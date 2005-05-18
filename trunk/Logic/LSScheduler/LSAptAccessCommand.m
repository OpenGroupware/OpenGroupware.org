/*
 Copyright (C) 2000-2005 SKYRIX Software AG
 
 This file is part of OpenGroupware.org.

 Commentaires
 
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

/*
  takes either a single global-id or multiple gids and returns either
  a single string containing the permissions or a dictionary where the
  key is the gid and the value is the permission-string.
*/

@class NSArray;

//**************************************************************************
// Hack made by GLC
//
//
//
//**************************************************************************
#define GLC_DEBUG 1

@interface LSAptAccessCommand : LSDBObjectBaseCommand
{
	NSArray *gids;
	BOOL    singleFetch;
	NSDictionary *currentDelegation;
}
- (NSArray*)getArrayOfDelegationForType:(NSString*)type;
@end

#include <LSFoundation/LSCommandKeys.h>
#include <LSFoundation/LSFoundation.h>
#include "common.h"

@implementation LSAptAccessCommand

static NSString *right_deluv = @"deluv";
static NSString *right_luv   = @"luv";
static NSString *right_lv    = @"lv";
static NSString *right_l     = @"l";
static EONull   *null  = nil;

#define NONE_RIGHT		0
#define DELETE_RIGHT	2
#define EDIT_RIGHT		4
#define LIST_RIGHT		8
#define UPDATE_RIGHT	16
#define VIEW_RIGHT		32
#define ALL_RIGHT	( DELETE_RIGHT | EDIT_RIGHT | LIST_RIGHT | UPDATE_RIGHT | VIEW_RIGHT )

//**************************************************************************
// 
//
//
//
//**************************************************************************
+ (void)initialize
{
	if (null == nil)
		null = [[EONull null] retain];
}
//**************************************************************************
// 
//
//
//
//**************************************************************************
- (NSString *)entityName
{
	return @"Date";
}

//**************************************************************************
// 
//
//
//
//**************************************************************************
- (id)initForOperation:(NSString *)_operation inDomain:(NSString *)_domain
{
	self = [super initForOperation:_operation inDomain:_domain];
	if(self)
	{
		gids = nil;
		singleFetch = NO;
		currentDelegation = nil;
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
	if(self->gids != nil)
		[self->gids release];
	if(self->currentDelegation != nil)
		[self->currentDelegation release];
	[super dealloc];
}

/* execution */
//**************************************************************************
// check if the _pkey parameters is equal to "OGo root" account "id"
// whitch is in general 10000
//
// so return YES if _pkey is equal to 10000 or NO is any other situation
//
// Parameter : _ctx is NEVER use.
//
//**************************************************************************
- (BOOL)isRootAccountPKey:(NSNumber *)_pkey inContext:(id)_ctx 
{
	return [_pkey intValue] == 10000 ? YES : NO;
}
//**************************************************************************
// set the LSDBObjectBaseComand return value with a "copy" of the real objects
//
// _value is the object to return a copy.
//
//
//**************************************************************************
- (void)setReturnValueToCopyOfValue:(id)_value 
{
	id copyValue;
  
	copyValue = [_value copy];  // copy _value
	[self setReturnValue:copyValue]; // set return value with the new "copied" object
	[copyValue release]; // release since setReturnValue retain object
}
//**************************************************************************
// 
//
//
//
//**************************************************************************
- (NSArray *)_fetchTeamGIDsOfAccountWithGID:(EOGlobalID *)_gid inContext:(id)_ctx
{
#ifdef GLC_DEBUG
	NSArray * anArray = LSRunCommandV(_ctx,@"account",@"teams",
						@"object",_gid, 
						@"fetchGlobalIDs", [NSNumber numberWithBool:YES], nil);

	return anArray;
#else
	return LSRunCommandV(_ctx, @"account", @"teams", 
			@"object", _gid, 
			@"fetchGlobalIDs", [NSNumber numberWithBool:YES], nil);
#endif
}
//**************************************************************************
// 
//
//
//
//**************************************************************************
- (NSArray *)_fetchMemberGIDsOfTeamWithGID:(EOGlobalID *)_gid inContext:(id)_ctx
{
#ifdef GLC_DEBUG
	NSArray * anArray = LSRunCommandV(_ctx, @"team", @"members", 
			@"team", _gid, 
			@"fetchGlobalIDs", [NSNumber numberWithBool:YES], nil);

	return anArray;
#else
	return LSRunCommandV(_ctx, @"team", @"members", 
			@"team", _gid, 
			@"fetchGlobalIDs", [NSNumber numberWithBool:YES], nil);
#endif
}
//**************************************************************************
// 
//
//
//
//**************************************************************************

- (EOKeyGlobalID *)teamGID:(NSNumber *)_pkey 
{
	if (_pkey == nil) 
		return nil;
	return [EOKeyGlobalID globalIDWithEntityName:@"Team" keys:&_pkey keyCount:1 zone:NULL];
}

//**************************************************************************
// 
//
//
//
//**************************************************************************
- (EOKeyGlobalID *)personGID:(NSNumber *)_pkey 
{
	if (_pkey == nil) 
		return nil;
	return [EOKeyGlobalID globalIDWithEntityName:@"Person" keys:&_pkey keyCount:1 zone:NULL];
}

//**************************************************************************
// 
//
//
//
//**************************************************************************
- (void) _prepareForExecutionInContext:(id)_context
{
	id	login;
	int	loginPersonID;
	NSDictionary *delegationEntries = nil;
	// 
	// if you're owner you can delete
	//
	login = [_context valueForKey:LSAccountKey];
	loginPersonID = [[login valueForKey:@"companyId"] intValue];

	delegationEntries = LSRunCommandV(_context,@"appointment",@"get-delegation-for-delegate", 
			@"withDelegateId",[login valueForKey:@"companyId"],
			nil);

	if(delegationEntries != nil)
	{
		if(self->currentDelegation != nil)
			[self->currentDelegation release];

		self->currentDelegation = [delegationEntries copy];
	}

	[super _prepareForExecutionInContext:_context];
}

//**************************************************************************
// 
//
//
//
//**************************************************************************
- (void)_executeForRootInContext:(id)_context
{
	/* root has access to all operations */
	NSMutableDictionary *accessDictionnary;
	NSEnumerator *enumerator;
	EOGlobalID   *gid;
  
	if (self->singleFetch) 
	{
		[self setReturnValue:right_deluv];
		return;
	}
  
	accessDictionnary = [NSMutableDictionary dictionaryWithCapacity:[self->gids count]];
	enumerator = [self->gids objectEnumerator];
	while ((gid = [enumerator nextObject]) != nil)
		[accessDictionnary setObject:right_deluv forKey:gid];
  
	[self setReturnValueToCopyOfValue:accessDictionnary];
}
//**************************************************************************
// 
//
//
//
//**************************************************************************
- (BOOL) isAnAppointmentParticipant:(id)aRow inContext:(id)_context
{
	EOGlobalID	*globalID;
	EOGlobalID	*loginGlobalID;
	EOEntity	*entity;
	NSArray		*participants;
	NSArray		*arrayOfAccounts;
	unsigned	participantsCounter;
	id		login;
	id		anObject;
	unsigned	counter,i;

	// *************************************************************
	//               HACK (TM) Copyright (C) GROS GORET
	// *************************************************************
	// return YES;


	entity = [self entity];

	login    = [_context valueForKey:LSAccountKey];
	loginGlobalID = [login valueForKey:@"globalID"];

	globalID = [entity globalIDForRow:aRow];


	participants = LSRunCommandV(_context, @"appointment", @"get-participants", @"date",globalID, @"fetchGlobalIDs",[NSNumber numberWithBool:YES], nil);

	if([participants containsObject:loginGlobalID] == YES)
	{
		return YES;
	}

	// ok so the login account is not a real participant of the appointment
	// but it may have access by delegation : someone gave him/her some delegations
	// and those are participants of the appointment 

	NSString *rdvType = [aRow valueForKey:@"rdvType"];
	NSArray *arrayDelegation = [self getArrayOfDelegationForType:rdvType];

	counter = [arrayDelegation count];

	NSEnumerator *enumerator = [participants objectEnumerator];
	while((anObject = [enumerator nextObject]))
	{
		for(i = 0 ; i < counter; i++)
		{
			NSNumber *anID = [arrayDelegation objectAtIndex:i];
			EOKeyGlobalID *personID = [self personGID:anID];
			if([anObject isEqual:personID] == YES)
			{
				return YES;
			}

			EOKeyGlobalID *teamID = [self teamGID:anID];
			if([anObject isEqual:teamID] == YES)
			{
				return YES;
			}
		}
	}
		
	return NO;
}
//**************************************************************************
// 
//
//
//
//**************************************************************************
- (BOOL)checkForArrayOfTeamID:(NSArray*)arrayOfTeamID inAccessList:(NSString*)accessList
{	
	int count,i;
	EOGlobalID *accessTeamGid;

	NSArray * arrayOfID = [accessList componentsSeparatedByString:@","];
	count = [arrayOfID count];

	for(i = 0; i < count ; i++)
	{
		NSNumber *staffPid;

		staffPid = [NSNumber numberWithInt:[[arrayOfID objectAtIndex:i] intValue]];

		accessTeamGid = [EOKeyGlobalID globalIDWithEntityName:@"Team"  keys:&staffPid keyCount:1  zone:NULL];	

		if([arrayOfTeamID containsObject:accessTeamGid] == YES)
		{
			return YES;
		}
	}

	return NO;
}
//**************************************************************************
// 
//
//
//
//**************************************************************************
- (BOOL)checkForPersonID:(id)anID inAccessList:(NSString*)accessList
{
	NSArray * arrayOfID = [accessList componentsSeparatedByString:@","];

	//accessList could contains personID and TeamID. So in case of TeamID we need
	// to expand Team and to check one by one id contains in this team to see if 
	// the current id is contains in.

	// But to preserve some CPU time we first check without determining the difference between Person
	// and Team. If the id match we return YES. This IS ONLY POSSIBLE beacause a Team ID can't never be 
	// the same of the one of a person id. 

	// If this design change , this method MUST change

	if([arrayOfID containsObject:[anID stringValue]] == YES)
	{
		return YES;
	}

	return NO;
}
//**************************************************************************
// 
//
//
//
//**************************************************************************
- (NSArray*)getArrayOfDelegationForType:(NSString*)type
{
	if(type == nil)
	{
		return nil;
	}

	if([type length] <= 0)
	{
		return nil;
	}

	if([type isEqualToString:@"Public"] == YES)
	{
		return [currentDelegation valueForKey:@"idPublic"];
	}	

	if([type isEqualToString:@"Private"] == YES)
	{
		return [currentDelegation valueForKey:@"idPrivate"];
	}	

	if([type isEqualToString:@"Confidential"] == YES)
	{
		return [currentDelegation valueForKey:@"idConfidential"];
	}	

	if([type isEqualToString:@"Normal"] == YES)
	{
		return [currentDelegation valueForKey:@"idNormal"];
	}	

	return nil;	
}

//**************************************************************************
// 
//
//
//
//**************************************************************************
- (BOOL)isInReadAccessList:(id)aRow inContext:(id)_context
{
	id	login;
	id	ownerId;
	id	loginPersonID;
	id	anID;
	int	integerLoginPersonID;
	NSArray *loginTeams;
	NSArray *arrayOfID;

	if((aRow == nil) || (_context == nil))
		return NO;

	login = [_context valueForKey:LSAccountKey];
	loginPersonID = [login valueForKey:@"companyId"] ;
	integerLoginPersonID = [loginPersonID  intValue];
	ownerId = [aRow objectForKey:@"ownerId"];
	loginTeams = [self _fetchTeamGIDsOfAccountWithGID:[login valueForKey:@"globalID"] inContext:_context];

	// first get the read access list
	NSString * readAccessList = [aRow valueForKey:@"readAccessList"];
	if(readAccessList != nil)
	{
		if ([readAccessList length] > 0)
		{
			// first check as a person meber of the accessList
			if([self checkForPersonID:loginPersonID inAccessList:readAccessList] == YES)
			{
				return YES;
			}
			// now check as a teamMember
			if([self checkForArrayOfTeamID:loginTeams inAccessList:readAccessList] == YES)
			{
				return YES;
			}
			// nwo check if the login account have a delegation for this type of appointment
			// and if one of the delegate id is a member of the write access list

			// first get the rdvType
			NSString * rdvType = [aRow valueForKey:@"rdvType"];
			arrayOfID = [self getArrayOfDelegationForType:rdvType];
			if(arrayOfID != nil)
			{
				NSEnumerator * enumerator = [arrayOfID objectEnumerator];
				while((anID = [enumerator nextObject]))
				{
					// on day we should manage delegation about team
					if([self checkForPersonID:anID inAccessList:readAccessList] == YES)
					{
						return YES;
					}
				}
			}
		}
	}

	return NO;
}
//**************************************************************************
// 
//
//
//
//**************************************************************************
- (BOOL)isInWriteAccessList:(id)aRow inContext:(id)_context
{
	id	login;
	id	ownerId;
	id	loginPersonID;
	id	anID;
	int	integerLoginPersonID;
	NSArray *loginTeams;
	NSArray *arrayOfID;

	if((aRow == nil) || (_context == nil))
		return NO;

	login = [_context valueForKey:LSAccountKey];
	loginPersonID = [login valueForKey:@"companyId"] ;
	integerLoginPersonID = [loginPersonID  intValue];
	ownerId = [aRow objectForKey:@"ownerId"];
	loginTeams = [self _fetchTeamGIDsOfAccountWithGID:[login valueForKey:@"globalID"] inContext:_context];

	// first get the write access list
	NSString * writeAccessList = [aRow valueForKey:@"writeAccessList"];
	if(writeAccessList != nil)
	{
		if ([writeAccessList length] > 0)
		{
			// first check as a person meber of the accessList
			if([self checkForPersonID:loginPersonID inAccessList:writeAccessList] == YES)
			{
				return YES;
			}
			// now check as a teamMember
			if([self checkForArrayOfTeamID:loginTeams inAccessList:writeAccessList] == YES)
			{
				return YES;
			}
			// nwo check if the login account have a delegation for this type of appointment
			// and if one of the delegate id is a member of the write access list

			// first get the rdvType
			NSString * rdvType = [aRow valueForKey:@"rdvType"];
			arrayOfID = [self getArrayOfDelegationForType:rdvType];
			if(arrayOfID != nil)
			{
				NSEnumerator * enumerator = [arrayOfID objectEnumerator];
				while((anID = [enumerator nextObject]))
				{
					// on day we should manage delegation about team
					if([self checkForPersonID:anID inAccessList:writeAccessList] == YES)
					{
						return YES;
					}
				}
			}
		}
	}

	return NO;
}

//**************************************************************************
// 
//
//
//
//**************************************************************************
- (BOOL)isInDelegationList:(id)aRow inContext:(id)_context
{
	id	login;
	id	ownerId;
	id	loginPersonID;
	int	integerLoginPersonID;
	NSArray *arrayOfID;
	
	if((aRow == nil) || (_context == nil))
		return NO;
	
	login = [_context valueForKey:LSAccountKey];
	loginPersonID = [login valueForKey:@"companyId"] ;
	integerLoginPersonID = [loginPersonID  intValue];
	ownerId = [aRow objectForKey:@"ownerId"];

	NSString * rdvType = [aRow valueForKey:@"rdvType"];

	arrayOfID = [self getArrayOfDelegationForType:rdvType];
	if([arrayOfID containsObject:ownerId])
	{
		return YES;
	}

	return NO;
}
//**************************************************************************
// 
//
//
//
//**************************************************************************
- (BOOL) isOwnerOfAppointment:(id)aRow inContext:(id)_context
{
	id	login;
	id	ownerId;
	id	loginPersonID;
	int	integerLoginPersonID;
	
	if((aRow == nil) || (_context == nil))
		return NO;
	
	login = [_context valueForKey:LSAccountKey];
	loginPersonID = [login valueForKey:@"companyId"] ;
	integerLoginPersonID = [loginPersonID  intValue];
	ownerId = [aRow objectForKey:@"ownerId"];

	    
	if ([ownerId intValue] == integerLoginPersonID)
	{
		return YES;
	}

	return NO;
}

//**************************************************************************
// 
//
//
//
//**************************************************************************
- (BOOL) hasDeleteRight:(id)aRow inContext:(id)_context
{
	// this currently have no sense since we check first that a user have all
	// right. May be in the future.
	return NO;
}

//**************************************************************************
// 
//
//
//
//**************************************************************************
- (BOOL) hasEditRight:(id)aRow inContext:(id)_context
{
	// Edit right is manage like Delete right in this implementation
	return NO;
}

//**************************************************************************
// 
//
//
//
//**************************************************************************
- (BOOL) hasListRight:(id)aRow inContext:(id)_context
{
	id	login;
	id	ownerId;
	id	loginPersonID;
	NSArray *loginTeams;
	EOGlobalID *aTeamGID;
	NSNumber  *ownerID;
	id	ownerGID;
	id 	loginPersonGID;
	id	membersGID;
	NSArray *membersOfTeam;
	NSEnumerator *loginTeamEnumerator;
	NSEnumerator *memberEnumerator;
	BOOL ownerIsMember;
	BOOL meIsMember;
	// an id have list right when :
	// - it is a team member of the owner
	// - the rdvType of the appointment is Public;
	if((aRow == nil) || (_context == nil))
		return NO;

	NSString * rdvType = [aRow valueForKey:@"rdvType"];
	if([rdvType isEqualToString:@"Public"] == YES)
		return YES;
	
	login = [_context valueForKey:LSAccountKey];
	loginPersonID = [login valueForKey:@"companyId"] ;

	ownerId = [aRow objectForKey:@"ownerId"];
	ownerID = [aRow valueForKey:@"ownerId"];

	ownerGID = [self personGID:ownerID];
	loginPersonGID = [self personGID:loginPersonID];

	loginTeams = [self _fetchTeamGIDsOfAccountWithGID:[login valueForKey:@"globalID"] inContext:_context];

	loginTeamEnumerator = [loginTeams objectEnumerator];
	memberEnumerator = nil;

	while((aTeamGID = [loginTeamEnumerator nextObject]))
	{
		ownerIsMember = NO;
		meIsMember = NO;
		membersOfTeam = [self _fetchMemberGIDsOfTeamWithGID:aTeamGID inContext:_context];
		memberEnumerator = [membersOfTeam objectEnumerator];
		while((membersGID = [memberEnumerator nextObject]))
		{
			if([membersGID isEqual:ownerGID] == YES)
			{
				ownerIsMember = YES;
			}
			if([membersGID isEqual:loginPersonGID] == YES)
			{
				meIsMember = YES;
			}
		}
		if((ownerIsMember == YES) && (meIsMember == YES))
		{
			return YES;
		}
	}

	return NO;
}

//**************************************************************************
// 
//
//
//
//**************************************************************************
- (BOOL) hasUpdateRight:(id)aRow inContext:(id)_context
{
	if([self isAnAppointmentParticipant:aRow inContext:_context] == YES)
		return YES;

	return NO;
}

//**************************************************************************
// 
//
//
//
//**************************************************************************
- (BOOL) isMemberOfOwnerTeam:(id)aRow inContext:(id)_context
{
	id ownerID;
	id login;
	id loginCompanyID;
	id keyGlobalID;
	NSArray * arrayOfTeamGIDForOwner;
	NSArray * arrayOfPersonIDForTeam;
	id aTeamID;
	
	if((aRow == nil) || (_context == nil))
		return NO;
	// get the login id
	
	login = [_context valueForKey:LSAccountKey];
	loginCompanyID = [login valueForKey:@"companyId"];
	NSNumber *aNumber = [NSNumber numberWithInt:[loginCompanyID intValue]];
	keyGlobalID = [self personGID:aNumber];
	
	// first get Teams of owner
	ownerID = [aRow objectForKey:@"ownerId"];
	NSNumber *numberOwnerID = [NSNumber numberWithInt:[ownerID intValue]];
	EOKeyGlobalID * anID = [self personGID:numberOwnerID];
	arrayOfTeamGIDForOwner = [self _fetchTeamGIDsOfAccountWithGID:anID inContext:_context];

	
	NSEnumerator * enumeratorOfTeam = [arrayOfTeamGIDForOwner objectEnumerator];
	while((aTeamID = [enumeratorOfTeam nextObject]))
	{
		arrayOfPersonIDForTeam = [self _fetchMemberGIDsOfTeamWithGID:aTeamID inContext:_context];
		if([arrayOfPersonIDForTeam containsObject:keyGlobalID])
		{
			return YES;
		}
	}
	
	return NO;
}

//**************************************************************************
// 
//
//
//
//**************************************************************************
- (BOOL) hasViewRight:(id)aRow inContext:(id)_context
{
	if((aRow == nil) || (_context == nil))
		return NO;

	NSString * rdvType = [aRow valueForKey:@"rdvType"];
	if([rdvType isEqualToString:@"Public"] == YES)
		return YES;

	if([self isInReadAccessList:aRow inContext:_context] == YES)
		return YES;

	// if appoitment is of type "Normal" we allow a member of the owner team
	// to view the appointment
	
	if ([rdvType isEqualToString:@"Normal"] == YES)
	{
		if([self isMemberOfOwnerTeam:aRow inContext:_context] == YES)
			return YES;
	}

	return NO;
}

//**************************************************************************
// 
//
//
//
//**************************************************************************
- (BOOL) hasAllRights:(id)aRow inContext:(id)_context
{
	// to have all right an id must check againt one of this rules
	// - being the ownner (be carefull being the creator in not sufficient)
	// - id is  present in the delegation list of the appointment owner for this type of rendre-vous (Public, Normal,..)
	// - id is in the write access list of the appointment
	
	if((aRow == nil) || (_context == nil))
		return NO;
	
	// 
	// if you're owner you have all rights on this appointment
	//
	    
	if ([self isOwnerOfAppointment:aRow inContext:_context] == YES)
	{
		return YES;
	}

	// 
	// if you're in the delegation list for this type of appointment
	// you have all rights ie you act as the owner of this appointment
	//
	if ([self isInDelegationList:aRow inContext:_context] == YES)
	{
		return YES;
	}

	// if the creator of this appointment put your id in the write access_list
	// then you have all right on this appointment
	if ([self isInWriteAccessList:aRow inContext:_context] == YES)
	{
		return YES;
	}
	
	return NO;
}

//**************************************************************************
// 
//
//
//
//**************************************************************************
- (NSArray*)getAttributes
{
	EOEntity              *entity;
	NSArray               *attributes;
	NSString              *primaryKeyAttributeName;

	entity = [self entity];
	primaryKeyAttributeName = [[entity primaryKeyAttributeNames] objectAtIndex:0]; 
	attributes = [[NSArray alloc] initWithObjects:
			[entity attributeNamed:primaryKeyAttributeName],
			[entity attributeNamed:@"ownerId"],
			//####ADDED BY AO####
			[entity attributeNamed:@"creatorId"],
			[entity attributeNamed:@"accessTeamId"],
			[entity attributeNamed:@"writeAccessList"],
			[entity attributeNamed:@"rdvType"],
			//####ADDED BY AO####
			[entity attributeNamed:@"readAccessList"],
			 nil];
	return [attributes autorelease];
}
//**************************************************************************
// 
//
//
//
//**************************************************************************
- (EOSQLQualifier*) buildSQLQualifier
{
	NSArray 		*myAttributes;
	EOSQLQualifier		*myQualifier;
	EOAdaptorChannel	*myAdaptorChannel;
	NSMutableString		*requeteString;
	unsigned		i;
	BOOL			isFirst;
	unsigned		globalIDCount;
	EOEntity		*entity;
	NSString		*primaryKeyAttributeName;
		
	myAttributes = [[self getAttributes] copy];
	if(myAttributes == nil)
		return nil;

	[self assert:(myAdaptorChannel != nil) reason:@"missing adaptor channel"];

	globalIDCount = [self->gids count];
	
	/* build qualifier */
	
	isFirst = YES;
	requeteString      = [[NSMutableString alloc] initWithCapacity:1024];
	[requeteString appendString:@"%@ IN ("];

	entity = [self entity];

	primaryKeyAttributeName = [[entity primaryKeyAttributeNames] objectAtIndex:0];
	
	for (i = 0 ; i < globalIDCount; i++)
	{
		EOKeyGlobalID *gid;
		NSString *gidAsString;
	   
		gid = [self->gids objectAtIndex:i];
	   
		if (!isFirst)
			[requeteString appendString:@","];
	    
		 gidAsString = [[gid keyValues][0] stringValue];
		if ([gidAsString length] == 0)
		{
			continue;
		}
	   
		[requeteString appendString:gidAsString];
		isFirst = NO;
	}
	
	[requeteString appendString:@")"];
	
	myQualifier = [[EOSQLQualifier alloc] initWithEntity:entity qualifierFormat:requeteString, primaryKeyAttributeName];

	[myAttributes release];
	return [myQualifier autorelease];
}

//**************************************************************************
// 
//
//
//
//**************************************************************************
- (void)insertAccessRightTo:(NSMutableDictionary**)accessRight fromRight:(unsigned)rights forGID:(EOGlobalID**)gid
{

	if((rights & LIST_RIGHT) && (rights & UPDATE_RIGHT) && (rights & VIEW_RIGHT) && (rights & DELETE_RIGHT) && (rights & EDIT_RIGHT))
	{
		[*accessRight setObject:right_deluv forKey:[*gid copy]];
		return;
	}

	if((rights & LIST_RIGHT) && (rights & UPDATE_RIGHT) && (rights & VIEW_RIGHT))
	{
		[*accessRight setObject:right_luv forKey:[*gid copy]];
		return;
	}

	if((rights & LIST_RIGHT) && (rights & VIEW_RIGHT) )
	{
		[*accessRight setObject:right_lv forKey:[*gid copy]];
		return;
	}

	if((rights & LIST_RIGHT))
	{
		[*accessRight setObject:right_l forKey:[*gid copy]];
		return;
	}
	id gidCopy = [*gid copy];
	[*accessRight setObject:@"" forKey:gidCopy];
}

//**************************************************************************
// 
//
//
//
//**************************************************************************
- (void)_executeInContext:(id)_ctx
{
	EOGlobalID			*gid;
	NSAutoreleasePool	*pool;
	EOEntity			*entity;
	NSArray				*myAttributes;
	EOAdaptorChannel	*myAdaptorChannel;
	unsigned			globalIDCount;
	NSMutableDictionary	*accessRights;
	NSMutableDictionary	*writeAccessLists;
	NSMutableArray		*readAccessDates;
	id					login;
	NSArray				*loginTeams;
	BOOL				ok;
	NSDictionary		*resultRow;
	NSEnumerator		*enumerator;
	unsigned			right = 0;

	myAdaptorChannel = [[_ctx valueForKey:LSDatabaseChannelKey] adaptorChannel];
#ifdef GLC_DEBUG
	[myAdaptorChannel setDebugEnabled:YES];
#endif
    
	// if no gids just return
	if ((globalIDCount = [self->gids count]) == 0) 
	{
#ifdef GLC_DEBUG
		[self logWithFormat:@"*** _executeInContext : No gids so return nil."];
#endif
		[self setReturnValue:nil];
		return;
	}
	
	pool = [[NSAutoreleasePool alloc] init];

	// first get the current login id so here we know who we are 
	login    = [_ctx valueForKey:LSAccountKey];
    
	// check if we are "root". If yes we run _executeForRootInContext. This last method
	// just give all rights to all appointments
	if ([self isRootAccountPKey:[login valueForKey:@"companyId"] inContext:_ctx])
	{
		[self _executeForRootInContext:_ctx];
		[pool release];
		return;
	}
    
	// now we retrieve Team GID where we are a member
	loginTeams = [self _fetchTeamGIDsOfAccountWithGID:[login valueForKey:@"globalID"] inContext:_ctx];
#ifdef GLC_DEBUG
	[self logWithFormat:@"*** _executeInContext : our loginTeams are  : %@ ", loginTeams ];
#endif
    
	// create receiving object
	accessRights		= [NSMutableDictionary dictionaryWithCapacity:globalIDCount];
	writeAccessLists	= [NSMutableDictionary dictionaryWithCapacity:globalIDCount];
	readAccessDates		= [NSMutableArray arrayWithCapacity:globalIDCount];

	// now build our qualifier 
	// buildSQLQualifier use class variable "gids" tp build the request
	EOSQLQualifier* myQualifier = [[self buildSQLQualifier] copy];

	myAttributes = [[self getAttributes] copy];

	ok = [myAdaptorChannel selectAttributes:myAttributes describedByQualifier:myQualifier fetchOrder:nil lock:NO];
	RELEASE(myQualifier); myQualifier = nil;
	
	[self assert:ok format:@"*** _executeInContext : couldn't select objects by gid"];

	entity = [self entity];
	
	/* fetch appointment resultRows */
	//**********************************************************
	//
	// WE DO THE JOB IN TWO STEPS SINCE WE CAN'T FETCH WHEN YOU'RE
	// ALLREADY FETCHING and this is what we should really do :
	// - for each row (so when we fetch) we need to fetch a second list : the participants list.
	//
	// this is not allowed !!!!!
	//
	// so first we fetch and we check all records for trying to determine those with full right
	// (all right). For those we don't need participants list since it is based on ownership and delegation.
	// Others are simply insert in a temps array and for thos we will try to determine base on the
	// particpants list other rights. 
	////////////////////////////////////////////////////////////
	//
	//   HACK (TM) Copyright (C) " This Hack Sucks !!!!! "
	//
	///////////////////////////////////////////////////////////
	while ((resultRow = [myAdaptorChannel fetchAttributes:myAttributes withZone:NULL]))
	{
#ifdef GLC_DEBUG
		[self logWithFormat:@"*** _executeInContext : resultRow = %@",resultRow];
#endif	    
		gid = [entity globalIDForRow:resultRow];

		if(([self hasAllRights:resultRow inContext:_ctx]) == YES)
		{
			right = ALL_RIGHT;
			[self insertAccessRightTo:&accessRights fromRight:right forGID:&gid];
			continue;
		}

		[readAccessDates addObject:[resultRow copy]];
	}
	// stop fetching
	[myAdaptorChannel cancelFetch];

	// now we perform readAccessDate
	enumerator = [readAccessDates objectEnumerator];
	while ((resultRow = [enumerator nextObject]))
	{
		// Thierry SUCKS ;-)
		gid = [entity globalIDForRow:resultRow];

		if(([self hasDeleteRight:resultRow  inContext:_ctx]) == YES)
		{
			right |= DELETE_RIGHT;
		}

		if((right & DELETE_RIGHT) || ([self hasEditRight:resultRow  inContext:_ctx]) == YES)
		{
			right |= EDIT_RIGHT;
		}

		if((right & DELETE_RIGHT) || ([self hasUpdateRight:resultRow  inContext:_ctx]) == YES)
		{
			right |= UPDATE_RIGHT;
		}

		if((right & UPDATE_RIGHT) || ([self hasViewRight:resultRow  inContext:_ctx]) == YES)
		{
			right |= VIEW_RIGHT;
		}

		if((right & UPDATE_RIGHT) || (right & VIEW_RIGHT) || ([self hasListRight:resultRow  inContext:_ctx]) == YES)
		{
			right |= LIST_RIGHT;
		}

		[self insertAccessRightTo:&accessRights fromRight:right forGID:&gid];
	}

	/* set result */
	if (self->singleFetch)
	{
		[self setReturnValue:[accessRights objectForKey:[self->gids lastObject]]];
	}
	else
	{
		[self setReturnValueToCopyOfValue:accessRights];
	}
    
#ifdef GLC_DEBUG
	[self logWithFormat:@"***** _executeInContext : accessRights  = %@",accessRights];
#endif
	[myQualifier release]; myQualifier = nil;
	[myAttributes release]; myAttributes = nil;
	[pool release];
}

/* accessors */

//**************************************************************************
// 
//
//
//
//**************************************************************************
- (void)setGlobalIDs:(NSArray *)_gids
{
	id tmp;
	if (self->gids == _gids)
		return;
	tmp = self->gids;
	self->gids = [_gids copy];
	[tmp release];
}
//**************************************************************************
// 
//
//
//
//**************************************************************************
- (NSArray *)globalIDs
{
	return self->gids;
}

//**************************************************************************
// 
//
//
//
//**************************************************************************
- (void)setGlobalID:(EOGlobalID *)_gid
{
	NSArray *a;
	a = _gid ? [[NSArray alloc] initWithObjects:&_gid count:1] : nil;
	[self setGlobalIDs:a];
	[a release];
	self->singleFetch = YES;
}
//**************************************************************************
// 
//
//
//
//**************************************************************************
- (EOGlobalID *)globalID
{
	return [self->gids lastObject];
}

/* key-value coding */

//**************************************************************************
// 
//
//
//
//**************************************************************************
- (void)takeValue:(id)_value forKey:(id)_key
{
	if ([_key isEqualToString:@"gid"])
		[self setGlobalID:_value];
	else if ([_key isEqualToString:@"gids"])
		[self setGlobalIDs:_value];
	else
		[super takeValue:_value forKey:_key];
}

//**************************************************************************
// 
//
//
//
//**************************************************************************
- (id)valueForKey:(id)_key
{
	id v;
  
	if ([_key isEqualToString:@"gid"])
		v = [self globalID];
	else if ([_key isEqualToString:@"gids"])
		v = [self globalIDs];
	else 
		v = [super valueForKey:_key];
	return v;
}

@end /* LSAptAccessCommand */
