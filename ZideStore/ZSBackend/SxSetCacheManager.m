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
// $Id: SxSetCacheManager.m 1 2004-08-20 11:17:52Z znek $

#include "SxSetCacheManager.h"
#include "common.h"

@implementation SxSetCacheManager

static NSString *SxSetGenerationName = @"generation";
static NSString *SxSetContentsName   = @"set";

static BOOL debugOn = YES;

- (id)initWithPath:(NSString *)_path setId:(id)_sid manager:(id)_manager {
  if ((self = [super init])) {
    self->path    = [_path copy];
    self->fm      = [[NSFileManager defaultManager] retain];
    self->setId   = [_sid retain];
    self->manager = _manager;
  }
  return self;
}

- (void)dealloc {
  [self->lastCSV release];
  [self->setId   release];
  [self->path    release];
  [self->fm      release];
  [super dealloc];
}

/* accessors */

- (NSString *)path {
  return self->path;
}

/* generation file */

- (int)createGenerationOfSetAtPath:(NSString *)_p {
  const char *fn;
  FILE *fh;
  int  generation = 9;
  
  fn = [fm fileSystemRepresentationWithPath:_p];
  
  if ((fh = fopen(fn, "w")) == NULL) {
    [self logWithFormat:@"could not create generation file at: %@", _p];
    return 4;
  }
  fprintf(fh, "%i\n", generation);
  fclose(fh);
  [self logWithFormat:@"created generation file with version 9: %@", _p];
  return generation;
}

- (int)generationOfSet {
  const char *fn;
  NSString *p;
  FILE *fh;
  int  generation = 0;
  
  p  = [self->path stringByAppendingString:SxSetGenerationName];
  fn = [fm fileSystemRepresentationWithPath:p];
  
  if ((fh = fopen(fn, "r")) == NULL)
    return [self createGenerationOfSetAtPath:p];
  
  fscanf(fh, "%i", &generation);
  fclose(fh);
  if (generation > 9)
    return generation;
  
  [self logWithFormat:@"could not read generation at %@", p];
  return 5;
}

/* id/version CSV */

- (int)refreshInterval {
  static int ref = -1;
  if (ref == -1) {
    ref = [[[NSUserDefaults standardUserDefaults] 
                            objectForKey:@"ZLFolderRefresh"] intValue];
  }
  return ref > 0 ? ref : 300; /* every five minutes */
}

- (NSString *)csvForSetInVersion:(int)_v {
  NSString *csvPath;
  NSString *s;
  
  if (_v == self->lastCSVVersion)
    /* cached */
    return self->lastCSV;
  
  /* load */
  
  csvPath = [NSString stringWithFormat:@"%@_%i", SxSetContentsName, _v];
  csvPath = [self->path stringByAppendingString:csvPath];
  
  if ((s = [[NSString alloc] initWithContentsOfFile:csvPath]) == nil)
    [self logWithFormat:@"no CSV for set generation %i", _v];
  
  /* cache */
  ASSIGNCOPY(self->lastCSV, s);
  self->lastCSVVersion = _v;
  
  return [s autorelease];
}

- (NSString *)csvForSet {
  return [self csvForSetInVersion:[self generationOfSet]];
}

- (NSException *)processNewCSV:(NSString *)_csv {
  int v = [self generationOfSet];
  
  if (debugOn) [self logWithFormat:@"process new CSV (%i) ...", v];
  return nil;
}
- (NSException *)processChangedCSV:(NSString *)_csv {
  int v = [self generationOfSet];
  
  if (debugOn) [self logWithFormat:@"process changed CSV (%i) ...", v];
  return nil;
}

- (NSException *)processCSVForChanges:(NSString *)_csv {
  NSString *current;

  if (_csv == nil) return nil;
  
  if ((current = [self csvForSet]) == nil)
    return [self processNewCSV:_csv];
  
  if (![current isEqualToString:_csv])
    return [self processChangedCSV:_csv];
  
  if (debugOn) [self logWithFormat:@"version did not change .."];
  return nil /* means OK */;
}

@end /* SxSetCacheManager */
