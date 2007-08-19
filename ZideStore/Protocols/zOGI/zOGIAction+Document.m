/*
  Copyright (C) 2006-2007 Whitemice Consulting

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

#include "zOGIAction.h"
#include "zOGIAction+Document.h"

@implementation zOGIAction(Document)

-(id)_renderDocuments:(NSArray *)_docs withDetail:(NSNumber *)_detail {
  NSMutableArray      *results;
  EOGenericRecord     *eoDoc;
  NSMutableDictionary *folder;
  int                 i;

  if (_docs == nil)
    return [[NSArray alloc] init];
  results = [[NSMutableArray alloc] initWithCapacity:[_docs count]];
  for(i = 0; i < [_docs count]; i++) {
    eoDoc = [_docs objectAtIndex:i];
    if ([[eoDoc valueForKey:@"isFolder"] intValue] == 1) {
      /* Render document as a folder */
      [self logWithFormat:@"Rendering Folder:%@", eoDoc];
      folder = [NSMutableDictionary dictionaryWithObjectsAndKeys: 
        [eoDoc valueForKey:@"documentId"], @"objectId",
        @"Folder", @"entityName",
        [self NIL:[eoDoc valueForKey:@"projectId"]], @"projectObjectId",
        [self NIL:[eoDoc valueForKey:@"firstOwnerId"]], @"creatorObjectId",
        [self NIL:[eoDoc valueForKey:@"currentOwnerId"]], @"ownerObjectId",
        [self NIL:[eoDoc valueForKey:@"title"]], @"title",
        [self NIL:[eoDoc valueForKey:@"creationDate"]], @"creation",
        [self NIL:[eoDoc valueForKey:@"parentDocumentId"]], @"folderObjectId",
        nil];
       if([_detail intValue] & zOGI_INCLUDE_CONTENTS)
         [folder setObject:[self _getContentsOfFolder:[eoDoc valueForKey:@"documentId"]]
                 forKey:@"_CONTENTS"];
       [results addObject:folder];
     } else {
         /* Render document as a file */
         [[self getCTX] runCommand:@"doc::get-attachment-name",
                                   @"document", eoDoc, 
                                   nil];
         [self logWithFormat:@"Rendering File:%@", eoDoc];
         [results addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys: 
           [eoDoc valueForKey:@"documentId"], @"objectId",
           @"File", @"entityName",
           [self NIL:[eoDoc valueForKey:@"projectId"]], @"projectObjectId",
           [self NIL:[eoDoc valueForKey:@"firstOwnerId"]], @"creatorObjectId",
           [self NIL:[eoDoc valueForKey:@"currentOwnerId"]], @"ownerObjectId",
           [self NIL:[eoDoc valueForKey:@"parentDocumentId"]], @"folderObjectId",
           [self NIL:[eoDoc valueForKey:@"title"]], @"filename",
           [self NIL:[eoDoc valueForKey:@"abstract"]], @"title",
           [self NIL:[eoDoc valueForKey:@"status"]], @"status",
           [self NIL:[eoDoc valueForKey:@"attachmentName"]], @"attachment",
           [self NIL:[eoDoc valueForKey:@"creationDate"]], @"creation",
           [self NIL:[eoDoc valueForKey:@"fileSize"]], @"fileSize",
           [self NIL:[eoDoc valueForKey:@"fileType"]], @"fileType",
           [self NIL:[eoDoc valueForKey:@"lastmodifiedDate"]], @"lastModified",
           [self NIL:[eoDoc valueForKey:@"versionCount"]], @"version",
           nil]];
        }
   }
  return results;
}

-(NSArray *)_getUnrenderedDocsForKeys:(id)_arg {
  NSArray *docs;
  docs = [[[self getCTX] runCommand:@"doc::get-by-globalid",
                                    @"gids", [self _getEOsForPKeys:_arg],
                                    nil] retain];
  return docs;
}

-(id)_getDocumentsForKeys:(id)_pkeys withDetail:(NSNumber *)_detail {
  return [self _renderDocuments:[self _getUnrenderedDocsForKeys:_pkeys] 
                      withDetail:_detail];
}

-(id)_getDocumentsForKeys:(id)_pkeys {
  [self logWithFormat:@"_getDocumentsForKeys([%@])", _pkeys];
  return [self _renderDocuments:[self _getUnrenderedDocsForKeys:_pkeys] 
                     withDetail:[NSNumber numberWithInt:0]];
}

-(id)_getDocumentForKey:(id)_pkey withDetail:(NSNumber *)_detail {
  [self logWithFormat:@"_getDocumentsForKeys([%@],[%@])", _pkey, _detail];
  return [[self _renderDocuments:[self _getUnrenderedDocsForKeys:_pkey]
                      withDetail:_detail] objectAtIndex:0];
}

-(id)_getDocumentForKey:(id)_pkey {
  [self logWithFormat:@"_getDocumentsForKeys([%@])", _pkey];
  return [[self _renderDocuments:[self _getUnrenderedDocsForKeys:_pkey]
                      withDetail:[NSNumber numberWithInt:0]] objectAtIndex:0];
}

-(id)_getContentsOfFolder:(id)_folderId {
  NSArray    *folderContents;

  folderContents = [[self getCTX] runCommand:@"doc::get",
                                   @"parentDocumentId", _folderId, 
                                   @"returnType", [NSNumber numberWithInt:LSDBReturnType_ManyObjects],
                                   nil];
  return [self _renderDocuments:folderContents
                     withDetail:[NSNumber numberWithInt:0]];
}

@end /* End zOGIAction(Document) */
