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

#include <OGoDocuments/SkyDocument.h>
#include <OGoDocuments/SkyDocumentManager.h>
#include <OGoDocuments/SkyContext.h>
#include "common.h"

#ifndef LIB_FOUNDATION_LIBRARY
@interface NSObject(SubclassResp)
- (void)subclassResponsibility:(SEL)_sel;
@end
#endif

@implementation SkyDocument

+ (int)version {
  return 1; /* v1 */
}

- (SkyDocumentType *)documentType {
  [self logWithFormat:@"ERROR(%s): subclasses must override this method!",
	  __PRETTY_FUNCTION__];
  return nil;
}

- (BOOL)isComplete {
  [self logWithFormat:@"ERROR(%s): subclasses must override this method!",
	  __PRETTY_FUNCTION__];
  return NO;
}

- (EOGlobalID *)globalID {
  [self logWithFormat:@"ERROR(%s): subclasses must override this method!",
	  __PRETTY_FUNCTION__];
  return nil;
}

/* properties */

- (BOOL)isReadable {
  return YES;
}
- (BOOL)isWriteable {
  return NO;
}
- (BOOL)isRemovable {
  return NO;
}
- (BOOL)isNew {
  return NO;
}
- (BOOL)isEdited {
  return NO;
}


/* document URL */

- (NSURL *)documentURL {
  return [[(id<SkyContext>)[self context]
                           documentManager] urlForDocument:self];
}

/* SKYRiX context the document lives in */

- (id)context {
  [self logWithFormat:@"ERROR(%s): subclasses must override this method!",
	  __PRETTY_FUNCTION__];
  return nil;
}

/* feature check */

- (BOOL)supportsFeature:(NSString *)_featureURI {
  return NO;
}

/* key-value coding */

- (id)handleQueryWithUnboundKey:(NSString *)_key {
  /* to please Cocoa ... */
  // TODO: this API changed on Panther
  return nil;
}

/* saving and deleting */

- (BOOL)save {
  return NO;
}

- (BOOL)delete {
  return NO;
}

- (BOOL)reload {
  return NO;
}

/* description */

- (void)appendAttributesToDescription:(NSMutableString *)_md {
  EOGlobalID *gid;
  id ctx;
  
  if ((gid = [self globalID]) != nil)
    [_md appendFormat:@" gid=%@", gid];
  
  if ((ctx = [self context]) != nil)
    [_md appendFormat:@" ctx=0x%08X", ctx];
}

- (NSString *)description {
  NSMutableString *ms;
  
  ms = [NSMutableString stringWithCapacity:128];
  [ms appendFormat:@"<0x%08X[%@]:", self, NSStringFromClass([self class])];
  [self appendAttributesToDescription:ms];
  [ms appendString:@">"];
  return ms;
}

@end /* SkyDocument */
