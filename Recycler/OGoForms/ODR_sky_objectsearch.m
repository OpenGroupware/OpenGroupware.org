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

#include <NGObjDOM/ODNodeRenderer.h>
#include <EOControl/EOControl.h>

/*
  Usage:
    
    <var:objectsearch datasource="datasource"
                      item="item"
                      string="string"
                      [selection="selection" | selections="selections"]
                      nilstring="nilstring"
                      qualifier="qualifier">
        some content
    </var:objectsearch>

  Example:

  <div>
    <script runat="server"><![CDATA[
       var selections = [];
       var project    = getProject();
       var ds         = project.getJobDataSource();
       var searchstr  = "";

       ds.setQualifier("name = 'test' AND name <> 'test'");

       function qualifier() {
         return (searchstr.length == 0)
           ? "name = 'test' AND name <> 'test'"
           : ("name like '" + searchstr + "*'");
       }
    ]]>
    </script>

    <var:objectsearch datasource="ds" item="item" string="item.name"
                      const:columns="3"
                      searchstring="searchstr"
                      js:qualifier="qualifier()"
                      const:nilstring="Not selected"
                      selection="selection">
                      
      <var:string value="item"/>

    </var:objectsearch>
  </div>                  
*/

@interface ODR_sky_objectsearch : ODNodeRenderer
{
  EODataSource *ds;
  NSArray      *selections;
  NSArray      *list;
  NSString     *formName;

  int     maxColumns;
  struct is {
    BOOL horizontal;
    BOOL checkbox;
  } is;
}
@end

#include "common.h"
#include <OGoFoundation/OGoComponent.h>
#include <OGoFoundation/OGoSession.h>
#include <OGoDocuments/SkyDocumentManager.h>

@implementation ODR_sky_objectsearch

- (void)dealloc {
  [self->selections release];
  [self->list     release];
  [self->formName release];
  [self->ds       release];
  [super dealloc];
}

- (BOOL)requiresFormForNode:(id)_domNode inContext:(WOContext *)_ctx {
  return YES;
}

static inline void
_applyIndex(ODR_sky_objectsearch *self, id _node, WOContext *_ctx, int _idx)
{
  BOOL     isHor;
  unsigned r, c, cnt, cols;

  isHor = self->is.horizontal;
  cols  = self->maxColumns;
  cnt   = [self->list count];
  r     = (isHor) ? (_idx / cols) + 1 : _idx % ((cnt / cols)+1) + 1;
  c     = (isHor) ? (_idx % cols) + 1 : _idx / ((cnt / cols)+1) + 1;

  if ([self isSettable:@"index" node:_node ctx:_ctx])
    [self setInt:_idx for:@"index" node:_node ctx:_ctx];

  if ([self isSettable:@"row" node:_node ctx:_ctx])
    [self setInt:r for:@"row" node:_node ctx:_ctx];

  if ([self isSettable:@"col" node:_node ctx:_ctx])
    [self setInt:c for:@"col" node:_node ctx:_ctx];
  
  if ([self isSettable:@"item" node:_node ctx:_ctx]) {
    if ((unsigned)_idx < cnt && (_idx >= 0))
      [self setValue:[self->list objectAtIndex:_idx]
            for:@"item" node:_node ctx:_ctx];
    else {
      [[_ctx component]
             debugWithFormat:@"array did change, index is invalid."];
      [self setValue:nil for:@"item" node:_node ctx:_ctx];
    }
  }
}

- (void)updateCacheForNode:(id)_node context:(WOContext *)_context {
  id tmp;
  
  [self->selections release]; self->selections = nil;
  [self->list       release]; self->list       = nil;
  [self->formName   release]; self->formName   = nil;
  [self->ds         release]; self->ds         = nil;
  self->is.checkbox  = NO;
  
  if ((tmp =[self valueFor:@"selections" node:_node ctx:_context])) {
    ASSIGN(self->selections, tmp);
    self->is.checkbox = YES;
  }
  else if ((tmp =[self valueFor:@"selection" node:_node ctx:_context])) {
    tmp = [NSArray arrayWithObject:tmp];
    ASSIGN(self->selections, tmp);
    self->is.checkbox = NO;    
  }

  if ((tmp = [self valueFor:@"datasource" node:_node ctx:_context])) {
    ASSIGN(self->ds, tmp);
    tmp = [tmp fetchObjects];
    ASSIGN(self->list, tmp);
  }

  // merge 'list' and 'selection'
  if (self->is.checkbox || ([self->selections count] > 0 &&
      ![self->list containsObject:[self->selections lastObject]])) {
    int i, cnt;

    tmp  = [NSMutableArray arrayWithArray:self->selections];
    cnt  = [self->list count];
    for (i=0; i<cnt; i++) {
      id obj = [self->list objectAtIndex:i];

      if (![self->selections containsObject:obj])
        [tmp addObject:obj];
    }
    ASSIGN(self->list, tmp);
  }
  
  self->is.horizontal = [self boolFor:@"ishorizontal" node:_node ctx:_context];
  self->maxColumns    = [self  intFor:@"columns"      node:_node ctx:_context];
  self->maxColumns    = (self->maxColumns) ? self->maxColumns : 1;
  self->formName      = [[_context elementID] retain];
}

- (void)appendCheckbox:(id)_node
              response:(WOResponse *)_response
               context:(WOContext *)_ctx
                 index:(int)_idx
{
  NSString *string = [self stringFor:@"string" node:_node ctx:_ctx];
  id       item    = [self  valueFor:@"item"   node:_node ctx:_ctx];
  NSString *type   = nil;

  type = (self->is.checkbox) ? @"checkbox" : @"radio";
  
  [_response appendContentString:@"<input type=\""];
  [_response appendContentString:type];
  [_response appendContentString:@"\" name=\""];
  [_response appendContentString:self->formName];
  [_response appendContentString:@"\" value=\""];
  [_response appendContentString:[NSString stringWithFormat:@"%d", _idx]];
  [_response appendContentCharacter:'"'];
  if ([self->selections containsObject:item])
    [_response appendContentString:@" checked"];
  [_response appendContentString:@">\n"];
  
  if (string)
    [_response appendContentHTMLString:string];
}

- (void)appendListForNode:(id)_node
  response:(WOResponse *)_response
  context:(WOContext *)_ctx
{
  WOComponent *comp  = nil;
  unsigned    c, colCount; // column index
  unsigned    r, rowCount; // row    index
  unsigned    cnt;

  comp     = [_ctx component];
  colCount = self->maxColumns;
  cnt      = [self->list count];
  
  colCount = (colCount < cnt) ? colCount : cnt;
  colCount = (colCount) ? colCount : 1;
  rowCount = ((cnt % colCount) > 0) ? (cnt / colCount) + 1 : (cnt / colCount);

  [_response appendContentString:@"<table>\n"];

  // append nil string checkbox
  if (!self->is.checkbox &&
      [self hasAttribute:@"nilstring" node:_node ctx:_ctx]) {
    NSString *nilString = [self stringFor:@"nilstring" node:_node ctx:_ctx];

    [_response appendContentString:[NSString stringWithFormat:
               @"<tr><td align=\"left\" colspan=\"%d\">\n", colCount]];
    [_response appendContentString:@"<input type=\"radio\" name=\""];
    [_response appendContentString:self->formName];
    [_response appendContentString:@"\" value=\"nil\""];
    if ([self->selections count] == 0)
      [_response appendContentString:@" checked"];
    [_response appendContentString:@">\n"];
    [_response appendContentHTMLString:nilString];

    // append child nodes
    if ([self isSettable:@"item" node:_node ctx:_ctx])
      [self setValue:nil for:@"item" node:_node ctx:_ctx];
    
    [_ctx appendElementIDComponent:@"nil"];
    [super appendNode:_node toResponse:_response inContext:_ctx];
    [_ctx deleteLastElementIDComponent];
    
    [_response appendContentString:@"</td></tr>"];
  }

  for (r=0; r<rowCount; r++) {
    [_response appendContentString:@"<tr>"];    
    for (c=0; c<colCount; c++) {
      NSString *cColor = nil;
      NSString *align  = nil;
      NSString *valign = nil;
      NSString *width  = nil;
      unsigned i = (self->is.horizontal) ? r*colCount+c : c*rowCount+r;

      width = [NSString stringWithFormat:@"%d%%", (int)(100 / colCount)];

      [_response appendContentString:@"<td"];
      if (width) {
        [_response appendContentString:@" width=\""];
        [_response appendContentString:width];
        [_response appendContentCharacter:'"'];
      }
      if (cColor) {
        [_response appendContentString:@" bgcolor=\""];
        [_response appendContentString:cColor];
        [_response appendContentCharacter:'"'];
      }
      if (align) {
        [_response appendContentString:@" align=\""];
        [_response appendContentString:align];
        [_response appendContentCharacter:'"'];
      }
      if (valign) {
        [_response appendContentString:@" valign=\""];
        [_response appendContentString:valign];
        [_response appendContentCharacter:'"'];
      }
      [_response appendContentCharacter:'>'];

      if (i<cnt) {
        [_ctx appendElementIDComponent:[NSString stringWithFormat:@"%i", i]];
        _applyIndex(self, _node, _ctx, i);
        [self appendCheckbox:_node response:_response context:_ctx index:i];
        [super appendNode:_node toResponse:_response inContext:_ctx];
        [_ctx deleteLastElementIDComponent];
      }
      else
        [_response appendContentString:@"&nbsp;"];

      [_response appendContentString:@"</td>"];
    }
    [_response appendContentString:@"</tr>"];
  }
  [_response appendContentString:@"</table>"];
}

- (void)appendTextFieldAndSubmit:(id)_node
  response:(WOResponse *)_response
  context:(WOContext *)_ctx
{
  NSString *searchStr = nil;

  if ([self hasAttribute:@"searchstring" node:_node ctx:_ctx])
    searchStr = [self stringFor:@"searchstring" node:_node ctx:_ctx];
      
  [_ctx appendElementIDComponent:@"text"];
  [_response appendContentString:
             @"<input type=\"text\" size=\"30\" name=\""];
  [_response appendContentString:[_ctx elementID]];
  [_response appendContentString:@"\" value=\""];
  [_response appendContentString:searchStr];
  [_response appendContentString:@"\">"];
  [_ctx deleteLastElementIDComponent]; // delete 'text'

  [_ctx appendElementIDComponent:@"submit"];
  [_response appendContentString:
             @"<input type=\"submit\" value=\"search\" name=\""];
  [_response appendContentString:[_ctx elementID]];
  [_response appendContentString:@"\">"];
  [_ctx deleteLastElementIDComponent]; // delete 'submit'
}

- (void)takeValuesForNode:(id)_node
  fromRequest:(WORequest *)_request
  inContext:(WOContext *)_ctx
{
  int i, cnt;
  
  [self updateCacheForNode:_node context:_ctx];

  cnt = [self->list count];

  {
    id textField;
    id submitButton;    
    
    [_ctx appendElementIDComponent:@"text"];
    textField = [_request formValueForKey:[_ctx elementID]];
    
    [self forceSetString:textField for:@"searchstring" node:_node ctx:_ctx];
    
    [_ctx deleteLastElementIDComponent]; // delete 'text'

    [_ctx appendElementIDComponent:@"submit"];
    submitButton = [_request formValueForKey:[_ctx elementID]];
    if (submitButton) {
      EOQualifier          *qual;
      NSString             *qualStr;
      EOFetchSpecification *fspec;

      qualStr = ([self hasAttribute:@"qualifier" node:_node ctx:_ctx])
        ? [self stringFor:@"qualifier" node:_node ctx:_ctx]
        : textField;
      
      qual = [EOQualifier qualifierWithQualifierFormat:qualStr];
      
      fspec = [[self->ds fetchSpecification] copy];
      if (fspec == nil)
        fspec = [[EOFetchSpecification alloc] init];
      [fspec setQualifier:qual];
      [self->ds setFetchSpecification:fspec];
      [fspec release]; fspec = nil;
    }
    [_ctx deleteLastElementIDComponent]; // delete 'submit'
  }
  
  if (self->is.checkbox) {
    NSMutableArray *sels;
    NSArray        *indices;
    int selCnt;
    
    indices = [_request formValuesForKey:self->formName];
    indices = [indices sortedArrayUsingSelector:@selector(compare:)];
    selCnt  = [indices count];
    sels    = [NSMutableArray arrayWithCapacity:selCnt];
    
    for (i=0; i < selCnt; i++) {
      int idx  = [[indices objectAtIndex:i] intValue];
      id  item = nil;

      if (0 <= idx && idx < cnt)
        item = [self->list objectAtIndex:idx];

      if (item)
        [sels addObject:item];
    }
    if ([self isSettable:@"selections" node:_node ctx:_ctx])
      [self setValue:sels for:@"selections" node:_node ctx:_ctx];
  }
  else {
    id item      = nil;
    id formValue = [_request formValueForKey:self->formName];

    if ((formValue != nil) && ![formValue isEqualToString:@"nil"]) {
      i = [formValue intValue];
      if (0 <= i && i < cnt)
        item = [self->list objectAtIndex:i];
    }
    
    if ([self isSettable:@"selection" node:_node ctx:_ctx])
      [self setValue:item for:@"selection" node:_node ctx:_ctx];
  }
}

- (id)invokeActionForNode:(id)_node
  fromRequest:(WORequest *)_request
  inContext:(WOContext *)_ctx
{
  return [super invokeActionForNode:_node
                fromRequest:_request
                inContext:_ctx];
}

- (void)appendNode:(id)_node
  toResponse:(WOResponse *)_response
  inContext:(WOContext *)_ctx
{
  [self updateCacheForNode:_node context:_ctx];
  [self appendTextFieldAndSubmit:_node response:_response context:_ctx];
  [self appendListForNode:_node response:_response context:_ctx];
}

@end /* ODR_sky_objectsearch */
