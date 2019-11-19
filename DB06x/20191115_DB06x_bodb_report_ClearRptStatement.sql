use bodb_report
go
/*
	Created: 20191115@Bobby
	DB: DB06x
	Task: Remove data from rptStatement for range BU -7 temporary
*/

DECLARE @BUDate		DATE
	, @CutoffDate	DATE

SELECT @BUDate = MAX(Winlostdate)
FROM bodb02.dbo.bettrans WITH(NOLOCK)
WHERE matchid = 0 AND bettype = 20000

SELECT @CutoffDate = DATEADD(DD, -7, @BUDate)

SELECT @BUDate [@BUDate], @CutoffDate [@CutoffDate]

DELETE dbo.rptStatement
WHERE winlostdate < @CutoffDate

--SELECT distinct winlostdate 
--from rptStatement with(nolock)
--WHERE winlostdate < @CutoffDate