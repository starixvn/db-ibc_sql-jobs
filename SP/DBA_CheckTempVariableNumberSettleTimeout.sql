USE [bodb02]
GO

/****** Object:  StoredProcedure [dbo].[DBA_CheckTempVariableNumberSettleTimeout]    Script Date: 01/26/2015 03:28:28 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[DBA_CheckTempVariableNumberSettleTimeout]
AS
--20141012@Cooper(DBTrans) Create for check settle time out
BEGIN
	SET NOCOUNT ON 
	SELECT KeyValue into #tmp FROM bodb02.dbo.TempVariableNumber  with(nolock)
	
	WAITFOR DELAY '00:10'

	SELECT 1 FROM #tmp t inner join bodb02.dbo.TempVariableNumber TVN with(nolock)
		on t.KeyValue = TVN.KeyValue

	IF @@Rowcount > 0
	BEGIN
		RAISERROR ('FAILED: Have settle Program time out - TempVariableNumber', 16, 1)
		RETURN
	END

	DROP TABLE #tmp
END


GO


