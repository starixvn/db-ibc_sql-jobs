

/*<info serverAlias="DBTXN-custdb"></info>*/

use custdb
go

insert into RepInfoGroup(GroupID, SourceServerName, SourceDBName)
values(0, 'DBCUST', 'custdb')