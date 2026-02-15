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

#import <LSFoundation/LSBaseCommand.h>

@class NSArray, NSNumber;

/**
 * @class LSFilterJobCommand
 * @brief Abstract base class for commands that filter
 *        a list of jobs by role criteria.
 *
 * Subclasses must override the -filter method to
 * perform the actual filtering logic. The command
 * provides a `jobList` to filter and optional
 * `creatorId`, `ownerId`, and `executantId` values
 * to match against.
 *
 * The result of -filter is set as the command's
 * return value.
 */
@interface LSFilterJobCommand : LSBaseCommand
{
  NSArray  *jobList;
  NSNumber *creatorId;
  NSNumber *ownerId;
  NSNumber *executantId;
}

- (id)filter; // subclassResponsibility

// accessors

- (NSArray *)jobList;
- (void)setJobList:(NSArray *)_jobList;

- (NSNumber *)executantId;
- (void)setExecutantId:(NSNumber *)_executantId;

- (NSNumber *)creatorId;
- (void)setCreatorId:(NSNumber *)_creatorId;

@end

