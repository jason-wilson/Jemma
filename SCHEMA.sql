DROP TABLE "source";
CREATE TABLE "source" (
  "id" INTEGER PRIMARY KEY NOT NULL,
  "name" TEXT
);

DROP TABLE "ipaddr";
CREATE TABLE "ipaddr" (
  "id" INTEGER PRIMARY KEY NOT NULL,
  "start" INTEGER NOT NULL,
  "end" INTEGER NOT NULL,
  "name" TEXT NOT NULL,
  "description" TEXT,
  "source" INTEGER,
  FOREIGN KEY ("source") REFERENCES "source"("id")
);

DROP TABLE "ipaddrextra";
CREATE TABLE "ipaddrextra" (
  "id" INTEGER PRIMARY KEY NOT NULL,
  "ipaddr" INTEGER NOT NULL,
  "key" TEXT NOT NULL,
  "value" TEXT,
  FOREIGN KEY ("ipaddr") REFERENCES "ipaddr"("id")
);
