#!/usr/bin/env python
# $Id: docmodel.py,v 1.1 2003/07/31 14:02:07 helge Exp $

#
# docmodel
#
# This tool is supposed to generate HTML reference documentation for
# an OGo model.
# It already emits a valid, but extremely ugly HTML file - to be worked
# on ...
#

from types  import *
from sys    import argv
import sys;
from string import uppercase, split

skyModelPath = argv[1]
adaptorName  = argv[2]

modelenv = {}

# formats

header = """<html>
  <head>
    <!-- automagically generated - DO NOT EDIT -->
    <title>OGo Database - Schema %(adaptorName)s</title>
  </head>
  <body bgcolor=\"#FFFFFF\">

  <table border="0">
    <tr>
      <td>Generation of Primary Keys (newKeyExpression)</td>
    </tr>
    <tr>
      <td><tt>%(newKeyExpression)s\"</tt></td>
    </tr>
  </table>

  <h4>Entities</h4>
  
"""

footer = "</body>\n</html>\n"

entityHeader = """
  <table border="0" width="100%%">
    <tr>
      <td width="25%%">Entity:</td>
      <td>%(name)s</td>
    </tr>
    <tr>
      <td><nobr>Mapped to Class</nobr></td>
      <td>%(className)s</td>
    </tr>
    <tr>
      <td><nobr>Primary-Key:</nobr></td>
      <td>%(primaryKey)s</td>
    </tr>
"""

entityFooter = "  </table>\n"

# attribute templates

attrsLockHeader = """
    <tr>
      <td valign="top"><nobr>Locked:</nobr></td>
      <td>
"""
attrsLockFooter = """
      </td>
    </tr>
"""
classPropHeader = """
    <tr>
      <td valign="top"><nobr>Properties:</nobr></td>
      <td>
"""
classPropFooter = """
      </td>
    </tr>
"""

attributesHeader    = """
    <tr>
      <td valign="top">Attributes:</td>
      <td>
        <table border="0" width="100%%">
          <tr>
            <td>Name</td>
            <td>Column</td>
            <td>Type</td>
            <td>Mapped</td>
          </tr>
"""
attributesFooter    = """
        </table>
      </td>
    </tr>
"""

attributeHeader    = """
          <tr>
            <td>%(name)s</td>
            <td>%(columnName)s</td>
            <td>%(externalType)s</td>
            <td>%(valueClassName)s</td>
            <td>
"""
attributeFooter    = """
            </td>
          </tr>
"""

# relationship templates

relationshipsHeader = """
    <tr>
      <td valign="top">Relationships:</td>
      <td>
        <table border="0" width="100%%">
          <tr>
            <td>Name</td>
            <td>Destination</td>
            <td>Join</td>
            <td>Info</td>
          </tr>
"""
relationshipsFooter = """
        </table>
      </td>
    </tr>
"""

relationshipHeader = """
          <tr>
            <td>%(name)s</td>
            <td>%(destination)s</td>
            <td><nobr>%(sourceAttribute)s => %(destinationAttribute)s</nobr></td>
            <td>inner, equal</td>
"""
relationshipFooter = """          </tr>"""



# sorters

def nameSortFunc(a, b):
    if a['name'] > b['name']: return 1
    else:                     return -1

# load model

class Constants:
    pass

execfile(skyModelPath, modelenv)

userTypes   = modelenv['userTypes'][adaptorName]
adaptorInfo = modelenv['adaptorInfo'][adaptorName]
entities    = {}
c           = Constants()

for key, value in modelenv.items():
    if (key[:1] in uppercase) & (type(value) == DictionaryType):
        entities[key] = value
    if type(value) is StringType:
        if value[:1] == '@':
            setattr(c, key, value)

# converting to adaptor model

def getKey(dict, key, defaultValue=None):
    try: return dict[adaptorName + key]
    except KeyError: pass
    try: return dict[key]
    except KeyError: pass
    return defaultValue

def processAttribute(name, info):
    info['name']           = name
    info['columnName']     = getKey(info, c.column)
    info['valueClassName'] = getKey(info, c.valueClass)

    v = getKey(info, c.coltype)
    try:
        v = userTypes[v]
    except KeyError: pass
    info['externalType'] = v
    
    v = getKey(info, c.valueType)
    if v is not None:
        info['valueType'] = v
    
    v = getKey(info, c.width)
    if v is not None:
        info['width'] = v
    
    v = getKey(info, c.calendarFormat)
    if v is not None:
        info['calendarFormat'] = v
    elif info['valueClassName'] == 'NSCalendarDate':
        info['calendarFormat'] = adaptorInfo['calendarFormat']
    
    flags = getKey(info, c.flags)
    if c.allowsNull in flags:
        info['allowsNull'] = 'Y'
    
    return info

def processRelationship(name, info):
    info['name'] = name
    
    flags    = getKey(info, c.flags)
    isToMany = c.isToMany in flags
    
    if isToMany:
        info['isToMany'] = 'Y'
        destination, sourceAttr = split(info[c.source], '.')
        destAttr = info[c.destination]
    else:
        sourceAttr = info[c.source]
        destination, destAttr = split(info[c.destination], '.')
    
    info['destination']          = destination
    info['sourceAttribute']      = sourceAttr
    info['destinationAttribute'] = destAttr
    
    return info

def processEntity(name, info):
    newInfo = {}
    newInfo['name']      = name
    newInfo['table']     = getKey(info, c.table)
    newInfo['className'] = getKey(info, c.className)
    
    classProperties          = []
    attributesUsedForLocking = []
    pkeyName                 = None
    attributes               = []
    relationships            = []

    # process attributes
    
    for propertyName, propertyInfo in info.items():
        if propertyName[:1] == '@':
            continue
        if type(propertyInfo) is not DictionaryType:
            continue
        if not propertyInfo.has_key(c.column):
            continue
        
        flags = getKey(propertyInfo, c.flags)
        
        if c.property in flags:
            classProperties.append(propertyName)
        if c.lock in flags:
            attributesUsedForLocking.append(propertyName)
        if c.primaryKey in flags:
            pkeyName = propertyName
        
        propertyInfo = processAttribute(propertyName, propertyInfo)
        attributes.append(propertyInfo)
    
    attributes.sort(nameSortFunc)
    attributes = tuple(attributes)
    
    # process relationships
    
    for propertyName, propertyInfo in info.items():
        if propertyName[:1] == '@':
            continue
        if type(propertyInfo) is not DictionaryType:
            continue
        if propertyInfo.has_key(c.column):
            continue
        
        flags = getKey(propertyInfo, c.flags)
        
        if c.property in flags:
            classProperties.append(propertyName)
        
        propertyInfo = processRelationship(propertyName, propertyInfo)
        relationships.append(propertyInfo)
    
    relationships.sort(nameSortFunc)
    relationships = tuple(relationships)
    
    # assign
    
    newInfo['attributes']               = attributes
    newInfo['relationships']            = relationships
    newInfo['classProperties']          = classProperties
    newInfo['attributesUsedForLocking'] = attributesUsedForLocking
    newInfo['primaryKey']               = pkeyName
    
    return newInfo

adaptorEntities = []

for entityName, entityInfo in entities.items():
    if (entityInfo.has_key('table_name')):
        entityName = entityInfo['table_name'];
    
    adaptorEntities.append(processEntity(entityName, entityInfo))

adaptorEntities.sort(nameSortFunc)

# generate output

def genAttribute(info):
    print attributeHeader % info
    if info.has_key('valueType'):
        print "          valueType      = %(valueType)s;" % info
    if info.has_key('allowsNull'):
        print "          allowsNull     = %(allowsNull)s;" % info
    if info.has_key('width'):
        print "          width          = %(width)i;" % info
    if info.has_key('calendarFormat'):
        print "          calendarFormat = \"%(calendarFormat)s\";" % info
    print attributeFooter % info

def genRelationship(info):
    print relationshipHeader % info
    
    if info.has_key("isToMany"):
        print "          isToMany       = %(isToMany)s;" % info
    
    print relationshipFooter % info

def genAttrsUsedForLocking(lockAttrs, einfo):
    print attrsLockHeader
    for attribute in lockAttrs:
        print "%s " % attribute
    print attrsLockFooter

def genClassProps(props, einfo):
    print classPropHeader
    for property in props:
        print "%s " % property
    print classPropFooter

def genAttributes(attrs, einfo):
    print attributesHeader % einfo
        
    for attribute in attrs:
        genAttribute(attribute)
        
    print attributesFooter % einfo

def genRelationships(rels, einfo):
    print relationshipsHeader % einfo
        
    for relship in rels:
        genRelationship(relship)
        
    print relationshipsFooter % einfo

def genEntity(info):
    print entityHeader % info

    # generate property infos
    
    if len(info['attributesUsedForLocking']) > 0:
        genAttrsUsedForLocking(info['attributesUsedForLocking'], info)
    
    if len(info['classProperties']) > 0:
        genClassProps(info['classProperties'], info)
    
    # generate attribute infos
    
    if len(info['attributes']):
        genAttributes(info['attributes'], info)
    
    # generate relationship infos
    
    if len(info['relationships']):
        genRelationships(info['relationships'], info)
    
    print entityFooter % info

# print EOModel header

print header % adaptorInfo

for entityInfo in adaptorEntities:
    genEntity(entityInfo)

# print EOModel footer

print footer
