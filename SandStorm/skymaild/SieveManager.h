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
// $Id$

#ifndef __SkyMailXmlRpcServer__SieveManager_H__
#define __SkyMailXmlRpcServer__SieveManager_H__

#import <Foundation/NSObject.h>

@class NSString, NSArray, NSMutableArray;
@class Filter, FilterEntry;

@interface SieveManager : NSObject
{
@private
  NSString       *server;
  int             port;
  NSString       *fileName;
  NSString       *userName;
  NSString       *password;
  NSMutableArray *filters;
  BOOL            useFileManager;
}

- (id)initWithServer:(NSString *)_server
  port:(int)_port
  fileName:(NSString *)_fileName
  userName:(NSString *)_userName
  password:(NSString *)_password;

// Accessors.

- (void)setServer:(NSString *)_server;
- (NSString *)server;

- (void)setPort:(int)_port;
- (int)port;

- (void)setUserName:(NSString *)_userName;
- (NSString *)userName;

- (void)setPassword:(NSString *)_password;
- (NSString *)password;

- (void)setFileName:(NSString *)_fileName;
- (NSString *)fileName;

- (void)setUseFileManager:(BOOL)_flag;
- (BOOL)useFileManager;

- (void)setFilters:(NSArray *)_filters;
- (NSMutableArray *)filters;

// Misc tools.

- (NSString *)installSievePath;
- (NSString *)defaultFileName;

- (NSString *)runSieveCommand:(NSString *)_paras cwd:(NSString *)_cwd;
- (NSString *)runSieveCommand:(NSString *)_paras;

- (void)filtersFromSieveFormat:(NSString *)_sieveFilter;
- (NSString *)filtersToSieveFormat;

- (void)updateFilterPositionAttributes;
- (void)sortUsingFilterPosAttribute;

// Filter files.

- (BOOL)saveLocalFilters;
- (BOOL)saveLocalFilters:(NSString *)_fileName;
- (BOOL)loadLocalFilters;
- (BOOL)loadLocalFilters:(NSString *)_fileName;
- (BOOL)deleteLocalFilters;
- (BOOL)deleteLocalFilters:(NSString *)_fileName;

- (NSArray *)fileNames;

- (BOOL)loadFile;
- (BOOL)loadFile:(NSString *)_fileName;
- (BOOL)saveFile;
- (BOOL)saveFile:(NSString *)_fileName;
- (BOOL)deleteFile;
- (BOOL)deleteFile:(NSString *)_fileName;

- (BOOL)activateFile;
- (BOOL)activateFile:(NSString *)_fileName;
- (NSString *)activeFile;
- (BOOL)isActiveFile;
- (BOOL)isActiveFile:(NSString *)_fileName;

// Filters.

- (NSArray *)filterNames;
- (Filter *)filterWithName:(NSString *)_filterName;
- (Filter *)filterAtPosition:(int)_pos;

- (BOOL)replaceFilter:(Filter *)_filter atPosition:(int)_pos;

- (BOOL)insertFilter:(Filter *)_filter atPosition:(int)_pos;
- (BOOL)insertFilter:(Filter *)_filter;

- (BOOL)deleteFilter:(Filter *)_filter;
- (BOOL)deleteFilterAtPosition:(int)_pos;
- (BOOL)deleteFilterWithName:(NSString *)_filterName;

@end

#endif /* __SkyMailXmlRpcServer__SieveManager_H__ */
