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

#import "common.h"
#import "LSPrintInvoiceCommand.h"

@interface LSPrintInvoiceCommand(PrivateMethods)
- (BOOL)_checkDirAndCreateIfNecessaryAtPath:(NSString *)_path;
- (NSData *)printout;
@end

@implementation LSPrintInvoiceCommand

#if !LIB_FOUNDATION_BOEHM_GC
- (void)dealloc {
  RELEASE(self->printout);
  [super dealloc];
}
#endif

- (void)_prepareForExecutionInContext:(id)_context {
  NSString     *status, *no;
  NSEnumerator *teamEnum;
  id           account, obj, team;
  BOOL         access = NO;

  obj      = [self object];
  status   = [obj valueForKey:@"status"];
  no       = [obj valueForKey:@"invoiceNr"];
  account  = [_context valueForKey:LSAccountKey];
  teamEnum = [LSRunCommandV(_context, @"account", @"teams",
                            @"account", account,
                            @"returnType", intObj(LSDBReturnType_ManyObjects),
                            nil)
                           objectEnumerator];
  
  while ((team = [teamEnum nextObject])) {
    if ([[team valueForKey:@"login"] isEqualToString:@"invoices"]) {
      access = YES;
      break;
    }
  }
  [self assert:access reason:@"You have no permission for doing that!"];
  [self assert: ([self printout] != nil) reason:@"Printout is *nil*"];
  
  [self assert:[status isEqualToString:@"00_created"]
        format:
        @"\nInvoice %@ can't be marked as printed in this status!"
        @"\nRechnung %@ kann in diesem Status nicht als gedruckt markiert"
        @" werden!", no, no];

  [super _prepareForExecutionInContext:_context];
}

- (id)_getInvoiceProjectInContex:(id)_context {
  id obj = [self object];
  id debitor = [obj valueForKey:@"debitor"];
  id projects =
    LSRunCommandV(_context,
                  @"enterprise", @"get-projects",
                  @"enterprise", debitor,
                  @"returnType", intObj(LSDBReturnType_ManyObjects),
                  nil);
  NSEnumerator *pjEnum = [projects objectEnumerator];
  id project;

  while ((project = [pjEnum nextObject])) {
    if (([project valueForKey:@"kind"] != nil) &&
        ([[project valueForKey:@"kind"]
                   isEqualToString:INVOICE_PROJECT_KIND]))
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
  id debitor = [[self object] valueForKey:@"debitor"];
  id name    = INVOICE_PROJECT_NAME;
  name = [name stringByAppendingString:
               [debitor valueForKey:@"description"]];
  return
    LSRunCommandV(_context,
                  @"project", @"new",
                  @"ownerId", [NSNumber numberWithInt:ROOT_ID],
                  @"teamId", _teamId,
                  @"name", name,
                  @"kind", INVOICE_PROJECT_KIND,
                  @"startDate", [NSCalendarDate date],
                  @"endDate", [NSCalendarDate dateWithString:@"2030-01-01"
                                              calendarFormat:@"%Y-%m-%d"],
                  @"accounts", [NSArray arrayWithObject:debitor],
                  @"isFake", [NSNumber numberWithBool:NO],
                  nil);
}

- (id)_getInvoiceFolderInProject:(id)_project
                     withContext:(id)_context {
  NSCalendarDate *date        = [[self object] valueForKey:@"invoiceDate"];
  NSString       *yearString  = [date descriptionWithCalendarFormat:@"%Y"];
  NSString       *monthString = [date descriptionWithCalendarFormat:@"%m"];
  id             rootDoc;
  id             folderEnum;
  id             folder = nil;

  LSRunCommandV(_context,
                @"project",     @"get-root-document",
                @"object",      _project,
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
  id title   = [[self object] valueForKey:@"invoiceNr"];
  id team    = [self _getInvoicesTeamInContext: _context];
  
  if (project == nil)
    project = [self _createInvoiceProjectInContex: _context
                    withTeam: [team valueForKey:@"companyId"]];
  folder = [self _getInvoiceFolderInProject: project withContext: _context];
  
  return LSRunCommandV(_context,
                       @"doc",         @"new",
                       @"folder",      folder,
                       @"project",     project,
                       @"isFolder",    [NSNumber numberWithBool:NO],
                       @"title",       title,
                       @"data",        self->printout,
                       @"fileType",    @"txt",
                       @"autoRelease", [NSNumber numberWithBool:YES],
                       nil);
}

- (void)_executeInContext:(id)_context {
  id account;
  id debitor;  
  id invoice;
  id document;
  id value;

  document = [self _savePrintoutInContext:_context];
  [[self object] takeValue:@"05_printed" forKey:@"status"];
  PREPAREINVOICEMONEY([self object]);
  [super _executeInContext:_context];

  invoice = [self object];
  debitor =
    LSRunCommandV(_context,
                  @"enterprise", @"get",
                  @"companyId", [invoice valueForKey:@"debitorId"],
                  nil);
  debitor = [debitor lastObject];
  account =
    LSRunCommandV(_context,
                  @"invoiceaccount", @"get",
                  @"companyId", [debitor valueForKey:@"companyId"],
                  nil);
  account = [account lastObject];
  // value must be negativ --> debit
  if ([[invoice valueForKey:@"kind"] isEqualToString:@"invoice_cancel"]) {
    // except it is invoice_cancel
    value = [invoice valueForKey:@"paid"];
    //value = [NSNumber numberWithDouble:([value doubleValue])];
    value = MONEY2SAVEFORNUMBER(value);
  }
  else {
    value = [invoice valueForKey:@"grossAmount"];
    value = MONEY2SAVEFORDOUBLE([value doubleValue]*(-1));
  }
  
  if ((account == nil) || (![account isNotNull])) {
    account =
      LSRunCommandV(_context,
                    @"enterprise", @"create-invoiceaccount",
                    @"object", debitor,
                    nil);
  }

  // logging printout
  LSRunCommandV(_context,
                @"invoiceaction", @"new",
                @"accountId",  [account valueForKey:@"invoiceAccountId"],
                @"invoiceId",  [invoice valueForKey:@"invoiceId"],
                @"documentId", [document valueForKey:@"documentId"],
                @"kind",       @"10_invoice_printout",
                @"logText",    @"Invoice printed",
                nil);

  // computing debit on account
  LSRunCommandV(_context,
                @"invoiceaccounting", @"new",
                @"invoiceId", [invoice valueForKey:@"invoiceId"],
                @"accountId", [account valueForKey:@"invoiceAccountId"],
                @"value",     value,
                nil);
  LSRunCommandV(_context,
                @"object",      @"add-log",
                @"logText",     @"Invoice printed",
                @"action",      @"05_changed",
                @"objectToLog", [self object],
                nil);
}

- (NSString*)entityName {
  return @"Invoice";
}

// key/value coding

- (void)setPrintout:(NSData *)_printout {
  ASSIGN(self->printout, _printout);
}
- (NSData*)printout {
  return self->printout;
}

- (void)takeValue:(id)_value forKey:(id)_key {
  if ([_key isEqualToString:@"printout"]) {
    [self setPrintout:_value];
    return;
  }
  [super takeValue:_value forKey:_key];
}

- (id)valueForKey:(id)_key {
  if ([_key isEqualToString:@"printout"])
    return [self printout];
  return [super valueForKey:_key];
}

@end
