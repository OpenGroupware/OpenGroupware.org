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

#include <OGoPalm/SkyPalmMemoDocument.h>
#include <OGoDocuments/SkyDocument.h>
#include <OGoDocuments/SkyDocumentFileManager.h>
#include <EOControl/EOKeyGlobalID.h>
#include <OGoPalm/SkyPalmConstants.h>
#include <OGoPalm/NGMD5Generator.h>
#include <NGExtensions/NGFileFolderInfoDataSource.h>

#include <LSFoundation/SkyObjectPropertyManager.h>

@interface NSObject(SkyPalmMemoNotifyProjectFileManager)

- (void)setContentString:(NSString *)_s;
- (NSString *)contentAsString;
- (BOOL)isWriteable;

- (id)initWithContext:(id)_ctx projectGlobalID:(EOGlobalID *)_gid;
- (EOGlobalID *)projectGlobalIDForDocumentGlobalID:(EOGlobalID *)_docGid
  context:(id)_ctx;
- (NSString *)unvalidateNotifyNameForPath:(NSString *)_path;

- (id)initWithGlobalID:(EOGlobalID *)_gid fileManager:(id)_fm;

- (id)fileManager;

@end

@implementation SkyPalmMemoDocument

- (void)dealloc {
  RELEASE(self->memo);
  [super dealloc];
}

/* accessors */

- (void)setMemo:(NSString *)_memo {
  if (![self->memo isEqualToString:_memo]) {
    ASSIGN(self->memo,_memo);
    //    [self resetVersion];
  }
}
- (NSString *)memo {
  return self->memo;
}

// description

- (NSString *)description {
  NSString *info = [NSString stringWithString:self->memo];
  int idx = 0;

  if (info == nil)
    return @"no_title";

  if ((idx = [info indexOfString:@"\n"]) != NSNotFound)
    info =  [info substringToIndex:idx];
  if ([info length] > 30)
    return [NSString stringWithFormat:@"%@..", [info substringToIndex:20]];
  return info;
}

/* overwriting */
- (NSMutableString *)_md5Source {
  NSMutableString *src = [NSMutableString stringWithCapacity:32];

  [src appendString:[self memo]];
  [src appendString:[super _md5Source]];
  return src;
}

- (void)takeValuesFromDictionary:(NSDictionary *)_dict {
  [self setMemo:[_dict valueForKey:@"memo"]];

  [super takeValuesFromDictionary:_dict];
}

- (NSMutableDictionary *)asDictionary {
  NSMutableDictionary *dict = [super asDictionary];

  if ((self->memo == nil) || ([self->memo length] == 0))
    [self setMemo:@"<empty memo>"];
  [self _takeValue:self->memo forKey:@"memo" toDict:dict];

  return dict;
}

- (void)takeValuesFromDocument:(SkyPalmDocument *)_doc {
  [self setMemo:[(SkyPalmMemoDocument *)_doc memo]];

  [super takeValuesFromDocument:_doc];
}

- (NSString *)insertNotificationName {
  return SkyNewPalmMemoNotification;
}
- (NSString *)updateNotificationName {
  return SkyUpdatedPalmMemoNotification;
}
- (NSString *)deleteNotificationName {
  return SkyDeletedPalmMemoNotification;
}

/*
- (BOOL)hasSkyrixRecord {
  if ([super hasSkyrixRecord]) {
    NSLog(@"%s %@", __PRETTY_FUNCTION__, [self skyrixRecord]);
    if (![[self skyrixRecord] isValid]) {
      [self setSkyrixId:0];
      [self setSyncType:SYNC_TYPE_DO_NOTHING];
      [self saveWithoutReset];
      return NO;
    }
    return YES;
  }
  return NO;
}
*/

- (void)takeValuesFromSkyrixRecord:(id)_skyrixRecord {
  // of type SkyProjectDocument
  NSString *m;
  
  m = [_skyrixRecord contentAsString];
  
  [self setMemo:(m == nil) ? (NSString *)@"<empty memo>" : m];
}
- (void)putValuesToSkyrixRecord:(id)_skyrixRecord {
  if ([_skyrixRecord isWriteable])
    [_skyrixRecord setContentString:[self memo]];
}

- (Class)projectFileManagerClass {
  static Class fmClass = Nil;
  if (fmClass == Nil) fmClass = NSClassFromString(@"SkyProjectFileManager");
  return fmClass;
}
- (Class)projectDocumentClass {
  static Class docClass = Nil;
  if (docClass == Nil) docClass = NSClassFromString(@"SkyProjectDocument");
  return docClass;
}

- (EOGlobalID *)_dbGlobalIdForId:(id)_docId {
  return [EOKeyGlobalID globalIDWithEntityName:@"Doc"
                        keys:&_docId keyCount:1 zone:nil];
}
- (id)_fileManagerForDocGID:(id)_docGid {
  id fm   = nil;
  id pGID = nil;
  
  pGID = [[self projectFileManagerClass] 
	   projectGlobalIDForDocumentGlobalID:_docGid
	   context:[self context]];
  
  fm = [[self projectFileManagerClass] alloc];
  fm = [fm initWithContext:[self context] projectGlobalID:pGID];
  return AUTORELEASE(fm);
}

- (void)_observeSkyrixRecord:(id)_skyrixRecord {
  NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
  NSString *name = nil;
  // this is only supported by db filemanagers
  name = [[_skyrixRecord fileManager]
                         unvalidateNotifyNameForPath:
                         [_skyrixRecord valueForKey:NSFilePath]];
  [nc addObserver:self
      selector:@selector(skyrixRecordChanged)
      name:name
      object:nil];
  self->isObserving = YES;
}

/* only db projects are supported so far */
- (id)_documentForId:(id)_docId {
  id       docGID = nil;
  id       d      = nil;
  id       fm     = nil;

  docGID = [self _dbGlobalIdForId:_docId];
  
  if ((fm = [self _fileManagerForDocGID:docGID]) == nil)
    // --> unable to load file
    // --> maybe already deleted
    return nil;
  
  d = [fm documentAtPath:[fm pathForGlobalID:docGID]];
  
  return d;
}
- (id)fetchSkyrixRecord {
  return [self _documentForId:[self skyrixId]];
}

- (NSNumber *)skyrixRecordVersion {
  return [[self skyrixRecord] valueForKey:@"versionCount"];
}
- (int)skyrixSyncState {
  int result = [super skyrixSyncState];

  if (result != SYNC_STATE_NOTHING_CHANGED)
    return result;
  if (![self hasSkyrixRecord])
    return result;
  else {
    NSData   *skyBlob  =
      [[[self skyrixRecord] contentAsString]
              dataUsingEncoding:NSUTF8StringEncoding];
    NSData   *palmBlob = [[self memo] dataUsingEncoding:NSUTF8StringEncoding];
    NSString *skyHash  = nil;
    NSString *palmHash = nil;
    NGMD5Generator *gen = nil;

    gen = [[NGMD5Generator alloc] init];
    [gen encodeData:skyBlob];
    skyHash  = [gen digestAsString];
    RELEASE(gen);

    gen = [[NGMD5Generator alloc] init];
    [gen encodeData:palmBlob];
    palmHash = [gen digestAsString];
    RELEASE(gen);

    if (![skyHash isEqualToString:palmHash])
      result = SYNC_STATE_SKYRIX_CHANGED;
  }
  return result;
}

- (void)saveSkyrixRecord {
  // is class SkyProjectDocument (so far)
  [(SkyDocument *)[self skyrixRecord] save];
  [(SkyDocument *)[self skyrixRecord] reload];
}

@end /* SkyPalmMemoDocument(AssignmentToSkyAppointmentDocument) */

@implementation SkyPalmMemoDocumentSelection

- (Class)mustBeClass {
  return [SkyPalmMemoDocument class];
}

@end /* SkyPalmMemoDocumentSelection */
