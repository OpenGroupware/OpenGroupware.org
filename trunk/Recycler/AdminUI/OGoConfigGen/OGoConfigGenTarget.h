/*
  Copyright (C) 2004-2005 SKYRIX Software AG

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

#ifndef __OGoConfigGen_OGoConfigGenTarget_H__
#define __OGoConfigGen_OGoConfigGenTarget_H__

#import <Foundation/NSObject.h>

@class NSString, NSMutableString, NSException;
@class OGoConfigGenTransaction;

@interface OGoConfigGenTarget : NSObject
{
  OGoConfigGenTransaction *tx; /* non-retained */
  NSString        *name;
  NSMutableString *content;
}

+ (id)targetWithName:(NSString *)_name 
  inTransaction:(OGoConfigGenTransaction *)_tx;
- (id)initWithName:(NSString *)_name 
  inTransaction:(OGoConfigGenTransaction *)_tx;

/* accessors */

- (OGoConfigGenTransaction *)configGenTransaction;
- (NSString *)name;
- (NSString *)content;

/* operations */

- (NSException *)write:(NSString *)_s;
- (NSException *)writeln:(NSString *)_s;

@end

#endif /* __OGoConfigGen_OGoConfigGenTarget_H__ */
