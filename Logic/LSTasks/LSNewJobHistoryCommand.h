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

#import <LSFoundation/LSDBObjectNewCommand.h>

/**
 * @class LSNewJobHistoryCommand
 * @brief Creates a new JobHistory record and its
 *        associated JobHistoryInfo.
 *
 * Inserts a new row into the JobHistory entity that
 * logs a state transition or action on a job. In
 * addition, a companion JobHistoryInfo record is
 * created to store an optional free-text comment
 * describing the history entry.
 */
@interface LSNewJobHistoryCommand : LSDBObjectNewCommand
{
  NSString *comment;
}

- (void)setComment:(NSString *)_comment;
- (NSString *)comment;

@end
