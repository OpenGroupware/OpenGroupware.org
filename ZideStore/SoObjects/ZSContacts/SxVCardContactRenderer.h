/*
  Copyright (C) 2002-2004 SKYRIX Software AG

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

#ifndef __Contacts_SxVCardContactRenderer_H__
#define __Contacts_SxVCardContactRenderer_H__

#import <Foundation/NSObject.h>

@class NSString, NSDictionary;
@class WOResponse;

/*
  SxVCardContactRenderer
  
  Superclass for SxVCardEnterpriseRenderer and SxVCardPersonRenderer.

  TODO: could be that this isn't used anymore! The LSAddress Logic bundle
        contains a command to create vcards for contacts.
*/

@interface SxVCardContactRenderer : NSObject

+ (SxVCardContactRenderer *)renderer;

- (WOResponse *)vCardResponseForObject:(id)_object inContext:(id)_ctx
  container:(id)_container;

- (NSString *)addressStringForDict:(NSDictionary *)_dict;

@end /* SxVCardContactRenderer */

#endif /* __Contacts_SxVCardContactRenderer_H__ */
