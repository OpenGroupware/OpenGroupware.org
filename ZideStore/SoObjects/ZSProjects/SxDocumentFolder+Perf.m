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

#include "SxDocumentFolder.h"
#include <ZSFrontend/SxMapEnumerator.h>
#include "common.h"

/* 
   The methods contained in here, are actually only required to increase
   performance by doing proper bulk fetches by using the user-agent and
   query detection in SxFolder.
   
   UPDATE: not only for performance, but also avoids a bug in IE WebFolders
           (sending the propinfo of the folder itself results in an IE
           recursion)
   UPDATE: apparently Nautilus requires that folder!
*/

@interface _SxDocPairEnumerator : NSEnumerator
{
@public
  /* TODO: clean up this ugly hack ... */
  id           obj;
  NSEnumerator *e;
}
@end

@implementation SxDocumentFolder(Perf)

/*
  Hehe: the actual gain of the stuff below is minimal, well, almost 
        non-existant! Why? Because the SkyProjectFileManager already does
	a whole lot of internal caching, eg it has all the file metadata
	as soon as a file existence check is performed!
*/

- (id)renderListEntry:(id)_entry {
  /*
    Attrs: davContentLength, davLastModified, davDisplayName,
           davIsExecutable, davResourceType
  */
  NSString *keys[16];
  id       values[16];
  unsigned count;
  id       tmp;
  
  //[self debugWithFormat:@"render: %@", _entry];
  count = 0;

  /* 
     Note: we need to add the special "{DAV:}href" attribute since the 
           dictionary we return has no idea about the object it represents ;-)
  */
  tmp = [[_entry valueForKey:@"NSFileName"] stringByEscapingURL];
  tmp = [[self baseURL] stringByAppendingString:tmp];
  keys[count]   = @"{DAV:}href";
  values[count] = tmp;
  if (tmp) count++;
  
  if ((tmp = [_entry valueForKey:NSFileSize])) {
    keys[count]   = @"davContentLength";
    values[count] = tmp;
    count++;
  }
  if ((tmp = [_entry valueForKey:NSFileModificationDate])) {
    keys[count]   = @"davLastModified";
    values[count] = tmp;
    count++;
  }
  if ([(tmp = [_entry valueForKey:@"SkyCreationDate"]) isNotNull]) {
    keys[count]   = @"davCreationDate";
    values[count] = tmp;
    count++;
  }
  else {
    keys[count]   = @"davCreationDate";
    //values[count] = @"Tue, 21 Sep 1976 12:00:00 GMT";
    values[count] = @"1976-09-21T12:00:00Z";
    count++;
  }
  if ((tmp = [_entry valueForKey:@"NSFileSubject"])) {
    keys[count]   = @"davDisplayName";
    values[count] = tmp;
    count++;
  }
  
  if ([[_entry valueForKey:NSFileType] isEqual:NSFileTypeDirectory]) {
    keys[count]   = @"davResourceType";
    values[count] = @"collection";
    count++;
    keys[count]   = @"davIsFolder";
    values[count] = @"1";
    count++;
    keys[count]   = @"davContentType";
    values[count] = @"httpd/unix-directory";
    count++;
  }
  else {
    keys[count]   = @"davResourceType";
    values[count] = @""; // we might render nil/not-set as propstat 404
    count++;
    
    keys[count]   = @"davContentType";
    if ((tmp = [_entry valueForKey:@"NSFileMimeType"]))
      values[count] = [tmp stringValue];
    else
      values[count] = nil;
    // TODO: check extensions of LSFoundation in addition?
    if (values[count] == nil)
      values[count] = @"application/octet-stream";
    count++;
  }
  
  keys[count]   = @"davIsExecutable";
  values[count] = @"0";
  count++;
  
  return [[[NSDictionary alloc] 
	    initWithObjects:values forKeys:keys count:count]
	    autorelease];
}

- (id)performListQuery:(EOFetchSpecification *)_fs inContext:(id)_ctx {
  EODataSource *ds;
  NSEnumerator *e;
  NSString *uaType;
  
  if ((ds = [self folderDataSourceInContext:_ctx]) == nil) {
    [self logWithFormat:
            @"WARNING: got no datasource for folder (path '%@', name '%@')",
            [self storagePath], [self nameInContainer]];
    return [NSException exceptionWithHTTPStatus:404 /* Not Found */
                        reason:@"got no datasource for folder ..."];
  }
  
  if ([self isDebuggingEnabled]) {
    [self debugWithFormat:@"perform list query: %@ using %@ ...", _fs, ds];
    [self debugWithFormat:@"  attrs: %@", [_fs selectedWebDAVPropertyNames]];
    [self debugWithFormat:@"  datasource: %@", ds];
  }
  
  if ((e = [ds fetchEnumerator]) == nil)
    return [self internalError:@"got no fetch enumerator!"];
  
  e = [SxMapEnumerator enumeratorWithSource:e
                       object:self selector:@selector(renderListEntry:)];

  /* now we need to hack the result to include 'self' :-( */
  uaType = [[[(WOContext *)_ctx request] clientCapabilities] userAgentType];
  
  if ([uaType isEqualToString:@"GNOME-VFS"] || 
      [uaType isEqualToString:@"Konqueror"]) {
    /* TODO: clean up this ugly hack ... */
    _SxDocPairEnumerator *pe;
    
    pe = [[[_SxDocPairEnumerator alloc] init] autorelease];
    pe->obj = [[[self davQueryOnSelf:_fs inContext:_ctx] lastObject] retain];
    pe->e   = [e retain];
    return pe;
  }
  else
    return e;
}

@end /* SxDocumentFolder(Perf) */

@implementation _SxDocPairEnumerator

- (void)dealloc {
  [self->obj release];
  [self->e   release];
  [super dealloc];
}

- (id)nextObject {
  if (self->obj) {
    id tmp = self->obj;
    self->obj = nil;
    return [tmp autorelease];
  }
  if (self->e) {
    id tmp = [self->e nextObject];
    if (tmp == nil) {
      [self->e release];
      self->e = nil;
    }
    return tmp;
  }
  return nil;
}

@end /* _SxDocPairEnumerator */
