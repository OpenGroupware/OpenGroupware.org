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

#include "NGResourceLocator+ZSF.h"
#include "common.h"

@implementation NGResourceLocator(ZSF)

+ (int)zsfMajorVersion {
  return ZSF_MAJOR_VERSION;
}
+ (int)zsfMinorVersion {
  return ZSF_MINOR_VERSION;
}
+ (NSString *)zsfShareDirectorySubPath {
  return [NSString stringWithFormat:@"share/zidestore-%i.%i/",
                     [self zsfMajorVersion], [self zsfMinorVersion]];
}

+ (NGResourceLocator *)zsfResourceLocator {
  NGResourceLocator *loc = nil;
  
  loc = [NGResourceLocator resourceLocatorForGNUstepPath:
                             @"Library/Libraries/Resources/ZSFrontend"
                           fhsPath:[self zsfShareDirectorySubPath]];
  return loc;
}

@end /* NGResourceLocator(ZSF) */
