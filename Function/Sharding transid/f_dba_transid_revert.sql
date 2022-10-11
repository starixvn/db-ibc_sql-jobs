/*<info serverAlias="DBTXN-bodb02,DBTP-bodb02,DBACC-bodb02,DBAGE-bodb02" executers="" viewers="" isFunction="1" isNested=""></info>*/

ALTER FUNCTION [dbo].[f_dba_transid_revert] 
(	
	@transid bigint,
	@isrefno bit = 0
)
RETURNS TABLE 
AS
/*
	Created: 20220824@Lukas
	DB: DBTXN.bodb02
	Task: 158293 - Scale out bettrans phase 1

	Revisions:
		- 20220824@Lukas: Create [RedmineID: #158293]
		- 20221011@Tina: Add more info for these servers DBACC, DBAGE on metadata [RedmineID: #178943]
*/
RETURN 
(
	 
	SELECT	CASE WHEN @isrefno = 0 THEN 'transid' ELSE 'refno' END AS cat,
			@transid as transid 
			, SWITCHOFFSET(DATEADD(SECOND,CASE WHEN @isrefno = 0 THEN (@transid & CAST(9223372032559808512 AS BIGINT))/0x0000000100000000 ELSE (@transid & CAST(576460752034988032 AS BIGINT))/0x000000010000000 END
				,'2022-07-01 00:00:00'),'-04:00') AS at_time
			,CASE WHEN @isrefno = 0 THEN (@transid & CAST(9223372032559808512 AS BIGINT))/0x0000000100000000 ELSE (@transid & CAST(576460752034988032 AS BIGINT))/0x000000010000000 END AS secdiff
			,CASE WHEN @isrefno = 0 THEN (@transid & CAST(4290772992 AS BIGINT))/4194304 ELSE (@transid & CAST(268173312 AS BIGINT))/CAST(262143 AS BIGINT) END AS SiteDBGroupID
			,CASE WHEN @isrefno = 0 THEN  @transid & CAST(4194303 AS BIGINT)  ELSE  @transid & CAST(262143 AS BIGINT) END AS sequenceNo
)

GO

