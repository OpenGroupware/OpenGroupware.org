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

/*
  supported JS properties:
  
    String baseURL   - readonly
  
  supported JS functions:
    
    Document getDocument(url|gid)
    Array    getDocuments(array of (urls|gids))
*/

#include "SkyDocumentManagerImp.h"
#include "common.h"

@implementation SkyDocumentManager(JSSupport)

/* properties */

- (NSString *)_jsprop_baseURL {
  return [[self skyrixBaseURL] absoluteString];
}

/* functions */

- (id)_jsfunc_getDocument:(NSArray *)_args {
  unsigned count;
  id uid, doc;
  
  if ((count = [_args count]) == 0) {
    NSLog(@"%s: to few arguments ...", __PRETTY_FUNCTION__);
    return nil;
  }
  
  uid = [_args objectAtIndex:0];
  
  NS_DURING {
    doc = [uid isKindOfClass:[EOGlobalID class]]
      ? [self documentForGlobalID:uid]
      : [self documentForURL:uid];
  }
  NS_HANDLER {
    *(&doc) = nil;
    fprintf(stderr, "WARNING: catched exception %s\n",
            [[localException description] cString]);
  }
  NS_ENDHANDLER;

#if DEBUG
  if (doc == nil) {
    NSLog(@"WARNING(%s): got no document for id '%@' ..",
          __PRETTY_FUNCTION__, uid);
  }
#endif
  
  return doc;
}

- (id)_jsfunc_getDocuments:(NSArray *)_args {
  unsigned       argc, i, count;
  NSArray        *array, *docs;
  NSMutableArray *gids = nil;
  
  if ((argc = [_args count]) == 0)
    return nil;
  
  array = [_args objectAtIndex:0];
  count = [array count];
  
  for (i = 0; i < count; i++) {
    id uid;
    
    uid = [_args objectAtIndex:i];
    if (![uid isKindOfClass:[EOGlobalID class]])
      uid = [self globalIDForURL:uid];
    
    if (uid)
      [gids addObject:uid];
  }
  
  NS_DURING {
    docs = [self documentsForGlobalIDs:gids];
    docs = [[docs shallowCopy] autorelease];
  }
  NS_HANDLER {
    *(&docs) = nil;
    fprintf(stderr, "WARNING: catched exception %s\n",
            [[localException description] cString]);
  }
  NS_ENDHANDLER;
  
  return docs;
}

@end /* SkyDocumentManager(JSSupport) */
