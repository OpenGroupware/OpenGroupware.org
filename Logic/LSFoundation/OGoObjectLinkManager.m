
#include <LSFoundation/OGoObjectLinkManager.h>
#include <LSFoundation/OGoObjectLink.h>
#include <LSFoundation/LSCommandContext.h>
#include <EOControl/EOKeyGlobalID.h>
#include "common.h"

@interface OGoObjectLink(ManagerInternals)
- (NSNumber *)_sourceId;
- (NSString *)_sourceType;
- (NSString *)_target;
- (NSNumber *)_targetId;
- (NSString *)_targetType;
- (NSString *)_linkType;
- (NSString *)_label;
- (void)_setGlobalID:(EOGlobalID *)_gid;
@end /* OGoObjectLink(ManagerInternals) */

@interface OGoObjectLinkManager(Internals)
- (EOAdaptorChannel *)adaptorChannel;
- (EOEntity *)entity;
- (EODatabase *)database;
- (NSException *)_deleteLinks:(EOKeyGlobalID *)_gid type:(NSString *)_type
  action:(NSString *)_action;
- (NSException *)missingEntityException;
@end /* OGoObjectLinkManager(Internals) */

@implementation OGoObjectLinkManager

static NSString *ObjectLinkException = @"OGoObjectLinkException";
static NSArray  *FetchAttr = nil;
static NSNull   *null = nil;

// TODO: remove this macro junk, we are implementing in ObjC, not CPP ...

#define BEGIN_ADAPTOR_TRANS(__adChannel)    \
  {                                         \
    BOOL             __commitTrans = NO;    \
    EOAdaptorContext *__ctx        = nil;   \
    if (![__adChannel isOpen]) {       \
      [__adChannel openChannel];            \
    }                                       \
    __ctx = [__adChannel adaptorContext];   \
    if (![__ctx hasOpenTransaction]) { \
      [__ctx beginTransaction];             \
      __commitTrans = YES;                  \
    }
 
#define CLOSE_ADAPTOR_TRANS(__rollback)    \
    if (__rollback)                        \
      [__ctx rollbackTransaction];         \
    else if (__commitTrans)                \
      [__ctx commitTransaction];           \
  }

+ (void)initialize {
  if (null == nil)
    null = [[NSNull null] retain];
}

- (id)initWithContext:(LSCommandContext *)_ctx {
  if ((self = [super init])) {
    self->context = _ctx; /* not retained */
  }
  return self;
}

- (void)dealloc {
  [self->database  release];
  [self->entity    release];
  [self->adChannel release];
  [self->adaptor   release];
  self->context = nil;
  [super dealloc];
}

- (NSException *)deleteLinksTo:(EOKeyGlobalID *)_tgid
  type:(NSString *)_type
{
  return [self _deleteLinks:_tgid type:_type action:@"to"];
}

- (NSException *)deleteLinksFrom:(EOKeyGlobalID *)_sgid
  type:(NSString *)_type
{
  return [self _deleteLinks:_sgid type:(NSString *)_type action:@"from"];
}

- (NSException *)deleteLink:(OGoObjectLink *)_link {
  return [self _deleteLinks:(EOKeyGlobalID *)[_link globalID] type:nil
               action:nil];
}

- (NSException *)deleteLinkGID:(EOGlobalID *)_gid {
  return [self _deleteLinks:(EOKeyGlobalID *)_gid type:nil action:nil];
}

- (NSException *)createLink:(OGoObjectLink *)_link {
  EOAdaptorChannel *adc;
  EOEntity         *e;
  id               objs[9], result;
  int              i;
  BOOL             rollback;
  static id keys[9] = {
    @"objectLinkId", @"sourceId", @"sourceType", @"target",
    @"targetId", @"targetType", @"linkType", @"label", nil
  };
  
  if (![_link isNew]) {
    [self logWithFormat:@"try to insert an already inserted object link [%@]",
          _link];
    return nil;
  }

  if ((e = [self entity]) == nil)
    return [self missingEntityException];
  
  adc      = [self adaptorChannel];
  result   = nil;
  rollback = NO;

  BEGIN_ADAPTOR_TRANS(adc) {
    objs[0] = [[adc primaryKeyForNewRowWithEntity:e]
                    objectForKey:@"objectLinkId"];

    if (objs[0] == nil) {
      result = [NSException exceptionWithName:ObjectLinkException
                            reason:@"primary key generation failed"
                            userInfo:nil];
    }
    else {
      NSDictionary *row;
      
      objs[1] = [_link _sourceId];
      objs[2] = [_link _sourceType];
      objs[3] = [_link _target];
      objs[4] = [_link _targetId];
      objs[5] = [_link _targetType];
      objs[6] = [_link _linkType];
      objs[7] = [_link _label];
      objs[8] = nil;

      for (i = 0; i < 8; i++) {
        if (objs[i] == nil)
          objs[i] = null;
      }
      row = [[NSDictionary alloc] initWithObjects:objs forKeys:keys count:8];

      if (![adc insertRow:row forEntity:e]) {
        result = [NSException exceptionWithName:ObjectLinkException
                              reason:@"object link insert failed"
                              userInfo:[NSDictionary dictionaryWithObject:row
                                                     forKey:@"row"]];
        rollback = YES;
      }
      [row release]; row = nil;
    }
  }
  if (!result) {
    [_link _setGlobalID:[EOKeyGlobalID globalIDWithEntityName:@"ObjectLink"
                                        keys:&objs[0] keyCount:1 zone:NULL]];
  }
  CLOSE_ADAPTOR_TRANS(rollback);
  return result;
}

- (NSArray *)allLinks:(NSString *)_type {
  return [self allLinksFrom:nil to:nil type:_type];
}

- (NSArray *)allLinksFrom:(EOKeyGlobalID *)_sgid type:(NSString *)_type {
  return [self allLinksFrom:_sgid to:nil type:_type];
}

- (NSArray *)allLinksFrom:(EOKeyGlobalID *)_sgid {
  return [self allLinksFrom:_sgid type:nil];
}

- (NSArray *)allLinksTo:(EOKeyGlobalID *)_tgid type:(NSString *)_type {
  return [self allLinksFrom:nil to:_tgid type:_type];
}

- (NSArray *)allLinksTo:(EOKeyGlobalID *)_tgid {
  return [self allLinksTo:_tgid type:nil];
}

- (NSArray *)allLinksFrom:(EOKeyGlobalID *)_sgid to:(EOKeyGlobalID *)_tgid
  type:(NSString *)_type
{
  EOEntity         *e;
  EOAdaptorChannel *adc;
  NSMutableArray   *result;
  EOSQLQualifier   *qualifier;
  BOOL             status;
  NSMutableString  *mstr;

  if ((e = [self entity]) == nil)
    return nil;

  status = YES;
  adc    = [self adaptorChannel];
  mstr   = [NSMutableString stringWithCapacity:64];

  if ([_type length] > 0) {
    [mstr appendFormat:@"linkType = '%@'", _type];
  }
  if (_sgid != nil) {
    if ([mstr length] > 0)
      [mstr appendString:@" AND "];

    [mstr appendFormat:@"sourceId = %@", [_sgid keyValues][0]];
  }
  if (_tgid != nil) {
    if ([mstr length] > 0)
      [mstr appendString:@" AND "];

    [mstr appendFormat:@"targetId = %@", [_tgid keyValues][0]];
  }
  qualifier = [[EOSQLQualifier alloc] initWithEntity:e qualifierFormat:mstr];
  result    = [NSMutableArray arrayWithCapacity:64];

  if (FetchAttr == nil) {
    FetchAttr = [[NSArray alloc] initWithObjects:
                                 [e attributeNamed:@"objectLinkId"],
                                 [e attributeNamed:@"sourceId"],
                                 [e attributeNamed:@"sourceType"],
                                 [e attributeNamed:@"target"],
                                 [e attributeNamed:@"targetId"],
                                 [e attributeNamed:@"targetType"],
                                 [e attributeNamed:@"linkType"],
                                 [e attributeNamed:@"label"], nil];
  }
  BEGIN_ADAPTOR_TRANS(adc) {
    NSException *error;
    
    error = [adc selectAttributesX:FetchAttr
		 describedByQualifier:qualifier fetchOrder:nil lock:NO];
    if (error != nil) {
      [self logWithFormat:@"selectObjectsDescribedByQualifier failed,"
            @" attributes: %@ qualifier: %@: %@", FetchAttr, qualifier, error];
      status = NO;
    }
    [qualifier release]; qualifier = nil;

    if (status) {
      NSMutableDictionary *dict;
      
      while ((dict = [adc fetchAttributes:FetchAttr withZone:NULL])) {
        OGoObjectLink *lnk;
        
        if ((lnk = [OGoObjectLink objectLinkWithAttributes:dict]) == nil) {
          [self errorWithFormat:@"could not create link object: id=%@",
                  [dict valueForKey:@"objectLinkId"]];
          continue;
        }
        [result addObject:lnk];
      }
    }
  }
  CLOSE_ADAPTOR_TRANS(NO);
  return [[result copy] autorelease];
}

@end /* OGoObjectLinkManager */

@implementation OGoObjectLinkManager(Internals)

- (EOAdaptorChannel *)adaptorChannel {
  if (self->adChannel == nil) {
    NSAssert(self->context, @"missing context");
    
    self->adChannel = [[[self->context valueForKey:LSDatabaseChannelKey]
                                       adaptorChannel] retain];
    
    NSAssert(self->adChannel, @"couldn`t find adaptor channel");
  }
  return self->adChannel;
}

- (EOEntity *)entity {
  EODatabase *db;
  
  if (self->entity)
    return self->entity;

  db = [self database];
  NSAssert(db != nil, @"missing database");
    
  if ((self->entity = [[db entityNamed:@"ObjectLink"] retain]) == nil) {
    [self logWithFormat:
	    @"couldn`t find entity named ObjectLink - update your model "
	    @"and database!"];
  }
  return self->entity;
}

- (EODatabase *)database {
  if (self->database == nil) {
    NSAssert(self->context, @"missing context");
    self->database = [[self->context valueForKey:LSDatabaseKey] retain];
    NSAssert(self->database != nil, @"did not find database");
  }
  return self->database;
}

- (NSException *)missingEntityException {
  return [NSException exceptionWithName:ObjectLinkException
		      reason:@"ObjectLink entity missing, update your DB"
		      userInfo:nil];
}

- (NSException *)_deleteLinks:(EOKeyGlobalID *)_gid type:(NSString *)_type
  action:(NSString *)_action
{
  EOEntity         *e;
  EOAdaptorChannel *adc;
  id               result;
  EOSQLQualifier   *qualifier;
  BOOL             rollbackTransaction;
  NSMutableString  *str;
  
  if ((e = [self entity]) == nil)
    return [self missingEntityException];
  
  rollbackTransaction = NO;
  result              = nil;
  adc                 = [self adaptorChannel];
  str                 = [NSMutableString stringWithCapacity:32];

  if (_gid == nil) {
    [self warnWithFormat:@"%s: got empty gid for action [%@]",
          __PRETTY_FUNCTION__, _action];
    return nil;
  }
  if (_action == nil) { /* gid is a ObjectLink Gid */
    if (![[_gid entityName] isEqualToString:@"ObjectLink"]) {
      [self logWithFormat:@"got wrong entity for %s [%@]",
            __PRETTY_FUNCTION__, _gid];
      return [NSException exceptionWithName:ObjectLinkException
                          reason:@"got wrong entity" userInfo:nil];
    }
    [str appendFormat:@"objectLinkId = %@", [_gid keyValues][0]];
  }
  else if ([_action isEqualToString:@"to"]) {
    [str appendFormat:@"targetId = %@", [_gid keyValues][0]];
  }
  else if ([_action isEqualToString:@"from"]) {
    [str appendFormat:@"sourceId = %@", [_gid keyValues][0]];
  }
  else {
    [self logWithFormat:@"internal error, got wrong action"];
    return nil;
  }
  if ([_type length] > 0)
    [str appendFormat:@" AND (linkType = '%@')", _type];
  
  qualifier = [[EOSQLQualifier alloc] initWithEntity:e qualifierFormat:str];
  BEGIN_ADAPTOR_TRANS(adc) {
    
    if (![adc deleteRowsDescribedByQualifier:qualifier]) {
      NSDictionary *ui;
      
      [self logWithFormat:@"delete with qualifier %@ failed", qualifier];
 
      ui = [NSDictionary dictionaryWithObjectsAndKeys:
                           qualifier, @"qualifier", nil];
      result = [NSException exceptionWithName:ObjectLinkException
                            reason:@"couldn`t delete row"
                            userInfo:ui];
      rollbackTransaction = YES;
    }
    [qualifier release]; qualifier = nil;        
  }
  CLOSE_ADAPTOR_TRANS(rollbackTransaction);
  return result;
}

@end /* OGoObjectLinkManager(Internals) */
