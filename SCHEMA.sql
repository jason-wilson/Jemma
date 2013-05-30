DROP TABLE "source";
CREATE TABLE "source" (
  "id" INTEGER PRIMARY KEY NOT NULL,
  "name" TEXT
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

