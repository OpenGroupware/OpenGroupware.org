OGoModel
========

Contains the database/entity mapping required for the EOF layer inside OGo. It
assigns internal names to external database table and column names.
This is/was mostly used to work around database keyword issues (eg date is a
special keyword in PostgreSQL but not in Sybase10).

The master mapping is stored in the OGoModel.py Python file, you generate the
actual DB-specific files from that using the 'genmodel.py ' tool:

To regenerate all model plists from OGoModel.py this used to work:

  make messages=yes debug=yes GEN_MODELS=yes PYTHON=/usr/bin/python all

However, it doesn't seem to do the trick anymore :-/ Just call it manually:

  ./genmodel.py OGoModel.py PostgreSQL > OpenGroupware.org_PostgreSQL.eomodel
  ./genmodel.py OGoModel.py MySQL5     > OpenGroupware.org_MySQL5.eomodel
