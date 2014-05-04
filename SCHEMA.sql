PRAGMA foreign_keys = ON;

DROP TABLE "source";
CREATE TABLE "source" (
  "id" INTEGER PRIMARY KEY NOT NULL,
  "name" TEXT,
  "loaded" DATE DEFAULT (DATETIME('now', 'localtime'))
);

DROP TABLE "ip";
CREATE TABLE "ip" (
  "id" INTEGER PRIMARY KEY NOT NULL,
  "start" INTEGER NOT NULL,
  "end" INTEGER NOT NULL,
  "name" TEXT NOT NULL,
  "description" TEXT,
  "source" INTEGER,
  FOREIGN KEY ("source") REFERENCES "source"("id") ON DELETE CASCADE
);

DROP TABLE "ipextra";
CREATE TABLE "ipextra" (
  "id" INTEGER PRIMARY KEY NOT NULL,
  "ip" INTEGER NOT NULL,
  "key" TEXT NOT NULL,
  "value" TEXT,
  "source" INTEGER,
  FOREIGN KEY ("source") REFERENCES "source"("id") ON DELETE CASCADE
  FOREIGN KEY ("ip") REFERENCES "ip"("id") ON DELETE CASCADE
);

DROP TABLE "grp";
CREATE TABLE "grp" (
  "id" INTEGER PRIMARY KEY NOT NULL,
  "name" TEXT NOT NULL,
  "description" TEXT,
  "source" INTEGER,
  FOREIGN KEY ("source") REFERENCES "source"("id") ON DELETE CASCADE
);

DROP TABLE "ipgrp";
CREATE TABLE "ipgrp" (
  "id" INTEGER PRIMARY KEY NOT NULL,
  "ip" INTEGER NOT NULL,
  "grp" INTEGER NOT NULL,
  FOREIGN KEY ("ip") REFERENCES "ip"("id") ON DELETE CASCADE,
  FOREIGN KEY ("grp") REFERENCES "grp"("id") ON DELETE CASCADE
);

DROP TABLE "grpgrp";
CREATE TABLE "grpgrp" (
  "id" INTEGER PRIMARY KEY NOT NULL,
  "parent" INTEGER NOT NULL,
  "child" INTEGER NOT NULL,
  FOREIGN KEY ("parent") REFERENCES "grp"("id") ON DELETE CASCADE,
  FOREIGN KEY ("child") REFERENCES "grp"("id") ON DELETE CASCADE
);

DROP TABLE "service";
CREATE TABLE "service" (
  "id"          INTEGER PRIMARY KEY NOT NULL,
  "name"        TEXT NOT NULL,
  "protocol"    TEXT NOT NULL,
  "ports"       TEXT,
  "description" TEXT,
  "source"      INTEGER NOT NULL,
  FOREIGN KEY ("source") REFERENCES "source"("id") ON DELETE CASCADE
);

DROP TABLE "servicegrp";
CREATE TABLE "servicegrp" (
  "id"          INTEGER PRIMARY KEY NOT NULL,
  "name"        TEXT NOT NULL,
  "description" TEXT,
  "source"      INTEGER NOT NULL,
  FOREIGN KEY ("source") REFERENCES "source"("id") ON DELETE CASCADE
);

DROP TABLE "servicegrpgrp";
CREATE TABLE "servicegrpgrp" (
  "id"          INTEGER PRIMARY KEY NOT NULL,
  "servicegrp"  INTEGER NOT NULL,
  "service"     INTEGER NOT NULL,
  FOREIGN KEY ("servicegrp") REFERENCES "servicegrp"("id") ON DELETE CASCADE,
  FOREIGN KEY ("service")  REFERENCES "service"("id") ON DELETE CASCADE
);

DROP TABLE "servicegrpservicegrp";
CREATE TABLE "servicegrpservicegrp" (
  "id"          INTEGER PRIMARY KEY NOT NULL,
  "parent"      INTEGER NOT NULL,
  "child"       INTEGER NOT NULL,
  FOREIGN KEY ("parent") REFERENCES "servicegrp"("id") ON DELETE CASCADE,
  FOREIGN KEY ("child")  REFERENCES "servicegrp"("id") ON DELETE CASCADE
);

DROP TABLE "objectset";
CREATE TABLE "objectset" (
  "id"          INTEGER PRIMARY KEY NOT NULL,
  "name"	TEXT NOT NULL,
  "source"      INTEGER NOT NULL,
  FOREIGN KEY ("source") REFERENCES "source"("id") ON DELETE CASCADE
);


DROP TABLE "objectsetlist";
CREATE TABLE "objectsetlist" (
  "id"          INTEGER PRIMARY KEY NOT NULL,
  "objectset"	INTEGER,
  "type"        TEXT NOT NULL,
  "ip"          INTEGER,
  "grp"         INTEGER,
  "service"     INTEGER,
  "servicegrp"  INTEGER,
  FOREIGN KEY ("objectset")  REFERENCES "objectset"("id") ON DELETE CASCADE,
  FOREIGN KEY ("ip")         REFERENCES "ip"("id") ON DELETE CASCADE,
  FOREIGN KEY ("grp")        REFERENCES "grp"("id") ON DELETE CASCADE,
  FOREIGN KEY ("service")    REFERENCES "service"("id") ON DELETE CASCADE,
  FOREIGN KEY ("servicegrp") REFERENCES "servicegrp"("id") ON DELETE CASCADE
);

DROP TABLE "fwrule";
CREATE TABLE "fwrule" (
  "id"          INTEGER PRIMARY KEY NOT NULL,
  "number"	INTEGER NOT NULL,
  "name"        TEXT NOT NULL,
  "enabled"     BOOLEAN DEFAULT 1,
  "action"      TEXT NOT NULL,
  "svcnot"      BOOLEAN DEFAULT 0,
  "service"     INTEGER,
  "srcnot"	BOOLEAN DEFAULT 0,
  "sourceset"	INTEGER,
  "dstnot"	BOOLEAN DEFAULT 0,
  "destination"	INTEGER,
  "description" TEXT,
  "track"       TEXT,
  "source"      INTEGER NOT NULL,
  FOREIGN KEY ("service")     REFERENCES "objectset"("id") ON DELETE CASCADE
  FOREIGN KEY ("sourceset")   REFERENCES "objectset"("id") ON DELETE CASCADE
  FOREIGN KEY ("destination") REFERENCES "objectset"("id") ON DELETE CASCADE
  FOREIGN KEY ("source")      REFERENCES "source"("id") ON DELETE CASCADE
);

DROP TABLE "natrule";
CREATE TABLE "natrule" (
  "id"          INTEGER PRIMARY KEY NOT NULL,
  "number"	INTEGER NOT NULL,
  "name"        TEXT NOT NULL,
  "enabled"     BOOLEAN DEFAULT 1,
  "origsrcset"	INTEGER,
  "origdstset"	INTEGER,
  "origsvcset"	INTEGER,
  "natsrcset"	INTEGER,
  "natdstset"	INTEGER,
  "natsvcset"	INTEGER,
  "nattype"     TEXT,
  "description" TEXT,
  "source"      INTEGER NOT NULL,
  FOREIGN KEY ("origsrcset")  REFERENCES "objectset"("id") ON DELETE CASCADE
  FOREIGN KEY ("origdstset")  REFERENCES "objectset"("id") ON DELETE CASCADE
  FOREIGN KEY ("origsvcset")  REFERENCES "objectset"("id") ON DELETE CASCADE
  FOREIGN KEY ("natsrcset")   REFERENCES "objectset"("id") ON DELETE CASCADE
  FOREIGN KEY ("natdstset")   REFERENCES "objectset"("id") ON DELETE CASCADE
  FOREIGN KEY ("natsvcset")   REFERENCES "objectset"("id") ON DELETE CASCADE
  FOREIGN KEY ("source")      REFERENCES "source"("id") ON DELETE CASCADE
);

DROP TABLE "route";
CREATE TABLE "route" (
  "id"          INTEGER PRIMARY KEY NOT NULL,
  "start"       INTEGER NOT NULL,
  "end"         INTEGER NOT NULL,
  "interface"	TEXT NOT NULL,
  "gateway"     INTEGER NOT NULL,
  "metric"      INTEGER,
  "source"      INTEGER NOT NULL,
  FOREIGN KEY ("source")      REFERENCES "source"("id") ON DELETE CASCADE
);
