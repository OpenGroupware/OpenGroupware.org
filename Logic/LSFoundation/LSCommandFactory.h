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

#ifndef __LSLogic_LSFoundation_LSCommandFactory_H__
#define __LSLogic_LSFoundation_LSCommandFactory_H__

#import <Foundation/NSObject.h>

@class NSString;

/**
 * @protocol LSCommandFactory
 * @brief Factory protocol for looking up command objects by
 *   domain and operation name.
 *
 * Implementations resolve a command string (e.g. "get") within
 * a domain (e.g. "person") to a concrete command instance
 * conforming to LSCommand. The factory is typically accessed
 * through the LSCommandContext.
 *
 * @see LSCommand
 * @see LSCommandContext
 */
@protocol LSCommandFactory

- (id)command:(NSString *)_command inDomain:(NSString *)_domainName;
- (id)lookupCommand:(NSString *)_command;

@end

#endif /* __LSLogic_LSFoundation_LSCommandFactory_H__ */
