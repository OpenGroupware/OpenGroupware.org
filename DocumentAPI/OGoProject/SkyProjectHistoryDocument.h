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

#ifndef __SkyProjectHistoryDocument_H__
#define __SkyProjectHistoryDocument_H__

#include <OGoDocuments/SkyDocument.h>

@class NSString, NSData, NSDictionary;

@interface SkyProjectHistoryDocument : SkyDocument
< SkyBLOBDocument, SkyStringBLOBDocument >
{
  id                    fileManager;
  NSData                *blob;
  NSString              *path;
  NSString              *filename;
  NSString              *version;
  NSString              *subject;
  unsigned              size;
  EOGlobalID            *globalID;
  id                    mainDocument;
}

- (id)initWithFileAttributes:(NSDictionary *)_attr
  fileManager:(id)_fm;

- (NSString *)path;
- (NSString *)filename;
- (NSString *)version;
- (unsigned)size;

- (void)setSubject:(NSString *)_s;
- (NSString *)subject;

- (NSData *)blob;
- (void)setContent:(NSData *)_c;
- (NSData *)content;
- (void)setContentString:(NSString *)_c;
- (NSString *)contentAsString;

- (id)fileManager;
- (BOOL)isEqual:(id)_obj;
- (EOGlobalID *)globalID;
- (id)mainDocument;

@end

#endif /* __SkyProjectHistoryDocument_H__ */
