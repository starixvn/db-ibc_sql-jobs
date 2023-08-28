

/*<info serverAlias="DBAGE-bodb02, DBBOF-bodb02"></info>*/

use bodb02
go

insert into RepInfoGroup(GroupID, SourceServerName, SourceDBName)
values(1, 'DBCUST', 'custdb')