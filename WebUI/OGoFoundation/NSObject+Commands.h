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

#ifndef __LSWFoundation_NSObject_Commands_H__
#define __LSWFoundation_NSObject_Commands_H__

#import <Foundation/NSObject.h>

@class NSString, NSDictionary;
@class OGoContextSession;

/**
 * @category NSObject(LSWCommands)
 * @brief Run OGo commands with the receiver as object.
 *
 * Convenience category that executes Logic commands in
 * the current session, automatically passing the
 * receiver as the "object" argument to the command.
 *
 * @see WOComponent(Commands)
 * @see OGoSession
 */
@interface NSObject(LSWCommands)

- (id)run:(NSString *)_command arguments:(NSDictionary *)_args;
- (id)run:(NSString *)_command, ...;
- (id)run1:(NSString *)_command, ...;

@end

#endif /* __LSWFoundation_NSObject_Commands_H__ */
