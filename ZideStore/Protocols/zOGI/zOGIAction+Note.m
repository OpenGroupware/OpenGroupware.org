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
  noteList = [NSMutableArray arrayWithCapacity:[notes count]];
  for (count = 0; count < [notes count]; count++) {
    note = [notes objectAtIndex:count];
    [noteList addObject:[self _renderNote:note]];
   }
  return noteList;
} /* end _getNotesForKey */

-(id)_getNoteById:(id)_objectId {
  id note;

  note = [[self getCTX] runCommand:@"note::get", 
                        @"documentId", _objectId, 
                        nil];
  [[self getCTX] runCommand:@"note::get-attachment-name", 
                 @"notes", note, 
                 nil];
  if ([note isKindOfClass:[NSArray class]])
    note = [note lastObject];
  if ([note isNotNull])
    return [self _renderNote:note];
  else
    return [self _makeUnknownObject:_objectId];
} /* end _getNoteById */

-(id)_renderNote:(NSDictionary *)_note {
  return [NSDictionary dictionaryWithObjectsAndKeys:
    [_note valueForKey:@"documentId"], @"objectId",
    @"note", @"entityName",
    [_note valueForKey:@"title"], @"title",
    [_note valueForKey:@"firstOwnerId"], @"creatorObjectId",
    [_note valueForKey:@"currentOwnerId"], @"ownerObjectId",
    [_note valueForKey:@"creationDate"], @"createdTime",
    [self ZERO:[_note valueForKey:@"projectId"]], @"projectObjectId",
    [self ZERO:[_note valueForKey:@"dateId"]], @"appointmentObjectId",
    [self ZERO:[_note valueForKey:@"companyId"]], @"companyObjectId",
    [self NIL:[NSString stringWithContentsOfFile:[_note valueForKey:@"attachmentName"]]],
      @"content",
    nil];
} /* end _renderNote */

/* Retrieve and return the unrendered notes for the specified object. */
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
  [[self getCTX] runCommand:@"note::get-attachment-name", 
                            @"notes", notes, 
                            nil];
  return notes;
} /* end _getUnrenderedNotesForKey */

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
  if (_notes == nil) {
    if ([self isDebug])
      [self logWithFormat:@"No _NOTES key.", _objectId];
    return nil;  
  }
  if ([_notes count] == 0) {
    if ([self isDebug])
      [self logWithFormat:@"No notes on object, deleing all notes."];
    return [self _deleteAllNotesFromObject:_objectId];
  }
  noteList = [NSMutableArray arrayWithCapacity:[_notes count]];
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
         [self _deleteNote:objectId withCommit:NO];
        }
   } // End while ((note = [[self _getNotesForKey:objectId] nextObject])
  return nil;
} /* end _saveNotes */

/* Delete all the notes from an object */
-(id)_deleteAllNotesFromObject:(NSString *)_objectId {
  NSArray       *objectNotes;
  NSEnumerator  *enumerator;
  NSDictionary  *note;

  objectNotes = [self _getUnrenderedNotesForKey:_objectId];
  enumerator = [objectNotes objectEnumerator];
  while ((note = [enumerator nextObject]) != nil) {
    [self _deleteNote:_objectId withCommit:NO];
   } // End while ((note = [enumerator nextObject]) != nil)
  return nil;
} /* end _deleteAllNotesFromObject */

/* Insert a note attached to the specified object,  that object must be
  an appointment, a project, or a company. */
-(id)_insertNote:(id)_objectId
       withTitle:(id)_title
     withContent:(id)_content {
  id                                             entityName;

  entityName = [self _getEntityNameForPKey:_objectId];
  if ([entityName isEqualToString:@"Date"]) {
    return [self _insertNote:_content 
                   withTitle:_title
                  forProject:nil
              forAppointment: _objectId
                  forCompany:nil
                  withCommit:0];
  } else if ([entityName isEqualToString:@"Project"]) {
      return [self _insertNote:_content  
                     withTitle:_title
                    forProject:_objectId
                forAppointment:nil
                    forCompany:nil
                    withCommit:0];
  } else if (([entityName isEqualToString:@"Person"]) || 
             ([entityName isEqualToString:@"Enterprise"])) {
      return [self _insertNote:_content
                     withTitle:_title
                    forProject:nil
                forAppointment:nil
                    forCompany:_objectId
                    withCommit:0];
  }
  return [NSException exceptionWithHTTPStatus:500
            reason:@"Cannot attach note to this object type"];
} /* end _insertNote */

-(id)_insertNote:(id)_content
       withTitle:(id)_title
      forProject:(id)_projectId 
  forAppointment:(id)_dateId 
      forCompany:(id)_companyId 
      withCommit:(BOOL)_doCommit {
  id                    note, dateId, projectId, companyId;
  NSNumber             *accountId;

  accountId =[self _getCompanyId];
  dateId = (_dateId != nil) ? _dateId : (id)[EONull null];
  projectId = (_projectId != nil) ? _projectId : (id)[EONull null];
  companyId = (_companyId != nil) ? _companyId : (id)[EONull null];
  if ([self isDebug])
    [self logWithFormat:@"Inserting note on  %@,%@,%@", dateId, projectId, companyId];
  note = [NSDictionary dictionaryWithObjectsAndKeys:
            dateId, @"dateId",
            projectId, @"projectId",
            companyId, @"companyId",
            accountId, @"firstOwnerId",
            accountId, @"currentOwnerId", 
            _title, @"title",
            _content, @"fileContent",
            [NSNumber numberWithBool:NO], @"isFolder",
            [NSNumber numberWithInt:[_content length]], @"fileSize",
            nil];
  note = [[self getCTX] runCommand:@"note::new" arguments:note];
  if (note == nil)
      return [NSException exceptionWithHTTPStatus:500
                          reason:@"Note creation failed"];
  if (_doCommit)
    [[self getCTX] commit];
  [[self getCTX] runCommand:@"note::get-attachment-name",
                            @"note", note,
                            nil];
  return [self _renderNote:note];
} /* end _insertNote */

/* Delete the specified note */
- (id)_deleteNote:(id)_noteId withCommit:(BOOL)_doCommit {
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

  if (_doCommit)
    [[self getCTX] commit];
  return [NSNumber numberWithBool:YES];
} /* end _deleteNote */

/* Update the title and content of the specified note 
   TODO: Does Logic auto update last modified time & user ? */
-(id)_updateNote:(id)_noteId
       withTitle:(id)_title
     withContent:(id)_content {
  id                                             note;
  NSString                                      *content;

  note = [[[self getCTX] runCommand:@"note::get",
             @"documentId", _noteId,
             nil] lastObject];
  [[self getCTX] runCommand:@"note::get-attachment-name",
                            @"note", note,
                            nil];
  content = [NSString stringWithContentsOfFile:[note valueForKey:@"attachmentName"]];
  if (![content isEqualTo:_content]) {
    [note takeValue:[NSNumber numberWithInt:[_content length]]
             forKey:@"fileSize"];
    [note takeValue:_content forKey:@"fileContent"];
    [note takeValue:_title forKey:@"title"];
    [[self getCTX] runCommand:@"note::set",
       @"object", note,
       @"fileContent", _content, nil];
    note = [[[self getCTX] runCommand:@"note::get",
               @"documentId", _noteId,
               nil] lastObject];
  }
  return [self _renderNote:note];
} /* end _updateNote */

@end /* End zOGIAction(Note) */
