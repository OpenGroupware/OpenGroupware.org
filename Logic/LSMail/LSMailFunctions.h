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
//$Id$

#ifndef __LSLogic_LSMail_LSMailFunctions_H__
#define __LSLogic_LSMail_LSMailFunctions_H__

#import "common.h"

typedef NSString*(*__LSMail_getIdExpr)(id,id,NSArray*,NSNumber*);

NSString *_getExprMoveEmails(id,id,NSArray*,NSNumber*);
NSString *_getExprCheckContent(id,id,NSArray*,NSNumber*);
NSString *_getExprDeleteEmails(id,id,NSArray*,NSNumber*);
NSString *_getExprDeleteContent(id,id,NSArray*,NSNumber*);
NSString *_getExprDeleteFolder(id,id,NSArray*,NSNumber*);
NSString *_getExprEmailForFolders(id,id,NSArray*,NSNumber*);
NSString *_getExprFolderForParentFolders(id,id,NSArray*,NSNumber*);
NSArray *_executeIdQueryWith(id,id,__LSMail_getIdExpr,NSArray*,NSNumber*);
NSArray *_getAllSubFolders(id,id,NSNumber*);


#endif // __LSLogic_LSMail_LSMailFunctions_H__

