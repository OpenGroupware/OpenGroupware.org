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

#ifndef __SkyXmlRpcServer_EOControl_XmlRpcDirectAction_H__
#define __SkyXmlRpcServer_EOControl_XmlRpcDirectAction_H__

#include <EOControl/EOFetchSpecification.h>
#include <EOControl/EOSortOrdering.h>
#include <EOControl/EOQualifier.h>

@interface EOFetchSpecification(XmlRpcDirectAction)

- (id)initWithBaseValue:(id)_baseValue;

@end /* EOFetchSpecification(XmlRpcDirectAction) */

@interface EOSortOrdering(XmlRpcDirectAction)

- (id)initWithBaseValue:(id)_baseValue;

@end /* EOFetchSpecification(XmlRpcDirectAction) */

@interface EOQualifier(XmlRpcDirectAction)

+ (EOQualifier *)qualifierToMatchAllValues:(NSDictionary *)_values
  selector:(SEL)_sel;

@end /* EOQualifier(XmlRpcDirectAction */

#endif /* __SkyXmlRpcServer_EOControl_XmlRpcDirectAction_H__ */
