// $Id$

#include <OGoDocuments/SkyDocument.h>
#include <NGLdap/NGLdap.h>
#include <GDLAccess/GDLAccess.h>
#include "common.h"
#include "SkyLDAPDocument.h"
#include "SkyLDAPDataSource.h"

@interface SkyLDAPDocument(Internals)

- (NSDictionary *)newAttrs;
- (NSDictionary *)updatedAttrs;
- (NSDictionary *)removedAttrs;
- (void)setValues;
- (NSString *)uniqueId;
- (void)setGlobalID:(EOGlobalID *)_gid;

@end // SkyLDAPDocument(Internals).


@interface SkyLDAPDataSource(Private)

- (BOOL)_testObj:(id)_obj;
- (NSArray *)_buildAttrs:(NSDictionary *)_dict withObjClass:(BOOL)_setObjClass;
- (NGLdapConnection *)connection;
- (BOOL)checkDN:(NSString *)_dn;
- (NSArray *)objectClassNames;
- (BOOL)_shouldCheckLastPathComponent;

@end // SkyLDAPDataSource(Private).


@implementation SkyLDAPDataSource

- (id)initWithBaseDN:(NSString *)_dn
  host:(NSString *)_host port:(int)_port bindDN:(NSString *)_bindDN
  credentials:(NSString *)_credentials
{
  if ([_dn length] == 0) {
    [self release];
    return nil;
  }
  
  if ((self = [super init])) {
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];

    self->dn = [_dn copy];

    if ([_host length] > 0)
      ASSIGN(self->host, _host);
    else
      ASSIGN(self->host, [ud objectForKey:@"Skyrix_LDAP_Host"]);
    
    self->port = (_port > 0) ? _port : 389;

    if ([_bindDN length])
      ASSIGN(self->bindDN, _bindDN);

    if ([_credentials length])
      ASSIGN(self->credentials, _credentials);
  }
  return self;
}

- (void)dealloc {
  RELEASE(self->dn);
  RELEASE(self->host);
  RELEASE(self->bindDN);
  RELEASE(self->credentials);
  RELEASE(self->connection);
  RELEASE(self->fspec);
  [super dealloc];
}

- (Class)documentClass {
  [self notImplemented:_cmd];
  return Nil;
}

- (id)createObject {
  return [[[[self documentClass] alloc]
                  initWithGlobalID:nil record:nil dataSource:self] 
                  autorelease];
}

- (void)insertObject:(id)_obj {
  NSString         *uniqueId;
  NSString         *ndn;
  NGLdapEntry      *entry;
  NGLdapConnection *conn;
  NGLdapGlobalID   *gid;
 
  conn = [self connection];

  if (! [self _testObj:_obj])
    return;

  if (! [_obj isNew]) {
    NSLog(@"%s couldn't insert new document %@",
          __PRETTY_FUNCTION__, _obj);
    return;
  }

  if (! [self checkDN:self->dn])
    return;

  uniqueId = [_obj valueForKey:[_obj uniqueId]];
  if (! uniqueId) {
    NSLog(@"ERROR[%s]: couldn't insert object, missing uniqe id obj %@",
          __PRETTY_FUNCTION__, _obj);
    return;
  }

  ndn   = [NSString stringWithFormat:@"%@=%@, %@",
                    [_obj uniqueId], uniqueId, self->dn];
  entry = [[NGLdapEntry alloc] initWithDN:ndn
                               attributes:[self _buildAttrs:[_obj newAttrs]
                                                withObjClass:YES]];
  entry = [entry autorelease];

  NSLog(@"%s data to insert = %@", __PRETTY_FUNCTION__, [entry ldif]);

  if (! [conn addEntry:entry]) {
    NSLog(@"ERROR[%s]: insert of %@ failed", __PRETTY_FUNCTION__, _obj);
    return;
  }

  [conn flushCache];
  [_obj setValues];

  gid = [[NGLdapGlobalID alloc] initWithHost:[conn hostName]
                                port:[conn port] dn:ndn];
  [_obj setGlobalID:gid];
  [gid release];
}

- (void)deleteObject:(id)_obj {
  NSString *ndn;

  if (! [self _testObj:_obj])
    return;

  ndn = [(NGLdapGlobalID *)[_obj globalID] dn];
  if (ndn == nil) {
    NSLog(@"ERROR[%s] missing globalID for %@", __PRETTY_FUNCTION__, _obj);
    return;
  }
  
  if ([[self connection] removeEntryWithDN:ndn])
    [_obj invalidate];

  [[self connection] flushCache];
}

- (void)updateObject:(id)_obj {
  NSEnumerator   *enumerator;
  id             obj;
  NSString       *ndn;
  NSMutableArray *modification;

  NSLog(@"%s start", __PRETTY_FUNCTION__);

  if (! [self _testObj:_obj])
    return;

  ndn = [(NGLdapGlobalID *)[_obj globalID] dn];
  if (! ndn) {
    NSLog(@"ERROR[%s] missing globalID for %@", __PRETTY_FUNCTION__, _obj);
    return;
  }

  modification = [NSMutableArray array];

  enumerator = [[self _buildAttrs:[_obj newAttrs] withObjClass:NO]
                      objectEnumerator];
  while ((obj = [enumerator nextObject])) {
    [modification addObject:[NGLdapModification addModification:obj]];
  }

  enumerator = [[self _buildAttrs:[_obj updatedAttrs] withObjClass:NO]
                      objectEnumerator];
  while ((obj = [enumerator nextObject])) {
    [modification addObject:[NGLdapModification replaceModification:obj]];
  }

  enumerator = [[self _buildAttrs:[_obj removedAttrs] withObjClass:NO]
                      objectEnumerator];
  while ((obj = [enumerator nextObject])) {
    [modification addObject:[NGLdapModification deleteModification:obj]];
  }

  NSLog(@"%s dn = %@", __PRETTY_FUNCTION__, ndn);
  NSLog(@"%s changes = %@", __PRETTY_FUNCTION__, modification);
  NSLog(@"%s conn = %@", __PRETTY_FUNCTION__, [self connection]);

  if (! [[self connection] modifyEntryWithDN:ndn changes:modification]) {
    NSLog(@"ERROR[%s]: modification of %@ failed!", __PRETTY_FUNCTION__, _obj);
  }

  [[self connection] flushCache];
}

- (void)setFetchSpecification:(EOFetchSpecification *)_fs { // kopieren?
  if (! [self->fspec isEqual:_fs]) {
    ASSIGNCOPY(self->fspec, _fs);
    [self postDataSourceChangedNotification];
  }
}
- (EOFetchSpecification *)fetchSpecification {
  return AUTORELEASE([self->fspec copy]);
}

// From NGLdapDataSource.m

- (NSDictionary *)_recordFromEntry:(NGLdapEntry *)_entry {
  NSMutableDictionary *md;
  NSEnumerator        *keys;
  NSString            *key;

  if (_entry == nil)
    return nil;

  md = [NSMutableDictionary dictionaryWithCapacity:[_entry count]];

  [md setObject:[_entry dn]  forKey:NSFileIdentifier];
  [md setObject:[_entry dn]  forKey:NSFilePath];
  [md setObject:[_entry rdn] forKey:NSFileName];

  keys = [[_entry attributeNames] objectEnumerator];

  while ((key = [keys nextObject])) {
    NGLdapAttribute *attribute;
    unsigned count;
    id value;

    attribute = [_entry attributeWithName:key];
    count     = [attribute count];

    if (count == 0)
      value = [EONull null];
    else if (count == 1)
      value = [attribute stringValueAtIndex:0];
    else
      value = [attribute allStringValues];

    [md setObject:value forKey:key];
  }

  //NSLog(@"%s made record %@", __PRETTY_FUNCTION__, md);

  return AUTORELEASE([md copy]);
}

// From NGLdapDataSource.m

- (NSArray *)fetchObjects {
  NSAutoreleasePool *pool;
  NSString          *scope;
  EOQualifier       *qualifier;
  NSArray           *sortOrderings;
  NSEnumerator      *e;
  NSString          *baseDN;
  NSMutableArray    *results;
  NGLdapEntry       *entry;
  NSArray           *array;
  NSArray           *attrs;
  id                obj;
  id                *buf;
  int               bufCnt;

  pool = [NSAutoreleasePool new];

  scope         = nil;
  qualifier     = nil;
  sortOrderings = nil;
  baseDN        = nil;
  attrs         = nil;

  if (self->fspec) {
    NSString *entityName;

    qualifier     = [self->fspec qualifier];
    sortOrderings = [self->fspec sortOrderings];
    scope         = [[self->fspec hints] objectForKey:@"NSFetchScope"];
    attrs         = [[self->fspec hints] objectForKey:@"NSFetchKeys"];

    if ((entityName = [self->fspec entityName])) {
      EOQualifier *oq;

      oq = [[EOKeyValueQualifier alloc]
                                 initWithKey:@"objectclass"
                                 operatorSelector:EOQualifierOperatorEqual
                                 value:entityName];
      if (qualifier) {
        NSArray *qa;

        qa = [NSArray arrayWithObjects:oq, qualifier, nil];
        qualifier = [[EOAndQualifier alloc] initWithQualifierArray:qa];
        qualifier = [qualifier autorelease];
        [oq release]; oq = nil;
      }
      else {
        qualifier = [oq autorelease];
        oq = nil;
      }
    }
  }
  else {
    EOSortOrdering *so;

    so = [EOSortOrdering sortOrderingWithKey:NSFileIdentifier
                         selector:EOCompareAscending];
    sortOrderings = [NSArray arrayWithObject:so];
  }

  if (scope == nil)
    scope = @"NSFetchScopeOneLevel";
  if (baseDN == nil)
    baseDN = self->dn;

  if ([scope isEqualToString:@"NSFetchScopeOneLevel"]) {
    e = [[self connection] flatSearchAtBaseDN:baseDN
                           qualifier:qualifier attributes:attrs];
  }
  else if ([scope isEqualToString:@"NSFetchScopeSubTree"]) {
    e = [[self connection] deepSearchAtBaseDN:baseDN
                           qualifier:qualifier attributes:attrs];
  }
  else {
    [NSException raise:@"NGLdapDataSourceException"
                 format:@"unsupported fetch-scope: '%@'!", scope];
    e = nil;
  }

  if (e == nil) {    // No results.
    RELEASE(pool);
    return nil;
  }

  // Transform results into records.

  results = [NSMutableArray arrayWithCapacity:64];
  while ((entry = [e nextObject])) {
    NSDictionary *record;

    if ((record = [self _recordFromEntry:entry]) == nil) {
      NSLog(@"WARNING: couldn't transform entry %@ into record!", entry);
      continue;
    }

    [results addObject:record];
  }
  array = AUTORELEASE([results copy]);

  // Apply sort-orderings in-memory.

  if (sortOrderings)
    array = [array sortedArrayUsingKeyOrderArray:sortOrderings];

  // Now build a global id and create our documents.

  buf    = calloc([array count], sizeof(id));
  bufCnt = 0;

  e = [array objectEnumerator];
  while ((obj = [e nextObject])) {
    NGLdapGlobalID *gid;

    gid = [[NGLdapGlobalID alloc] initWithHost:[[self connection] hostName]
                                  port:[[self connection] port]
                                  dn:[obj objectForKey:@"NSFileIdentifier"]];

    buf[bufCnt] = [[[self documentClass] alloc] initWithGlobalID:gid
                                                record:obj dataSource:self];
    RELEASE(gid); gid = nil;
    AUTORELEASE(buf[bufCnt]);
    bufCnt++;
  }

  array = [NSArray arrayWithObjects:buf count:bufCnt];
  free(buf); buf = NULL;

  // Finished.

  array = [array retain];
  [pool release];

  return [array autorelease];
}

@end /* SkyLDAPDataSource */


@implementation SkyLDAPDataSource(Private)

- (NGLdapConnection *)connection {
  if (! self->connection) {
    self->connection = [[NGLdapConnection alloc] initWithHostName:self->host
                                                 port:self->port];
    if (! self->connection) {
      NSLog(@"ERROR[%s]: missing ldap-connection (host:%@; port:%d)",
            __PRETTY_FUNCTION__, self->host, self->port);
      return nil;
    }

    if ([self->connection isBound])
      [self->connection unbind];

    NSLog(@"%s try to bind to: %@ (%@)", __PRETTY_FUNCTION__,
          self->bindDN, self->credentials);

    if (! [self->connection bindWithMethod:@"simple"
               binddn:self->bindDN credentials:self->credentials]) {
      NSLog(@"%s couldn't bind to \"%@\"!", __PRETTY_FUNCTION__, self->bindDN);
      return nil;
    }

    [self->connection setUseCache:NO];

    NSLog(@"%s New connection created: %@", __PRETTY_FUNCTION__,
          self->connection);
  }

  return self->connection;
}

- (BOOL)_testObj:(id)_obj {
  if (![_obj isKindOfClass:[self documentClass]]) {
    NSLog(@"ERROR[%s] got wrong obj <%@>", __PRETTY_FUNCTION__, _obj);
    return NO;
  }
  return YES;
}

- (BOOL)checkDN:(NSString *)_dn {
  if ([self _shouldCheckLastPathComponent]) {
    EOQualifier      *qual;
    NSArray          *attr;
    NSEnumerator     *enumerator;
    id               obj;

    if (! [self->dn length]) {
      NSLog(@"ERROR[%s]: missing search path", __PRETTY_FUNCTION__);
      return NO;
    }

    attr = [[self->dn lastDNComponent] componentsSeparatedByString:@"="];
    if ([attr count] != 2) {
      NSLog(@"ERROR[%s]: unbalanced DN %@", __PRETTY_FUNCTION__, self->dn);
      return NO;
    }

    qual = [EOQualifier qualifierWithQualifierFormat:@"%@=%@",
                        [attr objectAtIndex:0], [attr objectAtIndex:1]];
    enumerator = [[self connection] flatSearchAtBaseDN:
                       [self->dn stringByDeletingLastDNComponent]
                       qualifier:qual attributes:nil];

    obj = [enumerator nextObject];
    if (! obj) {
      NGLdapEntry     *entry;
      NGLdapAttribute *attribute;
      NSMutableArray  *array;

      array = [NSMutableArray array];

      attribute = [[NGLdapAttribute alloc]
                                    initWithAttributeName:@"objectclass"];
      AUTORELEASE(attribute);
      [attribute addStringValue:@"top"];
      [attribute addStringValue:@"organizationalunit"];
      [array addObject:attribute];

      attribute = [[NGLdapAttribute alloc] initWithAttributeName:
                                           [attr objectAtIndex:0]];
      AUTORELEASE(attribute);
      [attribute addStringValue:[attr objectAtIndex:1]];
      [array addObject:attribute];

      entry = [[NGLdapEntry alloc] initWithDN:self->dn attributes:array];
      AUTORELEASE(entry);

      if (! [[self connection] addEntry:entry]) {
        NSLog(@"%s: couldn't insert entry %@", __PRETTY_FUNCTION__, entry);
        return NO;
      }
    }
  }
  return YES;
}

- (NSArray *)_buildAttrs:(NSDictionary *)_dict
            withObjClass:(BOOL)_setObjClass {
  id              *buf, key;
  int             bufCnt;
  NSEnumerator    *enumerator;
  NSArray         *result;
  NGLdapAttribute *attr;

  buf    = calloc([_dict count] + 1, sizeof(id));
  bufCnt = 0;
  enumerator = [_dict keyEnumerator];

  while ((key = [enumerator nextObject])) {
    id v;

    v = [_dict objectForKey:key];
    attr = [[NGLdapAttribute alloc] initWithAttributeName:key];

    if ([v isKindOfClass:[NSArray class]]) {
      NSEnumerator *enumerator;
      id           obj;

      enumerator = [v objectEnumerator];
      while ((obj = [enumerator nextObject])) {
        [attr addStringValue:obj];
      }
    }
    else if ([v isKindOfClass:[NSString class]]) {
      [attr addStringValue:v];
    }
    else if ([v isKindOfClass:[NSCalendarDate class]]) {
      NSString       *str;
      NSCalendarDate *d;

      d = [v copy];

      [d setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"GMT"]];
      str = [v descriptionWithCalendarFormat:@"%Y%m%d%H%MZ"];
      [attr addStringValue:str];
      RELEASE(d); d = nil;
    }
    else if ([v isNotNull]) {
      NSLog(@"ERROR[%s]: unsupported class[%@] for attribute %@=%@",
            __PRETTY_FUNCTION__, NSStringFromClass([v class]), key, v);
      continue;
    }
    AUTORELEASE(attr);
    buf[bufCnt++] = attr;
  }

  if (_setObjClass) {
    attr = [[NGLdapAttribute alloc] initWithAttributeName:@"objectclass"];
    {
      NSEnumerator *enumerator;
      id           obj;

      enumerator = [[self objectClassNames] objectEnumerator];
      while ((obj = [enumerator nextObject])) {
        [attr addStringValue:obj];
      }
    }
    AUTORELEASE(attr);
    buf[bufCnt++] = attr;
  }
  result = [NSArray arrayWithObjects:buf count:bufCnt];
  free(buf); buf = NULL;
  NSLog(@"%s attr = %@", __PRETTY_FUNCTION__, result);
  return result;
}

- (BOOL)_shouldCheckLastPathComponent {
  return NO;
}

- (NSArray *)objectClassNames {
  return nil;
}

@end // SkyLDAPDataSource(Private).
