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

#ifndef __LSWebInterface_LSWTableView_H__
#define __LSWebInterface_LSWTableView_H__

#include <NGObjWeb/WOComponent.h>

@class NSArray, NSNumber;
@class NSFormatter;
@class LSWTableView;

/*
  NOTE: This component is DEPRECATED - use SkyTableView instead!
  
  LSWTableView Attributes:

    > title              - title of table view
    > label              - string left from content repetition
    > labels             - labels string dictionary (used by "labelKey" attr.)
    > list               - array of objects able to perform KVC
    < item               - current object of list array
    > itemActionDisabled - is action for item disabled ?
    <>start              - start index in 'list' array
    > blockSize          - height of table view (number of entries displayed)
    > attributes         - attribute configuration
    <>selectedAttribute  - current sort attribute
    > sorter             - object used to sort an array (an LSWTableViewSorter)
    < relatedObject      - object which is related to 'item'

  Callbacks
  
    > onNew              - parent action invoked if the new     link is clicked
    > onImport           - parent action invoked if the import  link is clicked
    > onRefresh          - parent action invoked if the refresh link is clicked

  Attribute attributes:

    key                  - key of value
    relKey               - relation key
    sort                 - enable or disable sorting (i.e. sort=YES)
    action               - parent action (i.e action="view")
    label                - attribute label (NOT LOCALIZED: use labelKey instead)
    nilString            - used if no value is found for key (i.e nilString="")
    labelKey             - attribute label
    isLocalized          - is value localized? (i.e. isLocalized=YES)
    isAltLocalized       - is altLabel localized? (i.e. isAltLocalized=YES)
    labels               - label dictionary (OLD: use isLocalized instead!!!)
    alt                  -
    altLabel             -
    href                 -
    image                -
    target               -
    align
    

  Example:
  
    ProjectList: LSWTableView {
      title             = "Projects";
      labels            = labels;
      start             = start;
      list              = projects;
      item              = project;
      selectedAttribute = selectedAttribute;
      attributes        = (
        { key = "name";  sort = YES; action = "viewProject"; },
        { key = "owner"; sort = NO;  relKey = "login"; label  = "manager"; },
        { 
          key       = "team"; 
          relKey    = "description"; 
          label     = "access team"; 
          sort      = NO;
          nilString = "private"; 
        },
        { key = "firstname"; sort=YES; labelKey="firstName"; },
        { key = "category"; sort=YES; isLocalized=YES; },
      );
      blockSize         = 10;
      sorter            = session.eoSorter;
      onNew             = "newProject";
    }
*/

@protocol LSWTableViewSorter < NSObject >

- (NSArray *)sortArray:(NSArray *)_array
  key:(NSString *)_key
  isDescending:(BOOL)_flag;

@end

@interface LSWTableView : WOComponent
{
@protected
  NSArray      *list;
  id           item;
  unsigned     index;
  unsigned     blockSize;       // HH: count
  unsigned     start;           // persistent HH: startIndex
  NSString     *evenRowColor;
  NSString     *oddRowColor;
  NSString     *nullString;

  NSArray      *attributes;
  NSString     *title;
  NSString     *label;
  id           labels;
  NSDictionary *selectedAttribute;
  BOOL         isDescending;    // otherwise ascending
  BOOL         isActionDisabled;
  BOOL         isMailAvailable;
  BOOL         isInternalMailEditor;
  id<LSWTableViewSorter> sort;

  // transient
  NSDictionary *attribute;      // non-retained
  NSString     *attributeKey;   // non-retained
  NSString     *relKey;         // non-retained

  NSString     *onNew;
  NSString     *onImport;
  NSString     *onRefresh;
  id           relatedObject;
  unsigned     idx;
  NSArray      *sortedArray;

  NSFormatter *dateFormatter;
  NSFormatter *numberFormatter;

  id configHandler;

  // cached methods
  id (*getItemValue)(id self, SEL _cmd, NSString *_key);
  id (*getAttrValue)(id self, SEL _cmd, NSString *_key);
}

// API

- (void)setTitle:(NSString *)_title;
- (NSString *)title;
- (void)setLabel:(NSString *)_label;
- (NSString *)label;
- (void)setLabels:(id)_labels;

- (void)setList:(NSArray *)_list;
- (NSArray *)list;
- (void)setItem:(id)_item;
- (id)item;

- (void)setStart:(unsigned)_start;
- (unsigned)start;
- (void)setBlockSize:(unsigned)_blockSize;
- (unsigned)blockSize;

- (void)setAttributes:(NSArray *)_attributes;
- (NSArray *)attributes;

- (void)setSelectedAttribute:(NSDictionary *)_attribute;
- (NSDictionary *)selectedAttribute;
- (void)setIsDescending:(BOOL)_isDescending;
- (BOOL)isDescending;

- (void)setSorter:(id<LSWTableViewSorter>)_sorter;
- (id<LSWTableViewSorter>)sorter;

- (void)setDateFormatter:(NSFormatter *)_formatter;
- (NSFormatter *)dateFormatter;

- (void)setNumberFormatter:(NSFormatter *)_formatter;
- (NSFormatter *)numberFormatter;

- (void)setRelatedObject:(id)_object;
- (id)relatedObject;

- (void)setOnNew:(NSString *)_onNew;
- (NSString *)onNew;
- (void)setOnImport:(NSString *)_onImport;
- (NSString *)onImport;
- (void)setOnRefresh:(NSString *)_onRefresh;
- (NSString *)onRefresh;

// internal

- (BOOL)isSelectedAttribute;

- (unsigned)currentPageNumber;
- (unsigned)lastPageNumber;
- (unsigned)objectsFrom;
- (unsigned)objectsTo;

- (void)setEvenRowColor:(NSString *)_color;
- (NSString *)evenRowColor;
- (void)setOddRowColor:(NSString *)_color;
- (NSString *)oddRowColor;

- (void)setIndex:(unsigned)_idx;
- (unsigned)index;

- (NSString *)relatedObjectAlt;

- (BOOL)isNotFirstPage;
- (BOOL)isNotLastPage;

- (BOOL)isLinkAttribute;

- (id)viewObject;

@end

#import <NGObjWeb/WODynamicElement.h>

@interface WODynamicElement(LSWTableViewAdditions)

- (void)appendFontToResponse:(WOResponse *)_response
  color:(NSString *)_color
  face:(NSString *)_face
  size:(NSString *)_size;

@end
  
#endif /* __LSWebInterface_LSWTableView_H__ */
