/*
  Copyright (C) 2006 Helge Hess

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

#ifndef __LSLogic_LSSearch_OGoSQLGenerator_H__
#define __LSLogic_LSSearch_OGoSQLGenerator_H__

#import <Foundation/NSObject.h>

/*
  OGoSQLGenerator

  TODO: document
  
  This really belongs into GDL, but its already quite hackish ... Its more or
  less the same thing like EOSQLExpression. Plus some OGo specific datamodel
  things.
  
  Features:
  - globalID/gid/pkey/primaryKey special keys
  - comment special key (eg CompanyInfo)
  - CSV attributes (keywords)
  - extra attributes (company_value and obj_property)
*/

@class NSMutableString, NSMutableDictionary;
@class EOQualifier;
@class EOAdaptor, EOModel, EOEntity;

@interface OGoSQLGenerator : NSObject
{
  EOModel             *model;
  EOEntity            *entity;
  EOAdaptor           *adaptor;
  NSMutableString     *sql;
  NSMutableDictionary *prefixToAlias;
  NSMutableDictionary *prefixToEntity;
}

/* qualifier generation */

- (void)appendQualifier:(EOQualifier *)_qualifier;

@end

#endif /* __LSLogic_LSSearch_OGoSQLGenerator_H__ */
