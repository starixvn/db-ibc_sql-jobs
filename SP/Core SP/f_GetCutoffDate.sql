/*<info serverAlias="DBAGE-bodb02,DBACC-bodb02,DBTXN-bodb02" selecters="bodbDownlineNet,bodbDownlineNetView,bodbExtAccNet" isFunction="1" isNested="1"></info>*/
ALTER FUNCTION [dbo].f_GetCutOffDate()
RETURNS TABLE
AS

/*
	Creator: Sol
	Date: 20210709
	Task: Get cutoff date
	DB: DBAGE-bodb02,DBACC-bodb02,DBTXN-bodb02
	
	Revision:
		- 20210617@Sol: get cutoff date of net turn over - [RedmineId : #156653]
		- 20211122@Percy: Add cutoff date of gross comm [RedmineID: #164479]
*/

RETURN

	SELECT CutoffDate, TypeName
	FROM (
		VALUES ('2021-08-05', 'NetTO')
			,('2021-12-11', 'GrossComm')
	) AS t (CutoffDate, TypeName)
	
GO