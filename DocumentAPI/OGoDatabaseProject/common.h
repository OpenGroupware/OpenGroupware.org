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

#ifndef __libSkyProject_common_H__
#define __libSkyProject_common_H__

#import <Foundation/Foundation.h>

#include <EOControl/EOControl.h>
#include <NGExtensions/NGExtensions.h>
#include <NGExtensions/EOQualifier+CtxEval.h>
#include <NGExtensions/NGFileFolderInfoDataSource.h>
#include <GDLAccess/GDLAccess.h>

#include <LSFoundation/OGoContextManager.h>
#include <LSFoundation/LSFoundation.h>
#include <LSFoundation/LSTypeManager.h>
#include <LSFoundation/OGoContextSession.h>


#ifndef SEL_EQ
#  if !GNU_RUNTIME
#    define SEL_EQ(__A__,__B__) (__A__==__B__?YES:NO)
#  else
#    include <objc/objc-api.h>
#    define SEL_EQ(__A__,__B__) sel_eq(__A__,__B__)
#  endif
#endif

#  ifndef ASSIGN_IFNOT_EQUAL
#    define ASSIGN_IF_NOT_EQUAL(_obj_, _val_, _flag_) {               \
       if (((id)_val_ != (id)_obj_) && (![_obj_ isEqual:_val_])) {    \
         _flag_ = YES;                                                \
         if (_val_) [_val_ retain];                                   \
         if (_obj_) [_obj_ release];                                  \
         _obj_ = (id)_val_;                                           \
       }                                                              \
     }
#  endif

#  ifndef ASSIGNCOPY_IFNOT_EQUAL
#    define ASSIGNCOPY_IFNOT_EQUAL(_obj_, _val_, _flag_) {            \
       if (((id)_val_ != (id)_obj_) && (![_obj_ isEqual:_val_])) {    \
         _flag_ = YES;                                                \
         if (_val_) _val_ = [_val_ copy];                             \
         if (_obj_) [_obj_ release];                                  \
         _obj_ = (id)_val_;                                           \
       }                                                              \
     }
#  endif

#endif /* __libSkyProject_common_H__ */
