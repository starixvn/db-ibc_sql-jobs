SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

/****** Object:  Stored Procedure dbo.Task_BATransaction_Copy_Ticket    Script Date: 8/7/2018 5:16:54 PM ******/
 
CREATE PROCEDURE dbo.Task_BATransaction_Copy_Ticket @XmlData NVARCHAR(MAX), @ErrorCode INT = 0 OUTPUT
AS  
/*  
	Created: 20180806@Patrick
	Task: Copy BA ticket from DB052 for temporary
	DB: DB042.bodb_Licensee  
	Revisions: 
		
 */  
BEGIN
	SET NOCOUNT ON

	IF @XmlData IS NULL RETURN

	SET @ErrorCode = 0
	DECLARE @xml XML = CAST(@XmlData AS XML)

	DECLARE @__BATransData TABLE (transid BIGINT, transdate DATETIME, custId INT, recommend INT, srecommend INT)
	INSERT @__BATransData(transid, transdate, custId, recommend, srecommend)
	SELECT r.value('./@t','bigint'), r.value('./@td','datetime'), r.value('./@c','int')
		, r.value('./@r','int'), r.value('./@s','int')
	FROM @xml.nodes('//root/r') AS RECORDS(r)
	OPTION (OPTIMIZE FOR (@xml = NULL ))

	INSERT INTO dbo.LicenseeBATransaction_active(TransID, transdate, custid, recommend, srecommend)
	SELECT transid, transdate, custId, recommend, srecommend
	FROM @__BATransData t
	WHERE NOT EXISTS (
		SELECT TOP 1 1 
		FROM dbo.LicenseeBATransaction_active b WITH(NOLOCK)
		WHERE t.transid = b.TransID
	)

END


GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO


GO 
