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

#include "SxFreeBusyManager.h"
#include "common.h"
#include <GDLAccess/GDLAccess.h>
#include <EOControl/EOKeyGlobalID.h>
#include <NGExtensions/NGExtensions.h>

// TODO: HACK! Why is the backend calling into the frontend?!
//#include <Frontend/Appointments/SxAppointment.h>

@implementation SxFreeBusyManager

static SxFreeBusyManager *sharedInstance = NULL;

+ (id)freeBusyManager {
  if (sharedInstance == NULL) {
    sharedInstance = [[SxFreeBusyManager alloc] init];
  }
  return sharedInstance;
}

- (EOAdaptor *)adaptor {
  if (self->adaptor == nil) {
    NSUserDefaults *defs;
    NSString       *adaptorName;
    NSDictionary   *conDict;
    
    defs        = [NSUserDefaults standardUserDefaults];
    adaptorName = [defs stringForKey:@"LSAdaptor"];

    self->adaptor = [[EOAdaptor adaptorWithName:adaptorName] retain];

    if ((conDict = [self->adaptor connectionDictionary]) == nil) {
      /* no connection dictionary set in adaptor .. */
      *(&conDict) = [defs dictionaryForKey:@"LSConnectionDictionary"];
      
      if (conDict) [self->adaptor setConnectionDictionary:conDict];
    }

  }
  return self->adaptor;
}

- (EOAdaptorContext *)adaptorContext {
  if (self->context == nil) {
    self->context = [[[self adaptor] createAdaptorContext] retain];
  }
  return self->context;
}

- (EOAdaptorChannel *)adaptorChannel {
  if (self->channel == nil) {
    self->channel = [[[self adaptorContext] createAdaptorChannel] retain];
  }
  return self->channel;
}

- (NSString *)modelName {
  NSString *modelName;
   
  
  if (self->model) 
    return [self->model name];

  modelName = [[NSUserDefaults standardUserDefaults]
                               objectForKey:@"LSModelName"];
  
  if (modelName == nil) {
    EOAdaptorChannel *chan;
    EOAdaptorContext *ctx;
    BOOL             canConnect = YES;
    
    NS_DURING {
      chan = [self adaptorChannel];
      ctx  = [self adaptorContext];
      if (![chan isOpen]) {
        if (![chan openChannel]) {
          canConnect = NO;
          modelName  = nil;
        }
      }
      if (canConnect) {
        if ([chan evaluateExpression:
                 @"SELECT model_name FROM object_model"]) {
          NSArray      *attrs;
          NSDictionary *record;

          attrs = [chan describeResults];
          record = [chan fetchAttributes:attrs withZone:NULL];
          [chan cancelFetch];

          modelName = [record objectForKey:@"modelName"];
          [ctx commitTransaction];
        }
        [chan closeChannel];
      }
      else {
        [self logWithFormat:@"couldn't begin transaction to get modelname."];
        modelName = nil;
      }
    }
    NS_HANDLER {
      fprintf(stderr, "[%s] connection failed: %s\n",
              [[self description] cString],
              [[localException description] cString]);
      fflush(stderr);
      canConnect = NO;
    }
    NS_ENDHANDLER;    
  }

  return modelName;
}

- (EOModel *)model {
  NSString *modelName;
  
  if (self->model != nil)
    return self->model;
  
  if ((modelName = [self modelName])) {
    NGBundleManager *bm;
    NSString        *modelPath;
    NSBundle        *modelBundle;
    
    if ((bm = [NGBundleManager defaultBundleManager]) == nil)
      NSLog(@"ERROR: couldn't instantiate bundle manager !");
    
    modelBundle = [bm bundleProvidingResource:modelName ofType:@"EOModels"];
    if (modelBundle == nil) {
      NSLog(@"ERROR: did not find bundle for model %@ (type=EOModels)",
            modelName);
      modelPath = nil;
      return nil;
    }
    else {
      modelPath = [modelBundle pathForResource:modelName ofType:@"eomodel"];
      if (modelPath == nil) {
        NSLog(@"ERROR: did not find path for model %@ "
              @"(type=eomodel) in bundle %@",
              modelName, modelBundle);
        return nil;
      }
    }
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:modelPath]) {
      self->model = [[EOModel alloc] initWithContentsOfFile:modelPath];
    }
      
    if (self->model == nil) {
      NSString *path;
  
      path = [[NGBundle mainBundle]
                        pathForResource:modelName
                        ofType:@"eomodel"];
      if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        self->model = [[EOModel alloc] initWithContentsOfFile:path];
      }
    }
    if (self->model == nil) {
      NSLog(@"ERROR(%s): could not load model %@ !",
            __PRETTY_FUNCTION__, modelName);
      return nil;
    }
  }
  else {
    NSLog(@"ERROR(%s): no model name set", __PRETTY_FUNCTION__);
    return nil;
  }
  return self->model;
}

- (void)appendFirst:(NSString *)_str
                 as:(NSString *)_as
                 to:(NSMutableString *)_ms
{
  [_ms appendString:_str];
  [_ms appendString:@" AS "];
  [_ms appendString:_as];
}
- (void)append:(NSString *)_str as:(NSString *)_as to:(NSMutableString *)_ms {
  [_ms appendString:@", "];
  [self appendFirst:_str as:_as to:_ms];
}


- (NSString *)formatDate:(NSCalendarDate *)_date {
  EOEntity    *dateEntity;
  EOAttribute *startDateAttr;

  dateEntity    = [[self model] entityNamed:@"Date"];
  startDateAttr = [dateEntity attributeNamed:@"startDate"];

  if (startDateAttr == nil) {
    NSLog(@"ERROR[%s]: cannot get startDate attribute of entity Date",
          __PRETTY_FUNCTION__);
    return nil;
  }

  return [[self adaptor] formatValue:_date forAttribute:startDateAttr];
}

- (NSString *)formatEmail:(NSString *)_email {
  EOEntity    *cvEntity;
  EOAttribute *valueAttr;

  cvEntity  = [[self model] entityNamed:@"CompanyValue"];
  valueAttr = [cvEntity attributeNamed:@"value"];

  if (valueAttr == nil) {
    NSLog(@"ERROR[%s]: cannot get valueString attribute of entity "
          @"CompanyValue[%@] (model: %@)",
          __PRETTY_FUNCTION__, cvEntity, [self model]);
    return nil;
  }

  return [[self adaptor] formatValue:_email forAttribute:valueAttr];
}

- (NSString *)formatCompanyId:(id)_companyId {
  EOEntity    *personEntity;
  EOAttribute *valueAttr;

  personEntity  = [[self model] entityNamed:@"Person"];
  valueAttr     = [personEntity attributeNamed:@"companyId"];

  if (valueAttr == nil) {
    NSLog(@"ERROR[%s]: cannot get companyId attribute of entity "
          @"Person",
          __PRETTY_FUNCTION__);
    return nil;
  }

  return [[self adaptor] formatValue:_companyId forAttribute:valueAttr];
}

- (NSString *)dateTableName {
  return [[[self model] entityNamed:@"Date"] externalName];
}
- (NSString *)dateCompanyAssignmentTableName {
  return [[[self model] entityNamed:@"DateCompanyAssignment"] externalName];
}
- (NSString *)personTableName {
  return [[[self model] entityNamed:@"Person"] externalName];
}
- (NSString *)companyAssignmentTableName {
  return [[[self model] entityNamed:@"CompanyAssignment"] externalName];
}
- (NSString *)companyValueTableName {
  return [[[self model] entityNamed:@"CompanyValue"] externalName];
}
- (NSString *)teamTableName {
  return [[[self model] entityNamed:@"Team"] externalName];
}

- (id)freeBusyDataForExpression:(NSString *)_sql {
  NSString         *sql;
  EOAdaptorChannel *chan;
  EOAdaptorContext *ctx;
  NSArray          *attributes;
  id               record;
  NSMutableArray   *result;
  BOOL             closeConnection;
  static id        values[4];
  static id        keys[4] =
    { @"startDate", @"endDate", @"fbtype", @"busytype" };

  sql  = _sql;
  chan = [self adaptorChannel];
  ctx  = [self adaptorContext];

  closeConnection = NO;

  if (![chan isOpen]) {
    [chan openChannel];
    closeConnection = YES;
  }
  
  [ctx beginTransaction];
  
  if (![chan isOpen]) {
    return [NSException exceptionWithName:@"SQLException"
			reason:@"channel is not open"
			userInfo:nil];
  }
  if (![chan evaluateExpression:sql]) {
    [ctx rollbackTransaction];
    if (closeConnection) {
      [chan closeChannel];
    }
    return [NSException exceptionWithName:@"SQLException"
			reason:@"could not execute SQL statement"
			userInfo:nil];
  }
  
  if ((attributes = [chan describeResults]) == nil) {
    [chan cancelFetch];
    [ctx rollbackTransaction];
    if (closeConnection) {
      [chan closeChannel];
    }
    return [NSException exceptionWithName:@"SQLException"
			reason:
                        @"could not get a description of the SQL results"
			userInfo:nil];
  }

  result = [NSMutableArray array];
  while ((record = [chan fetchAttributes:attributes withZone:NULL])) {
    values[0] = [record objectForKey:@"startdate"];
    values[1] = [record objectForKey:@"enddate"];
    values[2] = [record objectForKey:@"fbtype"];
    values[3] = [record objectForKey:@"busytype"];

    [result addObject:
            [NSDictionary dictionaryWithObjects:values
                          forKeys:keys count:4]];
  }

  [ctx rollbackTransaction];
  if (closeConnection) 
    [chan closeChannel];
  
  return result;
}

- (NSString *)buildExpressionForEmail:(NSString *)_email
                                 from:(NSCalendarDate *)_from
                                   to:(NSCalendarDate *)_to
{
  NSString        *emailString;
  NSString        *fromString;
  NSString        *toString;
  NSMutableString *ms;

  ms = [NSMutableString stringWithCapacity:32];

  emailString = [self formatEmail:_email];
  fromString  = [self formatDate:_from];
  toString    = [self formatDate:_to];

  // SELECT
  [ms appendString:@"SELECT DISTINCT "
      @"d.date_id as pkey, "
      @"d.start_date as startdate, "
      @"d.end_date as enddate, "
      @"d.fbtype as fbtype, "
      @"d.busy_type as busytype"];

  // FROM
  [ms appendString:@" FROM "];
  [self appendFirst:[self dateTableName]             as:@"d"   to:ms];
  [self append:[self dateCompanyAssignmentTableName] as:@"dca" to:ms];
  [self append:[self personTableName]                as:@"p"   to:ms];
  [self append:[self companyAssignmentTableName]     as:@"ca"  to:ms];
  [self append:[self teamTableName]                  as:@"t"   to:ms];
  [self append:[self companyValueTableName]          as:@"cv"  to:ms];

  [ms appendFormat:@" WHERE "
      @"lower(cv.value_string) = %@ AND "
      @"lower(cv.attribute)    = 'email1' AND "
      @"p.db_status <> 'archived' AND "
      @"p.company_id = cv.company_id AND "
      
      @"ca.sub_company_id = p.company_id AND "
      @"t.company_id = ca.company_id AND "
      
      @"(dca.company_id = p.company_id OR dca.company_id = t.company_id) AND "
      @"d.end_date > %@ AND "
      @"d.start_date < %@ AND "
      @"d.date_id = dca.date_id",
      emailString, fromString, toString];

  return ms;
}

- (NSString *)buildExpressionForCompanyId:(id)_companyId
                                     from:(NSCalendarDate *)_from
                                       to:(NSCalendarDate *)_to
{
  NSString        *companyIdString;
  NSString        *fromString;
  NSString        *toString;
  NSMutableString *ms;

  ms = [NSMutableString stringWithCapacity:32];

  companyIdString = [self formatCompanyId:_companyId];
  fromString      = [self formatDate:_from];
  toString        = [self formatDate:_to];

  // SELECT
  [ms appendString:@"SELECT DISTINCT "
      @"d.date_id as pkey, "
      @"d.start_date as startdate, "
      @"d.end_date as enddate, "
      @"d.fbtype as fbtype, "
      @"d.busy_type as busytype"];

  // FROM
  [ms appendString:@" FROM "];
  [self appendFirst:[self dateTableName]             as:@"d"   to:ms];
  [self append:[self dateCompanyAssignmentTableName] as:@"dca" to:ms];
  [self append:[self personTableName]                as:@"p"   to:ms];
  [self append:[self companyAssignmentTableName]     as:@"ca"  to:ms];
  [self append:[self teamTableName]                  as:@"t"   to:ms];

  [ms appendFormat:@" WHERE "
      @"p.company_id = %@ AND "
      @"p.db_status <> 'archived' AND "

      @"ca.sub_company_id = p.company_id AND "
      @"t.company_id = ca.company_id AND "
   
      @"(dca.company_id = p.company_id OR dca.company_id = t.company_id) AND "
      @"d.end_date > %@ AND "
      @"d.start_date < %@ AND "
      @"d.date_id = dca.date_id",
      companyIdString, fromString, toString];

  return ms;
}

- (id)freeBusyDataForEmail:(NSString *)_email {
  NSCalendarDate *now = [NSCalendarDate date];
  return [self freeBusyDataForEmail:_email
               from:[now dateByAddingYears:0 months:-3 days:0]
               to:[now dateByAddingYears:0 months:3 days:0]];
}

- (id)freeBusyDataForEmail:(NSString *)_email
  from:(NSCalendarDate *)_from
  to:(NSCalendarDate *)_to
{
  EOKeyGlobalID *gid;
  
  // TODO: HACK HACK: why is the backend calling into the frontend?
  gid = (EOKeyGlobalID *)[NSClassFromString(@"SxAppointment")
                                           gidForPKeyEmail:_email];  
  return [self freeBusyDataForExpression:
               (gid != nil)
               ? [self buildExpressionForCompanyId:[gid keyValues][0]
                       from:_from to:_to]
               : [self buildExpressionForEmail:_email from:_from to:_to]];
}


- (id)freeBusyDataForCompanyId:(id)_companyId {
  NSCalendarDate *now = [NSCalendarDate date];
  return [self freeBusyDataForCompanyId:_companyId
               from:[now dateByAddingYears:0 months:-3 days:0]
               to:[now dateByAddingYears:0 months:3 days:0]];
}

- (id)freeBusyDataForCompanyId:(id)_companyId
                          from:(NSCalendarDate *)_from
                            to:(NSCalendarDate *)_to
{
  return [self freeBusyDataForExpression:
               [self buildExpressionForCompanyId:_companyId
                     from:_from to:_to]];
}

@end /* SxFreeBusyManager */
