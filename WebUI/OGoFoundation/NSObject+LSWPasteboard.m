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

#import "common.h"
#import "NSObject+LSWPasteboard.h"
#import <EOControl/EOKeyGlobalID.h>
#import <Foundation/NSURL.h>

@implementation NSObject(LSWPasteboardAdds)

- (NGMimeType *)lswPasteboardType {
  return [NGMimeType mimeType:@"objc"
                     subType:NSStringFromClass([self class])];
}

@end /* NSObject(LSWPasteboardAdds) */

@implementation EOGenericRecord(LSWPasteboardAdds)

- (NGMimeType *)lswPasteboardType {
  return [NGMimeType mimeType:@"eo"
                     subType:[[[self entity] name] lowercaseString]];
}

@end /* EOGenericRecord(LSWPasteboardAdds) */

@implementation EOKeyGlobalID(LSWPasteboardAdds)

- (NGMimeType *)lswPasteboardType {
  return [NGMimeType mimeType:@"eo-gid"
                     subType:[[self entityName] lowercaseString]];
}

@end /* EOKeyGlobalID(LSWPasteboardAdds) */

@implementation NSURL(LSWPasteboardAdds)

- (NGMimeType *)lswPasteboardType {
  return [NGMimeType mimeType:@"nsurl"
                     subType:[self scheme]];
}

@end /* NSURL(LSWPasteboardAdds) */

void __link_LSWPasteboard(void) {
  __link_LSWPasteboard();
}
