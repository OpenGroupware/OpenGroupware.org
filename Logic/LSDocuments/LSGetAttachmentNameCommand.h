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

#ifndef __LSGetAttachmentNameCommand_H__
#define __LSGetAttachmentNameCommand_H__

#include <LSFoundation/LSBaseCommand.h>

@class NSNumber;

/**
 * @class LSGetAttachmentNameCommand
 * @brief Resolves filesystem attachment paths for
 *        document objects.
 *
 * Given one or more document, note, or editing objects,
 * this command computes the filesystem path where the
 * corresponding attachment file is (or should be)
 * stored, and caches the result in the "attachmentName"
 * key of each object.
 *
 * Supports three storage layouts controlled by the
 * user defaults `UseFlatDocumentFileStructure` and
 * `UseFoldersForIDRanges`: flat storage in a single
 * directory, per-project subdirectories, and additional
 * ID-range subdirectories within project folders.
 *
 * Accepts objects via the "document", "note",
 * "documentEditing", "documentVersion" (singular) or
 * their plural forms. An optional `projectId` can be
 * set to override the project derived from the object.
 */
@interface LSGetAttachmentNameCommand : LSBaseCommand
{
  NSNumber *projectId;
}

@end

#endif /* __LSGetAttachmentNameCommand_H__ */
