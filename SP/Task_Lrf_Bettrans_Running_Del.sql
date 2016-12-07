USE [bodb02]
GO
ALTER PROCEDURE [dbo].[Task_Lrf_Bettrans_Running_Del]
AS
/*
	Created: 20161117@Patrick
	Task: Delete ticket in lrf bettrans running [Redmine: #67498]
	DB: DBEXT/bodb02
	Revisions:
   
 */
BEGIN
	SET NOCOUNT ON
	SET DEADLOCK_PRIORITY LOW
	
	CREATE TABLE #DataTmp (RowId INT IDENTITY(1,1), TransId BIGINT, LicenseeId INT)

	INSERT INTO #DataTmp(TransId, LicenseeId)
	SELECT TransId, LicenseeId
	FROM (
		SELECT ROW_NUMBER() OVER (PARTITION BY LicenseeId ORDER BY TransId DESC) RowId
			, br.TransId, br.LicenseeId
		FROM dbo.bettrans_lrf_betRunning br WITH (NOLOCK)
		WHERE EXISTS (SELECT TOP 1 1 
						FROM bodb_licensee.dbo.Licensees l WITH(NOLOCK) 
						WHERE l.LicenseeId = br.LicenseeId)
	) tmp
	WHERE rowId = 3000
	
	DECLARE @RowId INT
	SET @RowId = 1

	WHILE EXISTS (SELECT TOP 1 1 FROM #DataTmp WHERE RowId = @RowId)
	BEGIN
		DECLARE @LicenseeId INT, @TransId BIGINT
		
		SELECT @TransId = TransId, @LicenseeId = LicenseeId
		FROM #DataTmp WHERE RowId = @RowId

		SET @RowId = @RowId + 1
		
		DELETE br
		FROM dbo.bettrans_lrf_betRunning br WITH(ROWLOCK, INDEX = CIX_LicenseeID_TransID_Scott)
		WHERE LicenseeID = @LicenseeId AND transid < @TransId
		
	END
	DROP TABLE #DataTmp
END

