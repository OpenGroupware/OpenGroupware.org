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

#include "LSAddressConverterCommand.h"
#include "common.h"
#include <NGObjWeb/WOResponse.h>

// TODO: this class uses WOResponse ! either move the class to the UI or
//       split the functionality

/*
  Note: this can also trigger external Python programs for export. Is this
        actually used somwhere? (forkExport)
*/

@implementation LSAddressConverterCommand

- (void)dealloc {
  [self->type       release];
  [self->kind       release];
  [self->ids        release];
  [self->labels     release];
  [self->forkExport release];
  [super dealloc];
}

/* command methods */

- (void)_prepareForExecutionInContext:(id)_context {
  [super _prepareForExecutionInContext:_context];
  self->forkExport = [[NSNumber numberWithBool:NO] retain];
}

- (NSData *)_buildConverterDataOfType:(NSString *)_type
  kind:(NSString *)_kind
  primaryKeys:(NSArray *)_pkeys
  labels:(NSDictionary *)_labels
  entityName:(NSString *)_ename
  inContext:(id)_context
{
  NSData *data;
  
  data = LSRunCommandV(_context, @"address", @"build-converter-data",
		       @"type",   _type,
		       @"kind",   _kind,
		       @"ids",    _pkeys,
		       @"labels", _labels,
		       @"entityName", _ename,
		       nil);
  return data;
}

/* optional support for forking converter processes */

- (NSData *)_buildDataWithForkedProcessInContext:(id)_context
  stringEncoding:(NSStringEncoding)enc
  entityName:(NSString *)entityName
{
  NSData       *data;
  NSTask       *task;
  NSPipe       *outPipe, *inPipe;
  NSArray      *args    = nil;
  NSFileHandle *handle  = nil;
  id           account;
    
  NSAssert(((self->ids != nil) || ([self->ids count] > 0)),
	   @"no ids were set");
  
  account = [_context valueForKey:LSAccountKey];
  task    = [[NSTask alloc] init];
  outPipe = [NSPipe pipe];
  inPipe  = [NSPipe pipe];

  handle = [inPipe fileHandleForWriting];
  args   = [NSArray arrayWithObjects:
                      [[_context valueForKey:LSUserDefaultsKey]
                                 valueForKey:@"BuildFormletterPath"],
                      [account valueForKey:@"login"],
                      [_context valueForKey:LSCryptedUserPasswordKey],
		    nil];

  [task setLaunchPath:@"python"];    
  [task setArguments:args];
  [task setStandardInput:inPipe];
  [task setStandardOutput:outPipe];    
  [task launch];

  [task release]; task = nil;
    
  [handle writeData:[entityName dataUsingEncoding:enc]];
  [handle writeData:[@"\0" dataUsingEncoding:enc]];
  [handle writeData:[self->type dataUsingEncoding:enc]];
  [handle writeData:[@"\0" dataUsingEncoding:enc]];
  [handle writeData:[self->kind dataUsingEncoding:enc]];
  [handle writeData:[@"\0" dataUsingEncoding:enc]];
  [handle writeData:
            [[[self->ids map:@selector(valueForKey:)
                        with:@"companyId"] componentsJoinedByString:@" "]
                         dataUsingEncoding:enc]];
  [handle writeData:[@"\0" dataUsingEncoding:enc]];

  { /* Got format */
      NSDictionary    *dict       = nil;
      NSMutableString *str        = nil;
      NSEnumerator    *enumerator = nil;
      NSDictionary    *obj        = nil;
      NSString        *format     = nil;

      format = [[NSString alloc] initWithFormat:@"LS%@FormLetter", entityName];
      dict = [[[_context valueForKey:LSUserDefaultsKey]
                         valueForKey:format] valueForKey:self->kind];
      [format release]; format = nil;
        
      str = [[NSMutableString alloc] init];

      enumerator = [dict objectEnumerator];

      while ((obj = [enumerator nextObject])) {
        [str appendString:[obj objectForKey:@"key"]];
        [str appendString:@"\0"];
        [str appendString:[obj objectForKey:@"suffix"]];
        [str appendString:@"\0"];             
      }
      [handle writeData:[str dataUsingEncoding:enc]];  
      [str release]; str = nil;
  }
  [handle closeFile];

  handle = [outPipe fileHandleForReading];   
  data   = [handle readDataToEndOfFile];
  [handle closeFile];
  
  return data;
}

- (void)_executeInContext:(id)_context {
  // TODO: this does not really belong here
  NSDictionary *contentTypes = nil;
  id           response      = nil;
  NSData       *data         = nil;
  NSStringEncoding enc;
  NSString     *entityName;
  
  enc = [NSString defaultCStringEncoding];

  [self assert:(self->ids != nil) reason:@"no ids set"];

  contentTypes = [[(NSUserDefaults *)[_context valueForKey:LSUserDefaultsKey]
                             dictionaryForKey:@"ConverterAttributes"]
                             objectForKey:@"contentTypes"];

  entityName = 
    [(EOEntity *)[[self->ids lastObject] valueForKey:@"entity"] name];
  if (![entityName isNotEmpty] && [self->ids isNotEmpty]) {
    NSNumber *cId;
    
    cId = [[self->ids lastObject] valueForKey:@"companyId"];
    entityName = 
      [[[_context typeManager] globalIDForPrimaryKey:cId] entityName];
  }

  [self assert:(contentTypes != nil)
        reason:@"no contentTypes-dictionary was set"];

  // TODO: do we really need to refer WOResponse here?
  response = [[NSClassFromString(@"WOResponse") alloc] init];
  [response setStatus:200 /* OK */];
  {
    NSString *t;
    
    if ((t = [contentTypes valueForKey:self->type]) == nil)
      t = @"text/plain";
    
    [response setHeader:t forKey:@"content-type"];
  }

  [response setHeader:@"identity" forKey:@"content-encoding"];

  if (![self->forkExport boolValue]) { // default behaviour (no fork)
    data = [self _buildConverterDataOfType:self->type
		 kind:self->kind
		 primaryKeys:
		   [self->ids map:@selector(valueForKey:) with:@"companyId"]
		 labels:self->labels
		 entityName:entityName
		 inContext:_context];
  }
  else {
    data = [self _buildDataWithForkedProcessInContext:_context
		 stringEncoding:enc
		 entityName:entityName];
  }
  
  [response setContent:data];
  [self setReturnValue:response];
  [response release];
}

/* accessors */

- (void)setForkExport:(NSNumber *)_forkExport {
  ASSIGNCOPY(self->forkExport, _forkExport);
}
- (NSNumber *)forkExport {
  return self->forkExport;
}

- (void)setType:(NSString *)_type {
  ASSIGNCOPY(self->type, _type);
}
- (NSString *)type {
  return self->type;
}

- (void)setKind:(NSString *)_kind {
  ASSIGNCOPY(self->kind, _kind);
}
- (NSString *)kind {
  return self->kind;
}

- (void)setIds:(NSArray *)_ids {
  ASSIGNCOPY(self->ids, _ids);
}
- (NSArray *)ids {
  return self->ids;
}

- (void)setLabels:(NSDictionary *)_dict {
  ASSIGN(self->labels, _dict);
}
- (NSDictionary *)labels {
  return self->labels;
}

/* key/value coding */

- (void)takeValue:(id)_value forKey:(NSString *)_key {
  if ([_key isEqualToString:@"type"])
    [self setType:_value];
  else if ([_key isEqualToString:@"ids"])
    [self setIds:_value];
  else if ([_key isEqualToString:@"labels"])
    [self setLabels:_value];
  else if ([_key isEqualToString:@"kind"])
    [self setKind:_value];
  else if ([_key isEqualToString:@"forkExport"])
    [self setForkExport:_value];
  else
    [super takeValue:_value forKey:_key];
}

- (id)valueForKey:(NSString *)_key {
  // TODO: no get accessors?
  return [super valueForKey:_key];
}

@end /* LSAddressConverterCommand */
