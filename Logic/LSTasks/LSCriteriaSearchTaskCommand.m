/*
  Copyright (C) 2009 Whitemice Consulting (Adam Tauno Williams)

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

/* This command is used by zOGI to perform searches for tasks
   beyond todo/delegated/etc...  The client can search by attribute,
   property, or notation contents.  Currently used by the 
   _searchForTasks method of of "ZideStore/Protocols/zOGI/zOGIAction+Task.m".
   "property.{PROP}" is turned into  a property qualifier to allow searching 
   by property. "notation" keyword is matched to any comment on the job.

   TODO: Abstract this so the same functionality can be easily
         used to add useful search functionality to other 
         entities.  The qualifier searching supported via the
	 EOModel (or whatever) is very limited.  The theory is
         that we build a joined query of the relevent tables
         and then turn the provided criteria array of qualifications
         into a WHERE clause.

   TODO: Document.
 */

#include <LSFoundation/LSDBObjectBaseCommand.h>

@class NSCalendarDate, NSTimeZone, NSNumber;
@class NSMutableString;
@class LSCommandContext;

@interface LSCriteriaSearchTaskCommand : LSDBObjectBaseCommand
{
  NSArray          *criteria;
  NSMutableString  *sql;
  NSNumber         *limit;
}

@end

#include "common.h"

@implementation LSCriteriaSearchTaskCommand

+ (void)initialize {
}

- (id)initForOperation:(NSString *)_operation inDomain:(NSString *)_domain {
  if ((self = [super initForOperation:_operation inDomain:_domain])) {
    sql = [NSMutableString stringWithCapacity:512];
  }
  return self;
}

- (void)dealloc {
  [self->criteria release];
  [super dealloc];
}

- (NSMutableString *)query {
  return sql;
}

- (void)setCriteria:(NSArray *)_criteria {
  ASSIGNCOPY(self->criteria, _criteria);
}
- (NSArray *)criteria {
  return self->criteria;
}
- (void)setLimit:(NSNumber *)_limit {
  ASSIGNCOPY(self->limit, _limit);
}
- (NSNumber *)limit {
  return self->limit;
}

/* Query */

-(NSString *)_takeNamespaceFromProperty:(NSString *)_property {
  return [[[_property componentsSeparatedByString:@"}"]
              objectAtIndex:0] substringFromIndex:1];
} /* end _takeNamespaceFromProperty */

-(NSString *)_takeAttributeFromProperty:(NSString *)_property {
  return [[_property componentsSeparatedByString:@"}"] objectAtIndex:1];
} /* end _takeAttributeFromProperty */

-(void)_appendCriteriaForProperty:(NSString *)_property
                    andExpression:(NSString *)_expression
                         andValue:(id)_value
{
  [[self query] appendFormat:@"(op.namespace_prefix = '%@' AND "
                             @" op.value_key = '%@' AND "
                             @" op.value_string ",
                             [self _takeNamespaceFromProperty:_property],
                             [self _takeAttributeFromProperty:_property]];
  /* append expression, anything other than ILIKE or LIKE is EQUALS */
  if ([_expression isNotNull])
  {
    if ([_expression isEqualToString:@"ILIKE"] || 
        [_expression isEqualToString:@"LIKE"])
      [[self query] appendString:_expression];
    else [[self query] appendString:@"="];
  } else [[self query] appendString:@"="];
  /* append value */
  [[self query] appendFormat:@" '%@')", [_value stringValue]];
}

-(void)_appendCriteriaWithKey:(NSString *)_key
                andExpression:(NSString *)_expression
                     andValue:(id)_value
{
  [[self query] appendFormat:@"(%@ ", _key];
  /* append expression, anything other than ILIKE or LIKE is EQUALS */
  if ([_expression isEqualToString:@"ILIKE"] || 
      [_expression isEqualToString:@"LIKE"])
    [[self query] appendString:_expression];
  else if ([_expression isEqualToString:@"NOTEQUALS"])
    [[self query] appendString:@"!="];
  else [[self query] appendString:@"="];
  /* append value */
  if ([_value isKindOfClass:[NSString class]])
    [[self query] appendFormat:@" '%@')", _value];
  else [[self query] appendFormat:@" %@)", _value];
}

- (void)addInnerJoin:(NSString *)_entity 
                  as:(NSString *)_as 
                  on:(NSString *)_on {
  [[self query] appendFormat:@" INNER JOIN %@ %@ ON %@ ",
                     [[[self databaseModel] entityNamed:_entity] externalName],
                     _as,
                     _on];
}

- (void)addOuterJoin:(NSString *)_entity
                  as:(NSString *)_as 
                  on:(NSString *)_on {
  [[self query] appendFormat:@" LEFT OUTER JOIN %@ %@ ON %@ ",
                     [[[self databaseModel] entityNamed:_entity] externalName],
                     _as,
                     _on];
}

- (NSString *)translateKey:(NSString *)_key {
  NSString *key;
  
  key = [[[[self databaseModel] entityNamed:@"Job"] attributeNamed:_key] columnName];
  if ([key isNotNull])
    return [NSString stringWithFormat:@"j.%@", key];
  key = [[[[self databaseModel] entityNamed:@"JobHistory"] attributeNamed:_key] columnName];
  if ([key isNotNull])
    return [NSString stringWithFormat:@"jh.%@", key];
  key = [[[[self databaseModel] entityNamed:@"JobHistory"] attributeNamed:_key] columnName];
  if ([key isNotNull])
    return [NSString stringWithFormat:@"jhi.%@", key];
  key = [[[[self databaseModel] entityNamed:@"ObjectProperty"] attributeNamed:_key] columnName];
  if ([key isNotNull])
    return [NSString stringWithFormat:@"op.%@", key];
  return _key;
}

- (void)_processCriteriaArray:(NSArray *)_criteria {
  NSEnumerator *enumerator;
  NSArray      *keyParts;
  NSString     *key;
  id            c;
  int           counter = 0;

  enumerator = [_criteria objectEnumerator];
  [[self query] appendString:@" ("];
  while ((c = [enumerator nextObject]) != nil)
  {
    counter++;
    if (counter > 1)
    {
      if ([[c objectForKey:@"conjunction"] isNotNull])
        [[self query] appendFormat:@" %@ ", [c objectForKey:@"conjunction"]];
        else [[self query] appendFormat:@" AND "];
    }
    if ([[c objectForKey:@"key"] isNotNull])
    {
      keyParts = [[c objectForKey:@"key"] componentsSeparatedByString:@"."];
      if ([keyParts count] == 1)
      {
        key = [keyParts objectAtIndex:0];
        if ([key isEqualToString:@"notation"])
           key = @"jhi.comment";
        [self _appendCriteriaWithKey:[self translateKey:key]
                       andExpression:[c objectForKey:@"expression"]
                            andValue:[c objectForKey:@"value"]];
      } else
        {
          if ([[keyParts objectAtIndex:0] isEqualToString:@"property"])
          {
            key = [[c objectForKey:@"key"] substringFromIndex:9];
            [self _appendCriteriaForProperty:key
                               andExpression:[c objectForKey:@"expression"]
                                    andValue:[c objectForKey:@"value"]];
          } else [self logWithFormat:@"Discarding job search key %@", 
                                      [c objectForKey:@"key"]];
        }
    } else if ([[c objectForKey:@"clause"] isNotNull])
      {        
        [self _processCriteriaArray:[c objectForKey:@"clause"]];
      }
  }
  [[self query] appendString:@") "];
}

- (void)_buildQueryExpression {
  if ([self limit] == nil)
    [self setLimit:[NSNumber numberWithInt:150]];
  [[self query] appendFormat:@"SELECT DISTINCT j.job_id "
                             @"FROM %@ j ",
                             [[[self databaseModel] entityNamed:@"Job"] externalName]];
  [self addInnerJoin:@"JobHistory" 
                  as:@"jh" 
                  on:@"(jh.job_id = j.job_id)"];
  [self addInnerJoin:@"JobHistoryInfo" 
                  as:@"jhi" 
                  on:@"(jhi.job_history_id = jh.job_history_id)"];
  [self addOuterJoin:@"ObjectProperty" 
                  as:@"op" 
                  on:@"(op.obj_id = j.job_id)"];
  [[self query] appendString:@" WHERE "];
  if ([[self criteria] count] > 0)
    [self _processCriteriaArray:[self criteria]];
    else [[self query] appendString:@"1=1"];
  [[self query] appendFormat:@"LIMIT %@", [self limit]];
} /* end buildQueryExpression */

- (void)_prepareForExecutionInContext:(id)_context {
  [self _buildQueryExpression];
  [super _prepareForExecutionInContext:_context];
}

- (void)_executeInContext:(id)_context {
  NSArray             *attributes;
  NSDictionary        *record;
  EOAdaptorChannel    *eoChannel;
  NSMutableArray      *jobIds;
  NSArray             *gids;

  jobIds = [NSMutableArray arrayWithCapacity:150];
  eoChannel = [[self databaseChannel] adaptorChannel];
  if ([eoChannel evaluateExpression:[self query]]) {
    if ((attributes = [eoChannel describeResults]) != nil) {
      while ((record = [eoChannel fetchAttributes:attributes 
                                          withZone:NULL]) != nil) {
        [jobIds addObject:[record valueForKey:@"jobId"]];
      }
    }
  }
  gids = [[_context typeManager] globalIDsForPrimaryKeys:jobIds];
  [self setReturnValue:[_context runCommand:@"job::get-by-globalid",
                                            @"gids", gids,
                                            @"maxSearchCount", [self limit],
                                            nil]];
}

/* key-value coding */

- (void)takeValue:(id)_value forKey:(NSString *)_key {
  if ([_key isEqualTo:@"criteria"]) {
    [self setCriteria:_value];
  } else if ([_key isEqualTo:@"maxSearchCount"]) {
    [self setLimit:_value];
  } else {
      [super takeValue:_value forKey:_key];
    }
}

- (id)valueForKey:(NSString *)_key {
  if ([_key isEqualTo:@"criteria"])
    return [self criteria];
  if ([_key isEqualTo:@"maxSearchCount"])
    return [self limit];
  return [super valueForKey:_key];
}

@end /* LSCriteriaSearchTaskCommand */
