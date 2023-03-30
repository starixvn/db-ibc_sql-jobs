/*<info serverAlias="DBTXN-bodb02" executers="" viewers="" isFunction="1" isNested=""></info>*/

CREATE FUNCTION [dbo].[f_Get_SiteDBGroupID]()
RETURNS SMALLINT
AS
/*
	Created: 20220804@Helen
	DB: DBTXN.bodb02
	Task: 158293 - Scale out bettrans phase 1

	Revisions:
		- 20220804@Helen: Create [RedmineID: #158293]
		- 20220912@Tina: add more sitedb2 [RedmineID: #158293]
		- 20230327@Tina: built up the AlwaysOn Availability Group (AG) feature for sitedb1 (DB66 and DB67)
		- 20230330@Tina: add more sitedb2 local
*/
BEGIN
  RETURN 
  CASE 
     WHEN @@SERVERNAME IN ('DBTRANS','SITDBTRANS','TESTDBTRANS','db-60\devdbtrans') THEN 0
     WHEN @@SERVERNAME IN ('DBGRP01N1','DBGRP01N2','SITDBGRP01N1','SITDBGRP01N2','db62\DEVSITEDB','testdb053\TESTSITEDB','DB66','DB67') THEN 1
	 WHEN @@SERVERNAME IN ('DBGRP02N1','DBGRP02N2','SITDBGRP02N1','SITDBGRP02N2') THEN 2
	 WHEN @@SERVERNAME IN ('TestSiteDB2') THEN 3
  ELSE 1023 END 
END
GO