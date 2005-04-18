MySQL database creation scripts
===============================

Surprisingly the PostgreSQL script loads almost unchanged.

Changes
=======

TIMESTAMP WITH TIMEZONE => DATETIME

TODO
====

- company/document views
  - then: inserts
- sequence

MySQL Notes
===========

Creating new users ... using 'GRANT':

  GRANT ALL PRIVILEGES ON *.* 
        TO OGo@"%"
        IDENTIFIED BY 'test'
        WITH GRANT OPTION;
