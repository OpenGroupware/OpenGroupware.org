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

#include "SkyDocument+Pub.h"
#include "common.h"

/*
  JavaScript

    Properties
      String   objType       - readonly
      String   objClass      - readonly
      BOOL     isRoot        - readonly
      String   contentType   - readonly
      String   lastChanged   - readonly
      BOOL     hasSuperLinks - readonly
      Object   id            - readonly
      String   name          - readonly
      String   title         - readonly
    
    Methods
      Document getParentDocument([count])
      Document getIndexDocument()
      Array    getChildList()
      Array    getTocList()
      Array    getDocumentsToRoot()
*/

@implementation SkyDocument(PubJS)

- (id)_jsprop_objType {
  return [self npsDocumentType];
}
- (id)_jsprop_objClass {
  return [self npsDocumentClassName];
}
- (id)_jsprop_isRoot {
  NSString    *p;
  SkyDocument *parent;
  
  p = [self valueForKey:@"NSFilePath"];
  
  if ([p isEqualToString:@"/"])
    /* is root folder */
    return [NSNumber numberWithBool:YES];
  
  if ((parent = [self parentDocument]) == nil)
    /* has no parent, must be root ... */
    return [NSNumber numberWithBool:YES];
  
  if (![[parent valueForKey:@"NSFilePath"] isEqualToString:@"/"])
    /* parent is not root folder */
    return [NSNumber numberWithBool:NO];
  
  /* parent is root folder */
  if ([[parent pubIndexFilePath] isEqualToString:p])
    /* self is index file of root-folder, so this is root ... */
    return [NSNumber numberWithBool:YES];
  
  return [NSNumber numberWithBool:NO];
}
- (id)_jsprop_contentType {
  return [self valueForKey:@"NSFileMimeType"];
}
- (id)_jsprop_lastChanged {
  return [self valueForKey:NSFileModificationDate];
}
- (id)_jsprop_hasSuperLinks {
  return [NSNumber numberWithBool:NO];
}
- (id)_jsprop_id {
  return [self globalID];
}
- (id)_jsprop_name {
  return [self valueForKey:@"NSFileName"];
}
- (id)_jsprop_title {
  return [self valueForKey:@"NSFileSubject"];
}

- (id)_jsfunc_getParentDocument:(NSArray *)_args {
  unsigned count;
  SkyDocument *doc;
  
  if ((count = [_args count]) == 0)
    return [self parentDocument];

  doc = self;
  for (count = [[_args objectAtIndex:0] intValue]; count > 0; count --)
    doc = [doc parentDocument];
  return doc;
}

- (id)_jsfunc_getIndexDocument:(NSArray *)_args {
  SkyDocument *idx;
  
  if ((idx = [self pubIndexDocument])) {
    // NSLog(@"%@: found idx document %@ ...", self, idx);
    return idx;
  }
  
#if DEBUG
  NSLog(@"WARNING(%@): found no idx document ...", self);
#endif
  
  return nil;
}

- (id)_jsfunc_getChildList:(NSArray *)_args {
  return [self pubChildListDocuments];
}
- (id)_jsfunc_getTocList:(NSArray *)_args {
  return [self pubTocListDocuments];
}
- (id)_jsfunc_getDocumentsToRoot:(NSArray *)_args {
  return [self pubFolderDocumentsToRoot];
}

@end /* SkyDocument(PubJS) */
