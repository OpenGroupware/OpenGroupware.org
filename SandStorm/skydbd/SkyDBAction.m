/*
  Copyright (C) 2000-2004 SKYRIX Software AG

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
// $Id$

#include "SkyDBAction.h"
#include "common.h"
#include <EOControl/EOControl.h>
#include "EOControl+XmlRpcDirectAction.h"
#include <OGoIDL/NGXmlRpcAction+Introspection.h>

@interface DirectAction : SkyDBAction
@end

@implementation DirectAction
@end /* DirectAction */

@interface SkyDBAction(Privates)
- (id)_startChannel;
- (BOOL)_stopChannel;
@end

@implementation SkyDBAction

+ (NSArray *)xmlrpcNamespaces {
  return [NSArray arrayWithObject:@"db"];
}

- (NSString *)xmlrpcComponentNamespace {
  NSUserDefaults *ud;
  NSString *suffix;
  id tmp;
  
  ud  = [NSUserDefaults standardUserDefaults];

  if ((suffix = [ud objectForKey:@"SxComponentNamespace"]) == nil) {

    suffix = [super xmlrpcComponentName];

    if ((tmp = [self adaptorName])) {
      suffix = [[suffix stringByAppendingString:@"."]
                        stringByAppendingString:tmp];
    }
    if ((tmp = [self connectionDictionary])) {
      NSDictionary *d;

      d = tmp;
      if ((tmp = [d objectForKey:@"hostName"])) {
        suffix = [[suffix stringByAppendingString:@"."]
                          stringByAppendingString:tmp];
      }
      if ((tmp = [d objectForKey:@"databaseName"])) {
        suffix = [[suffix stringByAppendingString:@"."]
                          stringByAppendingString:tmp];
      }
      if ((tmp = [d objectForKey:@"userName"])) {
        suffix = [[suffix stringByAppendingString:@"."]
                          stringByAppendingString:tmp];
      }
    }
  }
  else {
    suffix = [@"." stringByAppendingString:suffix];
  }
  
  tmp = [suffix length] > 0
    ? [[super xmlrpcComponentNamespacePrefix] stringByAppendingString:suffix]
    : [super xmlrpcComponentNamespace];


  {
    static BOOL didLogNS = NO;
    if (!didLogNS) {
      didLogNS = YES;
      [self logWithFormat:@"using namespace: %@", tmp];
    }
  }
  
  return tmp;
}

- (id)initWithContext:(WOContext *)_ctx {
  if ((self = [super initWithContext:_ctx])) {
    NSBundle *bundle;
    NSString *path;

    bundle = [NSBundle bundleForClass:[self class]];
    path = [bundle pathForResource:@"INTERFACE" ofType:@"xml"];
    if (path != nil)
      [self registerInterfaceAtPath:path forComponentName:
            [self xmlrpcComponentNamespace]];
    else
      [self logWithFormat:@"INTERFACE.xml not found in bundle path"];
  }
  return self;
}

- (void)dealloc {
  RELEASE(self->databaseDataSource);
  [super dealloc];
}

/* environment */

- (BOOL)authIsValid {
  NSString       *credentials;
  NSRange        r;
  NSArray        *creds;
  NSString       *user;
  NSString       *password;
  NSUserDefaults *ud;
  NSDictionary   *account;
  
  credentials = [[self request] headerForKey:@"authorization"];
  
  r = [credentials rangeOfString:@" " options:NSBackwardsSearch];

  if(r.length == 0) {
    NSLog(@"%s: invalid 'authorization' header", __PRETTY_FUNCTION__);
    return NO;
  }

  credentials = [credentials substringFromIndex:(r.location + r.length)];
  credentials = [credentials stringByDecodingBase64];
  creds       = [credentials componentsSeparatedByString:@":"];
  user        = [creds objectAtIndex:0];
  password    = [creds objectAtIndex:1];

  ud = [NSUserDefaults standardUserDefaults];

  if ((account = [ud objectForKey:@"SkyDBDAccount"]) == nil) {
    NSLog(@"%s: no SkyDBDAccount found in userDefaults",__PRETTY_FUNCTION__);
    return NO;
  }
  
  if (![[account objectForKey:@"username"] isEqualToString:user]) {
    NSLog(@"%s: invalid username", __PRETTY_FUNCTION__);
    return NO;
  }

  if (![[account objectForKey:@"password"] isEqualToString:password]) {
    NSLog(@"%s: invalid password", __PRETTY_FUNCTION__);
    return NO;
  }
  
  return YES;
}

- (NSDictionary *)connectionDictionary {
  return [[NSUserDefaults standardUserDefaults]
                          dictionaryForKey:@"LSConnectionDictionary"];
}
- (NSDictionary *)pkeyGeneratorDictionary {
  return [[NSUserDefaults standardUserDefaults]
                          dictionaryForKey:@"pkeyGeneratorDictionary"];
}
- (NSString *)adaptorName {
  return [[NSUserDefaults standardUserDefaults]
                          stringForKey:@"LSAdaptor"];
}

- (EOAdaptor *)adaptor {
  if (self->adaptor == nil) {
    self->adaptor = [[EOAdaptor adaptorWithName:[self adaptorName]] retain];
    [self->adaptor setConnectionDictionary:[self connectionDictionary]];
    [self->adaptor setPkeyGeneratorDictionary:[self pkeyGeneratorDictionary]];
  }
  return self->adaptor;
}
- (EOAdaptorContext *)adaptorContext {
  if (self->adCtx == nil)
    self->adCtx = [[[self adaptor] createAdaptorContext] retain];
  return self->adCtx;
}
- (EOAdaptorChannel *)adaptorChannel {
  if (self->adCh == nil)
    self->adCh = [[[self adaptorContext] createAdaptorChannel] retain];
  return self->adCh;
}

- (EOAdaptorDataSource *)databaseDataSource {
  if (self->databaseDataSource == nil) {
    self->databaseDataSource =
      [[EOAdaptorDataSource alloc]
                            initWithAdaptorChannel:[self adaptorChannel]
                            connectionDictionary:[self connectionDictionary]];
    
    [self->databaseDataSource openChannel];
  }
  return self->databaseDataSource;
}

/* operation */

- (EOKeyGlobalID *)globalIDForObject:(id)_object
                             inTable:(NSString *)_entity
                             channel:(EOAdaptorChannel *)_channel
{
  EOAttribute   *primaryKey;
  NSString      *primaryKeyName;
  NSString      *keyValue;
  EOKeyGlobalID *keyGlob;
  NSNumber      *key;
  
  primaryKey = [[_channel primaryKeyAttributesForTableName:_entity]
                         objectAtIndex:0];

  primaryKeyName = [[primaryKey columnName] lowercaseString];

  if (( keyValue = [_object objectForKey:primaryKeyName]) == nil) {
    NSLog(@"%s: primary key attribute missing in object %@",
          __PRETTY_FUNCTION__,
          _object);
    return nil;
  }

  key = [NSNumber numberWithInt:[keyValue intValue]];
  
  keyGlob = [EOKeyGlobalID globalIDWithEntityName:_entity
                           keys:&key
                           keyCount:1
                           zone:nil];  
  return keyGlob;
}

- (NSArray *)fetchAction:(id)_entity:(id)_arg {
  EOFetchSpecification  *fSpec          = nil;
  EODataSource          *databaseDS     = nil;
  NSArray               *result         = nil;
  NSMutableArray        *returnValue    = nil;
  NSEnumerator          *resultEnum     = nil;
  id                    resultElem      = nil;
  
  databaseDS = [self databaseDataSource];
  
  fSpec = [[[EOFetchSpecification alloc] initWithBaseValue:_arg] autorelease];
  [fSpec setEntityName:_entity];
  
  [databaseDS setFetchSpecification:fSpec];

  result = [databaseDS fetchObjects];
  returnValue = [NSMutableArray arrayWithCapacity:[result count]];
  
  resultEnum = [result objectEnumerator];

  while((resultElem = [resultEnum nextObject])) {
    NSMutableDictionary *dict;
    dict = [NSMutableDictionary dictionaryWithCapacity:[resultElem count]];
    [dict addEntriesFromDictionary:resultElem];
    [dict removeObjectForKey:@"globalID"];
    [returnValue addObject:dict];
  }
  return returnValue;
}

- (EOEntity *)entityForTableNamed:(NSString *)_tableName
  channel:(EOAdaptorChannel *)_channel
{
  static NSMutableDictionary *tableNameToEntity = nil;
  EOEntity *entity;
  NSArray  *attrs, *pkeys;
  
  if ([_tableName length] == 0)
    return nil;
  
  if (tableNameToEntity == nil)
    tableNameToEntity = [[NSMutableDictionary alloc] initWithCapacity:32];
  if ((entity = [tableNameToEntity objectForKey:_tableName]))
    return entity;
  
  attrs = [_channel attributesForTableName:_tableName];
  pkeys = [_channel primaryKeyAttributesForTableName:_tableName];
  
  entity = [[[EOEntity alloc] init] autorelease];
  
  [entity setName:_tableName];
  [entity setClassName:@"EOGenericRecord"];
  [entity setExternalName:_tableName];

  /* add attrs */
  {
    NSEnumerator *e;
    EOAttribute  *a;

    e = [attrs objectEnumerator];
    while ((a = [e nextObject]))
      [entity addAttribute:a];
  }
  
  /* set pkeys */
  [entity setPrimaryKeyAttributes:pkeys];
  
  if (entity)
    [tableNameToEntity setObject:entity forKey:_tableName];
  return entity;
}

- (id)insertAction:(NSString *)_entity:(NSDictionary *)_arg {
  EOAdaptorChannel *ch;
  NSDictionary     *row;
  EOEntity         *entity;
  id result;
  
  /* process args */
  
  if ([_arg isKindOfClass:[NSDictionary class]])
    row = _arg;
  else if ([_arg respondsToSelector:@selector(asDictionary)])
    row = [(id)_arg asDictionary];
  else
    row = [[_arg stringValue] propertyList];
  
  if ([row count] == 0) {
    [self logWithFormat:@"nothing to insert into '%@' ...", _entity];
    return [NSNumber numberWithBool:NO];
  }
  
  /* open channel */

  if ((ch = [self _startChannel]) == nil) {
    [self logWithFormat:@"missing adaptor channel ..."];
    return nil;
  }

  /* find entity */
  
  if ((entity = [self entityForTableNamed:_entity channel:ch]) == nil) {
    [self logWithFormat:@"failed to get entity for table named '%@'",
            _entity];
    [self _stopChannel];
    return [NSNumber numberWithBool:NO];
  }
  
  /* execute insert */
  
  NS_DURING {
    BOOL ok = [ch insertRow:row forEntity:entity];
    result = [[NSNumber numberWithBool:ok] retain];
  }
  NS_HANDLER {
    result = [localException retain];
  }
  NS_ENDHANDLER;
  
  result = [result autorelease];
  
  /* tear down */
  
  [self _stopChannel];
  
  return result;
}

- (id)updateAction:(id)_entity:(id)_arg {
  EOAdaptorDataSource   *databaseDS     = nil;
  EOAdaptorChannel      *channel        = nil;
  EOKeyGlobalID         *keyGlob        = nil;
  id                    object;
  
  databaseDS = [self databaseDataSource];

  [databaseDS commitTransaction];
  channel = [databaseDS beginTransaction];
  
  object = [databaseDS createObject];
  [object addEntriesFromDictionary:_arg];
  
  keyGlob = [self globalIDForObject:object
                  inTable:_entity
                  channel:channel];
  
  [object takeValue:keyGlob forKey:@"globalID"];
  
  [databaseDS updateObject:object];

  [object removeObjectForKey:@"globalID"];
  return object;
}

- (id)deleteAction:(id)_entity:(id)_arg {
  EOAdaptorDataSource   *databaseDS     = nil;
  EOAdaptorChannel      *channel        = nil;
  EOKeyGlobalID         *keyGlob        = nil;
  id                    object;
  
  databaseDS = [self databaseDataSource];

  [databaseDS commitTransaction];
  channel = [databaseDS beginTransaction];
  
  keyGlob = [self globalIDForObject:object
                  inTable:_entity
                  channel:channel];

  object = [databaseDS createObject];
  [object addEntriesFromDictionary:_arg];

  [object takeValue:keyGlob forKey:@"globalID"];
  
  [databaseDS deleteObject:object];
  
  [object removeObjectForKey:@"globalID"];
  return object;
  // hh: ??? return _arg;
}

- (NSArray *)evaluateAction:(id)_entity:(NSString *)_expression {
  EOAdaptorDataSource *databaseDS = nil;
  EOAdaptorChannel    *channel    = nil;
  NSMutableArray      *result     = nil;
  NSArray             *attrs      = nil;
  
  databaseDS = [self databaseDataSource];
  
  [databaseDS commitTransaction];
  channel = [databaseDS beginTransaction];

  if((attrs = [channel attributesForTableName:_entity]) == nil) {
    NSLog(@"ERROR[%s]: couldn't find table name '%@' in database",
          __PRETTY_FUNCTION__, _entity);
    [databaseDS rollbackTransaction];
    return nil;
  }

  if ([attrs count] == 0) {
    NSLog(@"ERROR[%s]: missing columns in table '%@'",
          __PRETTY_FUNCTION__, _entity);
    [databaseDS rollbackTransaction];
    return nil;
  }

  if (![channel evaluateExpression:_expression]) {
    NSLog(@"evaluate of expression %@ failed",_expression);
    [channel cancelFetch];
    [databaseDS rollbackTransaction];
    return nil;
  }
  
  result = [NSMutableArray arrayWithCapacity:64];
  
  {
    NSMutableDictionary *row    = nil;
    id                  *values = NULL;
    id                  *keys   = NULL;
    int                 attrCnt = 0;

    attrCnt    = [attrs count];
    values     = malloc(sizeof(id) * attrCnt + 1);
    keys       = malloc(sizeof(id) * attrCnt + 1);    
    
    while ((row = [channel fetchAttributes:attrs withZone:NULL])) {

      id                  attr      = nil;
      NSEnumerator        *attrEnum = nil;
      NSMutableDictionary *r        = nil;
      int                 rowCnt    = 0;
       
      attrEnum = [attrs objectEnumerator];

      while ((attr = [attrEnum nextObject])) {
        id obj;
        NSString *cn = nil;

        obj = [row objectForKey:[(EOAttribute *)attr name]];

        if (obj == nil)
          continue;

        cn = [[attr columnName] lowercaseString];
        values[rowCnt] = obj;
        keys[rowCnt] = cn;
        rowCnt++;        
      }

      r = [[NSMutableDictionary alloc]
                                initWithObjects:values
                                forKeys:keys
                                count:rowCnt];
      [result addObject:r];
      RELEASE(r); r = nil;
    }
    free(values); values = NULL;
    free(keys);   keys = NULL;
  }
  [channel cancelFetch];
  [databaseDS commitTransaction];
  
  return result;
}

- (id)_startChannel {
  EOAdaptorChannel *ch;
  EOAdaptorContext *cx;
  
  if ((cx = [self adaptorContext]) == nil) {
    [self logWithFormat:@"missing adaptor context ..."];
    return nil;
  }
  if ((ch = [self adaptorChannel]) == nil) {
    [self logWithFormat:@"missing adaptor channel ..."];
    return nil;
  }
  
  if (![ch isOpen]) {
    if (![ch openChannel]) {
      [self logWithFormat:@"couldn't open adaptor channel ..."];
      return nil;
    }
    self->didOpenChannel = YES;
  }
  if (![cx hasOpenTransaction]) {
    if (![cx beginTransaction]) {
      [self logWithFormat:@"couldn't begin transaction ..."];
      if (self->didOpenChannel) {
        [ch closeChannel];
        self->didOpenChannel = NO;
      }
      return nil;
    }
    self->didStartTx = YES;
  }
  return ch;
}
- (BOOL)_stopChannel {
  BOOL result = YES;
  if (self->didStartTx) {
    if (![self->adCtx commitTransaction]) {
      [self logWithFormat:@"WARNING: commit of tx failed !"];
      result = NO;
    }
    self->didStartTx = NO;
  }
  if (self->didOpenChannel) {
    [self->adCh closeChannel];
    self->didOpenChannel = NO;
  }
  return result;
}

- (NSArray *)evaluateAction:(NSString *)_expression {
  EOAdaptorChannel *ch;
  NSArray        *attrs;
  NSMutableArray *results;
  NSDictionary   *record;
  
  results = nil;
  if (self->didStartTx || self->didOpenChannel)
    [self _stopChannel];
  
  if ((ch = [self _startChannel]) == nil) {
    [self logWithFormat:@"missing adaptor channel ..."];
    return nil;
  }
  
  if (![ch evaluateExpression:_expression]) {
    [self logWithFormat:@"evaluation of expression failed."];
    goto done;
  }
  
  if ([ch isFetchInProgress]) {
    results = [NSMutableArray arrayWithCapacity:128];
    
    attrs = [ch describeResults];
    while ((record = [ch fetchAttributes:attrs withZone:NULL]))
      [results addObject:record];
  }
  else
    results = (id)[NSNumber numberWithBool:YES];
  
 done:
  if ([ch isFetchInProgress])
    [ch cancelFetch];

  [self _stopChannel];
  
  return results;
}

- (NSArray *)getAttributesOfTableAction:(NSString *)_table {
  EOAdaptorChannel *ch;
  NSArray *result;
  
  if ((ch = [self _startChannel]) == nil) {
    [self logWithFormat:@"missing adaptor channel ..."];
    return nil;
  }
  
  result = [ch attributesForTableName:_table];
  
  [self _stopChannel];
  
  return result;
}
- (NSArray *)getPrimaryKeyAttributesOfTableAction:(NSString *)_table {
  EOAdaptorChannel *ch;
  NSArray *result;
  
  if ((ch = [self _startChannel]) == nil) {
    [self logWithFormat:@"missing adaptor channel ..."];
    return nil;
  }
  
  result = [ch primaryKeyAttributesForTableName:_table];
  
  [self _stopChannel];
  
  return result;
}

- (NSArray *)getTablesAction {
  EOAdaptorChannel *ch;
  NSArray *result;
  
  if ((ch = [self _startChannel]) == nil) {
    [self logWithFormat:@"missing adaptor channel ..."];
    return nil;
  }
  
  result = [ch describeTableNames];
  
  [self _stopChannel];
  
  return result;
}

@end /* SkyDBAction(DB) */

#include <XmlRpc/XmlRpcCoder.h>

@implementation EOAttribute(XmlRpcCoding)

- (void)encodeWithXmlRpcCoder:(XmlRpcEncoder *)_coder {
  [_coder encodeArray:
          [NSArray arrayWithObjects:
                     [self name],
                     [self columnName],
                     [self externalType],
                     nil]];
}

@end /* EOAttribute(XmlRpcCoder) */
