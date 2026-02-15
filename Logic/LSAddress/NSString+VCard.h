/*
  Copyright (C) 2004 Helge Hess

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

#ifndef __LSAddress_NSString_VCard_H__
#define __LSAddress_NSString_VCard_H__

#import <Foundation/NSString.h>

/**
 * @category NSString(VCard)
 *
 * Adds vCard character escaping to NSString. The vCard
 * format requires that commas, semicolons, newlines, and
 * backslashes be escaped with a preceding backslash.
 *
 * Provides a method to count unsafe characters and a method
 * to return an escaped copy of the string suitable for use
 * in vCard property values.
 */
@interface NSString(VCard)

- (unsigned)numberOfUnsafeVCardCharacters;
- (NSString *)stringByEscapingUnsafeVCardCharacters;

@end

#endif /* __LSAddress_NSString_VCard_H__ */
