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

#include "SkyPubSKYOBJ.h"
#include "common.h"
#include "SkyDocument+Pub.h"
#include "SkyPubDataSource.h"
#include "SkyPubFileManager.h"
#include "PubKeyValueCoding.h"
#include <NGObjDOM/WOContext+Cursor.h>
#include <DOM/EDOM.h>

//#define PROF 1

@implementation SkyPubSKYOBJNodeRenderer(Document)

- (void)_appendDocumentNode:(id)_node
  toResponse:(WOResponse *)_response
  inContext:(WOContext *)_ctx
{
  /*
    document=path
      push the document at the specified path as the active context. relative
      pathes are allowed.
  */
  NSAutoreleasePool *pool;
  NSString          *path;
  id                document;
  
  if (![_node hasChildNodes])
    /* no content to write out ... */
    return;
  
  pool = [[NSAutoreleasePool alloc] init];
  
  path = [self stringFor:@"document" node:_node ctx:_ctx];
  if (![path isAbsolutePath]) {
    NSString *docPath;
    
    docPath = [[_ctx cursor] valueForKey:@"NSFilePath"];
    if ([docPath length] > 0)
      path = [docPath stringByAppendingPathComponent:path];
  }

  document = [[[_ctx cursor] pubFileManager] documentAtPath:path];
  
  if (document) {
    [_ctx pushCursor:document];
  
    [self appendChildNodes:[_node childNodes]
          toResponse:_response
          inContext:_ctx];
  
    [_ctx popCursor];
  }
  
  RELEASE(pool);
}

@end /* SkyPubSKYOBJNodeRenderer(Document) */
