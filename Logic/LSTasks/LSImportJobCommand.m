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

#include "LSImportJobCommand.h"
#include "common.h"

@implementation LSImportJobCommand

#if !LIB_FOUNDATION_BOEHM_GC
- (void)dealloc {
  RELEASE(self->data);
  RELEASE(self->errorReport);
  RELEASE(self->accounts);
  [super dealloc];
}
#endif

static id _searchAccounts(LSImportJobCommand *self, NSString *_id) {
  IMP     objAtIdx;
  int     i, cnt;
  id      obj       = nil;

  objAtIdx = [self->accounts methodForSelector:@selector(objectAtIndex:)];
  for (i = 0, cnt = [self->accounts count]; i < cnt; i++) {
    id name = nil;
    
    obj  = objAtIdx(self->accounts, @selector(objectAtIndex:), i);
    name = [obj valueForKey:@"job_import_name"];
    
    if ([name isNotNull]) {
      if ([name isEqualToString:_id])
        return obj;
    }
  }
  return nil;
}

static inline void _writeError(LSImportJobCommand *self,
                               int _pos,
                               NSString *_report) {
  NSMutableArray *report = nil;
  NSString       *number = [[NSNumber numberWithInt:_pos] stringValue];

  if ((report = [self->errorReport objectForKey:number]) == nil) {
    report = [NSMutableArray arrayWithCapacity:16];
    [self->errorReport setObject:report forKey:number];
  }
  [report addObject:_report];
}

static inline NSString *_skipCtrlsAndSpaces(NSString *_string) {
  int        i;
  char const *string = [_string cString];
  int        length  = [_string cStringLength];

  for (i = length - 1; i >= 0; i--) {
    if (string[i] != ' ' && string[i] != '\n' && string[i] != '\r')
      break;
  }
  return [NSString stringWithCString:string length:i+1];
}

typedef BOOL (*SetFunction)(id, NSMutableDictionary *, NSString *,id, id, int);

static inline NSString *_getTimeZone(id self, id _context);
static inline NSString *_getImportString(id self, id _data);
static inline int      _setFcts(id self, NSDictionary *_config,
                                SetFunction **_importFcts);
BOOL _checkJobColumn(id, id, int);

BOOL _setHierachieNumer(id self, NSMutableDictionary *_job, NSString *_timeZone,
                        id _data, id _name, int _cnt);
BOOL _setStartDate(id self, NSMutableDictionary *_job, NSString *_timeZone,
                    id _data, id _name, int _cnt);
BOOL _setEndDate(id self, NSMutableDictionary *_job, NSString *_timeZone,
                 id _data, id _name, int _cnt);
BOOL _setExecutant(id self, NSMutableDictionary *_job, NSString *_timeZone,
                   id _data, id _name, int _cnt);
BOOL _setDatabaseField(id self, NSMutableDictionary *_job, NSString *_timeZone,
                       id _data, id _name, int _cnt);


- (void)_executeInContext:(id)_context {
  SetFunction    *importFcts = NULL;
  NSDictionary   *config     = nil;
  int            fctCount    = 0;
  NSMutableArray *jobList    = nil;

  config  = [[_context userDefaults] dictionaryForKey:@"LSJobImportFormat"];
  jobList = [NSMutableArray arrayWithCapacity:64];
  
  if ((fctCount = _setFcts(self, config, &importFcts)) != -1) {
    NSString       *seperator     = nil;
    NSString       *timeZone      = nil;
    NSArray        *import        = nil;
    IMP            objAtIdxImport = NULL;
    SEL            objAtIdx       = NULL;
    int            i, cnt         = 0;
    NSArray        *importMap     = nil;
    IMP            objAtIdxMap    = NULL;

    objAtIdx = @selector(objectAtIndex:);
    
    importMap   = [config valueForKey:@"Format"];
    objAtIdxMap = [importMap methodForSelector:objAtIdx];
    seperator   = [config valueForKey:@"Seperator"];
    timeZone    = _getTimeZone(self, _context);
    import      = [_getImportString(self, self->data)
                                  componentsSeparatedByString:@"\n"];
    objAtIdxImport = [import methodForSelector:objAtIdx];
    
    for (i = 0, cnt = [import count]; i < cnt; i++) {
      NSArray *jobImportColumn =
                        [objAtIdxImport(import, objAtIdx, i)
                                       componentsSeparatedByString:seperator];
      
      if (_checkJobColumn(self, jobImportColumn, fctCount)) {
        IMP                 objAtIdxColumn = NULL;
        int                 iC, cntC       = 0;
        NSMutableDictionary *job           = nil;
        BOOL                checkImp       = YES;

        cntC = [jobImportColumn count];
        job = [NSMutableDictionary dictionaryWithCapacity:cntC];
        objAtIdxColumn  = [jobImportColumn methodForSelector:objAtIdx];
        checkImp = YES;
        for (iC = 0; iC < cntC; iC++) {
          BOOL check = importFcts[iC](self, job, timeZone,
                             _skipCtrlsAndSpaces(objAtIdxColumn(jobImportColumn,
                                                                objAtIdx, iC)),
                             objAtIdxMap(importMap, objAtIdx, iC), i);
          checkImp = checkImp && check;
        }
        if (checkImp && ([job count] ==fctCount))
          [jobList addObject:job];
      }
    }
  }
  NGFree(importFcts);
  [self setReturnValue:jobList];
}

static inline NSString *_getTimeZone(id self, id _context) {
  NSString *timeZone;
  
  timeZone = [(NSUserDefaults *)[_context valueForKey:LSUserDefaultsKey] 
                                objectForKey:@"timezone"];
  if (timeZone == nil) {
    [self logWithFormat:@"Note: user has no timezone ste, using GMT."];
    timeZone = @"GMT";
  }
  return timeZone;
}

static inline NSString *_getImportString(id self, id _data) {
  if ([_data isKindOfClass:[NSString class]])
    return _data;

  if ([_data isKindOfClass:[NSData class]]) {
    NSString *returnValue;
    
    returnValue = [[NSString alloc] initWithData:_data
                                      encoding:NSASCIIStringEncoding];
    return [returnValue autorelease];
  }
  
  [self logWithFormat:@"ERROR: unsupported data-object[%@]: %@", 
          [_data class], _data];
  return nil;
}

static inline int _setFcts(id self, NSDictionary *_config,
                           SetFunction **_importFcts) {
  
  NSArray      *format     = nil;
  NSEnumerator *enumerator = nil;
  id           obj         = nil;
  int          cnt, i      = 0;
  SEL          _cmd        = @selector(_setFcts);

  NSAssert(*_importFcts == NULL, @"importFcts should be NULL");
  
  format     = [_config valueForKey:@"Format"];
  cnt        = [format count];
  enumerator = [format objectEnumerator];

  *_importFcts = (void *)NGMallocAtomic(sizeof(SetFunction) * cnt);
  i = 0;
  while ((obj = [enumerator nextObject])) {
    if ([obj isEqualToString:@"startDate"])
      (*_importFcts)[i] = (void *)_setStartDate;
    else if ([obj isEqualToString:@"endDate"])
      (*_importFcts)[i] = (void *)_setEndDate;
    else if ([obj isEqualToString:@"ExecutantToken"])
      (*_importFcts)[i] = (void *)_setExecutant;
    else
      (*_importFcts)[i] = (void *)_setDatabaseField;
      
    i++;
  }
  return cnt;
}

BOOL _setStartDate(id self, NSMutableDictionary *_job, NSString *_timeZone,
                   id _data, id _name, int _cnt) {
  NSString *format = @"%Y-%m-%d %Z";      
  NSString *sDate = [[_data stringByAppendingString:@" "]
                            stringByAppendingString:_timeZone];
  NSCalendarDate *date  = [NSCalendarDate dateWithString:sDate
                                          calendarFormat:format];
  if (date) {
    [_job setObject:date forKey:@"startDate"];
  }
  else {
    _writeError(self, _cnt + 1,
                [[@"no startdate \"" stringByAppendingString:
                   sDate] stringByAppendingString:@"\""]);
    return NO;
  }
  return YES;
}

BOOL _setEndDate(id self, NSMutableDictionary *_job, NSString *_timeZone,
                 id _data, id _name, int _cnt) {

  NSString *format = @"%Y-%m-%d %Z";
  NSString *sDate = [[_data stringByAppendingString:@" "]
                            stringByAppendingString:_timeZone];
  NSCalendarDate *date  = [NSCalendarDate dateWithString:sDate
                                          calendarFormat:format];
  if (date) {
    [_job setObject:date forKey:@"endDate"];
  }
  else {
    _writeError(self, _cnt + 1,
                [[@"no enddate \"" stringByAppendingString:
                   sDate] stringByAppendingString:@"\""]);
    return NO;
  }
  return YES;
}

BOOL _setExecutant(id self, NSMutableDictionary *_job, NSString *_timeZone,
                   id _data, id _name, int _cnt) {

  id dum = _searchAccounts(self, _data);
  
  if (dum != nil)
    [_job setObject:dum forKey:@"executant"];
  else {
    _writeError(self, _cnt + 1,
                [[@"found no executant for name \""
                   stringByAppendingString: _data]
                          stringByAppendingString:@"\""]);
    return NO;
  }
  return YES;
}

BOOL _setDatabaseField(id self, NSMutableDictionary *_job, NSString *_timeZone,
                       id _data, id _name, int _cnt) {
  [_job setObject:_data forKey:_name];
  return YES;
}
  
BOOL _checkJobColumn(id self, id _obj, int _cnt) {
  if ([_obj isKindOfClass:[NSArray class]])
    if ([_obj count] == _cnt)
      return YES;
  return NO;
}

/*
- (void)_executeInContext:(id)_context {
  NSString            *string    = nil;
  NSArray             *compArray = nil;
  NSMutableArray      *result    = nil;
  NSMutableDictionary *job       = nil;  
  IMP                 objAtIdx;
  IMP                 addObj;   
  int                 i, cnt;
  NSString            *timeZone  = nil;


  compArray = [string componentsSeparatedByString:@"\n"];
  objAtIdx  = [compArray methodForSelector:@selector(objectAtIndex:)];
  result    = [NSMutableArray array];
  addObj    = [result methodForSelector:@selector(addObject:)];
  
  for (i = 0, cnt = [compArray count]; i < cnt; i++) {
    NSMutableDictionary *job       = nil;
    NSArray             *jobPieces = nil;
    id                  executant  = nil;

    job = [NSMutableDictionary dictionaryWithCapacity:5];
    jobPieces =[objAtIdx(compArray, @selector(objectAtIndex:), i)
                        componentsSeparatedByString:@";"];
    if ([jobPieces count] != 5) {
      if ([_skipCtrlsAndSpaces([compArray objectAtIndex:i])cStringLength] > 0) {
        _writeError(self, i + 1, [@"wrong format "
                               stringByAppendingString:
                               [compArray objectAtIndex:i]]);
      }
    }
    else {
      { // number
        [job setObject:[jobPieces objectAtIndex:0] forKey:@"number"];
      }
      { // job-name
        [job setObject:[jobPieces objectAtIndex:1] forKey:@"name"];
      }
      { // start-date
      }
      { // end-date
      }
      { // get EO - Executant
      }
      if ([job count] == 4) {
        addObj(result, @selector(addObject:), job);
      }
      else
        _writeError(self, i + 1,
                    [@"couldn`t import record: " stringByAppendingString:
                      [job description]]);
    }
  }
  [self setReturnValue:result];
}
*/
// accessors

- (id)data {
  return self->data;
}
- (void)setData:(id)_data {
  ASSIGN(self->data, _data);
}

- (id)accounts {
  return self->accounts;
}
- (void)setAccounts:(id)_accounts {
  ASSIGN(self->accounts, _accounts);
}

- (NSMutableDictionary *)errorReport {
  return self->errorReport;
}
- (void)setErrorReport:(NSMutableDictionary *)_report {
  ASSIGN(self->errorReport, _report);
}
// key/value coding

- (void)takeValue:(id)_value forKey:(id)_key {
  if ([_key isEqualToString:@"data"])
    [self setData:_value];
  else if ([_key isEqualToString:@"errorReport"]) {
    NSAssert([_value isKindOfClass:[NSMutableDictionary class]],
             @"errorReport is no mutable dictionary");
    [self setErrorReport:_value];
  }
  else if ([_key isEqualToString:@"accounts"]) {
    [self setAccounts:_value];
  }
  else
    [self foundInvalidSetKey:_key];
}

- (id)valueForKey:(id)_key {
  if ([_key isEqualToString:@"data"])
    return [self data];
  else
    return [self foundInvalidGetKey:_key];
}


@end
