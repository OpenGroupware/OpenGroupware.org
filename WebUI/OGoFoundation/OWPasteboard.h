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

#ifndef __NGObjWeb_OWPasteboard_H__
#define __NGObjWeb_OWPasteboard_H__

#import <Foundation/NSMapTable.h>
#import <Foundation/NSObject.h>

@class NSString, NSArray, NSMutableDictionary;
@class NGMimeType;

/*
  A web pasteboard used in conjunction with OWSession.
  See NSPasteboard's description for a conceptual introduction.
*/

@interface OWPasteboard : NSObject
{
@protected
  NSString   *name;
  id         owner;
  int        changeCount;
  NSArray    *declaredTypes;
  NSMutableDictionary *type2content;
}

- (id)initWithName:(NSString *)_name; // designated initializer

// accessors

- (NSString *)name;
- (id)owner;
- (int)changeCount;
- (void)clear; // remove all contents

// types

- (int)declareTypes:(NSArray *)_types owner:(id)_newOwner;
- (int)addTypes:(NSArray *)_types owner:(id)_newOwner;

- (NGMimeType *)availableTypeFromArray:(NSArray *)_types;

- (NSArray *)types;

// content

- (BOOL)setObject:(id)_object forType:(NGMimeType *)_type;
- (id)objectForType:(NGMimeType *)_type;

@end

@interface OWPasteboard(ConvenienceMethods)

- (int)declareTypesWithOwner:(id)_newOwner types:(NGMimeType *)_first, ...;
- (NGMimeType *)availableTypeFromList:(NGMimeType *)_first, ...;

@end

@interface NSObject(OWPasteboardOwner)

- (void)pasteboardChangedOwner:(OWPasteboard *)_pasteboard;

- (void)pasteboard:(OWPasteboard *)_pasteboard
  provideDataForType:(NGMimeType *)_type;

@end

#endif /* __NGObjWeb_OWPasteboard_H__ */
