/*
  Copyright (C) 2004 SKYRIX Software AG

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
// $Id$

#include "NSString+P4.h"
#include "common.h"

@implementation NSString(P4)

- (BOOL)isPubPreviewMimeType {
  unsigned len;
  
  if ((len = [self length]) < 9) return NO;
  if (len == 9  && [self hasPrefix:@"text/html"])       return YES;
  if (len == 10 && [self hasPrefix:@"text/xhtml"])      return YES;
  if (len == 15 && [self hasPrefix:@"text/structured"]) return YES;
  return NO;
}

- (BOOL)isPubPreviewExtension {
  unsigned len;
  
  if ((len = [self length]) < 3) return NO;

  switch (len) {
  case 3:
    if ([self isEqualToString:@"htm"])   return YES;
    if ([self isEqualToString:@"stx"])   return YES;
    return NO;
  case 4:
    return [self isEqualToString:@"html"];
  case 5:
    return [self isEqualToString:@"xhtml"];
  }
  return NO;
}

- (BOOL)isPubDOMMimeType {
  unsigned len;
  
  if ((len = [self length]) < 9) return NO;
  if (len == 9  && [self hasPrefix:@"text/html"])       return YES;
  if (len == 10 && [self hasPrefix:@"text/xhtml"])      return YES;
  if (len == 15 && [self hasPrefix:@"text/structured"]) return YES;
  if (len == 8  && [self hasPrefix:@"text/xml"])        return YES;
  if (len == 8  && [self hasPrefix:@"text/svg"])        return YES;
  return NO;
}

- (BOOL)isPubDOMExtension {
  unsigned len;
  
  if ((len = [self length]) < 3) return NO;

  switch (len) {
  case 3:
    if ([self isEqualToString:@"htm"]) return YES;
    if ([self isEqualToString:@"stx"]) return YES;
    if ([self isEqualToString:@"sfm"]) return YES;
    return NO;
  case 4:
    return [self isEqualToString:@"html"];
  case 5:
    if ([self isEqualToString:@"xhtml"]) return YES;
    if ([self isEqualToString:@"xtmpl"]) return YES;
    return NO;
  }
  return NO;
}

- (BOOL)isEditAsNewExtension {
  unsigned len;
  
  if ((len = [self length]) < 2) return NO;

  switch (len) {
  case 2:
    return [self isEqualToString:@"js"];
  case 3:
    if ([self isEqualToString:@"sfm"]) return YES;
    if ([self isEqualToString:@"txt"]) return YES;
    if ([self isEqualToString:@"xml"]) return YES;
    if ([self isEqualToString:@"stx"]) return YES;
    return NO;
  case 4:
    if ([self isEqualToString:@"html"]) return YES;
    return NO;
  case 5:
    if ([self isEqualToString:@"xhtml"]) return YES;
    if ([self isEqualToString:@"xtmpl"]) return YES;
    return NO;
  }
  return NO;
}

@end /* NSString(P4) */
