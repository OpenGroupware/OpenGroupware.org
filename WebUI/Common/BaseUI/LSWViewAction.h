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

#ifndef __LSWFoundation_LSWDirectAction_H__
#define __LSWFoundation_LSWDirectAction_H__

#include <NGObjWeb/WODirectAction.h>

@interface LSWViewAction : WODirectAction

/* actions */

- (id<WOActionResults>)viewDocumentAction;
- (id<WOActionResults>)viewProjectAction;

- (id<WOActionResults>)viewPersonAction;
- (id<WOActionResults>)viewEnterpriseAction;
- (id<WOActionResults>)viewAppointmentAction;
- (id<WOActionResults>)viewNoteAction;
- (id<WOActionResults>)viewJobAction;

@end

#endif /* __LSWFoundation_LSWDirectAction_H__ */
