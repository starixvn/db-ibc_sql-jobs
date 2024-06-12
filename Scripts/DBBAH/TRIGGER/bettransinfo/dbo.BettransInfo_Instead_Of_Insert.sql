/*<info serverAlias="DBBAH-bodb02" executers="" viewers="" isFunction="0"></info>*/
/*
   Created:Kathy@20240611  
   DB: DBBAH-bodb02
*/
USE [bodb02]
GO

CREATE TRIGGER [dbo].[BettransInfo_Instead_Of_Insert]
   ON [dbo].[BettransInfo]
   INSTEAD OF INSERT
AS 
/*
	Created: 20240611@Kathy
	DB: DBBAH.bodb02
	Task:  [Redmine: #180225]
	Revision:
		- 20240611@Kathy: Create trigger [Redmine:#206286]
*/

BEGIN
	SET NOCOUNT ON;

	INSERT INTO [dbo].[BettransInfo]
           ([transid]
           ,[SecAcceptTime]
           ,[LiveBetAcceptTime]
           ,[OriginalOdds]
           ,[RepUpdateTime]
           ,[ThirdTransID])
    SELECT [transid]
           ,[SecAcceptTime]
           ,[LiveBetAcceptTime]
           ,[OriginalOdds]
           ,[RepUpdateTime]
           ,[ThirdTransID]
	FROM INSERTED AS i
		CROSS APPLY (SELECT TOP 1 1 as valid 
                     FROM dbo.f_dba_transid_revert(i.TransId,0)
                     WHERE SiteDBGroupID = 0
              ) AS t
	WHERE t.valid = 1
	
END
GO

