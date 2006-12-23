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

#include <OGoDocuments/SkyDocument+JS.h>
#include <OGoDocuments/SkyDocumentManager.h>
#include <OGoDocuments/SkyContext.h>
#include "common.h"

@implementation SkyDocument(JSSupport)

static int debugJS = 0;
static NSNumber *yesNum = nil;
static NSNumber *noNum  = nil;

static void _ensureBools(void) {
  if (yesNum == nil) yesNum = [[NSNumber numberWithBool:YES] retain];
  if (noNum  == nil) noNum  = [[NSNumber numberWithBool:NO]  retain];
}

/* properties */

- (id)_jsprop_isReadable {
  _ensureBools();
  return [self isReadable]
    ? yesNum : noNum;
}
- (id)_jsprop_isWriteable {
  _ensureBools();
  return [self isWriteable]
    ? yesNum : noNum;
}
- (id)_jsprop_isRemovable {
  _ensureBools();
  return [self isRemovable]
    ? yesNum : noNum;
}

- (id)_jsprop_isNew {
  _ensureBools();
  return [self isNew]
    ? yesNum : noNum;
}

- (id)_jsprop_isEdited {
  _ensureBools();
  return [self isEdited]
    ? yesNum : noNum;
}

/* functions */

- (id)_jsfunc_getDocumentType:(NSArray *)_args {
  return [self documentType];
}

- (id)_jsfunc_getGlobalID:(NSArray *)_gids {
  return [self globalID];
}

- (id)_jsfunc_getDocumentURL:(NSArray *)_args {
  id<SkyDocumentManager> dm;
  NSURL *url;
  
  if ((dm = [(id<SkyContext>)[self context] documentManager]) == nil) {
    NSLog(@"WARNING(%s): can't get document manager ...", __PRETTY_FUNCTION__);
    return nil;
  }
  
  if ((url = [dm urlForDocument:self]) == nil)
    return nil;
  
  if ([[url baseURL] isEqual:[dm skyrixBaseURL]])
    return [url relativeString];
  
  return [url absoluteString];
}

- (id)_jsfunc_supportsFeature:(NSArray *)_args {
  unsigned i, count;

  _ensureBools();
  
  if ((count = [_args count]) == 0)
    return yesNum;

  for (i = 0; i < count; i++) {
    NSString *feature;
    
    feature = [_args objectAtIndex:i];

    if (![self supportsFeature:feature])
      return noNum;
  }
  
  return yesNum;
}

/* attribute methods */

- (id)_jsfunc_getAttribute:(NSArray *)_args {
  unsigned count;

  if ((count = [_args count]) == 0)
    return nil;
  else if (count == 1)
    return [self valueForKey:[_args objectAtIndex:0]];
  else {
    NSString *key;
    NSString *ns;
    
    key = [_args objectAtIndex:0];
    ns  = [_args objectAtIndex:1];
    
    key = [ns isNotEmpty]
      ? (NSString *)[NSString stringWithFormat:@"{%@}%@", ns, key]
      : key;
    
    return [self valueForKey:key];
  }
}

- (id)_jsfunc_hasAttribute:(NSArray *)_args {
  _ensureBools();
  return ([self _jsfunc_getAttribute:_args] != nil)
    ? yesNum : noNum;
}

- (id)_jsfunc_setAttribute:(NSArray *)_args {
  unsigned count;
  NSString *key;
  id   value;
  BOOL result;
  
  _ensureBools();
  
  if ((count = [_args count]) < 2) {
    return noNum;
  }
  else if (count == 2) {
    key   = [_args objectAtIndex:0];
    value = [_args objectAtIndex:1];
  }
  else {
    NSString *ns;
    
    key   = [_args objectAtIndex:0];
    ns    = [_args objectAtIndex:1];
    value = [_args objectAtIndex:2];
    
    key = [ns isNotEmpty]
      ? (NSString *)[NSString stringWithFormat:@"{%@}%@", ns, key]
      : key;
  }
  
  result = YES;
  NS_DURING
    [self takeValue:value forKey:key];
  NS_HANDLER
    result = NO;
  NS_ENDHANDLER;
  
  return result ? yesNum : noNum;
}

- (id)_jsfunc_removeAttribute:(NSArray *)_args {
  unsigned count;
  NSString *key;
  BOOL result;
  _ensureBools();
  
  if ((count = [_args count]) == 0)
    return noNum;
  else if (count == 1)
    key = [_args objectAtIndex:0];
  else {
    NSString *ns;
    
    key = [_args objectAtIndex:0];
    ns  = [_args objectAtIndex:1];
    
    key = [ns isNotEmpty]
      ? (NSString *)[NSString stringWithFormat:@"{%@}%@", ns, key]
      : key;
  }

  result = YES;
  NS_DURING
    [self takeValue:nil forKey:key];
  NS_HANDLER
    result = NO;
  NS_ENDHANDLER;
  
  return result ? yesNum : noNum;
}

/* saving and deleting */

- (id)_jsfunc_remove:(NSArray *)_args {
  _ensureBools();
  return [self delete]
    ? yesNum : noNum;
}

- (id)_jsfunc_save:(NSArray *)_args {
  unsigned count;
  _ensureBools();
  
  count = [_args count];

  if (count > 0) {
#if DEBUG
    NSLog(@"%s: -save() doesn't support arguments (%@) ... ",
          __PRETTY_FUNCTION__, _args);
#endif
  }
  
  return [self save]
    ? yesNum : noNum;
}

- (id)_jsfunc_reload:(NSArray *)_args {
  unsigned count;
  _ensureBools();
  
  if ((count = [_args count]) == 0)
    return [self reload] ? yesNum : noNum;
  else
    return noNum;
}

/* content */

- (id)_jsfunc_setContent:(NSArray *)_args {
  NSString *s;
  _ensureBools();
  
  if (![self supportsFeature:SkyDocumentFeature_STRINGBLOB]) {
#if DEBUG
    NSLog(@"%s: document %@ doesn't support string-BLOB's !",
          __PRETTY_FUNCTION__, self);
#endif
    return noNum;
  }
  
  s = [[_args valueForKey:@"stringValue"] componentsJoinedByString:@""];
  [(id<SkyStringBLOBDocument>)self setContentString:(s ? s : (NSString *)@"")];
  return yesNum;
}
- (id)_jsfunc_getContent:(NSArray *)_args {
  NSString *s;
  
  if (![self supportsFeature:SkyDocumentFeature_STRINGBLOB]) {
    if (debugJS)
      [self logWithFormat:@"document does not support string blob ..."];
    return nil;
  }
  
  s = [(id<SkyStringBLOBDocument>)self contentAsString];
  return s != nil ? s : (NSString *)@"";
}

- (id)_jsfunc_setContentAsDOM:(NSArray *)_args {
  _ensureBools();
  
  if (![self supportsFeature:SkyDocumentFeature_DOMBLOB])
    return noNum;
  
  [(id<SkyDOMBLOBDocument>)self setContentDOMDocument:
                           [_args objectAtIndex:0]];
  return yesNum;
}
- (id)_jsfunc_getContentAsDOM:(NSArray *)_args {
  if (![self supportsFeature:SkyDocumentFeature_DOMBLOB])
    return nil;
  
  return [(id<SkyDOMBLOBDocument>)self contentAsDOMDocument];
}

@end /* SkyDocument */
