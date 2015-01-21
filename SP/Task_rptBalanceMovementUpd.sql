USE [bodb02]
GO

/****** Object:  StoredProcedure [dbo].[Task_rptBalanceMovementUpd]    Script Date: 01/21/2015 01:41:45 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/****** Object:  Stored Procedure dbo.Task_rptBalanceMovementUpd    Script Date: 9/19/2009 5:05:36 PM ******/
CREATE PROCEDURE [dbo].[Task_rptBalanceMovementUpd]
	@checkTime	DATETIME 
AS
/*	Created by: Jamie
	Date: 2009-08-22
	Task: Updating Balance Movement 
	DB: DB06.BODB02 

	Param's Explanation:
		@checkTime = DATEADD(Minute,-2,CURRENT_TIMESTAMP)
*/
BEGIN
	SET NOCOUNT ON
	IF EXISTS (SELECT 1 FROM CalcList_Customer WITH (NOLOCK) WHERE AddTime < @checkTime)
	BEGIN
		DECLARE	@tmpCust TABLE (custid INT, winlostdate DATETIME)

		UPDATE	bodb_Report.dbo.rptCustBalance WITH (UPDLOCK ,ROWLOCK)
		SET		ComOriginal = ISNULL(t.ComOriginal,0),
				PosOriginal = ISNULL(t.PosOriginal,0),
				BetOriginal = ISNULL(t.BetOriginal,0),
				TraOriginal = ISNULL(t.TraOriginal,0),
				BalOriginal = ISNULL(t.ComOriginal,0) + ISNULL(t.PosOriginal,0)+ ISNULL(t.BetOriginal,0) + ISNULL(t.TraOriginal,0),
				ComBase		= ISNULL(t.ComBase,0),
				PosBase		= ISNULL(t.PosBase,0),
				BetBase		= ISNULL(t.BetBase,0), 
				TraBase		= ISNULL(t.TraBase,0),
				BalBase		= ISNULL(t.ComBase,0) + ISNULL(t.PosBase,0) + ISNULL(t.BetBase,0) + ISNULL(t.TraBase,0),
				UpdDate		= GETDATE()
		OUTPUT  inserted.custid, inserted.winlostdate INTO @tmpCust(custid, winlostdate)
		FROM	(
					SELECT 	b.srecommend,	
							b.winlostdate,	
							--Original 
							SUM (CASE WHEN b.bettype < 91 THEN b.winlost-b.actual_stake ELSE 0 END) BetOriginal,
							SUM (CASE WHEN b.bettype < 91 THEN b.swinlost + b.mwinlost + b.awinlost ELSE 0 END) PosOriginal,
							SUM (CASE WHEN b.bettype < 91 THEN b.scomm ELSE 0 END) ComOriginal,
							SUM (CASE WHEN b.bettype > 90 THEN b.swinlost + b.scomm + b.mwinlost + b.awinlost + b.winlost-b.actual_stake ELSE 0 END) TraOriginal,
						
							--Base 	
							SUM ((CASE WHEN b.bettype < 91 THEN b.winlost-b.actual_stake ELSE 0 END)* b.actualrate) BetBase,
							SUM ((CASE WHEN b.bettype < 91 THEN b.swinlost + b.mwinlost + b.awinlost ELSE 0 END)* b.actualrate) PosBase,
							SUM ((CASE WHEN b.bettype < 91 THEN b.scomm ELSE 0 END)* b.actualrate) ComBase,
							SUM ((CASE WHEN b.bettype > 90 THEN b.swinlost + b.scomm + b.mwinlost + b.awinlost + b.winlost-b.actual_stake ELSE 0 END)* b.actualrate) TraBase

					FROM	bettrans b WITH (NOLOCK)
							INNER JOIN  CalcList_Customer c ON b.srecommend = c.custid AND b.winlostdate = c.winlostdate
					WHERE	b.ruben = 1 AND c.AddTime < @checkTime
					GROUP BY srecommend, b.winlostdate
				) t 
				INNER JOIN	bodb_Report.dbo.rptCustBalance b ON t.srecommend = b.custid AND t.winlostdate = b.winlostdate 
		IF @@ERROR = 0 
		BEGIN 
			DELETE	CalcList_Customer 
			FROM	CalcList_Customer l 
					INNER JOIN @tmpCust t ON l.custid = t.custid AND l.winlostdate = t.winlostdate 
		END
		
	END
END
GO

GRANT EXECUTE ON [dbo].[Task_rptBalanceMovementUpd] TO [bodbAdminNet] AS [dbo]
GO

GRANT VIEW DEFINITION ON [dbo].[Task_rptBalanceMovementUpd] TO [vnteam] AS [dbo]
GO


