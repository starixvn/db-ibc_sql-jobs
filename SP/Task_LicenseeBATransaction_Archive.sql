USE [bodb02]
GO

/****** Object:  StoredProcedure [dbo].[Task_LicenseeBATransaction_Archive]    Script Date: 01/26/2015 04:45:37 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Task_LicenseeBATransaction_Archive]
AS
/*
	Created: Viet
	Date: 20121120
	Task: archive data for LicenseeBATransaction_active
	DB: DB052.bodb02
	
	Revisions:
		
	Paramters Explanation:
*/
SET NOCOUNT ON	

	SELECT ba.TransID, ba.transdate, ba.custid, ba.recommend, ba.srecommend, b.winlostdate
	INTO #TempData 
	from bodb_licensee.dbo.LicenseeBATransaction_active ba with(rowlock)
		inner join dbo.bettrans14 b with(nolock) on b.transid = ba.transid

	IF @@rowcount = 0 RETURN		
			
	INSERT INTO	bodb_licensee.dbo.LicenseeBATransaction_bk (
		TransID, transdate, custid, recommend, srecommend, winlostdate
	)
	SELECT TransID, transdate, custid, recommend, srecommend, winlostdate
	FROM #TempData
	
	IF @@error=0
	BEGIN
		DELETE d
		FROM bodb_licensee.dbo.LicenseeBATransaction_active d
			INNER JOIN #TempData s on d.transid = s.transid
	END		

SET NOCOUNT OFF	

GO


