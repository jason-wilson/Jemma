DROP TABLE "source";
CREATE TABLE "source" (
  "id" INTEGER PRIMARY KEY NOT NULL,
  "name" TEXT,
  "loaded" DATETIME
);

DROP TABLE "ip";
CREATE TABLE "ip" (
  "id" INTEGER PRIMARY KEY NOT NULL,
  "start" INTEGER NOT NULL,
  "end" INTEGER NOT NULL,
  "name" TEXT NOT NULL,
  "description" TEXT,
  "source" INTEGER,
  FOREIGN KEY ("source") REFERENCES "source"("id")
);

DROP TABLE "ipextra";
CREATE TABLE "ipextra" (
  "id" INTEGER PRIMARY KEY NOT NULL,
  "ip" INTEGER NOT NULL,
  "key" TEXT NOT NULL,
  "value" TEXT,
  FOREIGN KEY ("ip") REFERENCES "ip"("id")
);

DROP TABLE "grp";
CREATE TABLE "grp" (
  "id" INTEGER PRIMARY KEY NOT NULL,
  "name" TEXT NOT NULL,
  "description" TEXT,
  "source" INTEGER,
  FOREIGN KEY ("source") REFERENCES "source"("id")
);

DROP TABLE "ipgrp";
CREATE TABLE "ipgrp" (
  "id" INTEGER PRIMARY KEY NOT NULL,
  "ip" INTEGER NOT NULL,
  "grp" INTEGER NOT NULL,
  FOREIGN KEY ("ip") REFERENCES "ip"("id"),
  FOREIGN KEY ("grp") REFERENCES "grp"("id")
);

DROP TABLE "grpgrp";
CREATE TABLE "grpgrp" (
  "id" INTEGER PRIMARY KEY NOT NULL,
  "parent" INTEGER NOT NULL,
  "child" INTEGER NOT NULL,
  FOREIGN KEY ("parent") REFERENCES "grp"("id"),
  FOREIGN KEY ("child") REFERENCES "grp"("id")
);

DROP TABLE "service";
CREATE TABLE "service" (
  "id"          INTEGER PRIMARY KEY NOT NULL,
  "name"        TEXT NOT NULL,
  "protocol"    TEXT NOT NULL,
  "ports"       TEXT,
  "description" TEXT,
  "source"      INTEGER NOT NULL,
  FOREIGN KEY ("source") REFERENCES "source"("id")
);

DROP TABLE "servicegrp";
CREATE TABLE "servicegrp" (
  "id"          INTEGER PRIMARY KEY NOT NULL,
  "name"        TEXT NOT NULL,
  "description" TEXT,
  "parent"      INTEGER NOT NULL,
  "child"       INTEGER NOT NULL,
  FOREIGN KEY ("parent") REFERENCES "service"("id"),
  FOREIGN KEY ("child")  REFERENCES "service"("id")
);

DROP TABLE "objectset";
CREATE TABLE "objectset" (
  "id"          INTEGER PRIMARY KEY NOT NULL,
  "name"	TEXT NOT NULL,
  "source"      INTEGER NOT NULL,
  FOREIGN KEY ("source") REFERENCES "source"("id")
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
  FOREIGN KEY ("objectset")  REFERENCES "objectset"("id"),
  FOREIGN KEY ("ip")         REFERENCES "ip"("id"),
  FOREIGN KEY ("grp")        REFERENCES "grp"("id"),
  FOREIGN KEY ("service")    REFERENCES "service"("id"),
  FOREIGN KEY ("servicegrp") REFERENCES "servicegrp"("id")
);

DROP TABLE "fwrule";
CREATE TABLE "fwrule" (
  "id"          INTEGER PRIMARY KEY NOT NULL,
  "number"	INTEGER NOT NULL,
  "name"        TEXT NOT NULL,
  "action"      TEXT NOT NULL,
  "service"     INTEGER,
  "sourceset"	INTEGER,
  "destination"	INTEGER,
  "description" TEXT,
  "source"      INTEGER NOT NULL,
  FOREIGN KEY ("service")     REFERENCES "objectset"("id")
  FOREIGN KEY ("sourceset")   REFERENCES "objectset"("id")
  FOREIGN KEY ("destination") REFERENCES "objectset"("id")
  FOREIGN KEY ("source")      REFERENCES "source"("id")
);
