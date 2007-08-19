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

#ifndef __zOGIAction_Assignment_H__
#define __zOGIAction_Assignment_H__

#include "zOGIAction.h"

@interface zOGIAction(Assignment)

-(id)_renderAssignment:(id)_objectId
                source:(id)_source 
                target:(id)_target 
                    eo:(id)_eo;
-(id)_getCompanyAssignments:(id)_company 
                        key:(NSString *)_key;
-(NSException *)_saveCompanyAssignments:(NSArray *)_assignments
                               objectId:(id)_objectId
                                    key:(NSString *)_key
                           targetEntity:(NSString *)_targetEntity
                              targetKey:(NSString *)_targetKey;

@end

#endif /* __zOGIAction_Assignment_H__ */
