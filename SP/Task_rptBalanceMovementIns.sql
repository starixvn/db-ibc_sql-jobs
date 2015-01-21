USE [bodb02]
GO

/****** Object:  StoredProcedure [dbo].[Task_rptBalanceMovementIns]    Script Date: 01/21/2015 01:34:50 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/****** Object:  Stored Procedure dbo.Task_rptBalanceMovementIns    Script Date: 9/19/2009 5:05:36 PM ******/
CREATE PROCEDURE [dbo].[Task_rptBalanceMovementIns]
	@winlostdate	DATETIME 
AS
/*	Created by: Jamie
	Date: 2009-08-21
	Task: Inserting Balance Movement 
	DB: DB06.BODB02 	

*/
BEGIN
	SET NOCOUNT ON
	IF EXISTS (SELECT 1 FROM bodb_Report.dbo.rptCustBalance WITH (NOLOCK) WHERE winlostdate = @winlostdate)
	BEGIN
		DELETE FROM bodb_Report.dbo.rptCustBalance WHERE winlostdate = @winlostdate 
	END

	INSERT INTO bodb_Report.dbo.rptCustBalance(
		winlostdate, 
		CustID, 
		RoleID,
		ComOriginal, 
		PosOriginal, 
		BetOriginal, 
		TraOriginal, 
		BalOriginal,
		ComBase, 
		PosBase, 
		BetBase, 
		TraBase, 
		BalBase
	)
	SELECT	@winlostdate, 
			srecommend, 
			4, 
			ISNULL(ComOriginal,0), 
			ISNULL(PosOriginal,0), 
			ISNULL(BetOriginal,0), 
			ISNULL(TraOriginal,0), 
			ISNULL(ComOriginal,0) + ISNULL(PosOriginal,0)+ ISNULL(BetOriginal,0) + ISNULL(TraOriginal,0),
			ISNULL(ComBase,0), 
			ISNULL(PosBase,0), 
			ISNULL(BetBase,0), 
			ISNULL(TraBase,0), 
			ISNULL(ComBase,0) + ISNULL(PosBase,0) + ISNULL(BetBase,0) + ISNULL(TraBase,0)
	FROM (
			SELECT 	srecommend,		
					--Original 
					SUM (CASE WHEN bettype < 91 THEN winlost-actual_stake ELSE 0 END) BetOriginal,
					SUM (CASE WHEN bettype < 91 THEN swinlost + mwinlost + awinlost ELSE 0 END) PosOriginal,
					SUM (CASE WHEN bettype < 91 THEN scomm ELSE 0 END) ComOriginal,
					SUM (CASE WHEN bettype > 90 THEN winlost-actual_stake + swinlost + scomm + mwinlost + awinlost ELSE 0 END) TraOriginal,
				
					--Base 	
					SUM ((CASE WHEN bettype < 91 THEN winlost-actual_stake ELSE 0 END)* actualrate) BetBase,
					SUM ((CASE WHEN bettype < 91 THEN swinlost + mwinlost + awinlost ELSE 0 END)* actualrate) PosBase,
					SUM ((CASE WHEN bettype < 91 THEN scomm ELSE 0 END)* actualrate) ComBase,
					SUM ((CASE WHEN bettype > 90 THEN winlost-actual_stake + swinlost + scomm + mwinlost + awinlost ELSE 0 END)* actualrate) TraBase

			FROM	bettrans WITH (NOLOCK) 
			where	winlostdate = @winlostdate 
					AND ruben = 1 
					AND status NOT IN ('VOID','REJECT','REFUND')
			GROUP BY srecommend
	) t 

END
GO

GRANT EXECUTE ON [dbo].[Task_rptBalanceMovementIns] TO [bodbAdminNet] AS [dbo]
GO

GRANT VIEW DEFINITION ON [dbo].[Task_rptBalanceMovementIns] TO [vnteam] AS [dbo]
GO


