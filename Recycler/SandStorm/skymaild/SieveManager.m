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

#include "common.h"

#import <Foundation/Foundation.h>
#import <Foundation/NSUserDefaults.h>

#include <NGHttp/NGHttpHeaderFields.h>

#include <stdio.h>
#include <stdlib.h>

#include "SieveManager.h"
#include "Filter.h"
#include "FilterEntry.h"

@implementation SieveManager

- (id)initWithServer:(NSString *)_server
                port:(int)_port
            fileName:(NSString *)_fileName
            userName:(NSString *)_userName
            password:(NSString *)_password {
  if ((self = [super init])) {
    [self setPort:_port];
    [self setServer:_server];
    [self setUserName:_userName];
    [self setPassword:_password];
    if (![_fileName isNotNull])
      [self setFileName:[self defaultFileName]];
    else
      [self setFileName:_fileName];
    [self setFilters:[NSArray array]];
    [self setUseFileManager:NO];

    [self loadFile];
  }
  return self;
}

#if !LIB_FOUNDATION_BOEHM_GC
- (void)dealloc {
  RELEASE(self->server);
  RELEASE(self->userName);
  RELEASE(self->password);
  RELEASE(self->fileName);
  RELEASE(self->filters);

  [super dealloc];
}
#endif

// Accessors.

- (void)setServer:(NSString *)_server {
  ASSIGN(self->server, _server);
}
- (NSString *)server {
  return self->server;
}

- (void)setPort:(int)_port {
  self->port = _port;
}
- (int)port {
  return self->port;
}

- (void)setUserName:(NSString *)_userName {
  ASSIGN(self->userName, _userName);
}
- (NSString *)userName {
  return self->userName;
}

- (void)setPassword:(NSString *)_password {
  ASSIGN(self->password, _password);
}
- (NSString *)password {
  return self->password;
}

- (void)setFileName:(NSString *)_fileName {
  ASSIGN(self->fileName, _fileName);
}
- (NSString *)fileName {
  return self->fileName;
}

- (void)setUseFileManager:(BOOL)_flag {
  self->useFileManager = _flag;
}
- (BOOL)useFileManager {
  return self->useFileManager;
}

- (void)setFilters:(NSArray *)_filters {
  if (! [_filters isNotNull]) {
    NSLog(@"%s null filter list given", __PRETTY_FUNCTION__);
    return;
  }

  ASSIGN(self->filters, [NSMutableArray arrayWithArray:_filters]);
}
- (NSMutableArray *)filters {
  return self->filters;
}

// Misc tools.

- (NSString *)installSievePath {
  NSString *installSievePath = nil;

  installSievePath = [[NSUserDefaults standardUserDefaults]
                                      stringForKey:@"InstallSievePath"];
  if ([installSievePath length] == 0)
    return @"/usr/bin/installsieve";

  return installSievePath;
}

- (NSString *)defaultFileName {
  NSString *defaultFileName = nil;

  defaultFileName = [[NSUserDefaults standardUserDefaults]
                                     stringForKey:@"DefaultFilterFileName"];
  if ([defaultFileName length] == 0)
    return @"skyrix";

  return defaultFileName;
}

- (NSString *)runSieveCommand:(NSString *)_paras cwd:(NSString *)_cwd {
  NSTask         *task         = nil;
  int            rc            = 0;
  NSString       *cmd          = nil;
  NSFileHandle   *nullHandle   = nil;
  NSFileHandle   *outputHandle = nil;
  NSPipe         *outputPipe   = nil;
  NSData         *outputData   = nil;
  NSString       *outputString = nil;
  NSMutableArray *paras        = nil;

  paras = [NSMutableArray array];

  [paras addObject:@"-u"];
  [paras addObject:[self userName]];
  [paras addObject:@"-w"];
  [paras addObject:[self password]];
  {
    NSArray *a = nil;

    a = [_paras componentsSeparatedByString:@" "];

    if ([a count] > 0)
      [paras addObjectsFromArray:a];
  }
  [paras addObject:[self server]];

  cmd = [self installSievePath];

  if (! [[NSFileManager defaultManager] isExecutableFileAtPath:cmd]) {
    NSLog(@"%s: command path (%@) isn't executable",
          __PRETTY_FUNCTION__, cmd);
    return @"error";
  }

  if ([cmd length] == 0) {
    NSLog(@"%s: command path is empty", __PRETTY_FUNCTION__);
    return @"error";
  }

  task = [[NSTask alloc] init];

  outputPipe   = [NSPipe pipe];
  outputHandle = [outputPipe fileHandleForReading];
  nullHandle   = [NSFileHandle fileHandleForWritingAtPath:@"/dev/null"];

  //NSLog(@"%s: cmd = %@, paras = %@", __PRETTY_FUNCTION__, cmd, paras);

  [task setLaunchPath:cmd];
  [task setCurrentDirectoryPath:_cwd];
  [task setArguments:paras];
  [task setStandardOutput:outputPipe];
  [task setStandardError:nullHandle];
  [task launch];

  outputData = [outputHandle readDataToEndOfFile];

  if ([task isRunning])
    [task waitUntilExit];

  rc = [task terminationStatus];
  RELEASE(task); task = nil;

  outputString = [NSString stringWithCString:[outputData bytes]];

  if (rc != 0) {
    NSLog(@"%s: return code %d indicates an error", __PRETTY_FUNCTION__, rc);
    NSLog(@"%s: output =\n%@", __PRETTY_FUNCTION__, outputString);
    return @"error";
  }

  if ([outputString length] == 0)
    NSLog(@"%s: command output is empty", __PRETTY_FUNCTION__);

  return outputString;
}
- (NSString *)runSieveCommand:(NSString *)_paras {
  return [self runSieveCommand:_paras cwd:@"/tmp"];
}

- (void)filtersFromSieveFormat:(NSString *)_sieveFilter {
  NSLog(@"%s not implemented.", __PRETTY_FUNCTION__);
}

- (NSString *)filtersToSieveFormat {
  NSEnumerator    *enu         = nil;
  Filter          *filter      = nil;
  NSMutableString *sieveFilter = nil;
  BOOL            firstEntry   = YES;

  sieveFilter = [[NSMutableString alloc] init];

  [sieveFilter appendString:@"require [\"fileinto\"];\n\n"];

  enu = [[self filters] objectEnumerator];
  while ((filter = [enu nextObject])) {
    NSEnumerator *entryenu = nil;
    FilterEntry  *entry    = nil;

    if ([[filter entries] count] > 0) {
      BOOL     isFirst     = YES;
      NSString *folderName = nil;

      if (firstEntry == YES) {
        [sieveFilter appendString:@"if "];
        firstEntry = NO;
      }
      else
        [sieveFilter appendString:@"elsif "];

      if ([[filter match] isEqualToString:@"or"] == YES)
        [sieveFilter appendString:@"anyof ("];
      else
        [sieveFilter appendString:@"allof ("];

      entryenu = [[filter entries] objectEnumerator];
      while ((entry = [entryenu nextObject])) {
        NSString *kind = [entry filterKind];

        if (isFirst == YES)
          isFirst = NO;
        else
          [sieveFilter appendString:@", "];

        if ([kind isEqualToString:@"contains"] == YES)
          [sieveFilter appendString:@"header :contains"];
        else if ([kind isEqualToString:@"doesn`t contain"] == YES)
          [sieveFilter appendString:@"not header :contains"];
        else if ([kind isEqualToString:@"is"] == YES)
          [sieveFilter appendString:@"header :is"];
        else if ([kind isEqualToString:@"isn`t"] == YES)
          [sieveFilter appendString:@"not header :is"];
        else if ([kind isEqualToString:@"begins with"] == YES)
          [sieveFilter appendString:@"header :matches"];
        else if ([kind isEqualToString:@"ends with"] == YES)
          [sieveFilter appendString:@"header :matches"];
        else
          NSLog(@"%s: couldn't use entry %@", __PRETTY_FUNCTION__, entry);

        [sieveFilter appendString:@" \""];
        [sieveFilter appendString:[entry headerField]];
        [sieveFilter appendString:@"\" \""];
        [sieveFilter appendString:[entry string]];
        [sieveFilter appendString:@"\""];
      }

      [sieveFilter appendString:@")\n{\n  fileinto \""];

      folderName = [filter folder];
      if ([folderName hasPrefix:@"/"] == YES)
        folderName = [folderName substringWithRange:
                               NSMakeRange(1, [folderName length] - 1)];

      folderName = [[folderName componentsSeparatedByString:@"/"]
                                componentsJoinedByString:@"."];

      [sieveFilter appendString:folderName];
      [sieveFilter appendString:@"\";\n}\n"];
    }
  }

  return AUTORELEASE(sieveFilter);
}

- (void)updateFilterPositionAttributes {
  NSMutableArray *ma = [self filters];
  int i;

  for (i=0; i<[ma count]; i++)
    [[ma objectAtIndex:i] setFilterPos:i];
}

int sortUsingFilterPos (id num1, id num2, void *context) // internal function
{
  int v1 = [(Filter *)num1 filterPos];
  int v2 = [(Filter *)num2 filterPos];

  if (v1 < v2)
    return NSOrderedAscending;
  else if (v1 > v2)
    return NSOrderedDescending;
  else
    return NSOrderedSame;
}

- (void)sortUsingFilterPosAttribute {
  [self setFilters:[self->filters sortedArrayUsingFunction:
                        sortUsingFilterPos context:NULL]];
}
- (void)sortUsingFilterNames {
  [self setFilters:[self->filters sortedArrayUsingSelector:
                        @selector(filterName:)]];
}

// Filter files.

- (NSString *)homeDirectory {
  NSString      *dir  = nil;
  //NSFileManager *fm   = nil;
  //BOOL          isDir = NO;

  dir = @"/HOME/gerrit/dev/SkyrixRoot42/sievehomedir";
/* geht nicht. erstellt immer ein dir und wechselt rein. erstmal so.
  fm = [NSFileManager defaultManager];
  if (![fm fileExistsAtPath:dir isDirectory:&isDir])
    [fm createDirectoryAtPath:dir attributes:[NSDictionary dictionary]];
  else {
    if (!isDir) {
      NSLog(@"%s: no directory at path \"%@\"", __PRETTY_FUNCTION__, dir);
      return nil;
    }
    if (![fm isExecutableFileAtPath:dir]) {
      NSLog(@"%s: no executable directory at path \"%@\"",
            __PRETTY_FUNCTION__, dir);
      return nil;
    }
  }
*/
  return dir;
}

- (void)changeToHomeDirectory {
  NSString *dir = nil;

  dir = [self homeDirectory];
  if (!dir) {
    NSLog(@"%s: no homedir path", __PRETTY_FUNCTION__);
    return;
  }

  [[NSFileManager defaultManager] changeCurrentDirectoryPath:dir];
}

- (BOOL)saveLocalFilters:(NSString *)_fileName {
  NSString       *ffn = nil; // filter filename for local copy
  NSEnumerator   *enu = nil;
  NSMutableArray *ma  = nil;
  Filter         *fi  = nil;

  [self changeToHomeDirectory];

  ma  = [NSMutableArray array];
  ffn = [NSString stringWithFormat:@"%@-%@.plist",
                  [self userName], _fileName];

  enu = [[self filters] objectEnumerator];
  while ((fi = [enu nextObject]))
    [ma addObject:[fi dictionaryRepresentation]];

  if (! [ma writeToFile:ffn atomically:YES]) {
    NSLog(@"%s: couldn't write to data file", __PRETTY_FUNCTION__);
    return NO;
  }

  return YES;
}
- (BOOL)saveLocalFilters {
  return [self saveLocalFilters:[self fileName]];
}

- (BOOL)loadLocalFilters:(NSString *)_fileName {
  NSString       *ffn = nil; // filter filename for local copy
  NSEnumerator   *enu = nil;
  NSMutableArray *ma  = nil;
  NSDictionary   *fi  = nil;

  [self changeToHomeDirectory];

  ma  = [NSMutableArray array];
  ffn = [NSString stringWithFormat:@"%@-%@.plist",
                  [self userName], _fileName];

  enu = [[NSArray arrayWithContentsOfFile:ffn] objectEnumerator];
  while ((fi = [enu nextObject])) {
    NSLog(@"%s fi = %@", __PRETTY_FUNCTION__, fi);
    [ma addObject:[Filter filterWithDictionary:fi]];
  }

  [self setFilters:ma];

  return YES;
}
- (BOOL)loadLocalFilters {
  return [self loadLocalFilters:[self fileName]];
}

- (BOOL)deleteLocalFilters:(NSString *)_fileName {
  NSString *ffn = nil; // filter filename for local copy

  [self changeToHomeDirectory];

  ffn = [NSString stringWithFormat:@"%@-%@.plist",
                  [self userName], _fileName];

  if ([[NSFileManager defaultManager] isDeletableFileAtPath:ffn])
    [[NSFileManager defaultManager] removeFileAtPath:ffn handler:nil];

  return YES;
}
- (BOOL)deleteLocalFilters {
  return [self deleteLocalFilters:[self fileName]];
}

- (NSArray *)fileNames {
  NSMutableArray *result = nil;
  NSString       *output = nil;

  result = [NSMutableArray array];
  output = [self runSieveCommand:@"-l"];

  NSLog(@"%s: %@", __PRETTY_FUNCTION__, output);




  return result;
}

- (BOOL)loadFile {
  if (![[self fileName] isNotNull])
    return NO;
  if ([[self fileName] length] == 0)
    return NO;

  if ([self loadLocalFilters]) // forgets all changes in the sieve file.
    return YES;

  if (self->useFileManager) {

    NSLog(@"%s not implemented.", __PRETTY_FUNCTION__);

  } else {


  }

  [self sortUsingFilterPosAttribute];

  return NO; // error
}

- (BOOL)loadFile:(NSString *)_fileName {
  [self setFileName:_fileName];

  return [self loadFile];
}

- (BOOL)saveFile {
  NSString *output = nil;
  NSString *paras  = nil;

  if (![[self fileName] isNotNull])
    return NO;
  if ([[self fileName] length] == 0)
    return NO;

  // Update filter position attributes. SieveManager uses the array-index
  // as filter position flag.

  [self updateFilterPositionAttributes];

  if (! [self saveLocalFilters]) // hold a local copy as plist.
    return NO;

  // Save file temporarly.

  if (self->useFileManager) {

    NSLog(@"%s not implemented.", __PRETTY_FUNCTION__);

  } else {
    char     template[] = "/tmp/skyrix-sieve-dir-XXXXXX";
    NSString *fname     = nil;

    fname = [NSString stringWithCString:mktemp(template)];
    if ([fname length] > 0) {
      NSFileManager *fm     = nil;
      BOOL           result = NO;

      fm = [NSFileManager defaultManager];

      if ([fm createDirectoryAtPath:fname
              attributes:[NSDictionary dictionary]]) {
        [fm changeCurrentDirectoryPath:fname];

        result = [[self filtersToSieveFormat] writeToFile:[self fileName]
                                              atomically:YES];
        if (result == NO) {
          NSLog(@"%s: couldn't write to temporary file", __PRETTY_FUNCTION__);
          return NO;
        }

        paras  = [NSString stringWithFormat:@"-i %@", [self fileName]];
        NSLog(@"%s file = <<%@>>", __PRETTY_FUNCTION__,
              [NSString stringWithContentsOfFile:[self fileName]]);
        output = [self runSieveCommand:paras cwd:fname];

        if ([fm isDeletableFileAtPath:[self fileName]])
          [fm removeFileAtPath:[self fileName] handler:nil];

        [fm changeCurrentDirectoryPath:
            [fname stringByDeletingLastPathComponent]];
        [fm removeFileAtPath:[fname lastPathComponent] handler:nil];

        [self changeToHomeDirectory];
      }
      else {
        NSLog(@"%s: couldn't create temporary dir", __PRETTY_FUNCTION__);
        return NO;
      }
    }
    else {
      NSLog(@"%s: couldn't create temporary dir name", __PRETTY_FUNCTION__);
      return NO;
    }
  }

  if ([output isEqualToString:@"error"])
    return NO;

  // Noch auswerten

  NSLog(@"%s: output = %@", __PRETTY_FUNCTION__, output);




  return YES;
}

- (BOOL)saveFile:(NSString *)_fileName {
  [self setFileName:_fileName];

  return [self saveFile];
}

- (BOOL)deleteFile {
  return [self deleteFile:[self fileName]];
}
- (BOOL)deleteFile:(NSString *)_fileName {
  if (![_fileName isNotNull])
    return NO;
  if ([_fileName length] == 0)
    return NO;

  [self deleteLocalFilters:_fileName];

  if (self->useFileManager) {

    NSLog(@"%s not implemented.", __PRETTY_FUNCTION__);

  } else {
    NSString *paras  = nil;
    NSString *output = nil;

    paras  = [NSString stringWithFormat:@"-d %@", _fileName];
    output = [self runSieveCommand:paras];

    NSLog(@"%s: %@", __PRETTY_FUNCTION__, output);

    //"Deletescript error: Error deleting script"
  }

  return NO;
}

- (BOOL)activateFile {
  return [self activateFile:[self fileName]];
}

- (BOOL)activateFile:(NSString *)_fileName {
  if (![_fileName isNotNull])
    return NO;
  if ([_fileName length] == 0)
    return NO;

  if (self->useFileManager) {

/*
  if ([fm copy:source toPath:@"default" handler:nil])
    ;
*/

    NSLog(@"%s not implemented.", __PRETTY_FUNCTION__);

  } else {

    NSLog(@"%s not implemented.", __PRETTY_FUNCTION__);

  }

  return NO; // error
}

- (NSString *)activeFile {
  NSLog(@"%s not implemented.", __PRETTY_FUNCTION__);

  return nil;
}

- (BOOL)isActiveFile {
  return [self isActiveFile:[self fileName]];
}

- (BOOL)isActiveFile:(NSString *)_fileName {
  NSString *af = nil;

  af = [self activeFile];

  if ([af isNotNull]) {
    if ([_fileName isEqualToString:af])
      return YES;
  }

  return NO;
}

// Filters.

- (NSArray *)filterNames {
  NSMutableArray *ma  = nil;
  NSEnumerator   *enu = nil;
  Filter         *fi  = nil;

  ma = [NSMutableArray array];
  enu = [[self filters] objectEnumerator];
  while ((fi = [enu nextObject])) {
    if ([[fi filterName] length])
      [ma addObject:[fi filterName]];
  }

  NSLog(@"DDDD <%@> <%@>", [self filters], ma);

  return AUTORELEASE([ma copy]);
}

- (Filter *)filterWithName:(NSString *)_name {
  NSEnumerator *enu    = nil;
  Filter       *filter = nil;

  enu = [[self filters] objectEnumerator];
  while ((filter = [enu nextObject]))
    if ([[filter filterName] isEqualToString:_name])
      return filter;

  return nil;
}

- (Filter *)filterAtPosition:(int)_pos {
  NSMutableArray *ma = [self filters];

  if ([ma count] <= _pos) {
    NSLog(@"%s wrong position", __PRETTY_FUNCTION__);
    return nil;
  }

  if ([ma count] > _pos)
    return [ma objectAtIndex:_pos];

  return nil;
}

- (BOOL)replaceFilter:(Filter *)_filter atPosition:(int)_pos {
  NSMutableArray *ma = [self filters];

  if (! [_filter isNotNull]) {
    NSLog(@"%s null filter", __PRETTY_FUNCTION__);
    return NO;
  }

  if ([ma count] <= _pos) {
    NSLog(@"%s wrong position", __PRETTY_FUNCTION__);
    return NO;
  }

  [ma replaceObjectAtIndex:_pos withObject:_filter];

  return YES;
}

- (BOOL)insertFilter:(Filter *)_filter atPosition:(int)_pos {
  NSMutableArray *ma = [self filters];

  if (! [_filter isNotNull])
    return NO;

  if ([ma count] < _pos)
    return NO;

  if ([ma count] == _pos)
    return [self insertFilter:_filter]; // just add the filter

  [ma insertObject:_filter atIndex:_pos];

  return YES;
}

- (BOOL)insertFilter:(Filter *)_filter {
  if (! [_filter isNotNull]) {
    NSLog(@"%s can't insert null filter", __PRETTY_FUNCTION__);
    return NO;
  }

  [[self filters] addObject:_filter];

  return YES;
}

- (BOOL)deleteFilter:(Filter *)_filter {
  NSString *fn = nil;
  Filter   *fi = nil;

  if (! [_filter isNotNull]) {
    NSLog(@"%s: can't delete null object", __PRETTY_FUNCTION__);
    return NO;
  }

  fn = [_filter filterName];
  fi = [self filterWithName:fn];

  if (! [fi isNotNull])
    return NO;

  if ([fi filterPos] != [_filter filterPos])
    return NO;

  [[self filters] removeObjectAtIndex:[fi filterPos]];

  return YES;
}

- (BOOL)deleteFilterAtPosition:(int)_pos {
  if ([[self filters] count] <= _pos) {
    NSLog(@"%s: invalid object position", __PRETTY_FUNCTION__);
    return NO;
  }

  return [self deleteFilter:[[self filters] objectAtIndex:_pos]];
}

- (BOOL)deleteFilterWithName:(NSString *)_name {
  Filter *filter = nil;

  if (! [_name isNotNull]) {
    NSLog(@"%s: null name", __PRETTY_FUNCTION__);
    return NO;
  }

  filter = [self filterWithName:_name];

  if (! [filter isNotNull]) {
    NSLog(@"%s: null filter", __PRETTY_FUNCTION__);
    return NO;
  }

  return [self deleteFilter:filter];
}

@end // SieveManager
