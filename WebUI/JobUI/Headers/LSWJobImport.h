/*
  Copyright (C) 2000-2004 SKYRIX Software AG

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

#ifndef __OGo_JobUI_LSWJobImport_H__
#define __OGo_JobUI_LSWJobImport_H__

#include <OGoFoundation/LSWContentPage.h>

@class NSData, NSMutableArray, NSMutableDictionary, NSArray, NSString, NSNumber;

@interface LSWJobImport : LSWContentPage
{
@protected
  NSData              *data;
  NSMutableArray      *jobs;
  NSMutableDictionary *errorReport;
  id                  job;
  id                  project;
  int                 start;
  NSDictionary        *selectedAttribute;
  NSArray             *parentJobList;
  id                  item;
  id                  selectedParentJob;
  BOOL                oneControlJob;
  NSString            *importAnnotation;
  int                 count;
  int                 errorCount;  
  BOOL                showErrors;
  NSNumber            *currentErrorName;
  NSString            *currentError;
  BOOL                importField;
}


- (void)_setImportAnnotation:(NSArray *)_import;

- (id)import;
- (id)resumeSelected;
- (id)resumeAll;
- (id)viewExecutant;
- (id)viewProject;
- (id)editJob;
- (id)setImportAnnotation;

@end

#endif /* __OGo_JobUI_LSWJobImport_H__ */
