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

#include <OGoFoundation/LSWContentPage.h>

@class NSString, NSArray;
@class EOGlobalID;

@interface SkyProject4NewLink : LSWContentPage
{
  id         fileManager;
  EOGlobalID *folderGID;
  
  NSString   *fileName;
  NSString   *link;
  NSString   *subject;
  
  /* cache */
  NSArray    *favorites;
  id         favorite;
  
  /* transient */
  id item;
}

@end

#include <OGoFoundation/OGoClipboard.h>
#include <NGExtensions/NSString+Ext.h>
#include "common.h"

@implementation SkyProject4NewLink

static BOOL debugOn = NO;

- (void)dealloc {
  [self->item        release];
  [self->favorites   release];
  [self->favorite    release];
  [self->link        release];
  [self->fileName    release];
  [self->fileManager release];
  [self->folderGID   release];
  [self->subject     release];
  [super dealloc];
}

/* notifications */

- (void)sleep {
  [self->item release]; self->item = nil;
  [super sleep];
}

/* accessors */

- (void)setFileManager:(id)_fm {
  ASSIGN(self->fileManager, _fm);
}
- (id)fileManager {
  return self->fileManager;
}

- (void)setFolderId:(EOGlobalID *)_gid {
  ASSIGNCOPY(self->folderGID, _gid);
}
- (id)folderId {
  return self->folderGID;
}

- (void)setFileName:(NSString *)_fileName {
  ASSIGNCOPY(self->fileName, _fileName);
}
- (NSString *)fileName {
  return self->fileName;
}

- (void)setLink:(NSString *)_link {
  ASSIGNCOPY(self->link, _link);
}
- (NSString *)link {
  return self->link;
}

- (void)setSubject:(NSString *)_subject {
  ASSIGNCOPY(self->subject, _subject);
}
- (NSString *)subject {
  return self->subject;
}

- (NSString *)folderPath {
  EOGlobalID *fgid;
  
  fgid = [self folderId];
  return [[self fileManager] pathForGlobalID:fgid];
}
- (NSString *)filePath {
  EOGlobalID *fgid;
  NSString *path;
  
  fgid = [self folderId];
  path = [[self fileManager] pathForGlobalID:fgid];
  return [path stringByAppendingPathComponent:[self fileName]];
}

- (NSString *)windowTitle {
  NSString *path;
  NSString *lnk;

  lnk = [[self labels] valueForKey:@"CreateLinkAtPath"];

  lnk = (lnk != nil)
    ? lnk
    : @"create link at path ";

  path = [[self fileManager] pathForGlobalID:[self folderId]];
  path = [lnk stringByAppendingString:path];

  return path;
}

- (BOOL)showTitle {
  return [[self fileManager]
                isKindOfClass:NSClassFromString(@"SkyProjectFileManager")];
}

- (BOOL)isEditorPage {
  return YES;
}

- (NSArray *)favorites {
  NSMutableArray *t;
  NSEnumerator   *of;
  id f;
  
  if (self->favorites)
    return self->favorites;

  of = [[(OGoSession *)[self session] favorites] objectEnumerator];
  t  = [NSMutableArray arrayWithCapacity:8];
  while ((f = [of nextObject])) {
    id gid;
    
    if ([f respondsToSelector:@selector(entityName)])
      [t addObject:f];
    else if ((gid = [f valueForKey:@"globalID"]))
      [t addObject:gid];
  }
  self->favorites = [t copy];

  return self->favorites;
}

- (void)setFavorite:(id)_fav {
  ASSIGN(self->favorite, _fav);
}
- (id)favorite {
  return self->favorite;
}

- (void)setItem:(id)_item {
  ASSIGN(self->item, _item);
}
- (id)item {
  return self->item;
}

- (NSString *)itemLabel {
  NSString *olabel;
  NSString *elabel;
  NSString *tmp;
  
  elabel = [[self item] entityName];
  tmp    = [[self labels] valueForKey:elabel];
  if (tmp) elabel = tmp;
  
  olabel = [[self session] labelForObject:[self item]];
  
  if ([elabel length] > 0)
    olabel = [NSString stringWithFormat:@"%@: %@", elabel, olabel];
  
  return olabel;
}

- (NSString *)favoriteType {
  NSString *ename;
  NSString *ext;
  id fav;
  
  fav   = [self favorite];
  ename = nil;
  
  if ([fav respondsToSelector:@selector(entityName)])
    ename = [fav entityName];

  if ([ename length] == 0) {
    EOGlobalID *gid;

    if ((gid = [fav valueForKey:@"globalID"]))
      if ([gid isKindOfClass:[EOKeyGlobalID class]])
        ename = [gid entityName];
  }
  
  if ([ename length] == 0) {
#if DEBUG
    [self debugWithFormat:@"cannot determine entity of favorite: %@", fav];
#endif
    ename = nil;
  }
  
  if ([ename isEqualToString:@"Date"])
    ext = @"appointment";
  else if ([ename isEqualToString:@"Doc"])
    ext = @"document";
  else
    ext = [ename lowercaseString];
  
  return ext;
}

/* favorites */

- (BOOL)shouldUseFavoriteInsteadOfTarget:(NSString *)_target {
  if (self->favorite == nil)
    return NO;
  if ([_target length] > 0) // we prefer a typed target
    return NO;
  
  return YES;
}

- (EOKeyGlobalID *)getKeyGlobalIDOfFavorite:(id)_object {
  EOKeyGlobalID *gid;

  gid = ([_object isKindOfClass:[EOKeyGlobalID class]])
    ? _object
    : [_object valueForKey:@"globalID"];
  
  if (![gid isKindOfClass:[EOKeyGlobalID class]])
    return nil;
  if ([gid keyCount] != 1)
    return nil;
  return gid;
}

- (NSString *)getTargetOfKeyGlobalID:(EOKeyGlobalID *)_gid {
  NSString *s;
  
  if (_gid == nil)
    return nil;
  
  s = [[_gid keyValues][0] stringValue];
  if ([s length] == 0) 
    return nil;
  
  return s;
}

/* actions */

- (id)save {
  id       fm;
  NSString *fname;
  NSString *folderPath;
  NSString *target;
  
  fname = [self fileName];
  if ([fname length] == 0) {
    [self setErrorString:@"missing filename for link!"];
    return nil;
  }
  fm     = [self fileManager];
  target = [self link];
  
  if ([self shouldUseFavoriteInsteadOfTarget:target]) {
    EOKeyGlobalID *gid;
    
    if ((gid = [self getKeyGlobalIDOfFavorite:self->favorite]) == nil) {
      [self setErrorString:
	      @"could not determine usable object id of favorite-object!"];
      return nil;
    }
    
    if ((target = [self getTargetOfKeyGlobalID:gid]) == nil) {
      [self setErrorString:@"cannot link the specified favorite!"];
      return nil;
    }
    if (debugOn) {
      [self debugWithFormat:@"link to favorite: %@ to %@",
	      self->favorite, target];
    }
    
    if ([[fname pathExtension] length] == 0) {
      NSString *ttype;
      
      ttype = [self favoriteType];
      if ([ttype length] >= 0)
	fname = [fname stringByAppendingPathExtension:ttype];
    }
    else if (debugOn) {
      [self debugWithFormat:@"using path extension: %@", 
	      [fname pathExtension]];
    }
  }
  else if ([target length] == 0) {
    [self setErrorString:@"specify a link target!"];
    return nil;
  }
  else if ([target isAbsoluteURL]) {
    // do not try to check existence of URLs
  }
  else if ([fm fileExistsAtPath:target]) {
    /* make absolute fn */
    target = [[fm fileAttributesAtPath:target traverseLink:NO]
	          objectForKey:NSFilePath];
  }
  
  /* create new file */
  
  // Note: this is only required in database projects if you try to set
  //       a title
  // TODO: should be replaced with a feature check:
  //         [fm requiresPathExtensionAtPath:xx];
  if ([fm isKindOfClass:NSClassFromString(@"SkyProjectFileManager")]) {
    if ([[fname pathExtension] length] == 0)
      fname = [fname stringByAppendingPathExtension:@"link"];
  }
  
  folderPath = [fm pathForGlobalID:[self folderId]];
  fname      = [folderPath stringByAppendingPathComponent:fname];
  
  if ([fm fileExistsAtPath:fname]) {
    [self setErrorString:@"a file already exists at the specified path !"];
    return nil;
  }

  if (![fm createSymbolicLinkAtPath:fname pathContent:target]) {
    NSString *fmt;
    
    fmt = [NSString stringWithFormat:@"could not create link to '%@' at '%@'.",
                      target, fname];
    
    [self setErrorString:fmt];
    return nil;
  }
  
  if ([self->subject length] > 0) {
    NSDictionary *attrs;
    
    attrs = [NSDictionary dictionaryWithObjectsAndKeys:
			    self->subject, @"NSFileSubject", nil];
    
    if (![fm changeFileAttributes:attrs atPath:fname]) {
      NSString *fmt;
      
      fmt = [NSString stringWithFormat:
			@"could not set title for '%@'.", fname];
      [self setErrorString:fmt];
      return nil;
    }
  }
  
  return [[(OGoSession *)[self session] navigation] leavePage];
}

- (id)cancel {
  return [[(OGoSession *)[self session] navigation] leavePage];
}

@end /* SkyProject4NewLink */
