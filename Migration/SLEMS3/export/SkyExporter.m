// $Id$
#include "common.h"
#include "SkyExporter.h"

@implementation SkyExporter

- (id)init {
  if ((self = [super init])) {
    self->fm = [[NSFileManager defaultManager] retain]; 
  }
  return self;
}

- (void)dealloc {
  RELEASE(self->fm);
  RELEASE(self->path);
  RELEASE(self->entries);
  [super dealloc];
}

- (NSDictionary *)attributeMapping {
  return [self subclassResponsibility:_cmd];
}

- (NSMutableDictionary *)checkDict:(NSDictionary *)_dict {
  NSMutableDictionary *mdict;
  NSEnumerator        *keyEnum;
  NSMutableArray      *array;
  NSString            *key;
  NSDictionary        *mapping;

  array = [NSMutableArray arrayWithCapacity:[_dict count]];

  keyEnum = [_dict keyEnumerator];

  while ((key = [keyEnum nextObject])) {
    if ([[_dict objectForKey:key] isNotNull])
      [array addObject:key];
  }
  keyEnum = [array objectEnumerator];

  mdict   = [NSMutableDictionary dictionaryWithCapacity:[_dict count]];
  mapping = [self attributeMapping];
  
  while ((key = [keyEnum nextObject])) {
    NSString *k;
    if ((k = [mapping objectForKey:key])) {
      [mdict setObject:[_dict objectForKey:key] forKey:k];
    }
  }
  return mdict;
}

- (BOOL)write:(NSDictionary *)_dict toFile:(NSString *)_file {
  return [[self checkDict:_dict] writeToFile:_file atomically:YES];
}

- (BOOL)writeEntry:(NSDictionary *)_entry {
  id primKey;

  primKey = [self primaryKeyForEntry:_entry];

  if (writeSingleEntry) {
    return [self write:_entry toFile:
                 [[self->path stringByAppendingPathComponent:primKey]
                              stringByAppendingPathExtension:@"plist"]];
  }
  else {
    if (self->entries == nil) {
      self->entries = [[NSMutableDictionary alloc] initWithCapacity:128];
    }
    [self->entries setObject:[self checkDict:_entry] forKey:primKey];

    if ([self->entries count] > [self cacheSize]) {
      [self flush];
    }
  }
  return YES;
}

- (int)cacheSize {
  return 10;
}

- (NSString *)exportPath {
  return self->path;
}

- (void)flush {
  if (!self->writeSingleEntry) {
    NSDictionary *dict;
    NSString     *p;

    if (![self->entries count])
      return;
    
    p =  [self exportPath];

    if ([self->fm fileExistsAtPath:p]) {
      dict = [NSDictionary dictionaryWithContentsOfFile:p];
      [self->entries addEntriesFromDictionary:dict];
    }
    [self->entries writeToFile:p atomically:YES];
    [self->entries removeAllObjects];
  }
}

- (BOOL)exportToPath:(NSString *)_path {
  BOOL isDir;

  if ([self->fm fileExistsAtPath:_path isDirectory:&isDir]) {
    if (!isDir) {
      NSLog(@"%s: path is no directory %@", __PRETTY_FUNCTION__, _path);
      return NO;
    }
  }
  else {
    NSLog(@"createDirectoryAtPath %@", _path);
    if (![self->fm createDirectoryAtPath:_path attributes:nil]) {
      NSLog(@"%s: couldn`t create directory at path %@",
            __PRETTY_FUNCTION__, _path);
      return NO;
    }
  }
  ASSIGN(self->path, _path);
  self->writeSingleEntry = YES;

  return [self exportEntries];
}

- (BOOL)exportToFile:(NSString *)_file {
  BOOL result;
  
  if ([self->fm fileExistsAtPath:_file isDirectory:NULL]) {
    if ([[[NSUserDefaults standardUserDefaults]
                          objectForKey:@"Overwrite_Export_File"] boolValue]) {
      if (![self->fm removeFileAtPath:_file handler:nil]) {
        NSLog(@"%s: couldn`t remove file %@", __PRETTY_FUNCTION__, _file);
        return NO;
      }
    }
    else {
      NSLog(@"%s: file %@ already exist...", __PRETTY_FUNCTION__, _file);
      return NO;
    }
  }
  ASSIGN(self->path, _file);
  self->writeSingleEntry = NO;
  result = [self exportEntries];
  [self flush];
  return result;
}

- (BOOL)exportEntries {
  if (![self->path length]) {
    NSLog(@"%s: missing path ... ", __PRETTY_FUNCTION__);
    return NO;
  }
  return YES;
}

- (id)primaryKeyForEntry:(NSDictionary *)_entry {
  return [self subclassResponsibility:_cmd];
}
@end /* SkyExporter */


