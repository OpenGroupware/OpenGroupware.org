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
// $Id$

#ifndef __LSLogic_LSAddress_LSAddressConverterCommand_H__
#define __LSLogic_LSAddress_LSAddressConverterCommand_H__

#include <LSFoundation/LSBaseCommand.h>

@class NSString, NSArray, NSDictionary, NSNumber;

@interface LSAddressConverterCommand : LSBaseCommand
{
  NSString     *type;
  NSString     *kind;
  NSArray      *ids;
  NSDictionary *labels;
  NSNumber     *forkExport;
}
@end

#endif /* __LSLogic_LSAddress_LSAddressConverterCommand_H__ */
