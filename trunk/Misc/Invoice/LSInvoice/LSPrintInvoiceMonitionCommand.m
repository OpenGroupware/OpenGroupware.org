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

#include <LSFoundation/LSDBObjectBaseCommand.h>

/*
  Parameter:
    object/debitor    - debitor ('enterprise' object)
    invoices          - array of invoices which are printed
    printout          - NSData - object of the printout

*/

@class NSArray, NSData;

@interface LSPrintInvoiceMonitionCommand : LSDBObjectBaseCommand
{
  NSArray *invoices;
  NSData  *printout;
}

@end

#include "common.h"

@implementation LSPrintInvoiceMonitionCommand

#if !LIB_FOUNDATION_BOEHM_GC
- (void)dealloc {
  RELEASE(self->invoices);
  RELEASE(self->printout);
  [super dealloc];
}
#endif

// accessors

- (void)setInvoices:(NSArray*)_invoices {
  ASSIGN(self->invoices, _invoices);
}
- (NSArray*)invoices {
  return self->invoices;
}

- (void)setPrintout:(NSData*)_printout {
  ASSIGN(self->printout,_printout);
}
- (NSData*)printout {
  return self->printout;
}

// key/value coding

- (void)takeValue:(id)_val forKey:(id)_key {
  if ([_key isEqualToString:@"invoices"]) {
    [self setInvoices:_val];
    return;
  }
  if ([_key isEqualToString:@"printout"]) {
    [self setPrintout:_val];
    return;
  }
  if ([_key isEqualToString:@"debitor"]) {
    [self setObject:_val];
    return;
  }
  [super takeValue:_val forKey:_key];
}

-(id)valueForKey:(id)_key {
  if ([_key isEqualToString:@"invoices"]) {
    return [self invoices];
  }
  if ([_key isEqualToString:@"printout"]) {
    return [self printout];
  }
  if ([_key isEqualToString:@"debitor"]) {
    return [self object];
  }
  return [super valueForKey:_key];
}

- (void)_prepareForExecutionInContext:(id)_context {
  id           account;
  NSEnumerator *teamEnum;
  id           team;
  BOOL         access = NO;
  
  account = [_context valueForKey:LSAccountKey];
  teamEnum =
    [LSRunCommandV(_context, @"account", @"teams",
                  @"account", account,
                  @"returnType", intObj(LSDBReturnType_ManyObjects),
                  nil) objectEnumerator];
  while ((team = [teamEnum nextObject])) {
    if ([[team valueForKey:@"login"] isEqualToString:INVOICES_TEAM]) {
      access = YES;
    }
  }
  [self assert:access
        reason:@"You have no permission for doing that!"];
}

- (id)_getInvoiceProjectInContex:(id)_context {
  id debitor = [self object];
  id projects =
    LSRunCommandV(_context,
                  @"enterprise", @"get-projects",
                  @"enterprise", debitor,
                  @"returnType", intObj(LSDBReturnType_ManyObjects),
                  nil);
  NSEnumerator *pjEnum = [projects objectEnumerator];
  id project;
  id kind;

  while ((project = [pjEnum nextObject])) {
    kind = [project valueForKey:@"kind"];
    if ((kind != nil) &&
        ([kind isEqualToString:INVOICE_PROJECT_KIND]))
      return project;
  }
  return nil;
}

- (id)_getInvoicesTeamInContext:(id)_context {
  id team =   LSRunCommandV(_context,
                            @"team",  @"get",
                            @"login", INVOICES_TEAM,
                            nil);
  return [team lastObject];
}

- (id)_createInvoiceProjectInContex:(id)_context
      withTeam: (NSNumber*) _teamId
{
  id debitor = [self object];
  id name    = INVOICE_PROJECT_NAME;
  name = [name stringByAppendingString:
               [debitor valueForKey:@"description"]];
  return
    LSRunCommandV(_context,
                  @"project",   @"new",
                  @"ownerId",   [NSNumber numberWithInt:ROOT_ID],
                  @"teamId",    _teamId,
                  @"name",      name,
                  @"kind",      INVOICE_PROJECT_KIND,
                  @"startDate", [NSCalendarDate date],
                  @"endDate",   [NSCalendarDate dateWithString:@"2030-01-01"
                                                calendarFormat:@"%Y-%m-%d"],
                  @"accounts",  [NSArray arrayWithObject:debitor],
                  @"isFake",    [NSNumber numberWithBool:NO],
                  nil);
}

- (id)_getInvoiceFolderInProject:(id)_project
                     withContext:(id)_context {
  NSCalendarDate *date  = [NSCalendarDate date];
  NSString *yearString  = [date descriptionWithCalendarFormat:@"%Y"];
  NSString *monthString = [date descriptionWithCalendarFormat:@"%m"];
  id rootDoc;
  id folderEnum;
  id folder = nil;

  LSRunCommandV(_context,
                @"project", @"get-root-document",
                @"object", _project,
                @"relationKey", @"Doc",
                nil);
  rootDoc = [_project valueForKey:@"Doc"];
  //YearFolder ...
  folderEnum = [[rootDoc valueForKey:@"toDoc"] objectEnumerator];
  while ((folder = [folderEnum nextObject]) &&
         (!(
            ([[folder valueForKey:@"isFolder"] boolValue]) &&
            ([[folder valueForKey:@"title"] isEqualToString: yearString])
            )
          ))
    {}
  if (folder == nil) {
    folder =
      LSRunCommandV(_context,
                    @"doc",      @"new",
                    @"folder",   rootDoc,
                    @"project",  _project,
                    @"isFolder", [NSNumber numberWithBool:YES],
                    @"title",    yearString,
                    nil);
  }
  //MonthFolder ...
  rootDoc = folder;
  folder  = nil;
  folderEnum = [[rootDoc valueForKey:@"toDoc"] objectEnumerator];
  while ((folder = [folderEnum nextObject]) &&
         (!(
            ([[folder valueForKey:@"isFolder"] boolValue]) &&
            ([[folder valueForKey:@"title"] isEqualToString: monthString])
            )
          ))
    {}
  if (folder == nil) {
    folder = 
      LSRunCommandV(_context,
                    @"doc",      @"new",
                    @"folder",   rootDoc,
                    @"project",  _project,
                    @"isFolder", [NSNumber numberWithBool:YES],
                    @"title",    monthString,
                    nil);
  }
  return folder;
}

- (id)_savePrintoutInContext:(id)_context {
  id folder;
  id project = [self _getInvoiceProjectInContex: _context];
  id title   = @"Monition";
  id team    = [self _getInvoicesTeamInContext: _context];
  
  if (project == nil)
    project = [self _createInvoiceProjectInContex: _context
                    withTeam: [team valueForKey:@"companyId"]];
  folder = [self _getInvoiceFolderInProject:project withContext:_context];
  
  return LSRunCommandV(_context,
                       @"doc",         @"new",
                       @"folder",      folder,
                       @"project",     project,
                       @"isFolder",    [NSNumber numberWithBool:NO],
                       @"title",       title,
                       @"data",        [self printout],
                       @"fileType",    @"txt",
                       @"autoRelease", [NSNumber numberWithBool:YES],
                       nil);
}

- (void)_executeInContext:(id)_context {
  id            document;
  id            account;
  id            invoice;
  id            debitor;
  NSEnumerator *invoiceEnum;

  document = [self _savePrintoutInContext:_context];
  debitor  = [self object];

  account =
    LSRunCommandV(_context,
                  @"invoiceaccount", @"get",
                  @"companyId", [debitor valueForKey:@"companyId"],
                  nil);
  account = [account lastObject];
  if (account == nil) {
    account =
      LSRunCommandV(_context,
                    @"enterprise", @"create-invoiceaccount",
                    @"object", debitor,
                    nil);
  }

  invoiceEnum = [self->invoices objectEnumerator];

  while ((invoice = [invoiceEnum nextObject])) {
    LSRunCommandV(_context,
                  @"invoiceaction", @"new",
                  @"accountId",     [account valueForKey:@"invoiceAccountId"],
                  @"invoiceId",     [invoice valueForKey:@"invoiceId"],
                  @"documentId",    [document valueForKey:@"documentId"],
                  @"kind",          @"05_monition_printout",
                  @"logText",       @"Monition printed",
                  nil);
  }
  
  [self setReturnValue:debitor];
}

@end
