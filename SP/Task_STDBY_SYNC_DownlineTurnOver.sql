USE [bodb02]
GO

/****** Object:  StoredProcedure [dbo].[Task_STDBY_SYNC_DownlineTurnOver]    Script Date: 01/20/2015 05:58:42 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Task_STDBY_SYNC_DownlineTurnOver]

AS
/*	Created: Jamie
	Task: Sync DownlineTurnover_Setting (RUN ON STANDBY Servers)
	DB: DBAGE/bodb02 
*/
BEGIN
	SET NOCOUNT ON
	IF EXISTS(
		SELECT TOP 1 1
		FROM bodb02.dbo.DownlineTurnOver_Setting s WITH (NOLOCK)
			 RIGHT JOIN DBAGE.bodb02.dbo.DownlineTurnOver_Setting n WITH (NOLOCK) ON s.CustID = n.CustID AND s.matchid = n.matchid
		WHERE s.CustID IS NULL OR s.matchid IS NULL
	)
	BEGIN
		INSERT INTO [bodb02].[dbo].[DownlineTurnOver_Setting]
           ([custid]
           ,[matchid]
           ,[maxturnover]
           ,[totalturnover]
           ,[IsNotified])
		SELECT	n.[CustID]
			   ,n.[matchid]
			   ,n.[maxturnover]
			   , 0		----Default Values 
			   , 0		----Default Values 
		FROM bodb02.dbo.DownlineTurnOver_Setting s WITH (NOLOCK)
			 RIGHT JOIN DBAGE.bodb02.dbo.DownlineTurnOver_Setting n WITH (NOLOCK) ON s.CustID = n.CustID AND s.matchid = n.matchid
		WHERE s.CustID IS NULL OR s.matchid IS NULL
	END

END
GO


