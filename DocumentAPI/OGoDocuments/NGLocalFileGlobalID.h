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

#ifndef NGLocalFileGlobalID_h
#define NGLocalFileGlobalID_h

#import <Foundation/NSString.h>
#import <Foundation/NSUtilities.h>
#import <EOControl/EOControl.h>

@class NSString;

@interface NGLocalFileGlobalID : EOGlobalID
{
  NSString *path;
  NSString *rootPath;
}
- (id)initWithPath:(NSString *)_path rootPath:(NSString *)_root;
- (NSString *)path;
- (NSString *)rootPath;
@end /* NGLocalFileGlobalID */

#endif /* NGLocalFileGlobalID_h */
