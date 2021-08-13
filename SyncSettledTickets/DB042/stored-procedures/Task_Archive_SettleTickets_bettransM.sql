USE [bodb02]
GO

ALTER PROCEDURE [dbo].[Task_Archive_SettleTickets_bettransM] @winlostdate SMALLDATETIME
AS
/*
	Create By: 20180625@Patrick
	Task: Remove settled ticket for bettransm
	DB: DB042/bodb02
	
	Para's explaination
*/
BEGIN
	SET NOCOUNT ON

	SELECT DISTINCT refno, transid INTO #__RefNos
	FROM dbo.bettransm bm WITH(NOLOCK)
		INNER JOIN dbo.match14 m WITH(NOLOCK) ON bm.matchid = m.matchid
	WHERE eventdate = @winlostdate

	--==keep all sub when main still running
	DELETE t 
	FROM #__RefNos t
		INNER JOIN dbo.bettrans b WITH(NOLOCK) ON t.refno = b.refno
	WHERE matchid = 29 AND bettype = 29 AND statusID < 2

	DECLARE @__TempData TABLE (transid BIGINT PRIMARY KEY)
	WHILE 1 = 1
	BEGIN

		DELETE FROM @__TempData

		DELETE TOP(1000) FROM #__RefNos OUTPUT deleted.transid INTO @__TempData
		IF @@ROWCOUNT = 0
			BREAK

		DELETE FROM bm
		FROM dbo.bettransm bm WITH(ROWLOCK)
		WHERE bm.transid IN (SELECT t.transid FROM @__TempData t)
		
		WAITFOR DELAY '00:00:00:010'
	END
END
