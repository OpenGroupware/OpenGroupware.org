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

#ifndef __SKYKeyValueCoding_H__
#define __SKYKeyValueCoding_H__

#import <Foundation/NSObject.h>

@class NSString;

@interface NSObject(SKYKeyValueCoding)

- (id)npsValueForKey:(NSString *)_key inContext:(id)_ctx;
- (id)npsValueForKeyPath:(NSString *)_keypath inContext:(id)_ctx;

- (NSString *)npsStringifyValue:(id)_value inContext:(id)_ctx;
- (NSString *)npsStringValueForKey:(NSString *)_key inContext:(id)_ctx;
- (NSString *)npsStringValueForKeyPath:(NSString *)_keypath inContext:(id)_ctx;

@end

#endif /* __SKYKeyValueCoding_H__ */
