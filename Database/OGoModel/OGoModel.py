#!/usr/bin/env python

table          = "@table"
className      = "@class"
column         = "@columnName"
coltype        = "@externalType"
valueClass     = "@valueClassName"
valueType      = "@valueType"
allowsNull     = "@allowsNull"
width          = "@width"
destination    = "@destination"
flags          = "@flags"
yes            = 1
no             = 0
lock           = "@lock"
property       = "@property"
primaryKey     = "@primaryKey"
isToMany       = "@isToMany"
source         = "@sourceAttribute"
destination    = "@destinationAttribute"
calendarFormat = "@calendarFormat"

fb             = "FrontBase"
pgsql          = "PostgreSQL"
mysql5         = "MySQL5"
sqlite         = "SQLite"

adaptorInfo = {
  fb: {
    'adaptorClassName': 'FrontBaseAdaptor',
    'adaptorName':      'FrontBase',
    'newKeyExpression': 'SELECT UNIQUE FROM key_generator',
    'calendarFormat':   "%b %d %Y %I:%M:%S:000%p"
  },
  pgsql: {
    'adaptorClassName': 'PostgreSQLAdaptor',
    'adaptorName':      'PostgreSQL',
    'newKeyExpression': 'select nextval(\\\'key_generator\\\')',
    'calendarFormat':   "%Y-%m-%d %H:%M:%S"
  },
  mysql5: {
    'adaptorClassName': 'MySQLAdaptor',
    'adaptorName':      'MySQL',                   # TODO: do we need +10?
    'newKeyExpression': 'UPDATE key_generator SET id=LAST_INSERT_ID(id+1); SELECT LAST_INSERT_ID()',
    'calendarFormat':   "%Y-%m-%d %H:%M:%S"
  }
}

userTypes = {
  fb:     { },
  pgsql:  {
    't_id':            "INT",
    't_int':           "INT",
    't_bool':          "INT",
    't_string':        "VARCHAR(255)",
    't_smallstring':   "VARCHAR(100)",
    't_tinystring':    "VARCHAR(50)",
    't_tinieststring': "VARCHAR(10)",
    't_text':          "VARCHAR(4000)",
    't_datetime':      "DATE",
    't_price':         "INT", #"NUMERIC(19,2)",
    't_float':         "INT", #"NUMERIC(19,8)",
    't_money':         "INT", #"NUMERIC(19,4)",
    't_image':         "VARCHAR(4000)", #"LONG RAW",
    },
  mysql5:  {
    't_id':            "INT",
    't_int':           "INT",
    't_bool':          "INT",
    't_string':        "VARCHAR(255)",
    't_smallstring':   "VARCHAR(100)",
    't_tinystring':    "VARCHAR(50)",
    't_tinieststring': "VARCHAR(10)",
    't_text':          "TEXT",
    't_datetime':      "DATE",
    't_price':         "INT", #"NUMERIC(19,2)",
    't_float':         "INT", #"NUMERIC(19,8)",
    't_money':         "INT", #"NUMERIC(19,4)",
    't_image':         "LONGBLOB", #"LONG RAW",
    }
}

CompanyAssignment = {
    table:     "company_assignment",
    className: 'LSCompanyAssignment',
    
    # attributes
    
    "companyAssignmentId": {
      column:     "company_assignment_id",
      coltype:    't_id',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ primaryKey, lock, property, allowsNull, ],
    },
    "companyId": {
      column:     "company_id",
      coltype:    't_id',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, allowsNull, ],
    },
    "subCompanyId": {
      column:     "sub_company_id",
      coltype:    't_id',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, allowsNull, ],
    },
    "isHeadquarter": {
      column:     "is_headquarter",
      coltype:    't_bool',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, allowsNull, ],
    },
    "isChief": {
      column:     "is_chief",
      coltype:    't_bool',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, allowsNull, ],
    },
    "function": {
      column:        "ffunction",
      pgsql+column:  "function",
      mysql5+column: "function",
      coltype:       't_string',
      valueClass:    'NSString',
      width:         255,
      flags:         [ lock, property, allowsNull, ],
    },
    "dbStatus": {
      column:     "db_status",
      coltype:    't_tinystring',
      valueClass: 'NSString',
      width:      50,
      flags:      [ lock, property, allowsNull, ],
    },
    
    # relationships
    
    "toEnterprise": {
      flags:       [ property, ],
      source:      "companyId",
      destination: "Enterprise.companyId",
    },
    "toTeam": {
      flags:       [ property, ],
      source:      "companyId",
      destination: "Team.companyId",
    },
    "toPerson": {
      flags:       [ property, ],
      source:      "subCompanyId",
      destination: "Person.companyId",
    },
} # entity CompanyAssignment

CompanyValue = {
    table:     "company_value",
    className: 'LSCompanyValue',
    
    # attributes
    
    "companyValueId": {
      column:     "company_value_id",
      coltype:    't_id',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ primaryKey, lock, property, allowsNull, ],
    },
    "companyId": {
      column:     "company_id",
      coltype:    't_id',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, allowsNull, ],
    },
    "attribute": {
      column:     "attribute",
      coltype:    't_string',
      valueClass: 'NSString',
      width:      255,
      flags:      [ lock, property, allowsNull, ],
    },
    "value": {
      column:     "value_string",
      coltype:    't_string',
      valueClass: 'NSString',
      width:      255,
      flags:      [ lock, property, allowsNull, ],
    },
    "isEnum": {
      column:     "is_enum",
      coltype:    't_bool',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, allowsNull, ],
    },
    "dbStatus": {
      column:     "db_status",
      coltype:    't_tinystring',
      valueClass: 'NSString',
      width:      50,
      flags:      [ lock, property, allowsNull, ],
    },
    "uid": {
      column:        "uid",
      coltype:       't_id',
      valueClass:    'NSNumber',
      valueType:     'i',
      flags:         [ property, allowsNull, ],
    },
    "type": {
      column:        "ftype",
      pgsql+column:  "type",
      mysql5+column: "type",
      coltype:       't_int',
      valueClass:    'NSNumber',
      valueType:     'i',
      flags:         [ property, allowsNull, ],
    },
    "label": {
      column:     "label",
      coltype:    't_string',
      valueClass: 'NSString',
      width:      255,
      flags:      [ property, allowsNull, ],
    },
    "isLabelLocalized": {
      column:     "is_label_localized",
      coltype:    't_bool',
      valueClass: 'NSNumber',
      flags:      [ property, allowsNull, ],
    },
    
    # relationships
    
    "toPerson": {
      flags:       [ property, ],
      source:      "companyId",
      destination: "Person.companyId",
    },
    "toEnterprise": {
      flags:       [ property, ],
      source:      "companyId",
      destination: "Enterprise.companyId",
    },
    "toTeam": {
      flags:       [ property, ],
      source:      "companyId",
      destination: "Team.companyId",
    },
} # entity CompanyValue

CompanyCategory = {
    table:     "company_category",
    className: 'LSCompanyCategory',
    
    # attributes
    
    "companyCategoryId": {
      column:     "company_category_id",
      coltype:    't_id',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ primaryKey, lock, property, allowsNull, ],
    },
    "category": {
      column:     "category",
      coltype:    't_string',
      valueClass: 'NSString',
      width:      255,
      flags:      [ lock, property, allowsNull, ],
    },
    "dbStatus": {
      column:     "db_status",
      coltype:    't_tinystring',
      valueClass: 'NSString',
      width:      50,
      flags:      [ lock, property, allowsNull, ],
    },
} # entity CompanyCategory

Trust = {
    table:     "trust",
    className: 'LSTrust',
    
    # attributes
    
    "companyId": {
      column:     "company_id",
      coltype:    't_id',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ primaryKey, lock, property, allowsNull, ],
    },
    "ownerId": {
      column:     "owner_id",
      coltype:    't_id',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, allowsNull, ],
    },
    "contactId": {
      column:     "contact_id",
      coltype:    't_id',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, allowsNull, ],
    },
    "number": {
      column:        "fnumber",
      pgsql+column:  "number",
      mysql5+column: "number",
      coltype:       't_smallstring',
      valueClass:    'NSString',
      width:         100,
      flags:         [ lock, property, allowsNull, ],
    },
    "description": {
      column:     "description",
      coltype:    't_string',
      valueClass: 'NSString',
      width:      255,
      flags:      [ lock, property, allowsNull, ],
    },
    "priority": {
      column:     "priority",
      coltype:    't_tinystring',
      valueClass: 'NSString',
      width:      50,
      flags:      [ lock, property, allowsNull, ],
    },
    "keywords": {
      column:     "keywords",
      coltype:    't_string',
      valueClass: 'NSString',
      width:      255,
      flags:      [ lock, property, allowsNull, ],
    },
    "url": {
      column:     "url",
      coltype:    't_string',
      valueClass: 'NSString',
      width:      255,
      flags:      [ lock, property, allowsNull, ],
    },
    "email": {
      column:     "email",
      coltype:    't_smallstring',
      valueClass: 'NSString',
      width:      100,
      flags:      [ lock, property, allowsNull, ],
    },
    "dbStatus": {
      column:     "db_status",
      coltype:    't_tinystring',
      valueClass: 'NSString',
      width:      50,
      flags:      [ lock, property, allowsNull, ],
    },
    "isTrust": {
      column:     "is_trust",
      coltype:    't_bool',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, allowsNull, ],
    },
    "isPrivate": {
      column:     "is_private",
      coltype:    't_bool',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, allowsNull, ],
    },
    "isReadonly": {
      column:     "is_readonly",
      coltype:    't_bool',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, allowsNull, ],
    },
} # entity Trust

Staff = {
    table:     "staff",
    className: 'LSStaff',
    
    # attributes
    
    "staffId": {
      column:     "staff_id",
      coltype:    't_id',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, allowsNull, ],
    },
    "companyId": {
      column:     "company_id",
      coltype:    't_id',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ primaryKey, lock, property, allowsNull, ],
    },
    "description": {
      column:     "description",
      coltype:    't_string',
      valueClass: 'NSString',
      width:      255,
      flags:      [ lock, property, allowsNull, ],
    },
    "login": {
      column:     "login",
      coltype:    't_string',
      valueClass: 'NSString',
      width:      255,
      flags:      [ lock, property, allowsNull, ],
    },
    "isTeam": {
      column:     "is_team",
      coltype:    't_bool',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, allowsNull, ],
    },
    "isAccount": {
      column:     "is_account",
      coltype:    't_bool',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, allowsNull, ],
    },
    "dbStatus": {
      column:     "db_status",
      coltype:    't_tinystring',
      valueClass: 'NSString',
      width:      50,
      flags:      [ lock, property, allowsNull, ],
    },
    
    # relationships
    
    "toTeam": {
      flags:       [ property, ],
      source:      "companyId",
      destination: "Team.companyId",
    },
    "toPerson": {
      flags:       [ property, ],
      source:      "companyId",
      destination: "Person.companyId",
    },
    "toDocument": {
      flags:       [ property, isToMany, ],
      source:      "Doc.companyId",
      destination: "firstOwnerId",
    },
    "toDocument1": {
      flags:       [ property, isToMany, ],
      source:      "Doc.companyId",
      destination: "currentOwnerId",
    },
    "toDocumentEditing": {
      flags:       [ property, isToMany, ],
      source:      "DocumentEditing.companyId",
      destination: "currentOwnerId",
    },
    "toDocumentVersion": {
      flags:       [ property, isToMany, ],
      source:      "DocumentVersion.companyId",
      destination: "lastOwnerId",
    },
    "toJob": {
      flags:       [ property, isToMany, ],
      source:      "Job.companyId",
      destination: "creatorId",
    },
    "toJob1": {
      flags:       [ property, isToMany, ],
      source:      "Job.companyId",
      destination: "executantId",
    },
    "toJobHistory": {
      flags:       [ property, isToMany, ],
      source:      "JobHistory.companyId",
      destination: "actorId",
    },
    "toProject": {
      flags:       [ property, isToMany, ],
      source:      "Project.companyId",
      destination: "ownerId",
    },
    "toProject1": {
      flags:       [ property, isToMany, ],
      source:      "Project.companyId",
      destination: "teamId",
    },
} # entity Staff

JobHistory = {
    table:     "job_history",
    className: 'LSJobHistory',
    
    # attributes
    
    "jobHistoryId": {
      column:     "job_history_id",
      coltype:    't_id',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ primaryKey, lock, property, allowsNull, ],
    },
    "jobId": {
      column:     "job_id",
      coltype:    't_id',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, allowsNull, ],
    },
    "actorId": {
      column:     "actor_id",
      coltype:    't_id',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, allowsNull, ],
    },
    "action": {
      column:        "faction",
      pgsql+column:  "action",      
      mysql5+column: "action",      
      coltype:       't_tinystring',
      valueClass:    'NSString',
      width:         50,
      flags:         [ lock, property, allowsNull, ],
    },
    "actionDate": {
      column:     "action_date",
      coltype:    't_datetime',
      valueClass: 'NSCalendarDate',
      flags:      [ lock, property, allowsNull, ],
    },
    "jobStatus": {
      column:     "job_status",
      coltype:    't_tinystring',
      valueClass: 'NSString',
      width:      50,
      flags:      [ lock, property, allowsNull, ],
    },
    "dbStatus": {
      column:     "db_status",
      coltype:    't_tinystring',
      valueClass: 'NSString',
      width:      50,
      flags:      [ lock, property, allowsNull, ],
    },
    
    # relationships
    
    "toJob": {
      flags:       [ property, ],
      source:      "jobId",
      destination: "Job.jobId",
    },
    "toActor": {
      flags:       [ property, ],
      source:      "actorId",
      destination: "Staff.companyId",
    },
    "toJobHistoryInfo": {
      flags:       [ property, isToMany, ],
      source:      "JobHistoryInfo.jobHistoryId",
      destination: "jobHistoryId",
    },
} # entity JobHistory

AppointmentResource = {
    table:     "appointment_resource",
    className: 'LSAppointmentResource',
    
    # attributes
    
    "appointmentResourceId": {
      column:     "appointment_resource_id",
      coltype:    't_id',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ primaryKey, lock, property, allowsNull, ],
    },
    "name": {
      column:        "fname",
      pgsql+column:  "name",      
      mysql5+column: "name",      
      coltype:       't_string',
      valueClass:    'NSString',
      width:         255,
      flags:         [ lock, property, allowsNull, ],
    },
    "email": {
      column:        "email",
      coltype:       't_string',
      valueClass:    'NSString',
      width:         255,
      flags:         [ property, allowsNull, ],
    },
    "category": {
      column:        "category",
      coltype:       't_string',
      valueClass:    'NSString',
      width:         255,
      flags:         [ property, allowsNull, ],
    },
    "emailSubject": {
      column:        "email_subject",
      coltype:       't_string',
      valueClass:    'NSString',
      width:         255,
      flags:         [ property, allowsNull, ],
    },
    "notificationTime": {
      column:     "notification_time",
      coltype:    't_int',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ property, allowsNull, ],
    },
    "dbStatus": {
      column:     "db_status",
      coltype:    't_tinystring',
      valueClass: 'NSString',
      width:      50,
      flags:      [ lock, property, allowsNull, ],
    },
} # entity AppointmentResource

DateCompanyAssignment = {
    table:     "date_company_assignment",
    className: 'LSDateCompanyAssignment',
    
    # attributes
    
    "dateCompanyAssignmentId": {
      column:     "date_company_assignment_id",
      coltype:    't_id',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ primaryKey, lock, property, allowsNull, ],
    },
    "companyId": {
      column:     "company_id",
      coltype:    't_id',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, allowsNull, ],
    },
    "dateId": {
      column:     "date_id",
      coltype:    't_id',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, allowsNull, ],
    },
    "isStaff": {
      column:     "is_staff",
      coltype:    't_bool',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, allowsNull, ],
    },
    "partStatus": {
      column:     "partstatus",
      coltype:    't_tinystring',
      valueClass: 'NSString',
      width:      50,
      flags:      [ lock, property, allowsNull, ],
    },
    "role": {
      column:     "role",
      coltype:    't_tinystring',
      valueClass: 'NSString',
      width:      50,
      flags:      [ lock, property, allowsNull, ],      
    },
    "comment": {
      column:     "comment",
      coltype:    't_string',
      valueClass: 'NSString',
      width:      255,
      flags:      [ lock, property, allowsNull, ],      
    },
    "rsvp": {
      column:     "rsvp",
      coltype:    't_bool',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, allowsNull, ],      
    },
    "dbStatus": {
      column:     "db_status",
      coltype:    't_tinystring',
      valueClass: 'NSString',
      width:      50,
      flags:      [ lock, property, allowsNull, ],
    },
    "outlookKey": {
      column:     "outlook_key",
      coltype:    't_string',
      valueClass: 'NSString',
      width:      255,
      flags:      [ lock, property, allowsNull, ],
    },
    
    # relationships
    
    "toTeam": {
      flags:       [ property, ],
      source:      "companyId",
      destination: "Team.companyId",
    },
    "toPerson": {
      flags:       [ property, ],
      source:      "companyId",
      destination: "Person.companyId",
    },
    "toDate": {
      flags:       [ property, ],
      source:      "dateId",
      destination: "Date.dateId",
    },
} # entity DateCompanyAssignment

Person = {
    table:     "person",
    className: 'LSPerson',
    
    # attributes
    
    "companyId": {
      column:     "company_id",
      coltype:    't_id',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ primaryKey, lock, property, allowsNull, ],
    },
    "ownerId": {
      column:     "owner_id",
      coltype:    't_id',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, allowsNull, ],
    },
    "templateUserId": {
      column:     "template_user_id",
      coltype:    't_id',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ property, allowsNull, ],
    },
    "contactId": {
      column:     "contact_id",
      coltype:    't_id',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ property, allowsNull, ],
    },
    "isPerson": {
      column:     "is_person",
      coltype:    't_bool',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ property, allowsNull, ],
    },
    "isAccount": {
      column:     "is_account",
      coltype:    't_bool',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ property, allowsNull, ],
    },
    "isIntraAccount": {
      column:     "is_intra_account",
      coltype:    't_bool',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ property, allowsNull, ],
    },
    "isExtraAccount": {
      column:     "is_extra_account",
      coltype:    't_bool',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ property, allowsNull, ],
    },
    "isCustomer": {
      column:     "is_customer",
      coltype:    't_bool',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ property, allowsNull, ],
    },
    "isTemplateUser": {
      column:     "is_template_user",
      coltype:    't_bool',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ property, allowsNull, ],
    },
    "number": {
      column:        "fnumber",
      pgsql+column:  "number",      
      mysql5+column: "number",      
      coltype:       't_smallstring',
      valueClass:    'NSString',
      width:         100,
      flags:         [ property, allowsNull, ],
    },
    "description": {
      column:     "description",
      coltype:    't_string',
      valueClass: 'NSString',
      width:      255,
      flags:      [ property, allowsNull, ],
    },
    "priority": {
      column:     "priority",
      coltype:    't_tinystring',
      valueClass: 'NSString',
      width:      50,
      flags:      [ property, allowsNull, ],
    },
    "keywords": {
      column:     "keywords",
      coltype:    't_string',
      valueClass: 'NSString',
      width:      255,
      flags:      [ property, allowsNull, ],
    },
    "name": {
      column:        "fname",
      pgsql+column:  "name",      
      mysql5+column: "name",      
      coltype:       't_tinystring',
      valueClass:    'NSString',
      width:         50,
      flags:         [ property, allowsNull, ],
    },
    "middlename": {
      column:     "middlename",
      coltype:    't_tinystring',
      valueClass: 'NSString',
      width:      50,
      flags:      [ property, allowsNull, ],
    },
    "firstname": {
      column:     "firstname",
      coltype:    't_tinystring',
      valueClass: 'NSString',
      width:      50,
      flags:      [ property, allowsNull, ],
    },
    "salutation": {
      column:     "salutation",
      coltype:    't_tinystring',
      valueClass: 'NSString',
      width:      50,
      flags:      [ property, allowsNull, ],
    },
    "degree": {
      column:     "degree",
      coltype:    't_tinystring',
      valueClass: 'NSString',
      width:      50,
      flags:      [ property, allowsNull, ],
    },
    "birthday": {
      column:     "birthday",
      coltype:    't_datetime',
      valueClass: 'NSCalendarDate',
      flags:      [ property, allowsNull, ],
    },
    "url": {
      column:     "url",
      coltype:    't_string',
      valueClass: 'NSString',
      width:      255,
      flags:      [ property, allowsNull, ],
    },
    "sex": {
      column:     "sex",
      coltype:    't_tinieststring',
      valueClass: 'NSString',
      width:      10,
      flags:      [ property, allowsNull, ],
    },
    "isPrivate": {
      column:     "is_private",
      coltype:    't_bool',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ property, allowsNull, ],
    },
    "isReadonly": {
      column:     "is_readonly",
      coltype:    't_bool',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ property, allowsNull, ],
    },
    "isLocked": {
      column:     "is_locked",
      coltype:    't_bool',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ property, allowsNull, ],
    },
    "login": {
      column:     "login",
      coltype:    't_tinystring',
      valueClass: 'NSString',
      width:      50,
      flags:      [ property, allowsNull, ],
    },
    "password": {
      column:     "password",
      coltype:    't_string',
      valueClass: 'NSString',
      width:      255,
      flags:      [ property, allowsNull, ],
    },
    "imapPasswd": {
      column:     "pop3_account",
      coltype:    't_tinystring',
      valueClass: 'NSString',
      width:      50,
      flags:      [ property, allowsNull, ],
    },
    "sourceUrl": {
      column:     "source_url",
      coltype:    't_string',
      valueClass: 'NSString',
      width:      255,
      flags:      [ property, allowsNull, ],
    },
    "dbStatus": {
      column:     "db_status",
      coltype:    't_tinystring',
      valueClass: 'NSString',
      width:      50,
      flags:      [ lock, property, allowsNull, ],
    },
    "objectVersion": {
      column:     "object_version",
      coltype:    't_int',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, allowsNull, ],
    },
    "sensitivity": {
      column:     "sensitivity",
      coltype:    't_int',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ property, allowsNull, ],
    },
    "bossName": {
      column:     "boss_name",
      coltype:    't_string',
      valueClass: 'NSString',
      width:      255,
      flags:      [ property, allowsNull, ],
    },
    "partnerName": {
      column:     "partner_name",
      coltype:    't_string',
      valueClass: 'NSString',
      width:      255,
      flags:      [ property, allowsNull, ],
    },
    "assistantName": {
      column:     "assistant_name",
      coltype:    't_string',
      valueClass: 'NSString',
      width:      255,
      flags:      [ property, allowsNull, ],
    },
    "department": {
      column:     "department",
      coltype:    't_string',
      valueClass: 'NSString',
      width:      255,
      flags:      [ property, allowsNull, ],
    },
    "office": {
      column:     "office",
      coltype:    't_string',
      valueClass: 'NSString',
      width:      255,
      flags:      [ property, allowsNull, ],
    },
    "occupation": {
      column:     "occupation",
      coltype:    't_string',
      valueClass: 'NSString',
      width:      255,
      flags:      [ property, allowsNull, ],
    },
    "anniversary": {
      column:     "anniversary",
      coltype:    't_datetime',
      valueClass: 'NSCalendarDate',
      flags:      [ property, allowsNull, ],
    },
    "dirServer": {
      column:     "dir_server",
      coltype:    't_string',
      valueClass: 'NSString',
      width:      255,
      flags:      [ property, allowsNull, ],
    },
    "emailAlias": {
      column:     "email_alias",
      coltype:    't_string',
      valueClass: 'NSString',
      width:      255,
      flags:      [ property, allowsNull, ],
    },
    "freebusyUrl": {
      column:     "freebusy_url",
      coltype:    't_string',
      valueClass: 'NSString',
      width:      255,
      flags:      [ property, allowsNull, ],
    },
    "fileas": {
      column:     "fileas",
      coltype:    't_string',
      valueClass: 'NSString',
      width:      255,
      flags:      [ property, allowsNull, ],
    },
    "nameTitle": {
      column:     "name_title",
      coltype:    't_string',
      valueClass: 'NSString',
      width:      255,
      flags:      [ property, allowsNull, ],
    },
    "nameAffix": {
      column:     "name_affix",
      coltype:    't_string',
      valueClass: 'NSString',
      width:      255,
      flags:      [ property, allowsNull, ],
    },
    "imAddress": {
      column:     "im_address",
      coltype:    't_string',
      valueClass: 'NSString',
      width:      255,
      flags:      [ property, allowsNull, ],
    },
    "associatedContacts": {
      column:     "associated_contacts",
      coltype:    't_string',
      valueClass: 'NSString',
      width:      255,
      flags:      [ property, allowsNull, ],
    },    
    "associatedCategories": {
      column:     "associated_categories",
      coltype:    't_string',
      valueClass: 'NSString',
      width:      255,
      flags:      [ property, allowsNull, ],
    },
    "associatedCompany": {
      column:     "associated_company",
      coltype:    't_string',
      valueClass: 'NSString',
      width:      255,
      flags:      [ property, allowsNull, ],
    },        
    "showEmailAs": {
      column:     "show_email_as",
      coltype:    't_string',
      valueClass: 'NSString',
      width:      255,
      flags:      [ property, allowsNull, ],
    },        
    "showEmail2As": {
      column:     "show_email2_as",
      coltype:    't_string',
      valueClass: 'NSString',
      width:      255,
      flags:      [ property, allowsNull, ],
    },        
    "showEmail3As": {
      column:     "show_email3_as",
      coltype:    't_string',
      valueClass: 'NSString',
      width:      255,
      flags:      [ property, allowsNull, ],
    },        

    # relationships
    
    "toOwner": {
      flags:       [ property, ],
      source:      "ownerId",
      destination: "Staff.companyId",
    },
    "toContact": {
      flags:       [ property, ],
      source:      "contactId",
      destination: "Staff.companyId",
    },
    "toCompanyInfo": {
      flags:       [ property, ],
      source:      "companyId",
      destination: "CompanyInfo.companyId",
    },
    "toCompanyValue": {
      flags:       [ property, isToMany, ],
      source:      "CompanyValue.companyId",
      destination: "companyId",
    },
    "toCompanyAssignment": {
      flags:       [ property, isToMany, ],
      source:      "CompanyAssignment.companyId",
      destination: "companyId",
    },
    "toCompanyAssignment1": {
      flags:       [ property, isToMany, ],
      source:      "CompanyAssignment.companyId",
      destination: "subCompanyId",
    },
    "toDateCompanyAssignment": {
      flags:       [ property, isToMany, ],
      source:      "DateCompanyAssignment.companyId",
      destination: "companyId",
    },
    "toProjectCompanyAssignment": {
      flags:       [ property, isToMany, ],
      source:      "ProjectCompanyAssignment.companyId",
      destination: "companyId",
    },
    "toStaff": {
      flags:       [ property, isToMany, ],
      source:      "Staff.companyId",
      destination: "companyId",
    },
    "toAddress": {
      flags:       [ property, isToMany, ],
      source:      "Address.companyId",
      destination: "companyId",
    },
    "toTelephone": {
      flags:       [ property, isToMany, ],
      source:      "Telephone.companyId",
      destination: "companyId",
    },
} # entity Person

Project = {
    table:     "project",
    className: 'LSProject',
    
    # attributes
    
    "projectId": {
      column:     "project_id",
      coltype:    't_id',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ primaryKey, lock, property, allowsNull, ],
    },
    "ownerId": {
      column:     "owner_id",
      coltype:    't_id',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, allowsNull, ],
    },
    "teamId": {
      column:     "team_id",
      coltype:    't_id',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, allowsNull, ],
    },
    "name": {
      column:        "fname",
      pgsql+column:  "name",      
      mysql5+column: "name",      
      coltype:       't_string',
      valueClass:    'NSString',
      width:         255,
      flags:         [ lock, property, allowsNull, ],
    },
    "number": {
      column:        "fnumber",
      pgsql+column:  "number",      
      mysql5+column: "number",      
      coltype:       't_smallstring',
      valueClass:    'NSString',
      width:         100,
      flags:         [ lock, property, allowsNull, ],
    },
    "startDate": {
      column:     "start_date",
      coltype:    't_datetime',
      valueClass: 'NSCalendarDate',
      flags:      [ lock, property, allowsNull, ],
    },
    "endDate": {
      column:     "end_date",
      coltype:    't_datetime',
      valueClass: 'NSCalendarDate',
      flags:      [ lock, property, allowsNull, ],
    },
    "isFake": {
      column:     "is_fake",
      coltype:    't_bool',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, allowsNull, ],
    },
    "status": {
      column:     "status",
      coltype:    't_string',
      valueClass: 'NSString',
      width:      255,
      flags:      [ lock, property, allowsNull, ],
    },
    "dbStatus": {
      column:     "db_status",
      coltype:    't_tinystring',
      valueClass: 'NSString',
      width:      50,
      flags:      [ lock, property, allowsNull, ],
    },
    "kind": {
      column:     "kind",
      coltype:    't_tinystring',
      valueClass: 'NSString',
      width:      50,
      flags:      [ property, allowsNull, ],
    },
    "url": {
      column:     "url",
      coltype:    't_smallstring',
      valueClass: 'NSString',
      width:      100,
      flags:      [ property, allowsNull, ],
    },
    
    # relationships
    
    "toOwner": {
      flags:       [ property, ],
      source:      "ownerId",
      destination: "Staff.companyId",
    },
    "toStaffTeam": {
      flags:       [ property, ],
      source:      "teamId",
      destination: "Staff.companyId",
    },
    "toProjectCompanyAssignment": {
      flags:       [ property, isToMany, ],
      source:      "ProjectCompanyAssignment.projectId",
      destination: "projectId",
    },
    "toDocument": {
      flags:       [ property, isToMany, ],
      source:      "Doc.projectId",
      destination: "projectId",
    },
    "toJob": {
      flags:       [ property, isToMany, ],
      source:      "Job.projectId",
      destination: "projectId",
    },
    "toProjectInfo": {
      flags:       [ property, ],
      source:      "projectId",
      destination: "ProjectInfo.projectId",
    },
} # entity Project

Enterprise = {
    table:     "enterprise",
    className: 'LSEnterprise',
    
    # attributes
    
    "companyId": {
      column:     "company_id",
      coltype:    't_id',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ primaryKey, lock, property, allowsNull, ],
    },
    "ownerId": {
      column:     "owner_id",
      coltype:    't_id',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, allowsNull, ],
    },
    "contactId": {
      column:     "contact_id",
      coltype:    't_id',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ property, allowsNull, ],
    },
    "isEnterprise": {
      column:     "is_enterprise",
      coltype:    't_bool',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ property, allowsNull, ],
    },
    "isCustomer": {
      column:     "is_customer",
      coltype:    't_bool',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ property, allowsNull, ],
    },
    "isPrivate": {
      column:     "is_private",
      coltype:    't_bool',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ property, allowsNull, ],
    },
    "isReadonly": {
      column:     "is_readonly",
      coltype:    't_bool',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ property, allowsNull, ],
    },
    "number": {
      column:        "fnumber",
      pgsql+column:  "number",      
      mysql5+column: "number",      
      coltype:       't_smallstring',
      valueClass:    'NSString',
      width:         100,
      flags:         [ property, allowsNull, ],
    },
    "description": {
      column:     "description",
      coltype:    't_string',
      valueClass: 'NSString',
      width:      255,
      flags:      [ property, allowsNull, ],
    },
    "priority": {
      column:     "priority",
      coltype:    't_tinystring',
      valueClass: 'NSString',
      width:      50,
      flags:      [ property, allowsNull, ],
    },
    "keywords": {
      column:     "keywords",
      coltype:    't_string',
      valueClass: 'NSString',
      width:      255,
      flags:      [ property, allowsNull, ],
    },
    "url": {
      column:     "url",
      coltype:    't_string',
      valueClass: 'NSString',
      width:      255,
      flags:      [ property, allowsNull, ],
    },
    "bank": {
      column:     "bank",
      coltype:    't_smallstring',
      valueClass: 'NSString',
      width:      100,
      flags:      [ property, allowsNull, ],
    },
    "bankCode": {
      column:     "bank_code",
      coltype:    't_tinystring',
      valueClass: 'NSString',
      width:      50,
      flags:      [ property, allowsNull, ],
    },
    "account": {
      column:     "account",
      coltype:    't_tinystring',
      valueClass: 'NSString',
      width:      50,
      flags:      [ property, allowsNull, ],
    },
    "email": {
      column:     "email",
      coltype:    't_smallstring',
      valueClass: 'NSString',
      width:      100,
      flags:      [ property, allowsNull, ],
    },
    "sourceUrl": {
      column:     "source_url",
      coltype:    't_string',
      valueClass: 'NSString',
      width:      255,
      flags:      [ property, allowsNull, ],
    },
    "dbStatus": {
      column:     "db_status",
      coltype:    't_tinystring',
      valueClass: 'NSString',
      width:      50,
      flags:      [ property, allowsNull, ],
    },
    "login": {
      column:     "login",
      coltype:    't_tinystring',
      valueClass: 'NSString',
      width:      50,
      flags:      [ property, allowsNull, ],
    },
    "objectVersion": {
      column:     "object_version",
      coltype:    't_int',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, allowsNull, ],
    },
    "sensitivity": {
      column:     "sensitivity",
      coltype:    't_int',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ property, allowsNull, ],
    },
    "bossName": {
      column:     "boss_name",
      coltype:    't_string',
      valueClass: 'NSString',
      width:      255,
      flags:      [ property, allowsNull, ],
    },
    "partnerName": {
      column:     "partner_name",
      coltype:    't_string',
      valueClass: 'NSString',
      width:      255,
      flags:      [ property, allowsNull, ],
    },
    "assistantName": {
      column:     "assistant_name",
      coltype:    't_string',
      valueClass: 'NSString',
      width:      255,
      flags:      [ property, allowsNull, ],
    },
    "department": {
      column:     "department",
      coltype:    't_string',
      valueClass: 'NSString',
      width:      255,
      flags:      [ property, allowsNull, ],
    },
    "office": {
      column:     "office",
      coltype:    't_string',
      valueClass: 'NSString',
      width:      255,
      flags:      [ property, allowsNull, ],
    },
    "occupation": {
      column:     "occupation",
      coltype:    't_string',
      valueClass: 'NSString',
      width:      255,
      flags:      [ property, allowsNull, ],
    },
    "anniversary": {
      column:     "anniversary",
      coltype:    't_datetime',
      valueClass: 'NSCalendarDate',
      flags:      [ property, allowsNull, ],
    },
    "dirServer": {
      column:     "dir_server",
      coltype:    't_string',
      valueClass: 'NSString',
      width:      255,
      flags:      [ property, allowsNull, ],
    },
    "emailAlias": {
      column:     "email_alias",
      coltype:    't_string',
      valueClass: 'NSString',
      width:      255,
      flags:      [ property, allowsNull, ],
    },
    "freebusyUrl": {
      column:     "freebusy_url",
      coltype:    't_string',
      valueClass: 'NSString',
      width:      255,
      flags:      [ property, allowsNull, ],
    },
    "fileas": {
      column:     "fileas",
      coltype:    't_string',
      valueClass: 'NSString',
      width:      255,
      flags:      [ property, allowsNull, ],
    },
    "nameTitle": {
      column:     "name_title",
      coltype:    't_string',
      valueClass: 'NSString',
      width:      255,
      flags:      [ property, allowsNull, ],
    },
    "nameAffix": {
      column:     "name_affix",
      coltype:    't_string',
      valueClass: 'NSString',
      width:      255,
      flags:      [ property, allowsNull, ],
    },
    "imAddress": {
      column:     "im_address",
      coltype:    't_string',
      valueClass: 'NSString',
      width:      255,
      flags:      [ property, allowsNull, ],
    },
    "associatedContacts": {
      column:     "associated_contacts",
      coltype:    't_string',
      valueClass: 'NSString',
      width:      255,
      flags:      [ property, allowsNull, ],
    },    
    "associatedCategories": {
      column:     "associated_categories",
      coltype:    't_string',
      valueClass: 'NSString',
      width:      255,
      flags:      [ property, allowsNull, ],
    },
    "associatedCompany": {
      column:     "associated_company",
      coltype:    't_string',
      valueClass: 'NSString',
      width:      255,
      flags:      [ property, allowsNull, ],
    },
    "showEmailAs": {
      column:     "show_email_as",
      coltype:    't_string',
      valueClass: 'NSString',
      width:      255,
      flags:      [ property, allowsNull, ],
    },        
    "showEmail2As": {
      column:     "show_email2_as",
      coltype:    't_string',
      valueClass: 'NSString',
      width:      255,
      flags:      [ property, allowsNull, ],
    },        
    "showEmail3As": {
      column:     "show_email3_as",
      coltype:    't_string',
      valueClass: 'NSString',
      width:      255,
      flags:      [ property, allowsNull, ],
    },        
    "firstname": {
      column:     "firstname",
      coltype:    't_tinystring',
      valueClass: 'NSString',
      width:      50,
      flags:      [ property, allowsNull, ],
    },
    "birthday": {
      column:     "birthday",
      coltype:    't_datetime',
      valueClass: 'NSCalendarDate',
      flags:      [ property, allowsNull, ],
    },
    
    # relationships
    
    "toOwner": {
      flags:       [ property, ],
      source:      "ownerId",
      destination: "Staff.companyId",
    },
    "toContact": {
      flags:       [ property, ],
      source:      "contactId",
      destination: "Staff.companyId",
    },
    "toStaff": {
      flags:       [ property, isToMany, ],
      source:      "Staff.companyId",
      destination: "companyId",
    },
    "toCompanyInfo": {
      flags:       [ property, ],
      source:      "companyId",
      destination: "CompanyInfo.companyId",
    },
    "toCompanyValue": {
      flags:       [ property, isToMany, ],
      source:      "CompanyValue.companyId",
      destination: "companyId",
    },
    "toCompanyAssignment": {
      flags:       [ property, isToMany, ],
      source:      "CompanyAssignment.companyId",
      destination: "companyId",
    },
    "toCompanyAssignment1": {
      flags:       [ property, isToMany, ],
      source:      "CompanyAssignment.companyId",
      destination: "subCompanyId",
    },
    "toDateCompanyAssignment": {
      flags:       [ property, isToMany, ],
      source:      "DateCompanyAssignment.companyId",
      destination: "companyId",
    },
    "toProjectCompanyAssignment": {
      flags:       [ property, isToMany, ],
      source:      "ProjectCompanyAssignment.companyId",
      destination: "companyId",
    },
    "toAddress": {
      flags:       [ property, isToMany, ],
      source:      "Address.companyId",
      destination: "companyId",
    },
    "toTelephone": {
      flags:       [ property, isToMany, ],
      source:      "Telephone.companyId",
      destination: "companyId",
    },
    "toInvoice": {
      flags:       [ property, isToMany, ],
      source:      "Invoice.companyId",
      destination: "debitorId",
    },
} # entity Enterprise

DateInfo = {
    table:     "date_info",
    className: 'LSDateInfo',
    
    # attributes
    
    "dateInfoId": {
      column:     "date_info_id",
      coltype:    't_id',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, allowsNull, ],
    },
    "dateId": {
      column:     "date_id",
      coltype:    't_id',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ primaryKey, lock, property, allowsNull, ],
    },
    "comment": {
      column:        "comment",
      coltype:       't_text',
      fb+coltype:    'VARCHAR(100000)',
      valueClass:    'NSString',
      flags:         [ lock, property, allowsNull, ],
    },
    "dbStatus": {
      column:     "db_status",
      coltype:    't_tinystring',
      valueClass: 'NSString',
      width:      50,
      flags:      [ lock, property, allowsNull, ],
    },
    
    # relationships
    
    "toDate": {
      flags:       [ property, ],
      source:      "dateId",
      destination: "Date.dateId",
    },
} # entity DateInfo

Address = {
    table:     "address",
    className: 'LSAddress',
    
    # attributes
    
    "addressId": {
      column:     "address_id",
      coltype:    't_id',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ primaryKey, lock, property, allowsNull, ],
    },
    "companyId": {
      column:     "company_id",
      coltype:    't_id',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, allowsNull, ],
    },
    "name1": {
      column:     "name1",
      coltype:    't_string',
      valueClass: 'NSString',
      width:      255,
      flags:      [ lock, property, allowsNull, ],
    },
    "name2": {
      column:     "name2",
      coltype:    't_string',
      valueClass: 'NSString',
      width:      255,
      flags:      [ lock, property, allowsNull, ],
    },
    "name3": {
      column:     "name3",
      coltype:    't_string',
      valueClass: 'NSString',
      width:      255,
      flags:      [ lock, property, allowsNull, ],
    },
    "street": {
      column:     "street",
      coltype:    't_string',
      valueClass: 'NSString',
      width:      255,
      flags:      [ lock, property, allowsNull, ],
    },
    "zip": {
      column:     "zip",
      coltype:    't_tinystring',
      valueClass: 'NSString',
      width:      50,
      flags:      [ lock, property, allowsNull, ],
    },
    "city": {
      column:     "zipcity",
      coltype:    't_string',
      valueClass: 'NSString',
      width:      255,
      flags:      [ lock, property, allowsNull, ],
    },
    "country": {
      column:     "country",
      coltype:    't_smallstring',
      valueClass: 'NSString',
      width:      100,
      flags:      [ lock, property, allowsNull, ],
    },
    "state": {
      column:     "state",
      coltype:    't_smallstring',
      valueClass: 'NSString',
      width:      100,
      flags:      [ lock, property, allowsNull, ],
    },
    "type": {
      column:        "ftype",
      pgsql+column:  "type",      
      mysql5+column: "type",      
      coltype:       't_tinystring',
      valueClass:    'NSString',
      width:         50,
      flags:         [ lock, property, allowsNull, ],
    },
    "sourceUrl": {
      column:        "source_url",
      coltype:       't_string',
      valueClass:    'NSString',
      width:         255,
      flags:         [ lock, property, allowsNull, ],
    },
    "dbStatus": {
      column:     "db_status",
      coltype:    't_tinystring',
      valueClass: 'NSString',
      width:      50,
      flags:      [ lock, property, allowsNull, ],
    },
    
    # relationships
    
    "toEnterprise": {
      flags:       [ property, ],
      source:      "companyId",
      destination: "Enterprise.companyId",
    },
    "toPerson": {
      flags:       [ property, ],
      source:      "companyId",
      destination: "Person.companyId",
    },
    "toTeam": {
      flags:       [ property, ],
      source:      "companyId",
      destination: "Team.companyId",
    },
} # entity Address

DocumentVersion = {
    table:     "document_version",
    className: 'LSDocumentVersion',
    
    # attributes
    
    "documentVersionId": {
      column:     "document_version_id",
      coltype:    't_id',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ primaryKey, lock, property, allowsNull, ],
    },
    "documentId": {
      column:     "document_id",
      coltype:    't_id',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, allowsNull, ],
    },
    "lastOwnerId": {
      column:     "last_owner_id",
      coltype:    't_id',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, allowsNull, ],
    },
    "version": {
      column:     "version",
      coltype:    't_int',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, allowsNull, ],
    },
    "fileSize": {
      column:     "file_size",
      coltype:    't_int',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, allowsNull, ],
    },
    "creationDate": {
      column:     "creation_date",
      coltype:    't_datetime',
      valueClass: 'NSCalendarDate',
      flags:      [ lock, property, allowsNull, ],
    },
    "archiveDate": {
      column:     "archive_date",
      coltype:    't_datetime',
      valueClass: 'NSCalendarDate',
      flags:      [ lock, property, allowsNull, ],
    },
    "title": {
      column:     "title",
      coltype:    't_string',
      valueClass: 'NSString',
      width:      255,
      flags:      [ lock, property, allowsNull, ],
    },
    "abstract": {
      column:     "abstract",
      coltype:    't_string',
      valueClass: 'NSString',
      width:      255,
      flags:      [ lock, property, allowsNull, ],
    },
    "contact": {
      column:     "contact",
      coltype:    't_string',
      valueClass: 'NSString',
      width:      255,
      flags:      [ lock, property, allowsNull, ],
    },
    "fileType": {
      column:     "file_type",
      coltype:    't_string',
      valueClass: 'NSString',
      width:      255,
      flags:      [ lock, property, allowsNull, ],
    },
    "isPacked": {
      column:     "is_packed",
      coltype:    't_bool',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, allowsNull, ],
    },
    "dbStatus": {
      column:     "db_status",
      coltype:    't_tinystring',
      valueClass: 'NSString',
      width:      50,
      flags:      [ lock, property, allowsNull, ],
    },
    
    # relationships
    
    "toDoc": {
      flags:       [ property, ],
      source:      "documentId",
      destination: "Doc.documentId",
    },
    "toLastOwner": {
      flags:       [ property, ],
      source:      "lastOwnerId",
      destination: "Staff.companyId",
    },
} # entity DocumentVersion

DocumentEditing = {
    table:     "document_editing",
    className: 'LSDocumentEditing',
    
    # attributes
    
    "documentEditingId": {
      column:     "document_editing_id",
      coltype:    't_id',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, allowsNull, ],
    },
    "documentId": {
      column:     "document_id",
      coltype:    't_id',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ primaryKey, lock, property, allowsNull, ],
    },
    "currentOwnerId": {
      column:     "current_owner_id",
      coltype:    't_id',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, allowsNull, ],
    },
    "fileSize": {
      column:     "file_size",
      coltype:    't_int',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, allowsNull, ],
    },
    "version": {
      column:     "version",
      coltype:    't_int',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, allowsNull, ],
    },
    "contact": {
      column:     "contact",
      coltype:    't_string',
      valueClass: 'NSString',
      width:      255,
      flags:      [ lock, property, allowsNull, ],
    },
    "isAttachChanged": {
      column:     "is_attach_changed",
      coltype:    't_bool',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, allowsNull, ],
    },
    "checkoutDate": {
      column:     "checkout_date",
      coltype:    't_datetime',
      valueClass: 'NSCalendarDate',
      flags:      [ lock, property, allowsNull, ],
    },
    "title": {
      column:     "title",
      coltype:    't_string',
      valueClass: 'NSString',
      width:      255,
      flags:      [ lock, property, allowsNull, ],
    },
    "abstract": {
      column:     "abstract",
      coltype:    't_string',
      valueClass: 'NSString',
      width:      255,
      flags:      [ lock, property, allowsNull, ],
    },
    "status": {
      column:     "status",
      coltype:    't_tinystring',
      valueClass: 'NSString',
      width:      50,
      flags:      [ lock, property, allowsNull, ],
    },
    "fileType": {
      column:     "file_type",
      coltype:    't_string',
      valueClass: 'NSString',
      width:      255,
      flags:      [ lock, property, allowsNull, ],
    },
    "dbStatus": {
      column:     "db_status",
      coltype:    't_tinystring',
      valueClass: 'NSString',
      width:      50,
      flags:      [ lock, property, allowsNull, ],
    },
    
    # relationships
    
    "toCurrentOwner": {
      flags:       [ property, ],
      source:      "currentOwnerId",
      destination: "Staff.companyId",
    },
    "toDoc": {
      flags:       [ property, ],
      source:      "documentId",
      destination: "Doc.documentId",
    },
} # entity DocumentEditing

CompanyInfo = {
    table:     "company_info",
    className: 'LSCompanyInfo',
    
    # attributes
    
    "companyInfoId": {
      column:     "company_info_id",
      coltype:    't_id',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, allowsNull, ],
    },
    "companyId": {
      column:     "company_id",
      coltype:    't_id',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ primaryKey, lock, property, allowsNull, ],
    },
    "comment": {
      column:        "comment",
      coltype:       't_text',
      valueClass:    'NSString',
      flags:         [ lock, property, allowsNull, ],
    },
    "dbStatus": {
      column:     "db_status",
      coltype:    't_tinystring',
      valueClass: 'NSString',
      width:      50,
      flags:      [ lock, property, allowsNull, ],
    },
    
    # relationships
    
    "toPerson": {
      flags:       [ property, ],
      source:      "companyId",
      destination: "Person.companyId",
    },
    "toEnterprise": {
      flags:       [ property, ],
      source:      "companyId",
      destination: "Enterprise.companyId",
    },
    "toTeam": {
      flags:       [ property, ],
      source:      "companyId",
      destination: "Team.companyId",
    },
} # entity CompanyInfo

Note = {
    table:     "note",
    className: 'LSNote',
    
    # attributes
    
    "documentId": {
      column:     "document_id",
      coltype:    't_id',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ primaryKey, lock, property, allowsNull, ],
    },
    "parentDocumentId": {
      column:     "parent_document_id",
      coltype:    't_id',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, allowsNull, ],
    },
    "projectId": {
      column:     "project_id",
      coltype:    't_id',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, allowsNull, ],
    },
    "dateId": {
      column:     "date_id",
      coltype:    't_id',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, allowsNull, ],
    },
    "firstOwnerId": {
      column:     "first_owner_id",
      coltype:    't_id',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, allowsNull, ],
    },
    "currentOwnerId": {
      column:     "current_owner_id",
      coltype:    't_id',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, allowsNull, ],
    },
    "isFolder": {
      column:     "is_folder",
      coltype:    't_bool',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, allowsNull, ],
    },
    "isNote": {
      column:     "is_note",
      coltype:    't_bool',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, allowsNull, ],
    },
    "title": {
      column:     "title",
      coltype:    't_string',
      valueClass: 'NSString',
      width:      255,
      flags:      [ lock, property, allowsNull, ],
    },
    "abstract": {
      column:     "abstract",
      coltype:    't_string',
      valueClass: 'NSString',
      width:      255,
      flags:      [ lock, property, allowsNull, ],
    },
    "fileType": {
      column:     "file_type",
      coltype:    't_tinystring',
      valueClass: 'NSString',
      width:      50,
      flags:      [ lock, property, allowsNull, ],
    },
    "versionCount": {
      column:     "version_count",
      coltype:    't_int',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, allowsNull, ],
    },
    "creationDate": {
      column:     "creation_date",
      coltype:    't_datetime',
      valueClass: 'NSCalendarDate',
      flags:      [ lock, property, allowsNull, ],
    },
    "lastmodifiedDate": {
      column:     "lastmodified_date",
      coltype:    't_datetime',
      valueClass: 'NSCalendarDate',
      flags:      [ lock, property, allowsNull, ],
    },
    "status": {
      column:     "status",
      coltype:    't_tinystring',
      valueClass: 'NSString',
      width:      50,
      flags:      [ lock, property, allowsNull, ],
    },
    "dbStatus": {
      column:     "db_status",
      coltype:    't_tinystring',
      valueClass: 'NSString',
      width:      50,
      flags:      [ lock, property, allowsNull, ],
    },
    "objectVersion": {
      column:     "object_version",
      coltype:    't_int',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, allowsNull, ],
    },
    
    # relationships
    
    "toParentDocument": {
      flags:       [ property, ],
      source:      "parentDocumentId",
      destination: "Doc.documentId",
    },
    "toProject": {
      flags:       [ property, ],
      source:      "projectId",
      destination: "Project.projectId",
    },
    "toDate": {
      flags:       [ property, ],
      source:      "dateId",
      destination: "Date.dateId",
    },
    "toFirstOwner": {
      flags:       [ property, ],
      source:      "firstOwnerId",
      destination: "Staff.companyId",
    },
    "toCurrentOwner": {
      flags:       [ property, ],
      source:      "currentOwnerId",
      destination: "Staff.companyId",
    },
    "toDocument": {
      flags:       [ property, isToMany, ],
      source:      "Doc.documentId",
      destination: "parentDocumentId",
    },
    "toDocumentVersion": {
      flags:       [ property, isToMany, ],
      source:      "DocumentVersion.documentId",
      destination: "documentId",
    },
} # entity Note

Doc = {
    table:     "doc",
    className: 'LSDoc',
    
    # attributes
    
    "documentId": {
      column:     "document_id",
      coltype:    't_id',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ primaryKey, lock, property, allowsNull, ],
    },
    "parentDocumentId": {
      column:     "parent_document_id",
      coltype:    't_id',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, allowsNull, ],
    },
    "projectId": {
      column:     "project_id",
      coltype:    't_id',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, allowsNull, ],
    },
    "dateId": {
      column:     "date_id",
      coltype:    't_id',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, allowsNull, ],
    },
    "firstOwnerId": {
      column:     "first_owner_id",
      coltype:    't_id',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, allowsNull, ],
    },
    "currentOwnerId": {
      column:     "current_owner_id",
      coltype:    't_id',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, allowsNull, ],
    },
    "versionCount": {
      column:     "version_count",
      coltype:    't_int',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, allowsNull, ],
    },
    "fileSize": {
      column:     "file_size",
      coltype:    't_int',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, allowsNull, ],
    },
    "isFolder": {
      column:     "is_folder",
      coltype:    't_bool',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, allowsNull, ],
    },
    "isNote": {
      column:     "is_note",
      coltype:    't_bool',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, allowsNull, ],
    },
    "isObjectLink": {
      column:     "is_object_link",
      coltype:    't_bool',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, allowsNull, ],
    },
    "isIndexDoc": {
      column:     "is_index_doc",
      coltype:    't_bool',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, allowsNull, ],
    },
    "title": {
      column:     "title",
      coltype:    't_string',
      valueClass: 'NSString',
      width:      255,
      flags:      [ lock, property, allowsNull, ],
    },
    "abstract": {
      column:     "abstract",
      coltype:    't_string',
      valueClass: 'NSString',
      width:      255,
      flags:      [ lock, property, allowsNull, ],
    },
    "contact": {
      column:     "contact",
      coltype:    't_string',
      valueClass: 'NSString',
      width:      255,
      flags:      [ lock, property, allowsNull, ],
    },
    "objectLink": {
      column:     "object_link",
      coltype:    't_string',
      valueClass: 'NSString',
      width:      255,
      flags:      [ lock, property, allowsNull, ],
    },
    "fileType": {
      column:     "file_type",
      coltype:    't_tinystring',
      valueClass: 'NSString',
      width:      50,
      flags:      [ lock, property, allowsNull, ],
    },
    "creationDate": {
      column:     "creation_date",
      coltype:    't_datetime',
      valueClass: 'NSCalendarDate',
      flags:      [ lock, property, allowsNull, ],
    },
    "lastmodifiedDate": {
      column:     "lastmodified_date",
      coltype:    't_datetime',
      valueClass: 'NSCalendarDate',
      flags:      [ lock, property, allowsNull, ],
    },
    "status": {
      column:     "status",
      coltype:    't_tinystring',
      valueClass: 'NSString',
      width:      50,
      flags:      [ lock, property, allowsNull, ],
    },
    "dbStatus": {
      column:     "db_status",
      coltype:    't_tinystring',
      valueClass: 'NSString',
      width:      50,
      flags:      [ lock, property, allowsNull, ],
    },
    "objectVersion": {
      column:     "object_version",
      coltype:    't_int',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, allowsNull, ],
    },
    
    # relationships
    
    "toParentDocument": {
      flags:       [ property, ],
      source:      "parentDocumentId",
      destination: "Doc.documentId",
    },
    "toProject": {
      flags:       [ property, ],
      source:      "projectId",
      destination: "Project.projectId",
    },
    "toDate": {
      flags:       [ property, ],
      source:      "dateId",
      destination: "Date.dateId",
    },
    "toFirstOwner": {
      flags:       [ property, ],
      source:      "firstOwnerId",
      destination: "Staff.companyId",
    },
    "toCurrentOwner": {
      flags:       [ property, ],
      source:      "currentOwnerId",
      destination: "Staff.companyId",
    },
    "toNote": {
      flags:       [ property, isToMany, ],
      source:      "Note.documentId",
      destination: "parentDocumentId",
    },
    "toDoc": {
      flags:       [ property, isToMany, ],
      source:      "Doc.documentId",
      destination: "parentDocumentId",
    },
    "toDocumentVersion": {
      flags:       [ property, isToMany, ],
      source:      "DocumentVersion.documentId",
      destination: "documentId",
    },
    "toDocumentEditing": {
      flags:       [ property, ],
      source:      "documentId",
      destination: "DocumentEditing.documentId",
    },
} # entity Doc

Telephone = {
    table:     "telephone",
    className: 'LSTelephone',
    
    # attributes
    
    "telephoneId": {
      column:     "telephone_id",
      coltype:    't_id',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ primaryKey, lock, property, allowsNull, ],
    },
    "companyId": {
      column:     "company_id",
      coltype:    't_id',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, allowsNull, ],
    },
    "number": {
      column:        "fnumber",
      pgsql+column:  "number",      
      mysql5+column: "number",      
      coltype:       't_string',
      valueClass:    'NSString',
      width:         255,
      flags:         [ lock, property, allowsNull, ],
    },
    "realNumber": {
      column:     "real_number",
      coltype:    't_string',
      valueClass: 'NSString',
      width:      255,
      flags:      [ lock, property, allowsNull, ],
    },
    "type": {
      column:        "ftype",
      pgsql+column:  "type",      
      mysql5+column: "type",      
      coltype:       't_tinystring',
      valueClass:    'NSString',
      width:         50,
      flags:         [ lock, property, allowsNull, ],
    },
    "info": {
      column:     "info",
      coltype:    't_string',
      valueClass: 'NSString',
      width:      255,
      flags:      [ lock, property, allowsNull, ],
    },
    "url": {
      column:     "url",
      coltype:    't_string',
      valueClass: 'NSString',
      width:      255,
      flags:      [ lock, property, allowsNull, ],
    },
    "dbStatus": {
      column:     "db_status",
      coltype:    't_tinystring',
      valueClass: 'NSString',
      width:      50,
      flags:      [ lock, property, allowsNull, ],
    },
    
    # relationships
    
    "toPerson": {
      flags:       [ property, ],
      source:      "companyId",
      destination: "Person.companyId",
    },
    "toEnterprise": {
      flags:       [ property, ],
      source:      "companyId",
      destination: "Enterprise.companyId",
    },
    "toTeam": {
      flags:       [ property, ],
      source:      "companyId",
      destination: "Team.companyId",
    },
} # entity Telephone

Date = {
    table:        "appointment",
    pgsql+table:  "date_x",    
    mysql5+table: "apointment",    
    className:    'LSAppointment',
    
    # attributes
    
    "dateId": {
      column:     "date_id",
      coltype:    't_id',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ primaryKey, lock, property, allowsNull, ],
    },
    "parentDateId": {
      column:     "parent_date_id",
      coltype:    't_id',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ property, allowsNull, ],
    },
    "startDate": {
      column:     "start_date",
      coltype:    't_datetime',
      valueClass: 'NSCalendarDate',
      flags:      [ property, allowsNull, ],
    },
    "endDate": {
      column:     "end_date",
      coltype:    't_datetime',
      valueClass: 'NSCalendarDate',
      flags:      [ property, allowsNull, ],
    },
    "cycleEndDate": {
      column:     "cycle_end_date",
      coltype:    't_datetime',
      valueClass: 'NSCalendarDate',
      flags:      [ property, allowsNull, ],
    },
    "ownerId": {
      column:     "owner_id",
      coltype:    't_id',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, allowsNull, ],
    },
    "accessTeamId": {
      column:     "access_team_id",
      coltype:    't_id',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, allowsNull, ],
    },
    "notificationTime": {
      column:     "notification_time",
      coltype:    't_int',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ property, allowsNull, ],
    },
    "isAttendance": {
      column:     "is_attendance",
      coltype:    't_bool',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ property, allowsNull, ],
    },
    "isConflictDisabled": {
      column:     "is_conflict_disabled",
      coltype:    't_bool',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ property, allowsNull, ],
    },
    "type": {
      column:        "ftype",
      pgsql+column:  "type",      
      mysql5+column: "type",      
      coltype:       't_tinystring', # weekday,daily,weekly,monthly,yearly
      valueClass:    'NSString',
      width:         255,
      flags:         [ property, allowsNull, ],
    },
    "title": {
      column:     "title",
      coltype:    't_string',
      valueClass: 'NSString',
      width:      255,
      flags:      [ property, allowsNull, ],
    },
    "aptType": {
      column:     "apt_type",
      coltype:    't_smallstring',
      valueClass: 'NSString',
      width:      100,
      flags:      [ property, allowsNull, ],
    },
    "location": {
      column:     "location",
      coltype:    't_string',
      valueClass: 'NSString',
      width:      255,
      flags:      [ property, allowsNull, ],
    },
    "absence": {
      column:     "absence",
      coltype:    't_string',
      valueClass: 'NSString',
      width:      255,
      flags:      [ property, allowsNull, ],
    },
    "resourceNames": {
      column:     "resource_names",
      coltype:    't_string',
      valueClass: 'NSString',
      width:      255,
      flags:      [ property, allowsNull, ],
    },
    "writeAccessList": {
      column:     "write_access_list",
      coltype:    't_string',
      valueClass: 'NSString',
      width:      255,
      flags:      [ property, allowsNull, ],
    },
    "isAbsence": {
      column:     "is_absence",
      coltype:    't_bool',
      valueClass: 'NSNumber',
      flags:      [ property, allowsNull, ],
    },
    "calendarName": {
      column:     "calendar_name",
      coltype:    't_string',
      valueClass: 'NSString',
      width:      255,
      flags:      [ property, allowsNull, ],
    },
    "sourceUrl": {
      column:     "source_url",
      coltype:    't_string',
      valueClass: 'NSString',
      width:      255,
      flags:      [ property, allowsNull, ],
    },
    "fbtype": {
      column:     "fbtype",
      coltype:    't_tinystring',
      valueClass: 'NSString',
      width:      50,
      flags:      [  property, allowsNull, ],
    },
    "dbStatus": {
      column:     "db_status",
      coltype:    't_tinystring',
      valueClass: 'NSString',
      width:      50,
      flags:      [ property, allowsNull, ],
    },
    "objectVersion": {
      column:     "object_version",
      coltype:    't_int',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, allowsNull, ],
    },
    "sensitivity": {
      column:     "sensitivity",
      coltype:    't_int',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ property, allowsNull, ],
    },
    "busyType": {
      column:     "busy_type",
      coltype:    't_int',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ property, allowsNull, ],
    },
    "importance": {
      column:     "importance",
      coltype:    't_int',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ property, allowsNull, ],
    },
    "lastModified": {
      column:     "last_modified",
      coltype:    't_int',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ property, allowsNull, ],
    },
    "evoReminder": {
      column:     "evo_reminder",
      coltype:    't_string',
      valueClass: 'NSString',
      width:      255,
      flags:      [ property, allowsNull, ],
    },
    "olReminder": {
      column:     "ol_reminder",
      coltype:    't_string',
      valueClass: 'NSString',
      width:      255,
      flags:      [ property, allowsNull, ],
    },
    "onlineMeeting": {
      column:     "online_meeting",
      coltype:    't_string',
      valueClass: 'NSString',
      width:      255,
      flags:      [ property, allowsNull, ],
    },
    "associatedContacts": {
      column:     "associated_contacts",
      coltype:    't_string',
      valueClass: 'NSString',
      width:      255,
      flags:      [ property, allowsNull, ],
    },
    "keywords": {
      column:     "keywords",
      coltype:    't_string',
      valueClass: 'NSString',
      width:      255,
      flags:      [ property, allowsNull, ],
    },
    
    # relationships
    
    "toParentDate": {
      flags:       [ property, ],
      source:      "parentDateId",
      destination: "Date.dateId",
    },
    "toDate": {
      flags:       [ property, isToMany, ],
      source:      "Date.dateId",
      destination: "parentDateId",
    },
    "toOwner": {
      flags:       [ property, ],
      source:      "ownerId",
      destination: "Staff.companyId",
    },
    "toAccessTeam": {
      flags:       [ property, ],
      source:      "accessTeamId",
      destination: "Team.companyId",
    },
    "toDateInfo": {
      flags:       [ property, ],
      source:      "dateId",
      destination: "DateInfo.dateId",
    },
    "toDateCompanyAssignment": {
      flags:       [ property, isToMany, ],
      source:      "DateCompanyAssignment.dateId",
      destination: "dateId",
    },
    "toNote": {
      flags:       [ property, isToMany, ],
      source:      "Note.dateId",
      destination: "dateId",
    },
} # entity Date

Job = {
    table:     "job",
    className: 'LSJob',
    
    # attributes
    
    "jobId": {
      column:     "job_id",
      coltype:    't_id',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ primaryKey, lock, property, ],
    },
    "parentJobId": {
      column:     "parent_job_id",
      coltype:    't_id',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ property, allowsNull, ],
    },
    "projectId": {
      column:     "project_id",
      coltype:    't_id',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ property, allowsNull, ],
    },
    "creatorId": {
      column:     "creator_id",
      coltype:    't_id',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ property, ],
    },
    "executantId": {
      column:     "executant_id",
      coltype:    't_id',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ property, allowsNull, ],
    },
    "name": {
      column:        "fname",
      pgsql+column:  "name",      
      mysql5+column: "name",      
      coltype:       't_string',
      valueClass:    'NSString',
      width:         255,
      flags:         [ property, allowsNull, ],
    },
    "startDate": {
      column:     "start_date",
      coltype:    't_datetime',
      valueClass: 'NSCalendarDate',
      flags:      [ property, ],
    },
    "endDate": {
      column:     "end_date",
      coltype:    't_datetime',
      valueClass: 'NSCalendarDate',
      flags:      [ property, ],
    },
    "notify": {
      column:        "notify",
      pgsql+column:  "notify_x",      
      mysql5+column: "notify_x",      
      coltype:    't_int',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ property, allowsNull, ],
    },
    "isControlJob": {
      column:     "is_control_job",
      coltype:    't_bool',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ property, allowsNull, ],
    },
    "isTeamJob": {
      column:     "is_team_job",
      coltype:    't_bool',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ property, allowsNull, ],
    },
    "jobStatus": {
      column:     "job_status",
      coltype:    't_string',
      valueClass: 'NSString',
      width:      255,
      flags:      [ property, allowsNull, ],
    },
    "category": {
      column:     "category",
      coltype:    't_string',
      valueClass: 'NSString',
      width:      255,
      flags:      [ property, allowsNull, ],
    },
    "kind": {
      column:     "kind",
      coltype:    't_tinystring',
      valueClass: 'NSString',
      width:      50,
      flags:      [ property, allowsNull, ],
    },
    "priority": {
      column:     "priority",
      coltype:    't_int',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ property, allowsNull, ],
    },
    "dbStatus": {
      column:     "db_status",
      coltype:    't_tinystring',
      valueClass: 'NSString',
      width:      50,
      flags:      [ property, allowsNull, ],
    },
    "objectVersion": {
      column:     "object_version",
      coltype:    't_int',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, allowsNull, ],
    },
    "keywords": {
      column:     "keywords",
      coltype:    't_string',
      valueClass: 'NSString',
      width:      255,
      flags:      [ property, allowsNull, ],
    },
    "sourceUrl": {
      column:        "source_url",
      coltype:       't_string',
      valueClass:    'NSString',
      width:         255,
      flags:         [ property, allowsNull, ],
    },
    "sensitivity": {
      column:        "sensitivity",
      coltype:       't_int',
      valueClass:    'NSNumber',
      valueType:     'i',
      flags:         [ property, allowsNull, ],
    },
    "comment": {
      column:        "job_comment",
      coltype:       't_string',
      valueClass:    'NSString',
      width:         8000,
      flags:         [ property, allowsNull, ],
    },
    "completionDate": {
      column:        "completion_date",
      coltype:       't_datetime',
      valueClass:    'NSCalendarDate',
      flags:         [ property, allowsNull, ],
    },
    "percentComplete": {
      column:        "percent_complete",
      coltype:       't_int',
      valueClass:    'NSNumber',
      valueType:     'i',
      flags:         [ property, allowsNull, ],
    },
    "actualWork": {
      column:        "actual_work",
      coltype:       't_int',
      valueClass:    'NSNumber',
      valueType:     'i',
      flags:         [ property, allowsNull, ],
    },
    "totalWork": {
      column:        "total_work",
      coltype:       't_int',
      valueClass:    'NSNumber',
      valueType:     'i',
      flags:         [ property, allowsNull, ],
    },
    "lastModified": {
      column:        "last_modified",
      coltype:       't_int',
      valueClass:    'NSNumber',
      valueType:     'i',
      flags:         [ property, allowsNull, ],
    },
    "accountingInfo": {
      column:        "accounting_info",
      coltype:       't_string',
      valueClass:    'NSString',
      width:         255,
      flags:         [ property, allowsNull, ],
    },
    "kilometers": {
      column:        "kilometers",
      coltype:       't_string',
      valueClass:    'NSString',
      width:         255,
      flags:         [ property, allowsNull, ],
    },
    "associatedCompanies": {
      column:        "associated_companies",
      coltype:       't_string',
      valueClass:    'NSString',
      width:         255,
      flags:         [ property, allowsNull, ],
    },
    "associatedContacts": {
      column:        "associated_contacts",
      coltype:       't_string',
      valueClass:    'NSString',
      width:         255,
      flags:         [ property, allowsNull, ],
    },
    "timerDate": {
      column:        "timer_date",
      coltype:       't_datetime',
      valueClass:    'NSCalendarDate',
      flags:         [ property, allowsNull, ],
    },

    # relationships
    
    "toProject": {
      flags:       [ property, ],
      source:      "projectId",
      destination: "Project.projectId",
    },
    "toCreator": {
      flags:       [ property, ],
      source:      "creatorId",
      destination: "Staff.companyId",
    },
    "toExecutant": {
      flags:       [ property, ],
      source:      "executantId",
      destination: "Staff.companyId",
    },
    "toParentJob": {
      flags:       [ property, ],
      source:      "parentJobId",
      destination: "Job.jobId",
    },
    "toJob": {
      flags:       [ property, isToMany, ],
      source:      "Job.jobId",
      destination: "parentJobId",
    },
    "toJobHistory": {
      flags:       [ property, isToMany, ],
      source:      "JobHistory.jobId",
      destination: "jobId",
    },
    "toResourceAssignment": {
      flags:       [ property, isToMany, ],
      source:      "JobResourceAssignment.jobId",
      destination: "jobId",
    },
    "toChildJobAssignment": {
      flags:       [ property, isToMany, ],
      source:      "JobAssignment.jobId",
      destination: "parentJobId",
    },
    "toParentJobAssignment": {
      flags:       [ property, isToMany, ],
      source:      "JobAssignment.jobId",
      destination: "childJobId",
    }
} # entity Job

JobHistoryInfo = {
    table:     "job_history_info",
    className: 'LSJobHistoryInfo',
    
    # attributes
    
    "jobHistoryInfoId": {
      column:     "job_history_info_id",
      coltype:    't_id',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ primaryKey, lock, property, allowsNull, ],
    },
    "jobHistoryId": {
      column:     "job_history_id",
      coltype:    't_id',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, allowsNull, ],
    },
    "comment": {
      column:        "comment",
      coltype:       't_text',
      fb+coltype:    'VARCHAR(1000000)',
      valueClass:    'NSString',
      flags:         [ lock, property, allowsNull, ],
    },
    "dbStatus": {
      column:     "db_status",
      coltype:    't_tinystring',
      valueClass: 'NSString',
      width:      50,
      flags:      [ lock, property, allowsNull, ],
    },
    
    # relationships
    
    "toJobHistory": {
      flags:       [ property, ],
      source:      "jobHistoryId",
      destination: "JobHistory.jobHistoryId",
    },
} # entity JobHistoryInfo

Team = {
    table:     "team",
    className: 'LSTeam',
    
    # attributes
    
    "companyId": {
      column:     "company_id",
      coltype:    't_id',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ primaryKey, lock, property, allowsNull, ],
    },
    "ownerId": {
      column:     "owner_id",
      coltype:    't_id',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, allowsNull, ],
    },
    "contactId": {
      column:     "contact_id",
      coltype:    't_id',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ property, allowsNull, ],
    },
    "description": {
      column:     "description",
      coltype:    't_string',
      valueClass: 'NSString',
      width:      255,
      flags:      [ property, allowsNull, ],
    },
    "number": {
      column:        "fnumber",
      pgsql+column:  "number",      
      mysql5+column: "number",      
      coltype:       't_string',
      valueClass:    'NSString',
      width:         255,
      flags:         [ property, allowsNull, ],
    },
    "login": {
      column:     "login",
      coltype:    't_string',
      valueClass: 'NSString',
      width:      255,
      flags:      [ property, allowsNull, ],
    },
    "email": {
      column:     "email",
      coltype:    't_string',
      valueClass: 'NSString',
      width:      255,
      flags:      [ property, allowsNull, ],
    },
    "isTeam": {
      column:     "is_team",
      coltype:    't_bool',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ property, allowsNull, ],
    },
    "isLocationTeam": {
      column:     "is_location_team",
      coltype:    't_bool',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ property, allowsNull, ],
    },
    "dbStatus": {
      column:     "db_status",
      coltype:    't_tinystring',
      valueClass: 'NSString',
      width:      50,
      flags:      [ property, allowsNull, ],
    },
    "isPrivate": {
      column:     "is_private",
      coltype:    't_bool',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, allowsNull, ],
    },
    "isReadonly": {
      column:     "is_readonly",
      coltype:    't_bool',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, allowsNull, ],
    },
    "objectVersion": {
      column:     "object_version",
      coltype:    't_int',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, allowsNull, ],
    },
    "sensitivity": {
      column:     "sensitivity",
      coltype:    't_int',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ property, allowsNull, ],
    },
    "bossName": {
      column:     "boss_name",
      coltype:    't_string',
      valueClass: 'NSString',
      width:      255,
      flags:      [ property, allowsNull, ],
    },
    "partnerName": {
      column:     "partner_name",
      coltype:    't_string',
      valueClass: 'NSString',
      width:      255,
      flags:      [ property, allowsNull, ],
    },
    "assistantName": {
      column:     "assistant_name",
      coltype:    't_string',
      valueClass: 'NSString',
      width:      255,
      flags:      [ property, allowsNull, ],
    },
    "department": {
      column:     "department",
      coltype:    't_string',
      valueClass: 'NSString',
      width:      255,
      flags:      [ property, allowsNull, ],
    },
    "office": {
      column:     "office",
      coltype:    't_string',
      valueClass: 'NSString',
      width:      255,
      flags:      [ property, allowsNull, ],
    },
    "occupation": {
      column:     "occupation",
      coltype:    't_string',
      valueClass: 'NSString',
      width:      255,
      flags:      [ property, allowsNull, ],
    },
    "anniversary": {
      column:     "anniversary",
      coltype:    't_datetime',
      valueClass: 'NSCalendarDate',
      flags:      [ property, allowsNull, ],
    },
    "dirServer": {
      column:     "dir_server",
      coltype:    't_string',
      valueClass: 'NSString',
      width:      255,
      flags:      [ property, allowsNull, ],
    },
    "emailAlias": {
      column:     "email_alias",
      coltype:    't_string',
      valueClass: 'NSString',
      width:      255,
      flags:      [ property, allowsNull, ],
    },
    "freebusyUrl": {
      column:     "freebusy_url",
      coltype:    't_string',
      valueClass: 'NSString',
      width:      255,
      flags:      [ property, allowsNull, ],
    },
    "fileas": {
      column:     "fileas",
      coltype:    't_string',
      valueClass: 'NSString',
      width:      255,
      flags:      [ property, allowsNull, ],
    },
    "nameTitle": {
      column:     "name_title",
      coltype:    't_string',
      valueClass: 'NSString',
      width:      255,
      flags:      [ property, allowsNull, ],
    },
    "nameAffix": {
      column:     "name_affix",
      coltype:    't_string',
      valueClass: 'NSString',
      width:      255,
      flags:      [ property, allowsNull, ],
    },
    "imAddress": {
      column:     "im_address",
      coltype:    't_string',
      valueClass: 'NSString',
      width:      255,
      flags:      [ property, allowsNull, ],
    },
    "associatedContacts": {
      column:     "associated_contacts",
      coltype:    't_string',
      valueClass: 'NSString',
      width:      255,
      flags:      [ property, allowsNull, ],
    },    
    "associatedCategories": {
      column:     "associated_categories",
      coltype:    't_string',
      valueClass: 'NSString',
      width:      255,
      flags:      [ property, allowsNull, ],
    },
    "associatedCompany": {
      column:     "associated_company",
      coltype:    't_string',
      valueClass: 'NSString',
      width:      255,
      flags:      [ property, allowsNull, ],
    },        
    
    # relationships
    
    "toOwner": {
      flags:       [ property, ],
      source:      "ownerId",
      destination: "Staff.companyId",
    },
    "toContact": {
      flags:       [ property, ],
      source:      "contactId",
      destination: "Staff.companyId",
    },
    "toStaff": {
      flags:       [ property, isToMany, ],
      source:      "Staff.companyId",
      destination: "companyId",
    },
    "toCompanyInfo": {
      flags:       [ property, ],
      source:      "companyId",
      destination: "CompanyInfo.companyId",
    },
    "toCompanyValue": {
      flags:       [ property, isToMany, ],
      source:      "CompanyValue.companyId",
      destination: "companyId",
    },
    "toCompanyAssignment": {
      flags:       [ property, isToMany, ],
      source:      "CompanyAssignment.companyId",
      destination: "companyId",
    },
    "toCompanyAssignment1": {
      flags:       [ property, isToMany, ],
      source:      "CompanyAssignment.companyId",
      destination: "subCompanyId",
    },
    "toDate": {
      flags:       [ property, isToMany, ],
      source:      "Date.companyId",
      destination: "ownerId",
    },
    "toDateCompanyAssignment": {
      flags:       [ property, isToMany, ],
      source:      "DateCompanyAssignment.companyId",
      destination: "companyId",
    },
    "toProjectCompanyAssignment": {
      flags:       [ property, isToMany, ],
      source:      "ProjectCompanyAssignment.companyId",
      destination: "companyId",
    },
    "toAddress": {
      flags:       [ property, isToMany, ],
      source:      "Address.companyId",
      destination: "companyId",
    },
    "toTelephone": {
      flags:       [ property, isToMany, ],
      source:      "Telephone.companyId",
      destination: "companyId",
    },
} # entity Team

ProjectCompanyAssignment = {
    table:     "project_company_assignment",
    className: 'LSProjectCompanyAssignment',
    
    # attributes
    
    "projectCompanyAssignmentId": {
      column:     "project_company_assignment_id",
      coltype:    't_id',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ primaryKey, lock, property, allowsNull, ],
    },
    "companyId": {
      column:     "company_id",
      coltype:    't_id',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, allowsNull, ],
    },
    "projectId": {
      column:     "project_id",
      coltype:    't_id',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, allowsNull, ],
    },
    "info": {
      column:     "info",
      coltype:    't_string',
      valueClass: 'NSString',
      width:      255,
      flags:      [ property, allowsNull, ],
    },
    "accessRight": {
      column:     "access_right",
      coltype:    't_tinystring',
      valueClass: 'NSString',
      width:      50,
      flags:      [ property, allowsNull, ],
    },
    "hasAccess": {
      column:     "has_access",
      coltype:    't_bool',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ property, allowsNull, ],
    },
    "dbStatus": {
      column:     "db_status",
      coltype:    't_tinystring',
      valueClass: 'NSString',
      width:      50,
      flags:      [ lock, property, allowsNull, ],
    },
    
    # relationships
    
    "toPerson": {
      flags:       [ property, ],
      source:      "companyId",
      destination: "Person.companyId",
    },
    "toProject": {
      flags:       [ property, ],
      source:      "projectId",
      destination: "Project.projectId",
    },
} # entity ProjectCompanyAssignment

ObjectAcl = {
    table:     "object_acl",
    className: 'LSObjectAcl',
    
    # attributes
    
    "objectAclId": {
      column:     "object_acl_id",
      coltype:    't_id',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ primaryKey, lock, property, ],
    },
    "sortKey": {
      column:     "sort_key",
      coltype:    't_int',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ property, ],
    },
    "action": {
      column:        "faction",
      pgsql+column:  "action",      
      mysql5+column: "action",      
      coltype:    't_string',
      valueClass: 'NSString',
      width:      10,
      flags:      [ property, ],
    },
    "objectId": {
      column:     "object_id",
      coltype:    't_string',
      valueClass: 'NSString',
      width:      255,
      flags:      [ property, ],
    },
    "authId": {
      column:     "auth_id",
      coltype:    't_string',
      valueClass: 'NSString',
      width:      255,
      flags:      [ property, allowsNull, ],
    },
    "permissions": {
      column:     "permissions",
      coltype:    't_string',
      valueClass: 'NSString',
      valueType:  50,
      flags:      [ property, allowsNull, ],
    },
} # entity ObjectAcl

NewsArticle = {
    table:     "news_article",
    className: 'LSNewsArticle',
    
    # attributes
    
    "newsArticleId": {
      column:     "news_article_id",
      coltype:    't_id',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ primaryKey, lock, property, allowsNull, ],
    },
    "isIndexArticle": {
      column:     "is_index_article",
      coltype:    't_bool',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, allowsNull, ],
    },
    "name": {
      column:        "fname",
      pgsql+column:  "name",      
      mysql5+column: "name",      
      coltype:       't_string',
      valueClass:    'NSString',
      width:         255,
      flags:         [ lock, property, allowsNull, ],
    },
    "caption": {
      column:     "caption",
      coltype:    't_string',
      valueClass: 'NSString',
      width:      255,
      flags:      [ lock, property, allowsNull, ],
    },
    "dbStatus": {
      column:     "db_status",
      coltype:    't_tinystring',
      valueClass: 'NSString',
      width:      50,
      flags:      [ lock, property, allowsNull, ],
    },
    
    # relationships
    
    "toNewsArticleLink": {
      flags:       [ property, isToMany, ],
      source:      "NewsArticleLink.newsArticleId",
      destination: "newsArticleId",
    },
    "toNewsArticleLink1": {
      flags:       [ property, isToMany, ],
      source:      "NewsArticleLink.newsArticleId",
      destination: "subNewsArticleId",
    },
} # entity NewsArticle

NewsArticleLink = {
    table:     "news_article_link",
    className: 'LSNewsArticleLink',
    
    # attributes
    
    "newsArticleLinkId": {
      column:     "news_article_link_id",
      coltype:    't_id',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ primaryKey, lock, property, allowsNull, ],
    },
    "newsArticleId": {
      column:     "news_article_id",
      coltype:    't_id',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, allowsNull, ],
    },
    "subNewsArticleId": {
      column:     "sub_news_article_id",
      coltype:    't_id',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, allowsNull, ],
    },
    
    # relationships
    
    "toNewsArticle": {
      flags:       [ property, ],
      source:      "newsArticleId",
      destination: "NewsArticle.newsArticleId",
    },
    "toSubNewsArticle": {
      flags:       [ property, ],
      source:      "subNewsArticleId",
      destination: "NewsArticle.newsArticleId",
    },
} # entity NewsArticleLink

Log = {
    table:     "log",
    className: 'LSLog',
    
    # attributes
    
    "logId": {
      column:     "log_id",
      coltype:    't_id',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ primaryKey, lock, property, allowsNull, ],
    },
    "creationDate": {
      column:     "creation_date",
      coltype:    't_datetime',
      valueClass: 'NSCalendarDate',
      flags:      [ property, allowsNull, ],
    },
    "objectId": {
      column:     "object_id",
      coltype:    't_id',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ property, allowsNull, ],
    },
    "logText": {
      column:     "log_text",
      coltype:    't_text',
      valueClass: 'NSString',
      flags:      [ property, allowsNull, ],
    },
    "accountId": {
      column:     "account_id",
      coltype:    't_id',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ property, allowsNull, ],
    },
    "action": {
      column:        "faction",
      pgsql+column:  "action",      
      mysql5+column: "action",      
      coltype:       't_smallstring',
      valueClass:    'NSString',
      width:         100,
      flags:         [ property, allowsNull, ],
    },
} # entity Log

SessionLog = {
    table:     "session_log",
    className: 'LSSessionLog',
    
    # attributes
    
    "sessionLogId": {
      column:     "session_log_id",
      coltype:    't_id',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ primaryKey, lock, property, ],
    },
    "logDate": {
      column:     "log_date",
      coltype:    't_datetime',
      valueClass: 'NSCalendarDate',
      flags:      [ property, ],
    },
    "accountId": {
      column:     "account_id",
      coltype:    't_id',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ property, ],
    },
    "action": {
      column:        "faction",
      pgsql+column:  "action",      
      mysql5+column: "action",      
      coltype:       't_smallstring',
      valueClass:    'NSString',
      width:         100,
      flags:         [ property, allowsNull, ],
    },
} # entity Log

Invoice = {
    table:     "invoice",
    className: 'LSInvoice',
    
    # attributes
    
    "invoiceId": {
      column:     "invoice_id",
      coltype:    't_id',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ primaryKey, lock, property, ],
    },
    "parentInvoiceId": {
      column:     "parent_invoice_id",
      coltype:    't_id',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ property, ],
    },
    "invoiceNr": {
      column:     "invoice_nr",
      coltype:    't_tinystring',
      valueClass: 'NSString',
      width:      50,
      flags:      [ property, ],
    },
    "invoiceDate": {
      column:     "invoice_date",
      coltype:    't_datetime',
      valueClass: 'NSCalendarDate',
      flags:      [ property, allowsNull, ],
    },
    "debitorId": {
      column:     "debitor_id",
      coltype:    't_id',
      valueClass: 'NSNumber',
      flags:      [ property, ],
    },
    "kind": {
      column:     "kind",
      coltype:    't_smallstring',
      valueClass: 'NSString',
      width:      100,
      flags:      [ property, allowsNull, ],
    },
    "status": {
      column:     "status",
      coltype:    't_smallstring',
      valueClass: 'NSString',
      width:      100,
      flags:      [ property, lock, ],
    },
    "comment": {
      column:        "comment",
      coltype:       't_text',
      valueClass:    'NSString',
      flags:         [ property, allowsNull, ],
    },
    "netAmount": {
      column:     "net_amount",
      coltype:    't_double',
      valueType:  'd',
      valueClass: 'NSNumber',
      flags:      [ property, allowsNull, ],
    },
    "grossAmount": {
      column:     "gross_amount",
      coltype:    't_double',
      valueType:  'd',
      valueClass: 'NSNumber',
      flags:      [ property, allowsNull, ],
    },
    "paid": {
      column:     "paid",
      coltype:    't_double',
      valueType:  'd',
      valueClass: 'NSNumber',
      flags:      [ property, allowsNull, ],
    },
    "dbStatus": {
      column:     "db_status",
      coltype:    't_tinystring',
      valueClass: 'NSString',
      width:      50,
      flags:      [ property, allowsNull, ],
    },
    "objectVersion": {
      column:     "object_version",
      coltype:    't_int',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, allowsNull, ],
    },

    # relationships

    "toDebitor": {
      flags:       [ ],
      source:      "debitorId",
      destination: "Enterprise.companyId",
    },
    "toInvoiceArticleAssignment": {
      flags:       [ property, isToMany, ],
      source:      "InvoiceArticleAssignment.invoiceId",
      destination: "invoiceId",
    },
} #entity Invoice

InvoiceAccount = {
    table:     "invoice_account",
    className: 'LSInvoiceAccount',

    #attributes

    "invoiceAccountId" : {
      column:     "invoice_account_id",
      coltype:    't_id',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ primaryKey, lock, property, allowsNull, ],
    },
    "companyId" : {
      column:     "enterprise_id",
      coltype:    't_id',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, allowsNull, ],
    },
    "accountNr":  {
      column:     "account_nr",
      coltype:    't_tinystring',
      valueClass: 'NSString',
      width:      50,
      flags:      [ property, ],
    },
    "balance": {
      column:     "balance",
      coltype:    't_double',
      valueType:  'd',
      valueClass: 'NSNumber',
      flags:      [ property, allowsNull, ],
    },
    "dbStatus": {
      column:     "db_status",
      coltype:    't_tinystring',
      valueClass: 'NSString',
      width:      50,
      flags:      [ property, allowsNull, ],
    },
    "objectVersion": {
      column:     "object_version",
      coltype:    't_int',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, allowsNull, ],
    },
    
    # relationships
    
    "toEnterprise": {
      flags:       [ property, ],
      source:      "companyId",
      destination: "Enterprise.companyId",
    },
} # entity InvoiceAccount

InvoiceAction = {
    table:     "invoice_action",
    className: 'LSInvoiceAction',

    #attributes

    "invoiceActionId" : {
      column:     "invoice_action_id",
      coltype:    't_id',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ primaryKey, lock, property, allowsNull, ],
    },
    "accountId" : {
      column:     "account_id",
      coltype:    't_id',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, allowsNull, ],
    },
    "invoiceId" : {
      column:     "invoice_id",
      coltype:    't_id',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, allowsNull, ],
    },
    "documentId" : {
      column:     "document_id",
      coltype:    't_id',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, allowsNull, ],
    },
    "actionDate": {
      column:     "action_date",
      coltype:    't_datetime',
      valueClass: 'NSCalendarDate',
      flags:      [ property, allowsNull, ],
    },
    "kind": {
      column:     "action_kind",
      coltype:    't_tinystring',
      valueClass: 'NSString',
      width:      50,
      flags:      [ property, allowsNull, ],
    },
    "logText": {
      column:     "log_text",
      coltype:    't_text',
      valueClass: 'NSString',
      flags:      [ property, allowsNull, ],
    },
    "dbStatus": {
      column:     "db_status",
      coltype:    't_tinystring',
      valueClass: 'NSString',
      width:      50,
      flags:      [ lock, property, allowsNull, ],
    },
    "objectVersion": {
      column:     "object_version",
      coltype:    't_int',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, allowsNull, ],
    },

    # relationships
    
    "toInvoiceAccount": {
      flags:       [ property, ],
      source:      "accountId",
      destination: "InvoiceAccount.invoiceAccountId",
    },
    "toInvoice": {
      flags:       [ property, ],
      source:      "invoiceId",
      destination: "Invoice.invoiceId",
    },
    "toDocument": {
      flags:       [ property, ],
      source:      "documentId",
      destination: "Doc.documentId",
    },
} # entity InvoiceAction

InvoiceAccounting = {
    table:     "invoice_accounting",
    className: 'LSInvoiceAccounting',

    #attributes

    "invoiceAccountingId" : {
      column:     "invoice_accounting_id",
      coltype:    't_id',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ primaryKey, lock, property, allowsNull, ],
    },
    "actionId" : {
      column:     "action_id",
      coltype:    't_id',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, allowsNull, ],
    },
    "debit": {
      column:     "debit",
      coltype:    't_double',
      valueType:  'd',
      valueClass: 'NSNumber',
      flags:      [ property, allowsNull, ],
    },
    "balance": {
      column:     "balance",
      coltype:    't_double',
      valueType:  'd',
      valueClass: 'NSNumber',
      flags:      [ property, allowsNull, ],
    },
    "dbStatus": {
      column:     "db_status",
      coltype:    't_tinystring',
      valueClass: 'NSString',
      width:      50,
      flags:      [ lock, property, allowsNull, ],
    },
    "objectVersion": {
      column:     "object_version",
      coltype:    't_int',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, allowsNull, ],
    },

    # relationships
    
    "toInvoiceAction": {
      flags:       [ property, ],
      source:      "actionId",
      destination: "InvoiceAction.invoiceActionId",
    },
} # InvoiceAccounting

Article = {
    table:     "article",
    className: 'LSArticle',
    
    # attributes
    
    "articleId": {
      column:     "article_id",
      coltype:    't_id',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ primaryKey, lock, property, ],
    },
    "articleName": {
      column:     "article_name",
      coltype:    't_string',
      valueClass: 'NSString',
      width:      255,
      flags:      [ property, lock, ],
    },
    "articleNr": {
      column:     "article_nr",
      coltype:    't_string',
      valueClass: 'NSString',
      width:      255,
      flags:      [ property, lock, ],
    },
    "status": {
      column:     "status",
      coltype:    't_tinystring',
      valueClass: 'NSString',
      width:      50,
      flags:      [ property, ],
    },
    "comment": {
      column:     "article_text",
      coltype:    't_text',
      valueClass: 'NSString',
      flags:      [ property, allowsNull, ],
    },
    "price": {
      column:     "price",
      coltype:    't_double',
      valueClass: 'NSNumber',
      valueType:  'd',
      flags:      [ property, allowsNull, ],
    },
    "vat": {
      column:     "vat",
      coltype:    't_double',
      valueClass: 'NSNumber',
      valueType:  'd',
      flags:      [ property, allowsNull, ],
    },
    "vatGroup": {
      column:     "vat_group",
      coltype:    't_tinystring',
      valueClass: 'NSString',
      flags:      [ property, allowsNull, lock, ],
    },
    "articleUnitId": {
      column:     "article_unit_id",
      coltype:    't_id',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ property, ],
    },
    "articleCategoryId": {
      column:     "article_category_id",
      coltype:    't_id',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ property, ],
    },
    "objectVersion": {
      column:     "object_version",
      coltype:    't_int',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, allowsNull, ],
    },
    "dbStatus": {
      column:     "db_status",
      coltype:    't_tinystring',
      valueClass: 'NSString',
      width:      50,
      flags:      [ property, allowsNull, ],
    },

    # relationships

    "toInvoiceArticleAssignment": {
      flags:       [ property, isToMany, ],
      source:      "InvoiceArticleAssignment.articleId",
      destination: "articleId",
    },
    "toArticleUnit": {
      flags:       [ property, ],
      source:      "articleUnitId",
      destination: "ArticleUnit.articleUnitId",
    },
    "toArticleCategory": {
      flags:       [ property, ],
      source:      "articleCategoryId",
      destination: "ArticleCategory.articleCategoryId",
    },
} #entity Article

ArticleUnit = {
    table:     "article_unit",
    className: 'LSArticleUnit',
    
    # attributes
    
    "articleUnitId": {
      column:     "article_unit_id",
      coltype:    't_id',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ primaryKey, lock, property, ],
    },
    "singularUnit": {
      column:     "singular_unit",
      coltype:    't_string',
      valueClass: 'NSString',
      width:      255,
      flags:      [ property, lock, ],
    },
    "pluralUnit": {
      column:     "plural_unit",
      coltype:    't_string',
      valueClass: 'NSString',
      width:      255,
      flags:      [ property, lock, ],
    },
    "description": {
      column:     "format",
      coltype:    't_tinystring',
      valueClass: 'NSString',
      width:      50,
      flags:      [ property, lock, ],
    },
    
    #relationship
    
    "toArticle": {
      flags:       [ property, isToMany, ],
      source:      "Article.articleUnitId",
      destination: "articleUnitId",
    },
} #entity ArticleUnit

ArticleCategory = {
    table:     "article_category",
    className: 'LSArticleCategory',
    
    # attributes
    
    "articleCategoryId": {
      column:     "article_category_id",
      coltype:    't_id',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ primaryKey, lock, property, ],
    },
    "categoryName": {
      column:     "category_name",
      coltype:    't_string',
      valueClass: 'NSString',
      width:      255,
      flags:      [ property, lock, ],
    },
    "categoryAbbrev": {
      column:     "category_abbrev",
      coltype:    't_string',
      valueClass: 'NSString',
      width:      255,
      flags:      [ property, lock, ],
    },

    #relationship
    
    "toArticle": {
      flags:       [ property, isToMany, ],
      source:      "Article.articleCategoryId",
      destination: "articleCategoryId",
    }
} #entity ArticleCategory

InvoiceArticleAssignment = {
    table:     "invoice_article_assignment",
    className: 'LSInvoiceArticleAssignment',
    
    # attributes
    
    "invoiceArticleAssignmentId": {
      column:     "invoice_article_assignment_id",
      coltype:    't_id',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ primaryKey, lock, property, ],
    },
    "invoiceId": {
      column:     "invoice_id",
      coltype:    't_id',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ property, ],
    },
    "articleId": {
      column:     "article_id",
      coltype:    't_id',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ property, ],
    },
    "articleCount": {
      column:     "article_count",
      coltype:    't_double',
      valueClass: 'NSNumber',
      valueType:  'd',
      flags:      [ property, ],
    },
    "netAmount": {
      column:     "net_amount",
      coltype:    't_double',
      valueClass: 'NSNumber',
      valueType:  'd',
      flags:      [ property, allowsNull, ],
    },
    "vat": {
      column:     "vat",
      coltype:    't_double',
      valueClass: 'NSNumber',
      valueType:  'd',
      flags:      [ property, allowsNull, ],
    },
    "comment": {
      column:        "comment",
      coltype:       't_text',
      valueClass:    'NSString',
      flags:         [ property, allowsNull, ],
    },
    "objectVersion": {
      column:     "object_version",
      coltype:    't_int',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, allowsNull, ],
    },
    "dbStatus": {
      column:     "db_status",
      coltype:    't_tinystring',
      valueClass: 'NSString',
      width:      50,
      flags:      [ property, allowsNull, ],
    },

    # relationships
    
    "toInvoice": {
      flags:       [ property, ],
      source:      "invoiceId",
      destination: "Invoice.invoiceId",
    },
    "toArticle": {
      flags:       [ property, ],
      source:      "articleId",
      destination: "Article.articleId",
    },

} #entity InvoiceArticleAssignment

Resource = {
    table:        "resource",
    className:    'LSResource',
    
    # attributes
    
    "resourceId": {
      column:     "resource_id",
      coltype:    't_id',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ primaryKey, lock, property, ],
    },
    "resourceName": {
      column:     "resource_name",
      coltype:    't_string',
      valueClass: 'NSString',
      width:      255,
      flags:      [ property, ],
    },
    "token": {
      column:     "token",
      coltype:    't_string',
      valueClass: 'NSString',
      flags:      [ property, allowsNull, ],
    },
    "objectId": {
      column:     "object_id",
      coltype:    't_id',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ property, allowsNull ],
    },
    "quantity": {
      column:     "quantity",
      coltype:    't_int',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ property, allowsNull, ],
    },
    "comment": {
      column:        "comment",
      coltype:       't_text',
      valueClass:    'NSString',
      flags:         [ property, allowsNull ],
    },
    "standardCosts": {
      column:     "standard_costs",
      coltype:    't_price',
      valueClass: 'NSNumber',
      valueType:  'f',
      flags:      [ property, allowsNull, lock, ],
    },
    "type": {
      column:        "ftype",
      pgsql+column:  "type",      
      mysql5+column: "type",      
      coltype:    't_int',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ property, ],
    },
    "dbStatus": {
      column:     "db_status",
      coltype:    't_tinystring',
      valueClass: 'NSString',
      width:      50,
      flags:      [ property, allowsNull, ],
    },
    "objectVersion": {
      column:     "object_version",
      coltype:    't_int',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, allowsNull, ],
    },

# relationships

    "toSubResourceAssignment": {
      flags:       [ property, isToMany, ],
      source:      "ResourceAssignment.resourceId",
      destination: "superResourceId",
    },
} #entity Resource

ResourceAssignment = {
    table:     "resource_assignment",
    className: 'LSResourceAssignment',
    
    # attributes
    
    "resourceAssignmentId": {
      column:     "resource_assignment_id",
      coltype:    't_id',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ primaryKey, lock, property, ],
    },
    "superResourceId": {
      column:     "super_resource_id",
      coltype:    't_id',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, allowsNull, ],
    },
    "subResourceId": {
      column:     "sub_resource_id",
      coltype:    't_id',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, allowsNull, ],
    },
    "dbStatus": {
      column:     "db_status",
      coltype:    't_tinystring',
      valueClass: 'NSString',
      width:      50,
      flags:      [ lock, property, allowsNull, ],
    },
    
    # relationships
    
    "toSuperResource": {
      flags:       [ property, ],
      source:      "superResourceId",
      destination: "Resource.resourceId",
    },
    "toSubResource": {
      flags:       [ property, ],
      source:      "subResourceId",
      destination: "Resource.resourceId",
    },
} # entity ResourceAssignment


JobResourceAssignment = {
    table:     "job_resource_assignment",
    className: 'LSJobResourceAssignment',
    
    # attributes
    
    "jobResourceAssignmentId": {
      column:     "job_resource_assignment_id",
      coltype:    't_id',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ primaryKey, lock, property, ],
    },
    "resourceId": {
      column:     "resource_id",
      coltype:    't_id',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, ],
    },
    "jobId": {
      column:     "job_id",
      coltype:    't_id',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, ],
    },
    "operativePart": {
      column:     "operative_part",
      coltype:    't_int',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, allowsNull, ],
    },
    "dbStatus": {
      column:     "db_status",
      coltype:    't_tinystring',
      valueClass: 'NSString',
      width:      50,
      flags:      [ lock, property, allowsNull, ],
    },
    
    # relationships
    
    "toResource": {
      flags:       [ property, ],
      source:      "resourceId",
      destination: "Resource.resourceId",
    },
    "toJob": {
      flags:       [ property, ],
      source:      "jobId",
      destination: "Job.jobId",
    },
} # entity JobResourceAssignment


JobAssignment = {
    table:     "job_assignment",
    className: 'LSJobAssignment',
    
    # attributes
    
    "jobAssignmentId": {
      column:     "job_assignment_id",
      coltype:    't_id',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ primaryKey, lock, property, ],
    },
    "parentJobId": {
      column:     "parent_job_id",
      coltype:    't_id',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, ],
    },
    "childJobId": {
      column:     "child_job_id",
      coltype:    't_id',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, ],
    },
    "position": {
      column:        "fposition",
      pgsql+column:  "position_x",      
      mysql5+column: "position_x",      
      coltype:       't_int',
      valueClass:    'NSNumber',
      valueType:     'i',
      flags:         [ property, allowsNull, ],
    },
    "assignmentKind": {
      column:     "assignment_kind",
      coltype:    't_tinystring',
      valueClass: 'NSString',
      width:      50,
      flags:      [ property, allowsNull, ],
    },
    "dbStatus": {
      column:     "db_status",
      coltype:    't_tinystring',
      valueClass: 'NSString',
      width:      50,
      flags:      [ lock, property, allowsNull, ],
    },
    
    # relationships
    
    "toParentJob": {
      flags:       [ property, ],
      source:      "parentJobId",
      destination: "Job.jobId",
    },
    "toChildJob": {
      flags:       [ property, ],
      source:      "childJobId",
      destination: "Job.jobId",
    },
} # entity JobAssignment

ProjectInfo = {
    table:     "project_info",
    className: 'LSProjectInfo',
    
    # attributes
    
    "projectInfoId": {
      column:     "project_info_id",
      coltype:    't_id',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, allowsNull, ],
    },
    "projectId": {
      column:     "project_id",
      coltype:    't_id',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ primaryKey, lock, property, allowsNull, ],
    },
    "comment": {
      column:        "comment",
      coltype:       't_text',
      valueClass:    'NSString',
      flags:         [ property, allowsNull, ],
    },
    "dbStatus": {
      column:     "db_status",
      coltype:    't_tinystring',
      valueClass: 'NSString',
      width:      50,
      flags:      [ lock, property, allowsNull, ],
    },
    
    # relationships
    
    "toProject": {
      flags:       [ property, ],
      source:      "projectId",
      destination: "Project.projectId",
    },
} # entity ProjectInfo

ObjectProperty = {
    table:     "obj_property",
    className: 'LSObjectProperty',
    
    # attributes
    
    "objectPropertyId": {
      column:     "obj_property_id",
      coltype:    't_id',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ primaryKey, lock, property, ],
    },
    "objectId": {
      column:     "obj_id",
      coltype:    't_id',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, ],
    },
    "objectType": {
      column:     "obj_type",
      coltype:    't_string',
      valueClass: 'NSString',
      flags:      [ property, allowsNull, ],
    },
    "accessKey": {
      column:     "access_key",
      coltype:    't_id',
      valueClass: 'NSNumber',
      valueType:  'i',      
      flags:      [ property, allowsNull, ],
    },
    "key": {
      column:     "value_key",
      coltype:    't_string',
      valueClass: 'NSString',
      flags:      [ property, ],
    },
    "namespacePrefix": {
      column:     "namespace_prefix",
      coltype:    't_string',
      valueClass: 'NSString',
      flags:      [ property, allowsNull, ],
    },
    "preferredType": {
      column:     "preferred_type",
      coltype:    't_string',
      valueClass: 'NSString',
      flags:      [ property, ],
    },
    "valueString": {
      column:         "value_string",
      coltype:        't_string',
      fb+coltype:     'VARCHAR(2000000)',
      valueClass:     'NSString',
      flags:          [ property, allowsNull, ],
    },
    "valueInt": {
      column:     "value_int",
      coltype:    't_int',
      valueClass: 'NSNumber',
      valueType:  'i',      
      flags:      [ property, allowsNull, ],
    },
    "valueFloat": {
      column:     "value_float",
      coltype:    't_float',
      valueClass: 'NSNumber',
      valueType:  'f',
      flags:      [ property, allowsNull, ],
    },
    "valueDate": {
      column:     "value_date",
      coltype:    't_datetime',
      valueClass: 'NSCalendarDate',
      flags:      [ property, allowsNull, ],
    },
    "valueOID": {
      column:     "value_oid",
      coltype:    't_string',
      valueClass: 'NSString',
      flags:      [ property, allowsNull, ],
    },
    "blobSize": {
      column:     "blob_size",
      coltype:    't_int',
      valueClass: 'NSNumber',
      flags:      [ property, allowsNull, ],
    },
    "valueBlob": {
      column:     "value_blob",
      coltype:    't_image',
      valueClass: 'NSData',
      flags:      [ property, allowsNull, ],
    },
    # relationships
    
    "toDoc": {
      flags:       [ property, ],
      source:      "objectId",
      destination: "Doc.documentId",
    },
} # entity ObjectProperty

ObjectLink = {
    table:     "obj_link",
    className: 'LSObjectLink',
    
    # attributes
    
    "objectLinkId": {
      column:     "obj_link_id",
      coltype:    't_id',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ primaryKey, lock, property, ],
    },
    "sourceId": {
      column:     "source_id",
      coltype:    't_id',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, ],
    },
    "sourceType": {
      column:     "source_type",
      coltype:    't_tinystring',
      valueClass: 'NSString',
      flags:      [ property, allowsNull, allowsNull,],
    },
    "targetId": {
      column:     "target_id",
      coltype:    't_id',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, allowsNull,],
    },
    "target": {
      column:     "target",
      coltype:    't_string',
      valueClass: 'NSString',
      flags:      [ lock, property, ],
    },
    "targetType": {
      column:     "target_type",
      coltype:    't_tinystring',
      valueClass: 'NSString',
      flags:      [ property, allowsNull, ],
    },
    "linkType": {
      column:     "link_type",
      coltype:    't_tinystring',
      valueClass: 'NSString',
      flags:      [ property, allowsNull, ],
    },
    "label": {
      column:     "label",
      coltype:    't_string',
      valueClass: 'NSString',
      flags:      [ property, allowsNull, ],
    },
} # entity ObjectLink

ObjectInfo = {
    table:     "obj_info",
    className: 'LSObjectInfo',
    
    # attributes
    
    "objectId": {
      column:     "obj_id",
      coltype:    't_id',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ primaryKey, lock, property, ],
    },
    "objectType": {
      column:     "obj_type",
      coltype:    't_string',
      valueClass: 'NSString',
      flags:      [ lock, property, ],
    },
} # entity ObjectInfo

PalmAddress = {
    "table_name": 'palm_address',
    table:      "palm_address",
    className:  'LSPalmAddress',

    # attributes

    "company_id": {
      column:     "company_id",
      coltype:    't_id',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, ],
    },
    "device_id": {
      column:     "device_id",
      coltype:    't_smallstring',
      valueClass: 'NSString',
      flags:      [ lock, property, ],
    },
    "palm_address_id": {
      column:     "palm_address_id",
      coltype:    't_id',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ primaryKey, lock, property, ],
    },
    "palm_id": {
      column:     "palm_id",
      coltype:    't_id',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, allowsNull, ],
    },
    "category_index": {
      column:     "category_index",
      coltype:    't_int',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, allowsNull, ],
    },
    "is_deleted": {
      column:     "is_deleted",
      coltype:    't_bool',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, ],
    },
    "is_modified": {
      column:     "is_modified",
      coltype:    't_bool',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, ],
    },
    "is_archived": {
      column:     "is_archived",
      coltype:    't_bool',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, ],
    },
    "is_new": {
      column:     "is_new",
      coltype:    't_bool',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, ],
    },
    "is_private": {
      column:     "is_private",
      coltype:    't_bool',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, ],
    },

    "md5hash": {
      column:     "md5hash",
      coltype:    't_tinystring',
      valueClass: 'NSString',
      flags:      [ lock, property, ],
    },

    "address": {
      column:     "address",
      coltype:    't_string',
      valueClass: 'NSString',
      flags:      [ lock, property, allowsNull, ],
    },
    "city": {
      column:     "city",
      coltype:    't_string',
      valueClass: 'NSString',
      flags:      [ lock, property, allowsNull, ],
    },
    "company": {
      column:     "company",
      coltype:    't_string',
      valueClass: 'NSString',
      flags:      [ lock, property, allowsNull, ],
    },
    "country": {
      column:     "country",
      coltype:    't_string',
      valueClass: 'NSString',
      flags:      [ lock, property, allowsNull, ],
    },
    "display_phone": {
      column:     "display_phone",
      coltype:    't_int',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, ],
    },
    "firstname": {
      column:     "firstname",
      coltype:    't_string',
      valueClass: 'NSString',
      flags:      [ lock, property, allowsNull, ],
    },
    "lastname": {
      column:     "lastname",
      coltype:    't_string',
      valueClass: 'NSString',
      flags:      [ lock, property, allowsNull, ],
    },
    "note": {
      column:     "note",
      coltype:    't_text',
      valueClass: 'NSString',
      flags:      [ lock, property, allowsNull, ],
    },

    "phone0": {
      column:     "phone0",
      coltype:    't_string',
      valueClass: 'NSString',
      flags:      [ lock, property, allowsNull, ],
    },
    "phone1": {
      column:     "phone1",
      coltype:    't_string',
      valueClass: 'NSString',
      flags:      [ lock, property, allowsNull, ],
    },
    "phone2": {
      column:     "phone2",
      coltype:    't_string',
      valueClass: 'NSString',
      flags:      [ lock, property, allowsNull, ],
    },
    "phone3": {
      column:     "phone3",
      coltype:    't_string',
      valueClass: 'NSString',
      flags:      [ lock, property, allowsNull, ],
    },
    "phone4": {
      column:     "phone4",
      coltype:    't_string',
      valueClass: 'NSString',
      flags:      [ lock, property, allowsNull, ],
    },

    "phone_label_id0": {
      column:     "phone_label_id0",
      coltype:    't_int',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, ],
    },
    "phone_label_id1": {
      column:     "phone_label_id1",
      coltype:    't_int',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, ],
    },
    "phone_label_id2": {
      column:     "phone_label_id2",
      coltype:    't_int',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, ],
    },
    "phone_label_id3": {
      column:     "phone_label_id3",
      coltype:    't_int',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, ],
    },
    "phone_label_id4": {
      column:     "phone_label_id4",
      coltype:    't_int',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, ],
    },

    "state": {
      column:     "state",
      coltype:    't_string',
      valueClass: 'NSString',
      flags:      [ lock, property, allowsNull, ],
    },
    "title": {
      column:     "title",
      coltype:    't_string',
      valueClass: 'NSString',
      flags:      [ lock, property, allowsNull, ],
    },
    "zipcode": {
      column:     "zipcode",
      coltype:    't_string',
      valueClass: 'NSString',
      flags:      [ lock, property, allowsNull, ],
    },

    "custom1": {
      column:     "custom1",
      coltype:    't_string',
      valueClass: 'NSString',
      flags:      [ lock, property, allowsNull, ],
    },
    "custom2": {
      column:     "custom2",
      coltype:    't_string',
      valueClass: 'NSString',
      flags:      [ lock, property, allowsNull, ],
    },
    "custom3": {
      column:     "custom3",
      coltype:    't_string',
      valueClass: 'NSString',
      flags:      [ lock, property, allowsNull, ],
    },
    "custom4": {
      column:     "custom4",
      coltype:    't_string',
      valueClass: 'NSString',
      flags:      [ lock, property, allowsNull, ],
    },

    "skyrix_id": {
      column:     "skyrix_id",
      coltype:    't_id',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, allowsNull, ],
    },
    "skyrix_sync": {
      column:     "skyrix_sync",
      coltype:    't_int',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, allowsNull, ],
    },
    "skyrix_version": {
      column:     "skyrix_version",
      coltype:    't_int',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, allowsNull, ],
    },
    "skyrix_type": {
      column:     "skyrix_type",
      coltype:    't_tinystring',
      valueClass: 'NSString',
      flags:      [ lock, property, allowsNull, ],
    },
    "object_version": {
      column:     "object_version",
      coltype:    't_int',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, allowsNull, ],
    },
    "skyrix_palm_version": {
      column:     "skyrix_palm_version",
      coltype:    't_int',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, allowsNull, ],
    },
} #entity palm_address
  
PalmDate = {
    "table_name": 'palm_date',
    table:      "palm_date",
    className:  'LSPalmDate',

    # attributes

    "company_id": {
      column:     "company_id",
      coltype:    't_id',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, ],
    },
    "device_id": {
      column:     "device_id",
      coltype:    't_smallstring',
      valueClass: 'NSString',
      flags:      [ lock, property, ],
    },
    "palm_date_id": {
      column:     "palm_date_id",
      coltype:    't_id',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ primaryKey, lock, property, ],
    },
    "palm_id": {
      column:     "palm_id",
      coltype:    't_id',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, allowsNull, ],
    },
    "category_index": {
      column:     "category_index",
      coltype:    't_int',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, allowsNull, ],
    },
    "is_deleted": {
      column:     "is_deleted",
      coltype:    't_bool',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, ],
    },
    "is_modified": {
      column:     "is_modified",
      coltype:    't_bool',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, ],
    },
    "is_archived": {
      column:     "is_archived",
      coltype:    't_bool',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, ],
    },
    "is_new": {
      column:     "is_new",
      coltype:    't_bool',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, ],
    },
    "is_private": {
      column:     "is_private",
      coltype:    't_bool',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, ],
    },

    "md5hash": {
      column:     "md5hash",
      coltype:    't_tinystring',
      valueClass: 'NSString',
      flags:      [ lock, property, ],
    },

    "alarm_advance_time": {
      column:     "alarm_advance_time",
      coltype:    't_int',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, ],
    },
    "alarm_advance_unit": {
      column:     "alarm_advance_unit",
      coltype:    't_int',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, ],
    },
    "description": {
      column:     "description",
      coltype:    't_string',
      valueClass: 'NSString',
      flags:      [ lock, property, ],
    },
    "enddate": {
      column:     "enddate",
      coltype:    't_datetime',
      valueClass: 'NSCalendarDate',
      flags:      [ lock, property, allowsNull, ],
    },
    "is_alarmed": {
      column:     "is_alarmed",
      coltype:    't_bool',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, ],
    },
    "is_untimed": {
      column:     "is_untimed",
      coltype:    't_bool',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, ],
    },
    "note": {
      column:     "note",
      coltype:    't_text',
      valueClass: 'NSString',
      flags:      [ lock, property, allowsNull, ],
    },
    "repeat_enddate": {
      column:     "repeat_enddate",
      coltype:    't_datetime',
      valueClass: 'NSCalendarDate',
      flags:      [ lock, property, allowsNull, ],
    },
    "repeat_frequency": {
      column:     "repeat_frequency",
      coltype:    't_int',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, allowsNull, ],
    },
    "repeat_on": {
      column:     "repeat_on",
      coltype:    't_int',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, allowsNull, ],
    },
    "repeat_start_week": {
      column:     "repeat_start_week",
      coltype:    't_int',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, allowsNull, ],
    },
    "repeat_type": {
      column:     "repeat_type",
      coltype:    't_int',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, allowsNull, ],
    },
    "startdate": {
      column:     "startdate",
      coltype:    't_datetime',
      valueClass: 'NSCalendarDate',
      flags:      [ lock, property, allowsNull, ],
    },

    "exceptions": {
      column:     "exceptions",
      coltype:    't_text',
      valueClass: 'NSString',
      flags:      [ lock, property, allowsNull, ],
    },

    "skyrix_id": {
      column:     "skyrix_id",
      coltype:    't_id',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, allowsNull, ],
    },
    "skyrix_sync": {
      column:     "skyrix_sync",
      coltype:    't_int',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, allowsNull, ],
    },
    "skyrix_version": {
      column:     "skyrix_version",
      coltype:    't_int',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, allowsNull, ],
    },
    "object_version": {
      column:     "object_version",
      coltype:    't_int',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, allowsNull, ],
    },
    "skyrix_palm_version": {
      column:     "skyrix_palm_version",
      coltype:    't_int',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, allowsNull, ],
    },
} #entity palm_date

PalmMemo = {
    "table_name": 'palm_memo',
    table:      "palm_memo",
    className:  'LSPalmMemo',

    # attributes

    "company_id": {
      column:     "company_id",
      coltype:    't_id',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, ],
    },
    "device_id": {
      column:     "device_id",
      coltype:    't_smallstring',
      valueClass: 'NSString',
      flags:      [ lock, property, ],
    },
    "palm_memo_id": {
      column:     "palm_memo_id",
      coltype:    't_id',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ primaryKey, lock, property, ],
    },
    "palm_id": {
      column:     "palm_id",
      coltype:    't_id',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, allowsNull, ],
    },
    "category_index": {
      column:     "category_index",
      coltype:    't_int',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, allowsNull, ],
    },
    "is_deleted": {
      column:     "is_deleted",
      coltype:    't_bool',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, ],
    },
    "is_modified": {
      column:     "is_modified",
      coltype:    't_bool',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, ],
    },
    "is_archived": {
      column:     "is_archived",
      coltype:    't_bool',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, ],
    },
    "is_new": {
      column:     "is_new",
      coltype:    't_bool',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, ],
    },
    "is_private": {
      column:     "is_private",
      coltype:    't_bool',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, ],
    },

    "md5hash": {
      column:     "md5hash",
      coltype:    't_tinystring',
      valueClass: 'NSString',
      flags:      [ lock, property, ],
    },

    "memo": {
      column:     "memo",
      coltype:    't_text',
      valueClass: 'NSString',
      flags:      [ lock, property, ],
    },

    "skyrix_id": {
      column:     "skyrix_id",
      coltype:    't_id',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, allowsNull, ],
    },
    "skyrix_sync": {
      column:     "skyrix_sync",
      coltype:    't_int',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, allowsNull, ],
    },
    "skyrix_version": {
      column:     "skyrix_version",
      coltype:    't_int',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, allowsNull, ],
    },
    "object_version": {
      column:     "object_version",
      coltype:    't_int',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, allowsNull, ],
    },
    "skyrix_palm_version": {
      column:     "skyrix_palm_version",
      coltype:    't_int',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, allowsNull, ],
    },
} #entity palm_memo


PalmTodo = {
    "table_name": 'palm_todo',
    table:      "palm_todo",
    className:  'LSPalmToDo',

    # attributes

    "company_id": {
      column:     "company_id",
      coltype:    't_id',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, ],
    },
    "device_id": {
      column:     "device_id",
      coltype:    't_smallstring',
      valueClass: 'NSString',
      flags:      [ lock, property, ],
    },
    "palm_todo_id": {
      column:     "palm_todo_id",
      coltype:    't_id',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ primaryKey, lock, property, ],
    },
    "palm_id": {
      column:     "palm_id",
      coltype:    't_id',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, allowsNull, ],
    },
    "category_index": {
      column:     "category_index",
      coltype:    't_int',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, allowsNull, ],
    },
    "is_deleted": {
      column:     "is_deleted",
      coltype:    't_bool',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, ],
    },
    "is_modified": {
      column:     "is_modified",
      coltype:    't_bool',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, ],
    },
    "is_archived": {
      column:     "is_archived",
      coltype:    't_bool',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, ],
    },
    "is_new": {
      column:     "is_new",
      coltype:    't_bool',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, ],
    },
    "is_private": {
      column:     "is_private",
      coltype:    't_bool',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, ],
    },

    "md5hash": {
      column:     "md5hash",
      coltype:    't_tinystring',
      valueClass: 'NSString',
      flags:      [ lock, property, ],
    },

    "description": {
      column:     "description",
      coltype:    't_string',
      valueClass: 'NSString',
      flags:      [ lock, property, ],
    },
    "duedate": {
      column:     "duedate",
      coltype:    't_datetime',
      valueClass: 'NSCalendarDate',
      flags:      [ lock, property, allowsNull, ],
    },
    "note": {
      column:     "note",
      coltype:    't_text',
      valueClass: 'NSString',
      flags:      [ lock, property, allowsNull, ],
    },
    "priority": {
      column:     "priority",
      coltype:    't_int',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, ],
    },
    "is_completed": {
      column:     "is_completed",
      coltype:    't_bool',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, ],
    },

    "skyrix_id": {
      column:     "skyrix_id",
      coltype:    't_id',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, allowsNull, ],
    },
    "skyrix_sync": {
      column:     "skyrix_sync",
      coltype:    't_int',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, allowsNull, ],
    },
    "skyrix_version": {
      column:     "skyrix_version",
      coltype:    't_int',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, allowsNull, ],
    },
    "object_version": {
      column:     "object_version",
      coltype:    't_int',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, allowsNull, ],
    },
    "skyrix_palm_version": {
      column:     "skyrix_palm_version",
      coltype:    't_int',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, allowsNull, ],
    },
} #entity palm_todo

PalmCategory = {
    "table_name": 'palm_category',
    table:      "palm_category",
    className:  'LSPalmCategory',

    # attributes

    "company_id": {
      column:     "company_id",
      coltype:    't_id',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, ],
    },
    "device_id": {
      column:     "device_id",
      coltype:    't_smallstring',
      valueClass: 'NSString',
      flags:      [ lock, property, allowsNull, ],
    },
    "palm_category_id": {
      column:     "palm_category_id",
      coltype:    't_id',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ primaryKey, lock, property, ],
    },
    "palm_id": {
      column:     "palm_id",
      coltype:    't_id',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, allowsNull, ],
    },
    "palm_table": {
      column:     "palm_table",
      coltype:    't_tinystring',
      valueClass: 'NSString',
      flags:      [ lock, property, ],
    },
    "is_modified": {
      column:     "is_modified",
      coltype:    't_bool',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, ],
    },

    "md5hash": {
      column:     "md5hash",
      coltype:    't_tinystring',
      valueClass: 'NSString',
      flags:      [ lock, property, ],
    },

    "category_index": {
      column:     "category_index",
      coltype:    't_int',
      valueClass: 'NSNumber',
      valueType:  'i',
      flags:      [ lock, property, ],
    },
    "category_name": {
      column:     "category_name",
      coltype:    't_string',
      valueClass: 'NSString',
      flags:      [ lock, property, ],
    },
} #entity palm_category
