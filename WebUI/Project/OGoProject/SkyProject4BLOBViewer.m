/*
  Copyright (C) 2000-2004 SKYRIX Software AG

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

#include <OGoFoundation/OGoComponent.h>

/*
  SkyProject4BLOBViewer
  
  This components handles the lookup and instantiation of content viewers
  for certain document types. Note that it does not show the content itself.
  Look into the README file for a small explanation of how the embedded viewers
  are located.
*/

@class NSString;
@class EOGlobalID;

@interface SkyProject4BLOBViewer : OGoComponent
{
  id         fileManager;
  EOGlobalID *documentId;
  NSString   *mimeType;
  id         viewer;
  id         document;
}

@end

#include "SkyP4DocumentRequestHandler.h"
#include "NSData+SkyTextEditable.h"
#include <NGMime/NGMimeType.h>
#include "common.h"

@implementation SkyProject4BLOBViewer

static NGMimeType *textPlainType    = nil;
static BOOL       debugViewerLookup = NO;

+ (void)initialize {
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  
  if (textPlainType == nil)
    textPlainType = [[NGMimeType mimeType:@"text/plain"] retain];

  debugViewerLookup = [ud boolForKey:@"OGoDebugBLOBViewerLookup"];
}

- (void)dealloc {
  [self->viewer      release];
  [self->mimeType    release];
  [self->fileManager release];
  [self->documentId  release];
  [self->document    release];
  [super dealloc];
}

/* sleep */

- (void)sleep {
  [super sleep];
  [self->viewer release]; self->viewer = nil;
}

/* accessors */

- (void)setFileManager:(id)_fm {
  ASSIGN(self->fileManager, _fm);
}
- (id)fileManager {
  return self->fileManager;
}

- (void)setDocumentId:(EOGlobalID *)_gid {
  ASSIGNCOPY(self->documentId, _gid);
}
- (id)documentId {
  return self->documentId;
}

- (void)setMimeType:(NSString *)_type {
  ASSIGNCOPY(self->mimeType, _type);
}
- (NSString *)mimeType {
  return self->mimeType;
}

- (void)setDocument:(id)_doc {
  ASSIGN(self->document, _doc);
}
- (id)document {
  return self->document;
}

- (NSString *)documentPath {
  if (([self document]))
    return [[self document] path];

  if (([self documentId]))
    return [[self fileManager] pathForGlobalID:[self documentId]];

  return nil;
}

- (NSData *)content {
  NSString *path;
  
  if ((path = [self documentPath]) == nil) {
    [self debugWithFormat:@"missing document path .."];
    return nil;
  }

  return [[self fileManager] contentsAtPath:path];
}

/* defaults */

- (BOOL)isPluginViewerEnabled {
  // TODO: explain this section, what does 'isPluginViewerEnabled'?
  return [[[self session] userDefaults] boolForKey:@"LSPluginViewerEnabled"];
}

/* operation */

- (void)_setPathAndFileManagerInViewer:(id)_viewer {
  NSString   *path;
  EOGlobalID *pnum;
  id         uri;
  
  if (_viewer == nil)
    return;
  if ((path = [self documentPath]) == nil)
    /* no path available? */
    return;
  
  [_viewer takeValue:path               forKey:@"filename"];
  [_viewer takeValue:[self fileManager] forKey:@"fileManager"];
  
  pnum = [[[self fileManager]
                 fileSystemAttributesAtPath:path]
                 objectForKey:@"NSFileSystemNumber"];
  uri = [[self context] p4documentURLForProjectWithGlobalID:pnum
			path:path
			versionTag:nil];
  if (uri) [_viewer takeValue:uri forKey:@"uri"];
}

- (id)_makeDocViewerForType:(NGMimeType *)_type content:(NSData *)_data {
  /* TODO: split up method */
  WOComponent *v;
  OGoSession  *sn;

  sn = [self session];

  if (debugViewerLookup) {
    [self logWithFormat:@"lookup viewer for type %@ data 0x%08X(%d)",
	    _type, _data, [_data length]];
  }
  
  v = [sn instantiateComponentForCommand:@"docview-inline"
	  type:_type
	  object:_data];
  if (v != nil) {
    if (debugViewerLookup) {
      [self logWithFormat:@"  found 'docview-inline' for type %@: %@", 
	      _type, v];
    }
    [self _setPathAndFileManagerInViewer:v];
    return v;
  }
  
  v = [sn instantiateComponentForCommand:@"mailview" type:_type object:_data];
  if (v != nil) {
    if (debugViewerLookup)
      [self logWithFormat:@"  found 'mailview' for type %@: %@", _type, v];
    return v;
  }
  
  if (debugViewerLookup)
    [self logWithFormat:@"found no viewer for type %@.", _type];
  return nil;
}

- (void)resetViewerComponent {
  [self->viewer release];
  self->viewer = nil;
}

- (id)viewerComponent {
  NGMimeType *mtype;
  BOOL doShow;
  
  // TODO: explain this section, what does 'isPluginViewerEnabled'?
  if ((doShow = [self isPluginViewerEnabled])) {
    if (self->viewer) {
      if ([self->viewer respondsToSelector:@selector(object)]) {
        if ([[self->viewer object] isEqual:[self content]])
          return self->viewer;
      }

      /* Note: here is a case where the self->viewer is preserved! */
    }
    else
      [self resetViewerComponent];
  }
  else
    [self resetViewerComponent];
  
  mtype = [NGMimeType mimeType:[self mimeType]];
  if (debugViewerLookup) {
    [self logWithFormat:@"asked for viewer component (doShow=%s): %@", 
	  doShow ? "yes" : "no", mtype];
  }
  
  /* lookup document viewer */

  if (doShow) {
    [self resetViewerComponent];
    
    self->viewer = 
      [[self _makeDocViewerForType:mtype content:[self content]] retain];
    if (self->viewer) {
      [self debugWithFormat:@"use viewer: %@", self->viewer];
      return self->viewer;
    }
  }
  
  /* found no proper inline viewer, check for plaintext types */
  
  if (self->viewer == nil) {
    NSData *data;
    
    if ((data = [self content]) == nil)
      [self debugWithFormat:@"missing content .."];
    
    if ([data isSkyTextEditable]) {
      mtype = textPlainType;
      
      self->viewer = [[self _makeDocViewerForType:mtype content:data] retain];
      if (self->viewer) {
        [self debugWithFormat:@"use plain/text viewer: %@", self->viewer];
        return self->viewer;
      }
    }
    else {
      [self debugWithFormat:@"data is not text/plain .."];
    }
  }
  
  if (self->viewer == nil)
    [self debugWithFormat:@"did not find viewer for type %@", mtype];
  
  return self->viewer;
}

@end /* SkyProject4BLOBViewer */
