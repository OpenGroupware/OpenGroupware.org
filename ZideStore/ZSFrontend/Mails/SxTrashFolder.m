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
// $Id: SxTrashFolder.m 1 2004-08-20 11:17:52Z znek $

#include "SxTrashFolder.h"
#include "common.h"

@implementation SxTrashFolder

- (NSString *)outlookFolderClass {
  return @"IPF.Trash";
}

/* messages */

- (int)zlGenerationCount {
  /* trash folders have no messages and therefore never change */
  return 1;
}
- (id)getIDsAndVersionsAction:(id)_ctx {
  WOResponse *response = [(WOContext *)_ctx response];
  [response setStatus:200]; /* OK */
  [response setHeader:@"text/plain" forKey:@"content-type"];
  return response;
}
- (int)cdoContentCount {
  return 0;
}

/* actions */

- (id)davCreateObject:(NSString *)_name properties:(NSDictionary *)_props 
  inContext:(id)_ctx
{
  [self logWithFormat:@"fake successful creation in Trash folder ..."];
  [_ctx setObject:@"0000" forKey:@"SxNewObjectID"];
  return nil; /* nil says, everything's OK */  
}

@end /* SxTrashFolder */

@implementation SxInboxFolder
@end

@implementation SxViewsFolder
@end

@implementation SxCommonViewsFolder
@end
