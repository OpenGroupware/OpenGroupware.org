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

#include "LSGetAttachmentNameCommand.h"

@interface LSGetAttachmentNameCommand(Private)
- (NSString *)_primaryKeyNameForObj:(id)_obj inContext:(id)_ctx;
- (NSString *)_entityNameFor:(id)_obj;
- (NSString *)_nameOfAttachmentForObj:(id)_obj inContext:(id)_ctx;
- (NSString *)_newAttachmentNameForObj:(id)_obj inContext:(id)_ctx;
- (NSString *)_attachmentNameForObj:(id)_obj context:(id)_ctx;
- (NSString *)_idRangeAttachmentNameForObj:(id)_obj withFile:(NSString *)_s
  inContext:(id)_ctx;
@end

#include "common.h"

@implementation LSGetAttachmentNameCommand

static NSFileManager *fm = nil;
static BOOL UseFlatDocumentFileStructure = NO;
static BOOL UseFoldersForIDRanges        = NO;

+ (void)initialize {
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  
  UseFlatDocumentFileStructure = 
    [ud boolForKey:@"UseFlatDocumentFileStructure"];
  UseFoldersForIDRanges = [ud boolForKey:@"UseFoldersForIDRanges"];

  if (fm == nil) fm = [[NSFileManager defaultManager] retain];
}

- (void)dealloc {
  [self->projectId release];
  [super dealloc];
}

/* operations */

- (NSString *)_primaryKeyNameForObj:(id)_obj inContext:(id)_ctx {
  EOEntity *entity;
  NSArray  *pkeys;

  if ([_obj isKindOfClass:[EOGenericRecord class]])
    entity = [_obj entity];
  else {
    entity = [[[[_ctx valueForKey:LSDatabaseKey] adaptor] model]
                      entityNamed:[[_obj valueForKey:@"globalID"] entityName]];
  }
  pkeys = [entity primaryKeyAttributeNames];
  if ([pkeys count] != 1) {
    [self errorWithFormat:
	    @"[%s]: can only handle entities with one primary key "
            @"(entity=%@, keys=%@, obj=%@)",__PRETTY_FUNCTION__,
            entity, pkeys, _obj];
    return nil;
  }
  return [pkeys objectAtIndex:0];
}

- (NSString *)_entityNameFor:(id)_obj {
  return [_obj isKindOfClass:[EOGenericRecord class]]
    ? [_obj entityName]
    : [[_obj valueForKey:@"globalID"] entityName];
}

- (NSString *)_nameOfAttachmentForObj:(id)_obj inContext:(id)_ctx {
  NSUserDefaults *defaults;
  NSString       *path, *fileName ;

  defaults = [_ctx userDefaults];
  path     = [defaults stringForKey:@"LSAttachmentPath"];
  fileName = [self _attachmentNameForObj:_obj context:_ctx];
  
  return [path stringByAppendingPathComponent:fileName];
}

- (NSNumber *)_getProjectIdForDocId:(NSNumber *)_docId inContext:(id)_ctx {
  id doc;
  
  if (![_docId isNotNull]) return nil;
  doc = LSRunCommandV(_ctx, @"doc", @"get",
		      @"documentId", _docId,
		      @"loadPath", [NSNumber numberWithBool:NO], nil);
  if ([doc isKindOfClass:[NSArray class]])
    doc = [doc lastObject];
  
  return [doc valueForKey:@"projectId"];
}

- (NSString *)_newAttachmentNameForObj:(id)_obj inContext:(id)_ctx {
  // TODO: clean up method
  NSUserDefaults *defaults;
  NSString       *path, *fileName;
  NSNumber       *pid;
  BOOL           isDir;

  isDir      = NO;
  defaults   = [_ctx userDefaults];
  path       = [defaults stringForKey:@"LSAttachmentPath"];
  fileName   = [self _attachmentNameForObj:_obj context:_ctx];

  pid = [self->projectId isNotNull] 
    ? self->projectId
    : (NSNumber *)[_obj valueForKey:@"projectId"];
  
  if (![pid isNotNull]) {
    pid = [[_obj valueForKey:@"toDocument"] valueForKey:@"projectId"];
    
    if (![pid isNotNull]) {
      pid = [self _getProjectIdForDocId:[_obj valueForKey:@"documentId"]
		  inContext:_ctx];
    }
  }
  
  if (![pid isNotNull]) {
    [self errorWithFormat:@"[%s]: missing project id for doc %@",
          __PRETTY_FUNCTION__, _obj];
    return nil;
  }
  
  path = [path stringByAppendingPathComponent:[pid stringValue]];
  if (![fm fileExistsAtPath:path isDirectory:&isDir]) {
    id proj;
    NSString *s;
    
    proj = LSRunCommandV(_ctx, @"project", @"get", @"projectId", pid, nil);
    
    if (![fm createDirectoryAtPath:path attributes:nil]) {
      [self errorWithFormat:
	      @"[%s]: could not createDirectoryAtPath '%@' "
	      @"for obj %@ proj %@",
              __PRETTY_FUNCTION__, path, _obj, proj];
      return nil;
    }

    // TODO: explain this, write the description of the project EO to the
    //       index file?!
    s = [proj description];
    if (![s writeToFile:[path stringByAppendingPathComponent:@"index.txt"]
	    atomically:YES]) {
      [self warnWithFormat:
	      @"[%s]: could not write index file at path '%@' with "
	      @"contents %@",
              __PRETTY_FUNCTION__,
              [path stringByAppendingPathComponent:@"index.txt"], proj];
    }
    isDir = YES;
  }
  if (!isDir) {
    [self errorWithFormat:@"[%s]: path '%@' for doc %@ is no dir",
            __PRETTY_FUNCTION__, path, _obj];
    return nil;
  }
  return [path stringByAppendingPathComponent:fileName];
}

- (NSString *)_idRangeAttachmentNameForObj:(id)_obj withFile:(NSString *)_file
  inContext:(id)_ctx
{
  NSString *fileName, *path;
  NSString *folder   = nil;
  int      docId;
  BOOL     isDir;
  NSString *entityName;
    
  fileName   = _file;
  path       = [fileName stringByDeletingLastPathComponent];
  fileName   = [fileName lastPathComponent];
  entityName = [self _entityNameFor:_obj];
  
  if ([entityName isEqualToString:@"DocumentEditing"])
    docId = [[_obj valueForKey:@"documentEditingId"] intValue];
  else { 
    NSString *pKey;
    
    pKey  = [self _primaryKeyNameForObj:_obj inContext:_ctx];
    docId = [[_obj valueForKey:pKey] intValue];
  }
  folder = [[NSNumber numberWithInt:(1000 * (docId/1000))] stringValue];
  path   = [path stringByAppendingPathComponent:folder];
  
  if (![fm fileExistsAtPath:path isDirectory:&isDir]) {
    if (![fm createDirectoryAtPath:path attributes:nil]) {
      [self errorWithFormat:
	      @"[%s]: could not createDirectoryAtPath %@ for obj %@",
	      __PRETTY_FUNCTION__, path, _obj];
      return nil;
    }
    isDir = YES;
  }
  if (!isDir) {
    [self errorWithFormat:@"[%s]: path %@ for doc %@ is no dir",
          __PRETTY_FUNCTION__, path, _obj];
    return nil;
  }
  return [path stringByAppendingPathComponent:fileName];
}

- (NSString *)_attachmentNameForObj:(id)_obj context:(id)_ctx {
  NSString *fileName, *entityName, *fileExt;

  entityName = [self _entityNameFor:_obj];
  fileExt    = [_obj valueForKey:@"fileType"];
  
  if ([entityName isEqualToString:@"DocumentEditing"]) {
    fileName = [[_obj valueForKey:@"documentEditingId"] stringValue];
  }
  else { 
    fileName = [self _primaryKeyNameForObj:_obj inContext:_ctx];
    fileName = [[_obj valueForKey:fileName] stringValue];
  }
  if (![fileExt isNotNull])
    return fileName;
  
  return [[fileName stringByAppendingString:@"."] 
	            stringByAppendingString:fileExt];
}

                                                      
- (void)_validateKeysForContext:(id)_context {
  [LSDBObjectCommandException raiseOnFail:([self object] ? YES:NO) object:self
                              reason:@"no objects(s) set!"];
}

- (void)_fillAttachmentNameOfObject:(id)obj inContext:(id)_context {
  NSString *str;
    
  if ([[obj valueForKey:@"attachmentName"] isNotNull])
    /* already has a cached name */
    return;
    
  str = [self _nameOfAttachmentForObj:obj inContext:_context];
  
  if (!UseFlatDocumentFileStructure) {
    if (![fm fileExistsAtPath:str isDirectory:NULL]) {
      /* file does not exist, use new system */
      str = [self _newAttachmentNameForObj:obj inContext:_context];
      if (UseFoldersForIDRanges) {
	if (![fm fileExistsAtPath:str isDirectory:NULL]) {
	  str = [self _idRangeAttachmentNameForObj:obj withFile:str
		      inContext:_context];
	}
      }
    }
  }
  if (str == nil) {
    [self errorWithFormat:@"[%s]: missing attachment name for %@",
            __PRETTY_FUNCTION__, obj];
    return;
  }
  
  [obj takeValue:str forKey:@"attachmentName"];
}

- (void)_executeInContext:(id)_context {
  NSEnumerator *enumerator;
  id obj;
  
  enumerator = [[self object] objectEnumerator];
  while ((obj = [enumerator nextObject]))
    [self _fillAttachmentNameOfObject:obj inContext:_context];
}

- (NSNumber *)projectId {
  return self->projectId;
}
- (void)setProjectId:(NSNumber *)_pid {
  ASSIGN(self->projectId, _pid);
}

/* key/value coding */

- (BOOL)isObjectKey:(NSString *)_key {
  unsigned klen;
  
  klen = [_key length];
  if (klen ==  8 && [_key isEqualToString:@"document"])        return YES;
  if (klen ==  4 && [_key isEqualToString:@"note"])            return YES;
  if (klen ==  6 && [_key isEqualToString:@"object"])          return YES;
  if (klen == 15 && [_key isEqualToString:@"documentEditing"]) return YES;
  if (klen == 15 && [_key isEqualToString:@"documentVersion"]) return YES;
  return NO;
}
- (BOOL)isObjectArrayKey:(NSString *)_key {
  if ([_key isEqualToString:@"documents"])        return YES;
  if ([_key isEqualToString:@"notes"])            return YES;
  if ([_key isEqualToString:@"objects"])          return YES;
  if ([_key isEqualToString:@"documentEditings"]) return YES;
  if ([_key isEqualToString:@"documentVersions"]) return YES;
  return NO;
}

/* key/value coding */

- (void)takeValue:(id)_value forKey:(NSString *)_key {
  if ([_key isEqualToString:@"projectId"]) {
    [self setProjectId:_value];
    return;
  }
  if ([self isObjectKey:_key]) {
    [self setObject:[NSArray arrayWithObject:_value]];
    return;
  }
  if ([self isObjectArrayKey:_key]) {
    if ([_value isKindOfClass:[NSArray class]])
      [self setObject:_value];
    else
      [self setObject:_value ? [NSArray arrayWithObject:_value] : nil];
    return;
  }
  [super takeValue:_value forKey:_key];
}

- (id)valueForKey:(NSString *)_key {
  if ([_key isEqualToString:@"projectId"])
    return [self projectId];
  
  if ([self isObjectKey:_key])
    return [[self object] lastObject];

  if ([self isObjectArrayKey:_key])
    return [self object];
  
  return [super valueForKey:_key];
}

@end /* LSGetAttachmentNameCommand */
