/*
	Created: 20190806@Bobby
	Bug: 118279 - NAP Automate Licensee WL transfer - Correct the creator in July-2019 transfer tickets within StarixIT account
	DB: DBTXN-bodb02
*/
USE bodb02
GO

DECLARE @mothDate		DATE
	,@createrUserName	VARCHAR(30) = 'StarixIT'
	,@forexUsername		VARCHAR(50) = 'MYS-Forex G/(L)'
	,@createrID			INT
	,@forexID			INT
	,@bettype			INT = 21003

CREATE TABLE #tempCust (custid INT PRIMARY KEY)
CREATE TABLE #tempTransId (transid BIGINT PRIMARY KEY)

SELECT TOP(2) @createrID = CASE WHEN username = @createrUserName THEN custid ELSE @createrID END
	,@forexID = CASE WHEN username = @forexUsername THEN custid ELSE @forexID END
FROM CustDB.dbo.custInfo WITH(NOLOCK) 
WHERE username IN (@createrUserName,@forexUsername)
	
SELECT TOP(1) @mothDate = TransferDate
FROM dbo.LicenseeTransferPool WITH(NOLOCK)

SELECT @mothDate AS [winlostdate], @createrID AS [creater], @forexID AS [forex]

IF (@createrID IS NULL OR @mothDate IS NULL)
BEGIN
	SELECT 'Input is invalid.' AS [ERROR]
	RETURN
END

-- collect LIC super, LIC's transfer code AND forex users
INSERT INTO #tempCust(custid)
SELECT DISTINCT c.custid
FROM
(
	SELECT ca.custid
	FROM dbo.LicenseeTransferPool p WITH (NOLOCK)
	CROSS APPLY (
		SELECT CustID
		FROM (
			VALUES(p.FromCustId)
				,(p.ToCustID)
		) as c (custid)
	) as ca
	UNION ALL
	SELECT @forexID AS custid
) AS c

-- collect trans IDs to update creator
;WITH cte_transId AS(
	SELECT b.transid
	FROM dbo.bettrans b WITH (NOLOCK)
	INNER JOIN #tempCust p ON b.custid = p.custid
	WHERE b.winlostdate = @mothDate
		AND b.bettype = @bettype
)
INSERT INTO #tempTransId (transid)
SELECT b.transid
FROM dbo.bettrans b WITH (NOLOCK)
	INNER JOIN cte_transId t ON b.transid = t.transid
order by b.refno, b.transid

-- update creator by transid
UPDATE b
SET creator = @createrID
FROM dbo.bettrans b WITH(ROWLOCK)
INNER JOIN #tempTransId t ON b.transid = t.transid

-- double check the result
SELECT DISTINCT b.winlostdate, b.creator
FROM #tempTransId t
	inner join dbo.bettrans b WITH(NOLOCK)
	ON t.transid = b.transid

DROP TABLE #tempCust
DROP TABLE #tempTransId
