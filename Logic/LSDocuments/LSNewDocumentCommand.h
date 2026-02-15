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

#import <LSFoundation/LSDBObjectNewCommand.h>

@class NSData, NSString;

/**
 * @class LSNewDocumentCommand
 * @brief Creates a new document record in a project
 *        and writes its attachment to the filesystem.
 *
 * Inserts a new Doc entity row and, for non-folder
 * documents, also creates an associated DocumentEditing
 * record representing the initial checked-out version.
 * The binary content is written to disk as an attachment
 * file (via `LSGetAttachmentNameCommand`).
 *
 * Content can be supplied as raw `data` (NSData) or
 * as `fileContent` (NSString). The `filePath` is used
 * to derive the file extension. A `folder` and
 * `project` must be set before execution.
 *
 * When `autoRelease` is YES, the document is
 * immediately released (checked in) after creation.
 */
@interface LSNewDocumentCommand : LSDBObjectNewCommand
{
@protected  
  id       folder;
  id       project;
  NSData   *data;
  NSString *filePath;
  NSString *fileContent;
  BOOL     autoRelease;
}

- (void)_setFileType;

@end
