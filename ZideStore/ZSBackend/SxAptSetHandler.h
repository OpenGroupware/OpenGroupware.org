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

#ifndef __Appointments_SxAptSetHandler_H__
#define __Appointments_SxAptSetHandler_H__

#import <Foundation/NSObject.h>

/*
  SxAptSetHandler

  Internal object, used for handling set operatiosn ...
  
  Note: major difference: no operation should do a commit or rollback inside
        the handler !
  
  CoreInfo: title, location, end/startdate, sensitivity
*/

@class NSDate, NSString, NSArray;
@class SxAptSetIdentifier, SxAptManager;

@interface SxAptSetHandler : NSObject
{
  SxAptSetIdentifier   *setId;
  SxAptManager         *manager; /* non-retained */
}

- (id)initWithSetId:(SxAptSetIdentifier *)_setId
  manager:(SxAptManager *)_manager;

/* accessors */

/* operations */

- (NSArray *)fetchGIDs;
- (NSArray *)fetchGIDsFrom:(NSDate *)_from to:(NSDate *)_to;
- (NSArray *)fetchPkeysAndModDatesFrom:(NSDate *)_from to:(NSDate *)_to;
- (NSArray *)fetchCoreInfo;
- (NSArray *)fetchCoreInfoForGIDs:(NSArray *)_gids;

/* generation */

- (int)generationOfSet;

/* set */

- (NSString *)idsAndVersionsCSV;
- (int)fetchCount;

@end

#endif /* __Appointments_SxAptSetHandler_H__ */
