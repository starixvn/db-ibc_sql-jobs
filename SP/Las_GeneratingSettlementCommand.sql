USE [LASDB]
GO

/****** Object:  StoredProcedure [dbo].[Las_GeneratingSettlementCommand]    Script Date: 01/27/2015 23:28:57 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/****** Object:  Stored Procedure dbo.Las_GeneratingSettlementCommand    Script Date: 2/28/2014 9:51:06 AM ******/

CREATE PROCEDURE [dbo].[Las_GeneratingSettlementCommand]	@SPName			VARCHAR(200)
															,@SQLCommand	NVARCHAR(4000)
															,@CreatedDate	DATETIME
															,@StatusID		TINYINT
															,@MatchID		INT
															,@Bettype		SMALLINT
															,@Status		VARCHAR(50)
															,@BetCount		INT
AS
/*
Created		: 20140114@Don
Task		: Add settlement command to queue
DB			: DBLAS.lasdb
*/
BEGIN
	SET NOCOUNT ON

	INSERT INTO dbo.LicenseeAgentSettlement(SPName, SQLCommand, CreatedDate, StatusID, MatchID, Bettype, Status, BetCount)
		SELECT @SPName, @SQLCommand, @CreatedDate, @StatusID, @MatchID, @Bettype, @Status, @BetCount

END
GO

GRANT VIEW DEFINITION ON [dbo].[Las_GeneratingSettlementCommand] TO [vnteam] AS [dbo]
GO


