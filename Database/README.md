# Database - Schema and Data Model

Database contains SQL schema definitions for all
supported database backends and the entity-object
mapping model (EOModel) used by the GDLAccess ORM layer.


## Supported Backends

| Backend    | Directory     | Status               |
|------------|---------------|----------------------|
| PostgreSQL | `PostgreSQL/` | Primary, recommended |
| MySQL 5+   | `MySQL/`      | Alternative          |
| FrontBase  | `FrontBase/`  | Commercial           |
| SQLite     | `SQLite/`     | Work in progress     |


## PostgreSQL (Recommended)

Primary backend with full feature support.

| File | Purpose |
|-----------------------------------|---------------------------|
| `pg-build-schema.psql`            | Create schema             |
| `pg-build-schema.psql.constraints`| Foreign key constraints   |
| `pg-fill-objinfo.psql`            | Populate object info      |
| `pg-update-1.0to5.4.psql`         | Migration from 1.0        |
| `pg-update-schema.psql`           | Schema updates            |

Setup:
```bash
su - postgres
createuser OGo
createdb OGo
psql -h localhost OGo OGo < pg-build-schema.psql
```


## OGoModel - Entity-Object Mapping

The `OGoModel/` directory contains the EOF (Enterprise
Objects Framework) model that maps database tables to
Objective-C objects.

| File | Purpose |
|-----------------------------------------|----------------------|
| `OGoModel.py`                           | Master model (Python)|
| `genmodel.py`                           | Model generator      |
| `OpenGroupware.org_PostgreSQL.eomodel`  | PostgreSQL mapping   |
| `OpenGroupware.org_MySQL5.eomodel`      | MySQL 5 mapping      |
| `OpenGroupware.org_FrontBase2.eomodel`  | FrontBase mapping    |

The model maps internal entity names to external table
names (working around SQL keyword conflicts like `date`)
and defines relationships between entities.

Generate models:
```bash
cd OGoModel
./genmodel.py OGoModel.py PostgreSQL \
  > OpenGroupware.org_PostgreSQL.eomodel
```

Key classes: `OGoModel` (bundle principal),
`LSEOObject`, `LSDatabaseObject`.
