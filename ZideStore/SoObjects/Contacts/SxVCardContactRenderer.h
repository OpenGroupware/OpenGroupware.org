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
// $Id: SxVCardContactRenderer.h 1 2004-08-20 11:17:52Z znek $

#ifndef __Contacts_SxVCardContactRenderer_H__
#define __Contacts_SxVCardContactRenderer_H__

#import <Foundation/NSObject.h>

@class NSString, NSDictionary;
@class WOResponse;

@interface SxVCardContactRenderer : NSObject

+ (SxVCardContactRenderer *)renderer;
- (WOResponse *)vCardResponseForObject:(id)_object inContext:(id)_ctx
  container:(id)_container;
- (NSString *)addressStringForDict:(NSDictionary *)_dict;

@end /* SxVCardContactRenderer */

#endif /* __Contacts_SxVCardContactRenderer_H__ */
