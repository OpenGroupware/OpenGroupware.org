/*
  Copyright (C) 2006 Helge Hess

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

#ifndef __ZideStore_GCalComment_H__
#define __ZideStore_GCalComment_H__

#import <Foundation/NSObject.h>

/*
  GCalComment

    parent-folder: GCalComments
    subobjects:    -

  This maps to /calendar/feeds/$USERNAME/private/full/$PKEY/comments/12345.

  GCal comments are to be mapped to OGo notes.

  A complete URL:
    /calendar/feeds/$USER/private/full/$PKEY/comments/12345

  Schema:
    /calendar/feeds/$USER/visibility/projection/$PKEY/comment/$COMMENTID
*/

@class GCalComments;

@interface GCalComment : NSObject
{
  GCalComments *container;
  NSString     *name; /* primary key */
}

- (id)initWithName:(NSString *)_name inContainer:(id)_container;

/* accessors */

- (id)container;
- (NSString *)nameInContainer;

@end

#endif /* __ZideStore_GCalComment_H__ */
