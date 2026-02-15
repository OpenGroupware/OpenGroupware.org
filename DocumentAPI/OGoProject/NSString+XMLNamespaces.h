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

#import <Foundation/NSString.h>

/**
 * @category NSString(XMLNamespaces)
 * @brief Convenience methods for handling Clark-notation
 *        XML namespace prefixes in strings.
 *
 * Provides methods to detect, extract, remove, and set
 * XML namespace prefixes in the "{namespace}localName"
 * Clark notation commonly used in WebDAV property names.
 */
@interface NSString(XMLNamespaces)
- (BOOL)hasXMLNamespace;
- (NSString *)xmlNamespace;
- (NSString *)stringByRemovingXMLNamespace;
- (NSString *)stringBySettingXMLNamespace:(NSString *)_str;
@end /* NSString(Namespaces) */
