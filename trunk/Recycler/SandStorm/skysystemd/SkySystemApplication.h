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

#ifndef __SkySystem__Application_H__
#define __SkySystem__Application_H__

#include <NGObjWeb/WOCoreApplication.h>

@class NSString, NSDictionary;
@class NGXmlRpcRequestHandler;
@class SxComponent;
@class TaskComponent;

@interface SkySystemApplication : WOCoreApplication
{
  NSDictionary *components;
  NSDictionary *configuration;
  SxComponent  *registry;
  NGXmlRpcRequestHandler *rqHandler;
}

/* accessors */

- (void)setConfiguration:(NSDictionary *)_configuration;
- (NSDictionary *)configuration;

- (TaskComponent *)componentNamed:(NSString *)_name;
- (NSDictionary *)components;

/* introspection methods */

- (NSArray *)listMethods:(NSString *)_namespace;
- (NSArray *)methodSignature:(NSString *)_method;
- (NSString *)methodHelp:(NSString *)_method;

@end

#endif /* __SkySystem__Application_H__ */
