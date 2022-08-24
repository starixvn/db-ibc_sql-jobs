/*<info serverAlias="DBTXN-bodb02" executers="Dot_Member,Dot_Intg,Dot_Bonus,bodbAdminNet,bodbDownlineNet" viewers="" isFunction="1" isNested=""></info>*/

CREATE FUNCTION [dbo].[f_get_bettransX_transid]()
RETURNS [bigint] WITH EXECUTE AS CALLER
AS 
/*
	Created: 20220726@Lukas
	DB: DBTXN.bodb02
	Task: 158293 - Scale out bettrans phase 1

	Revisions:
		- 20220726@Lukas: Create [RedmineID: #158293]
*/

EXTERNAL NAME [GenShardID].[UserDefinedFunctions].[F_get_bettransX_transid]
GO