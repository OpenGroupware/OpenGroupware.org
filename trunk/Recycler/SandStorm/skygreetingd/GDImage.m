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

#include "GDImage.h"
#include "common.h"

#if defined(__APPLE__)
#warning no gd enabled on MacOSX ...
#else
#include <gd.h>
#endif

@implementation GDImage

- (id)initWithHandle:(void *)_handle freeWhenDone:(BOOL)_flag {
  if (_handle == NULL) {
    RELEASE(self);
    return nil;
  }
  self->im = _handle;
  self->freeWhenDone = _flag;
  return self;
}

#if 0
- (id)initWithJPEGData:(NSData *)_data {
}
- (id)initWithPNGData:(NSData *)_data {
}
#endif

- (id)initWithContentsOfFile:(NSString *)_path {
#if defined(__APPLE__)
  return nil;
#else
  NSString *ext;
  
  if ([_path length] == 0) {
    RELEASE(self);
    return nil;
  }
  
  ext = [[_path pathExtension] lowercaseString];
  if ([ext isEqualToString:@"jpg"] ||
      [ext isEqualToString:@"jpeg"]) {
    FILE *f;
    void *imh;

    if ((f = fopen([_path cString], "rb")) == NULL) {
      RELEASE(self);
      return nil;
    }
    
    imh = gdImageCreateFromJpeg(f);
    fclose(f);
    
    return [self initWithHandle:imh freeWhenDone:YES];
  }
#if 0
  else if ([ext isEqualToString:@"png"]) {
    FILE *f;
    void *imh;

    if ((f = fopen([_path cString], "rb")) == NULL) {
      RELEASE(self);
      return nil;
    }
    
    imh = gdImageCreateFromPNG(f);
    fclose(f);
    
    return [self initWithHandle:imh freeWhenDone:YES];
  }
#endif
  else {
    NSLog(@"%s: unsupported image type (ext=%@,path=%@)",
          __PRETTY_FUNCTION__, ext, _path);
    RELEASE(self);
    return nil;
  }
#endif
}

#if defined(__APPLE__)
#else

- (void)dealloc {
  if (self->im != NULL && freeWhenDone) {
    gdImageDestroy(self->im);
    self->im = NULL;
  }
  [super dealloc];
}

/* accessors */

- (void *)handle {
  return self->im;
}

- (int)width {
  return self->im ? gdImageSX((gdImagePtr)self->im) : -1;
}
- (int)height {
  return self->im ? gdImageSY((gdImagePtr)self->im) : -1;
}

/* saving */

- (NSData *)jpegData {
  void *jpegDataPtr = nil;
  int  size;
  
  if ((jpegDataPtr = gdImageJpegPtr(self->im, &size, 100/* ?? */))) {
    NSData *data;
    
    data = [NSData dataWithBytes:jpegDataPtr length:size];
    gdFree(jpegDataPtr);
    return data;
  }
  else
    return nil;
}

/* operations */

- (int)resolveColor:(int)_red:(int)_green:(int)_blue {
  return gdImageColorClosest(self->im, _red, _green, _blue); 
}

+ (BOOL)calculateBoundingRectFT:(int *)_brect
  forString:(NSString *)_s
  at:(int)_x:(int)_y angle:(double)_angle
  fontList:(NSString *)_flist size:(double)_ptsize
{
  /*
    Use a NULL gdImagePtr to get the bounding rectangle without
    rendering. 
    This is a relatively cheap operation if followed by a rendering
    of the same string, because of the caching of the partial
    rendering during bounding rectangle calculation.
  */
  char *err;
  
  err = gdImageStringFT(NULL,
                        _brect, 0,
                        (char *)[_flist cString], _ptsize,
                        _angle, _x, _y,
                        (char *)[_s cString]);
  if (err)
    NSLog(@"GDERROR(%s): %s", __PRETTY_FUNCTION__, err);
  
  return err ? NO : YES;
}

- (BOOL)writeStringFT:(NSString *)_s
  at:(NSPoint)_p angle:(double)_angle
  color:(int)_fg
  fontList:(NSString *)_flist size:(double)_ptsize
  boundingRect:(int *)_brect
{
  char *err;

  if ([_s length] == 0)
    return YES;
  
  err = gdImageStringFT(self->im,
                        _brect, _fg,
                        (char *)[_flist cString], _ptsize,
                        _angle, _p.x, _p.y,
                        (char *)[_s cString]);
  if (err)
    NSLog(@"GDERROR(%s): %s", __PRETTY_FUNCTION__, err);
  return err ? NO : YES;
}

- (void)copyRect:(NSRect)_src
  to:(NSPoint)_dst ofImage:(GDImage *)_img
{
  if (_img == NULL) return;
  
  gdImageCopy([_img handle], self->im,
              _dst.x, _dst.y,
              _src.origin.x, _src.origin.y,
              _src.size.width, _src.size.height);
}

#endif

@end /* GDImage */
