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

#ifndef __GDImage_H__
#define __GDImage_H__

#import <Foundation/NSObject.h>
#import <Foundation/NSGeometry.h>

@class NSString, NSData;

@interface GDImage : NSObject
{
  void *im;
  BOOL freeWhenDone;
}

- (id)initWithHandle:(void *)_handle freeWhenDone:(BOOL)_flag;
- (id)initWithContentsOfFile:(NSString *)_path;

/* accessors */

- (void *)handle;
- (int)width;
- (int)height;

/* saving */

- (NSData *)jpegData;

/* operations */

- (int)resolveColor:(int)_red:(int)_green:(int)_blue;

- (BOOL)writeStringFT:(NSString *)_s
  at:(NSPoint)_p angle:(double)_angle
  color:(int)_fg
  fontList:(NSString *)_flist size:(double)_ptsize
  boundingRect:(int *)_brect;

- (void)copyRect:(NSRect)_src
  to:(NSPoint)_dst ofImage:(GDImage *)_img;

@end

#endif /* __GDImage_H__ */
