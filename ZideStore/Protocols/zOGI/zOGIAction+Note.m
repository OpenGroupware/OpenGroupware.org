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
#include "zOGIAction+Object.h"
#include "zOGIAction+Note.h"
#include "zOGIAction+Appointment.h"
#include "zOGIAction+Project.h"

@implementation zOGIAction(Note)

-(id)_getNotesForKey:(NSString *)_objectId {
  NSArray        *notes;
  NSMutableArray *noteList;
  NSDictionary   *note;
  int count;
  
  notes = [self _getUnrenderedNotesForKey:_objectId];
  if ([notes count] == 0)
    return notes;
  noteList = [[NSMutableArray alloc] initWithCapacity:[notes count]];
  for (count = 0; count < [notes count]; count++) {
    note = [notes objectAtIndex:count];
    [noteList addObject:[self _renderNote:note]];
   }
  return noteList;
 } // End _getNotesForKey

-(id)_renderNote:(NSDictionary *)_note {
  return [NSDictionary dictionaryWithObjectsAndKeys:
    [_note valueForKey:@"documentId"], @"objectId",
    @"Note", @"entityName",
    [_note valueForKey:@"title"], @"title",
    [_note valueForKey:@"firstOwnerId"], @"creatorObjectId",
    [_note valueForKey:@"currentOwnerId"], @"ownerObjectId",
    [_note valueForKey:@"creationDate"], @"createdTime",
    [self NIL:[_note valueForKey:@"projectId"]], @"projectObjectId",
    [self NIL:[_note valueForKey:@"dateId"]], @"appointmentObjectId",
    [NSString stringWithContentsOfFile:[_note valueForKey:@"attachmentName"]],
    @"content",
    nil];
}
/*
   Retrieve and return the unrendered notes for the specified object.
 */
-(id)_getUnrenderedNotesForKey:(NSString *)_objectId {
  NSArray  *notes;
  NSString *entityName;
  
  notes = nil;
  entityName = [self _getEntityNameForPKey:_objectId];
  if ([entityName isEqualToString:@"Date"]) {
    notes = [[self getCTX] runCommand:@"note::get", @"dateId", _objectId,
                @"returnType", intObj(LSDBReturnType_ManyObjects),
                nil];
   } else if ([entityName isEqualToString:@"Project"]) {
    notes = [[self getCTX] runCommand:@"note::get", @"projectId", _objectId,
                @"returnType", intObj(LSDBReturnType_ManyObjects),
                nil];
   }
  if (notes == nil)
    return [NSArray array];
  [[self getCTX] runCommand:@"note::get-attachment-name", @"notes", notes, nil];
  return notes;
 } // End _getUnrenderedNotesForKey

/*
  Save notes
  Note dictionaries in _notes with an objectId of "0" are created as new,
  notes with a non-zero objectId are updated.  If the object has notes not 
  provided in the array they are deleted.
 */
-(id)_saveNotes:(NSArray *)_notes 
      forObject:(NSString *)_objectId {
  NSEnumerator	 *enumerator;
  NSDictionary   *note;
  NSString       *objectId;
  NSMutableArray *noteList;
  NSArray        *objectNotes;

  if ([self isDebug])
    [self logWithFormat:@"Saving notes on object %@", _objectId];
  if (_notes == nil) 
  {
    if ([self isDebug])
      [self logWithFormat:@"No _NOTES key.", _objectId];
    return nil;  
  }
  if ([_notes count] == 0) 
  {
    if ([self isDebug])
      [self logWithFormat:@"No notes on object, deleing all notes."];
    return [self _deleteAllNotesFromObject:_objectId];
  }
  noteList = [[NSMutableArray alloc] initWithCapacity:[_notes count]];
  enumerator = [_notes objectEnumerator];
  while ((note = [enumerator nextObject]) != nil) {
    objectId = [note objectForKey:@"objectId"];
    if ([objectId isKindOfClass:[NSNumber class]])
      objectId = [objectId stringValue];
    if ([objectId isEqualToString:@"0"]) {
      // objectId == 0, create note
      note = [self _insertNote:_objectId
                     withTitle:[note objectForKey:@"title"]
                   withContent:[note objectForKey:@"content"]];
      if ([note isKindOfClass:[NSException class]]) {
        return note;
       }
      [noteList addObject:[note objectForKey:@"objectId"]];
     } else {
         // objectId != 0, update note
         note = [self _updateNote:objectId
                        withTitle:[note objectForKey:@"title"]
                      withContent:[note objectForKey:@"content"]];
         if ([note isKindOfClass:[NSException class]]) {
           return note;
          }
         [noteList addObject:[note objectForKey:@"objectId"]];
        } // End else objectId != 0
   } // End while (note = [enumerator nextObject]) != nil)
  // Delete notes that were not provided by the client
  objectNotes = [self _getUnrenderedNotesForKey:_objectId];
  if (objectNotes == nil) {
    return nil;
   }
  enumerator = [objectNotes objectEnumerator];
  while ((note = [enumerator nextObject]) != nil) {
    objectId = [note objectForKey:@"documentId"];
    if ([noteList containsObject:objectId]) {
     } else {
         [self _deleteNote:objectId];
        }
   } // End while ((note = [[self _getNotesForKey:objectId] nextObject])
  return nil;
 } // End _saveNotes

/*
  Delete all the notes from an object
 */
-(id)_deleteAllNotesFromObject:(NSString *)_objectId {
  NSArray       *objectNotes;
  NSEnumerator  *enumerator;
  NSDictionary  *note;

  objectNotes = [self _getUnrenderedNotesForKey:_objectId];
  enumerator = [objectNotes objectEnumerator];
  while ((note = [enumerator nextObject]) != nil) {
    [self _deleteNote:_objectId];
   } // End while ((note = [enumerator nextObject]) != nil)
  return nil;
 }

/* 
  Insert a note attached to the specified object,  that object must be
  an appointment or a project.
 */
-(id)_insertNote:(id)_objectId
       withTitle:(id)_title
     withContent:(id)_content {
  id                    note, entityName, objectKey;
  NSNumber             *accountId;

  accountId =[self _getCompanyId];
  entityName = [self _getEntityNameForPKey:_objectId];
  if ([entityName isEqualToString:@"Date"])
  {
    objectKey = [NSString stringWithString:@"dateId"];
  } else if ([entityName isEqualToString:@"Project"])
    {
      objectKey = [NSString stringWithString:@"projectId"];
    } else return [NSException exceptionWithHTTPStatus:500
                      reason:@"Cannot attach note to this object type"];
  if ([self isDebug])
    [self logWithFormat:@"Inserting note on  %@ %@", objectKey, _objectId];
  note = [NSDictionary dictionaryWithObjectsAndKeys:
            _objectId, objectKey, 
            accountId, @"firstOwnerId",
            accountId, @"currentOwnerId", _title, @"title",
            _content, @"fileContent",
            [NSNumber numberWithBool:NO], @"isFolder",
            [NSNumber numberWithInt:[_content length]], @"fileSize",
            nil];
  note = [[self getCTX] runCommand:@"note::new" arguments:note];
  if (note == nil)
      return [NSException exceptionWithHTTPStatus:500
                          reason:@"Note creation failed"];
  return [self _renderNote:note];
 } // End _insertNote

- (id)_deleteNote:(id)_noteId {
  id note, result;

  if ([_noteId isKindOfClass:[NSString class]])
    _noteId = [NSNumber numberWithInt:[_noteId intValue]];
  note = [[self getCTX] runCommand:@"note::get",
             @"documentId", _noteId,
             nil];
  if (note == nil)
    return [NSException exceptionWithHTTPStatus:500
                        reason:@"Note does not exist"];
  result = [[self getCTX] runCommand:@"note::delete",
                   @"documentId", _noteId,
                   @"reallyDelete", [NSNumber numberWithBool:YES],
                 nil];
  return [NSNumber numberWithBool:YES];
 } // End _deleteNote

/*
  Update the title and content of the specified note
 */
-(id)_updateNote:(id)_noteId
       withTitle:(id)_title
     withContent:(id)_content {
  id note;

  note = [[[self getCTX] runCommand:@"note::get",
             @"documentId", _noteId,
             nil] lastObject];
  [note takeValue:[NSNumber numberWithInt:[_content length]] forKey:@"fileSize"];
  [note takeValue:_content forKey:@"fileContent"];
  [note takeValue:_title forKey:@"title"];
  [[self getCTX] runCommand:@"note::set",
     @"object", note,
     @"fileContent", _content, nil];
  note = [[[self getCTX] runCommand:@"note::get",
             @"documentId", _noteId,
             nil] lastObject];
  return [self _renderNote:note];
 } // End _updateNote

@end /* End zOGIAction(Note) */
