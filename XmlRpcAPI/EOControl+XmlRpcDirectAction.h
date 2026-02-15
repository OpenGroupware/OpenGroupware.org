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

#ifndef __SkyXmlRpcServer_EOControl_XmlRpcDirectAction_H__
#define __SkyXmlRpcServer_EOControl_XmlRpcDirectAction_H__

#include <EOControl/EOFetchSpecification.h>
#include <EOControl/EOSortOrdering.h>
#include <EOControl/EOQualifier.h>

/**
 * @category EOFetchSpecification(XmlRpcDirectAction)
 *
 * Adds -initWithBaseValue: to EOFetchSpecification for
 * constructing fetch specifications from XML-RPC
 * parameters. Accepts an NSDictionary with optional keys
 * "qualifier", "sortOrderings", "fetchLimit", and "hints",
 * or a plain qualifier format string. Automatically
 * disables document observer registration.
 */
@interface EOFetchSpecification(XmlRpcDirectAction)

- (id)initWithBaseValue:(id)_baseValue;

@end /* EOFetchSpecification(XmlRpcDirectAction) */

/**
 * @category EOSortOrdering(XmlRpcDirectAction)
 *
 * Adds -initWithBaseValue: to EOSortOrdering for
 * constructing sort orderings from XML-RPC parameters.
 * Accepts an NSDictionary with "key" and optional
 * "selector" entries, or a plain key string (defaults
 * to ascending sort).
 */
@interface EOSortOrdering(XmlRpcDirectAction)

- (id)initWithBaseValue:(id)_baseValue;

@end /* EOSortOrdering(XmlRpcDirectAction) */

/**
 * @category EOQualifier(XmlRpcDirectAction)
 *
 * Adds +qualifierToMatchAllValues:selector: to
 * EOQualifier for constructing AND-combined
 * key-value qualifiers from a dictionary. Each
 * key-value pair becomes an EOKeyValueQualifier joined
 * into an EOAndQualifier.
 */
@interface EOQualifier(XmlRpcDirectAction)

+ (EOQualifier *)qualifierToMatchAllValues:(NSDictionary *)_values
  selector:(SEL)_sel;

@end /* EOQualifier(XmlRpcDirectAction */

#endif /* __SkyXmlRpcServer_EOControl_XmlRpcDirectAction_H__ */
