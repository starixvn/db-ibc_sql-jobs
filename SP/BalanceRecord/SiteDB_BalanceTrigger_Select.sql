/*<info serverAlias="DBSIG-bodb02" executers="bodbAdminNet" viewers="" isFunction="0"></info>*/  
ALTER PROCEDURE [dbo].[SiteDB_BalanceTrigger_Select] 
(
	 @LastRowInserted	BIGINT
	,@Batch				INT = 2000
	,@IsTest			BIT
	,@TransInfo			VARBINARY(MAX) OUTPUT 
)
AS
/*
    Created: 20220130@Louisa
    DB: DBSIG/bodb02
   
   Revisions:
		- 20220130@Louisa: Phase 2 - use Web Service to pull ticket from SiteDB to DB05/DB05BK1 [176932]

	Param's explaination:
		@LastRowInserted: The last row which was inserted to DBBAH/bod02
*/
BEGIN
	
	SET NOCOUNT ON

	DECLARE @maxValue BIGINT

	SET @maxValue = (SELECT MAX(RowID) FROM [bodb02].[dbo].[BalanceTrigger] WITH(NOLOCK))

	WAITFOR DELAY '00:00:00.500'
	
	SET @TransInfo = COMPRESS((SELECT  TOP(@Batch)
									rowID			AS 'r'
									, custid		AS 'cid'
									, transid		AS 't'
									, bettype		AS 'bt'
									, actual_stake	AS 'act'
									, winlost		AS 'wl' 
									, playercomm	AS 'pc'
									, BalanceChanged AS 'bc'
									, NewBalance	AS 'nb'
									, ActionDate	AS 'ad'
									, ActionID		AS 'aid'
									, Action		AS 'a'
									, BTBalance		AS 'btb'
									, StatusId		AS 'sid'
									, MatchId		AS 'mid'
									, SettlementType AS 'st'
									, awinlost		AS 'aw'
									, mwinlost		AS 'mw'
									, swinlost		AS 'sw'
									, comm			AS 'c'
									, acomm			AS 'ac'
									, scomm			AS 'sc'
									, modds			AS 'm'
								FROM [bodb02].[dbo].[BalanceTrigger] WITH(NOLOCK) 
								WHERE RowID <= @maxValue AND RowID > @LastRowInserted
								ORDER BY RowID ASC
								FOR JSON PATH
								,INCLUDE_NULL_VALUES
							))
			 
END
GO
