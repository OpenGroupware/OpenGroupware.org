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

#ifndef __LSWebInterface_LSWMail_LSWMailFilterEditor_H__
#define __LSWebInterface_LSWMail_LSWMailFilterEditor_H__

#import <OGoFoundation/LSWContentPage.h>


@interface LSWMailFilterEditor : LSWContentPage
{
  NSMutableArray *filters;
@protected
  BOOL isInNewMode;
  NSMutableDictionary *filter;
  NSMutableDictionary *entry;
  NSMutableArray      *filterPos;
  NSMutableArray      *allFilters;
  id item;
  int index;
  //  NSDictionary *headerLabels;
  //  NSDictionary *filterKindLabels;
  int oldFilterPos;
  NSArray *matchList;
  id folder;
  NSMutableDictionary *folders;
}

- (BOOL)prepareForActivationCommand:(NSString *)_command
  type:(NGMimeType *)_type
  configuration:(NSDictionary *)_cmdCfg;

@end

#endif /* __LSWebInterface_LSWMail_LSWMailFilterEditor_H__ */
