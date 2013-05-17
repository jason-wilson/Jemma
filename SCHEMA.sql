DROP TABLE "source";
CREATE TABLE "source" (
  "id" INTEGER PRIMARY KEY NOT NULL,
  "name" TEXT
);

DROP TABLE "ipaddr";
CREATE TABLE "ipaddr" (
  "id" INTEGER PRIMARY KEY NOT NULL,
  "begin" INTEGER NOT NULL,
  "end" INTEGER NOT NULL,
  "name" TEXT NOT NULL,
  "description" TEXT,
  "source" INTEGER,
  FOREIGN KEY ("source") REFERENCES "source"("id")
);

insert into source(name) values ('test');
insert into source(name) values ('blah');
