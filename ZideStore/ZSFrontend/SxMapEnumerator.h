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
// $Id: SxMapEnumerator.h 1 2004-08-20 11:17:52Z znek $

#ifndef __sxdavd3_SxMapEnumerator_H__
#define __sxdavd3_SxMapEnumerator_H__

#import <Foundation/NSEnumerator.h>

/*
  SxMapEnumerator
  
  This enumerator goes over all objects in the source enumerator and
  calls the mapper callback on each to perform some operation on them.
  
  The callback method needs to have a format like:
  
    - (id)mapObject:(id)_object;
  
  note that it will be passed the "nil" object to terminate the events.
*/

@interface SxMapEnumerator : NSEnumerator
{
  NSEnumerator *source;
  id  object;
  SEL selector;
}

+ (id)enumeratorWithSource:(NSEnumerator *)_source 
  object:(id)_object selector:(SEL)_sel;
- (id)initWithSource:(NSEnumerator *)_source
  object:(id)_object selector:(SEL)_sel;

/* operations */

- (id)nextObject;

@end

#endif /* __sxdavd3_SxMapEnumerator_H__ */
