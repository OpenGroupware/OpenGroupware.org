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

#ifndef __zOGIAction_Resource_H__
#define __zOGIAction_Resource_H__

#include "zOGIAction.h"

@interface zOGIAction(Resource)
-(id)_getResourceByName:(NSString *)_arg;
-(id)_getResourcesForKeys:(id)_arg withDetail:(NSNumber *)_detail;
-(NSDictionary *)_getUnrenderedResourceForKey:(id)_arg;
-(id)_getResourceForKey:(id)_arg withDetail:(NSNumber *)_detail;
-(NSArray *)_renderNamedResources:(NSArray *)_names;
-(id)_searchForResources:(NSDictionary *)_query 
              withDetail:(NSNumber *)_detail
               withFlags:(NSDictionary *)_flags;
@end

#endif /* __zOGIAction_Resource_H__ */
