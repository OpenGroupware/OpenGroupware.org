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

#ifndef __LSLogic_LSFoundation_LSCommandKeys_H__
#define __LSLogic_LSFoundation_LSCommandKeys_H__

#import <Foundation/NSString.h>

#define LSDBReturnType_NoObject    ((int)0)
#define LSDBReturnType_OneObject   ((int)1)
#define LSDBReturnType_ManyObjects ((int)2)

// keys which are used in the context

#define LSSelfCommandKey         @"command"
#define LSParentCommandKey       @"parent"
#define LSCommandFactoryKey      @"factory"
#define LSDBTransactionKey       @"transaction"

#define LSDatabaseKey            @"database"
#define LSDatabaseContextKey     @"context"
#define LSDatabaseChannelKey     @"channel"
#define LSAccountKey             @"account"
#define LSUserDefaultsKey        @"userDefaults"
#define LSCryptedUserPasswordKey @"cryptedUserPwd"

// commonly used command functions

#define LSReturnsOneObject   ([self returnType] == LSDBReturnType_OneObject)
#define LSReturnsManyObjects ([self returnType] == LSDBReturnType_ManyObjects)

#endif /* __LSLogic_LSFoundation_LSCommandKeys_H__ */
