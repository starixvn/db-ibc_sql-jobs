/*<info serverAlias="DBACC-bodb02" isFunction="0" isNested="1"></info>*/
ALTER PROCEDURE [dbo].[Task_SuspiciousAccount_CheckTicket]
AS
/*
	Created: 20200309@Elodie
	Task: Check ticket of SuspiciousAccount's downline
	DB: DBACC/bodb02
	
	Revisions:
		- 20200309@Elodie: Initialize SP [RedmineID: #129119]
*/

BEGIN
	SET NOCOUNT ON
	CREATE TABLE #TicketList (recommend INT, mrecommend INT, srecommend INT)
	CREATE TABLE #NotifyList (CustId INT)

	DECLARE @MinId BIGINT, @MaxId BIGINT, @i BIGINT = 1000000

	SELECT @MinId = CAST(VValue AS BIGINT) FROM dbo.SystemSettings WITH (NOLOCK) WHERE VID = 25 -- VName = 'SuspiciousCust_MaxId'

	SELECT @MaxId = MAX(transid) FROM dbo.bettrans WITH (NOLOCK)

	IF @MaxId > @MinId
	BEGIN
		SELECT @MaxId = CASE WHEN @MaxId - @MinId > 5000 THEN @MinId + 5000 ELSE @MaxId END

		INSERT INTO #TicketList (recommend, mrecommend, srecommend)
		SELECT DISTINCT b.recommend, b.mrecommend, b.srecommend 
		FROM bettrans tl WITH (NOLOCK)
			CROSS APPLY (SELECT TOP (@i) b.CustID, b.recommend, b.mrecommend, b.srecommend, b.transid
						FROM bettrans b WITH (NOLOCK) 
						WHERE tl.matchid = b.matchid AND tl.custid = b.custid AND tl.bettype = b.bettype AND b.transid > @MinId AND b.transid <= @MaxId) b
		WHERE tl.transid > @MinId AND tl.transid <= @MaxId
			AND tl.transid = b.transid
		OPTION (OPTIMIZE FOR (@i = 1))

		INSERT INTO #NotifyList (CustId)
		SELECT sc.CustID
		FROM dbo.SuspiciousCust sc WITH (NOLOCK)			
		WHERE sc.NotifyStatus2 = 0
			AND EXISTS (SELECT 1 FROM #TicketList b WITH (NOLOCK) WHERE sc.custid = b.recommend OR sc.custid = b.mrecommend OR sc.custid = b.srecommend)
	END
	
	SELECT * FROM #NotifyList

	UPDATE s
	SET s.VValue = CAST(@MaxID AS VARCHAR(50))
	FROM dbo.SystemSettings s WITH (ROWLOCK) 
	WHERE VName = 'SuspiciousCust_MaxId'
	
	DROP TABLE #TicketList
	DROP TABLE #NotifyList
END
GO