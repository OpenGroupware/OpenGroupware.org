/*
  Copyright (C) 2000-2003 SKYRIX Software AG

  This file is part of OGo

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
// $Id$

#ifndef __LSFoundation_NSObject_Commands_H__
#define __LSFoundation_NSObject_Commands_H__

#import <Foundation/NSObject.h>

@class NSString, NSDictionary, NSMutableDictionary;
@class OGoContextSession;

/*
  This category runs commands based on objects.
*/

@interface NSObject(Commands)

- (id)run:(NSString *)_command
  marguments:(NSMutableDictionary *)_args
  session:(OGoContextSession *)_sn;

- (id)run:(NSString *)_command
  arguments:(NSDictionary *)_args
  session:(OGoContextSession *)_sn;

@end

/*
  Determine session & context of an object
*/

@interface NSObject(SessionContext)

- (OGoContextSession *)skySession;
- (id)commandContext;

@end

/*
  Run command's in the current session & context as determined above.
*/

@interface NSObject(CallCommands)
- (id)call:(NSString *)_command, ...;
- (id)call1:(NSString *)_command, ...;
- (id)callN:(NSString *)_command, ...;
@end

#endif /* __LSFoundation_NSObject_Commands_H__ */
