#!/usr/bin/env python
# $Id: genmodel.py,v 1.1.1.1 2003/07/09 22:57:26 cvs Exp $

from types  import *
from sys    import argv
import sys;
from string import uppercase, split

skyModelPath = argv[1]
adaptorName  = argv[2]

modelenv = {}

# formats

header = """{ // automagically generated - DO NOT EDIT !
  EOModelVersion   = 31;
  adaptorClassName = \"%(adaptorClassName)s\";
  adaptorName      = \"%(adaptorName)s\";

  pkeyGeneratorDictionary = {
    newKeyExpression = \"%(newKeyExpression)s\";
  };
  
  entities = ("""

footer = "  );\n}"

entityHeader = """    { // <entity name=%(name)s table=%(table)s>
      name                 = \"%(name)s\";
      externalName         = \"%(table)s\";
      className            = \"%(className)s\";
      primaryKeyAttributes = ( \"%(primaryKey)s\" );
      """

entityFooter = "    }," # "// </entity name=%(name)s>"

attributesHeader    = """
      attributes = ("""
attributesFooter    = "      );"

relationshipsHeader = """
      relationships = ("""
relationshipsFooter = "      );"

attributeHeader    = """        {
          name           = \"%(name)s\";
          columnName     = \"%(columnName)s\";
          externalType   = \"%(externalType)s\";
          valueClassName = \"%(valueClassName)s\";"""
attributeFooter    = """        },"""

relationshipHeader = """        {
          name        = \"%(name)s\";
          destination = \"%(destination)s\";
          joins       = ( {
            sourceAttribute      = \"%(sourceAttribute)s\";
            destinationAttribute = \"%(destinationAttribute)s\";
            joinSemantic         = EOInnerJoin;
            joinOperator         = EOJoinEqualTo;
          });"""
relationshipFooter = """        },"""

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

def genEntity(info):
    print entityHeader % info

    # generate property infos
    
    if len(info['attributesUsedForLocking']) > 0:
        s = "      attributesUsedForLocking = ( "
        for attribute in info['attributesUsedForLocking']:
            s = "%s%s, " % ( s, attribute )
        s = s[:-2] + " );"
        
        if len(s) > 78:
            print "      attributesUsedForLocking = ("
            for attribute in info['attributesUsedForLocking']:
                print "        %s," % attribute
            print "      );"
        else:
            print s
    
    if len(info['classProperties']) > 0:
        s = "      classProperties = ( "
        for property in info['classProperties']:
            s = "%s%s, " % ( s, property )
        s = s[:-2] + " );"
        
        if len(s) > 78:
            print "      classProperties = ("
            for property in info['classProperties']:
                print "        %s," % property
            print "      );"
        else:
            print s
    
    # generate attribute infos
    
    if len(info['attributes']):
        print attributesHeader % info
        
        for attribute in info['attributes']:
            genAttribute(attribute)
        
        print attributesFooter % info
    
    # generate relationship infos
    
    if len(info['relationships']):
        print relationshipsHeader % info
        
        for relship in info['relationships']:
            genRelationship(relship)
        
        print relationshipsFooter % info
    
    print entityFooter % info

# print EOModel header

print header % adaptorInfo

for entityInfo in adaptorEntities:
    genEntity(entityInfo)

# print EOModel footer

print footer
