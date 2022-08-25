/*<info serverAlias="DBTXN-bodb02"></info>*/

/*
	Created: 20220726@Lukas
	DB: DBTXN.bodb02
	Task: 158293 - Scale out bettrans phase 1
*/

/*
0. related objects
	- function get sitegroupID 
	- function get timediff
	- table for gen range of id
1. sp gen transid for bettrans
	1.1 create sequence obj bettrans
	1.2 SP get single transid
	1.3 SP get range transid 
	1.4 SP reset sequence 
	1.5 SQL Job reset sequence
2. sp gen transid for bettransx
	2.1 create sequence obj bettransX
	2.2 SP get single transid
	2.3 SP get range transid 
	2.4 SP reset sequence 
	2.5 SQL Job reset sequence
3. sp gen refno 
	3.1 create sequence obj refno
	3.2 SP get single transid
	3.3 SP get range transid 
	3.4 SP reset sequence 
	3.5 SQL Job reset sequence

*/
CREATE TABLE Numbers_255 (seq tinyint PRIMARY KEY)
GO
;with empty_row as (
select 1 as n UNION ALL select 1 as n UNION ALL select 1 as n UNION ALL select 1 as n --UNION ALL select 1 as n UNION ALL select 1 as n UNION ALL select 1 as n UNION ALL select 1 as n
)
, XX AS (select ROW_NUMBER() OVER (ORDER BY a.n) seq from empty_row a, empty_row b, empty_row c, empty_row d)
insert into Numbers_255
select * from xx where seq <= 255
GO

