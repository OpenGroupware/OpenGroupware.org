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

#include "common.h"
#include "LSWImapMailFolderEditor.h"

@interface LSWImapMailFolderEditor(PrivateMethodes)
- (BOOL)checkConstraints;
@end

@implementation LSWImapMailFolderEditor

- (void)dealloc {
  [self->folderName release];
  [super dealloc];
}

/* activation */

- (BOOL)prepareForActivationCommand:(NSString *)_command
  type:(NGMimeType *)_type
  configuration:(NSDictionary *)_cmdCfg
{
  if (self->folder != nil) {
    [self->folder release];
    self->folder = nil;
  }
  
  self->folder = [[[self session] getTransferObject] retain];

  if (self->folderName != nil) {
    [self->folderName release];
    self->folderName = nil;
  }
  
  if ([_command hasSuffix:@"new"]) {
    self->folderName = @"";
    self->isNew      = YES;
  }
  else if ([_command hasSuffix:@"edit"]) {
    self->folderName = [[(NGImap4Folder *)self->folder name] copy];
    self->isNew      = NO;
  }
  else {
    [self logWithFormat:@"WARNING: unknown command <%@>", _command];
    return NO;
  }
  return YES;
}

- (void)_processSaveException:(NSException *)_exception {
  if (_exception == nil)
    return;
  
  if ([_exception isKindOfClass:[NGImap4ResponseException class]]) {
    NSString *rawResp = @"RawResponse";
    NSString *respRes = @"ResponseResult";
    NSString *descr   = @"description";
    NSString *str;
    
    // TODO: not too good ..., should have some accessor for that
    str = [(NSDictionary *)[(NSDictionary *)[[_exception userInfo]
                         objectForKey:rawResp]
                         objectForKey:respRes]
                         objectForKey:descr];
        
    [self setErrorString:[[self labels] valueForKey:str]];
  }
  else if ([_exception isKindOfClass:[NGImap4Exception class]]) {
    [self setErrorString:[[self labels]
                                    valueForKey:[_exception reason]]];
  }
  else {
    [self logWithFormat:
	    @"ERROR(%s): save failed with reason %@", __PRETTY_FUNCTION__,
    	    _exception];
    [self setErrorString:[[self labels] valueForKey:@"SaveFolderFailed"]];
  }
}

- (id)save {
  NSString *del;
  
  del = [[[(NGImap4Folder *)self->folder context] client] delimiter];
  
  if ([self->folderName rangeOfString:del].length> 0) {
    NSString *s;
    
    s = [[self labels] valueForKey:@"ItsNotAllowedToUseChar"];
    s = [[NSString alloc] initWithFormat:del];
    [self setErrorString:s];
    [s release];
    return nil;
  }
  
  [self->folder resetLastException];
  if (self->isNew)
    [self->folder createSubFolderWithName:self->folderName];
  else
    [self->folder renameTo:self->folderName];    
  
  [self setErrorString:nil];

  [self _processSaveException:[self->folder lastException]];
  
  if ([self errorString] == nil)
    [self leavePage];
  
  return nil;
}

- (id)cancel {
  [self leavePage];
  return nil;
}

/* accessors */

- (void)setFolderName:(NSString *)_folderName {
  ASSIGNCOPY(self->folderName, _folderName);
}
- (NSString *)folderName {
  return self->folderName;
}

@end /* LSWImapMailFolderEditor */
