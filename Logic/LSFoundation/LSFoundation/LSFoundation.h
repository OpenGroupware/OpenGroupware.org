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

#ifndef __LSLogic_LSFoundation_H__
#define __LSLogic_LSFoundation_H__

#if NeXT_Foundation_LIBRARY || COCOA_Foundation_LIBRARY
#  include <NGExtensions/NGExtensions.h>
#endif

#include <LSFoundation/LSDBTransaction.h>
#include <LSFoundation/LSSort.h>
#include <LSFoundation/LSSortCommand.h>
//#include <LSFoundation/LSLoginCommand.h>
#include <LSFoundation/LSArrayFilterCommand.h>
#include <LSFoundation/LSDBObjectBaseCommand.h>
#include <LSFoundation/LSDBObjectTransactionCommand.h>
#include <LSFoundation/LSDBObjectNewKeyCommand.h>
#include <LSFoundation/LSDBArrayFilterCommand.h>
#include <LSFoundation/LSDBFetchRelationCommand.h>
#include <LSFoundation/LSDBObjectNewCommand.h>
#include <LSFoundation/LSDBObjectSetCommand.h>
#include <LSFoundation/LSDBObjectGetCommand.h>
#include <LSFoundation/LSDBObjectDeleteCommand.h>
#include <LSFoundation/LSCommand.h>
#include <LSFoundation/LSCommandKeys.h>
#include <LSFoundation/LSCommandFactory.h>
#include <LSFoundation/LSDBObjectCommandException.h>
#include <LSFoundation/LSMail.h>
#include <LSFoundation/SkyObjectPropertyManager.h>
#include <LSFoundation/SkyAttributeDataSource.h>
#include <LSFoundation/SkyAccessManager.h>

#include <LSFoundation/LSCommandContext.h>
#include <LSFoundation/LSTypeManager.h>

#include <LSFoundation/EODatabaseChannel+LSAdditions.h>

#define LINK_LSFoundation \
  static void __LINK_LSFoundation(void) __attribute__((unused)); \
  static void __LINK_LSFoundation() { \
    [LSDBObjectNewCommand         self]; \
    [LSDBObjectNewKeyCommand      self]; \
    [LSDBObjectSetCommand         self]; \
    [LSDBObjectGetCommand         self]; \
    [LSDBObjectDeleteCommand      self]; \
    [LSDBObjectBaseCommand        self]; \
    [LSDBObjectTransactionCommand self]; \
    [LSDBFetchRelationCommand self];     \
    [LSSystemCtxTransferCommand   self]; \
    [LSSystemCtxLogCommand        self]; \
    [LSDBObjectCommandException   self]; \
    [LSDBTransaction              self]; \
    [LSSort                       self]; \
    [LSSortCommand                self]; \
    [LSCryptCommand               self]; \
    [LSArrayFilterCommand         self]; \
    [LSDBArrayFilterCommand       self]; \
    [LSMail                       self]; \
    [SkyObjectPropertyManager     self]; \
    [SkyAttributeDataSource       self]; \
  }

#endif /* __LSLogic_LSFoundation_H__ */
