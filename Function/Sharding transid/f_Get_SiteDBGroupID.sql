/*<info serverAlias="DBTXN-bodb02" executers="Dot_Member,Dot_Intg,Dot_Bonus,bodbAdminNet,bodbDownlineNet" viewers="" isFunction="1" isNested=""></info>*/

CREATE FUNCTION [dbo].[f_Get_SiteDBGroupID]()
RETURNS SMALLINT
AS
/*
	Created: 20220804@Helen
	DB: DBTXN.bodb02
	Task: 158293 - Scale out bettrans phase 1

	Revisions:
		- 20220804@Helen: Create [RedmineID: #158293]
*/
BEGIN
  RETURN 
  CASE 
     WHEN @@SERVERNAME IN ('DBTRANS','SITDBTRANS','TESTDBTRANS','db-60\devdbtrans') THEN 0
     WHEN @@SERVERNAME IN ('DBGRP01N1','DBGRP01N2','SITDBGRP01N1','SITDBGRP01N2','db62\DEVSITEDB','testdb053\TESTSITEDB') THEN 1
  ELSE 1023 END 
END
GO