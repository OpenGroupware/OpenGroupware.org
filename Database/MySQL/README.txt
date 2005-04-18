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

Views
=====

Apparently there are no views with MySQL 4, so we will need:
  "Views (including updatable views) are implemented in the 5.0 version of
   MySQL Server. Views are available in binary releases from 5.0.1 and up."

Sequences
=========

create the sequence:
CREATE TABLE sequence (id INT NOT NULL);
INSERT INTO sequence VALUES (0);

fetch the next value:
UPDATE sequence SET id=LAST_INSERT_ID(id+1);
SELECT LAST_INSERT_ID();


MySQL Notes
===========

Creating new users ... using 'GRANT':

  GRANT ALL PRIVILEGES ON *.* 
        TO OGo@"%"
        IDENTIFIED BY 'OGo'
        WITH GRANT OPTION;
