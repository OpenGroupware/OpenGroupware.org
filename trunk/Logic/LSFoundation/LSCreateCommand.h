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

#ifndef __LSLogic_LSFoundation_LSCreateCommand_H__
#define __LSLogic_LSFoundation_LSCreateCommand_H__

#import <Foundation/NSObject.h>
#include <LSFoundation/LSCommandKeys.h>
#include <LSFoundation/LSCommandContext.h>
#include <LSFoundation/LSDBTransaction.h>
#include <LSFoundation/LSCommand.h>

// command creation

id<NSObject,LSCommand> LSCommand(NSString *_domain, NSString *_command);

id<NSObject,LSCommand>
LSCommandAV(NSString *_domain, NSString *_command, NSString *firstKey,
            va_list va);

id<NSObject,LSCommand>
LSCommandA(NSString *_domain, NSString *_command, NSString *firstKey, ...);

id<NSObject,LSCommand>
LSTCommandA(NSString *_domain, NSString *_command, NSString *firstKey, ...);

#endif /* __LSLogic_LSFoundation_LSCreateCommand_H__ */
