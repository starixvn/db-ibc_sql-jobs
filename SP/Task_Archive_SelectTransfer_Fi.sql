/*<info serverAlias="DBTXN-bodb02" executers="" viewers="" isFunction="0" isNested="0"></info>*/
USE [bodb02]
GO
 
CREATE PROCEDURE [dbo].[Task_Archive_SelectTransfer_Fi]
AS
 /*
	Created by: 20190117@Sophia
	Task: Insert data for transfer_fi
	DB: DBTXN.bodb02 
	Original: Acc_StatementFinance at DB06.bodb02
	
	Revisions:
	    - 20190117@Sophia : Initial SP [redmine: 105415]
	
 */
 
SET NOCOUNT ON 
BEGIN 
CREATE TABLE #Refno_temp (refno BIGINT, winlostdate SMALLDATETIME)
CREATE CLUSTERED INDEX [CIX_Winlostdate] ON #Refno_temp
(
    [Winlostdate] ASC,
    [RefNo] ASC
)

DECLARE @BalanceUpDay SMALLDATETIME
SELECT TOP 1 @BalanceUpDay = winlostdate + 7
FROM dbo.Bettrans WITH(NOLOCK)
WHERE bettype = 20000 AND matchid = 0 AND custid = 3

CREATE TABLE #InternalAccList (CustID INT, RoleID TINYINT)
INSERT INTO #InternalAccList (CustID, RoleID)
SELECT 	CustID, 2 
FROM 	DBCUST.CustDB.dbo.custAgent c WITH (NOLOCK)
WHERE 	c.isInternal = 1
UNION ALL 
SELECT 	CustID, 3
FROM 	DBCUST.CustDB.dbo.CustMaster c WITH (NOLOCK)
WHERE 	c.isInternal = 1
UNION ALL
SELECT 	CustID, 4 
FROM 	DBCUST.CustDB.dbo.CustSuper c WITH (NOLOCK)
WHERE 	c.isInternal = 1


INSERT INTO #Refno_temp
SELECT refno, winlostdate FROM bettrans b WITH (NOLOCK)
	INNER join #InternalAccList c WITH (NOLOCK) ON b.recommend = c.custid
WHERE c.RoleID = 2 AND bettype > 20000 AND matchid = 0 AND winlostdate < @BalanceUpDay
UNION
SELECT refno, winlostdate FROM bettrans b WITH (NOLOCK)
	INNER join #InternalAccList c WITH (NOLOCK) ON b.custid = c.custid
WHERE c.RoleID = 3 AND bettype > 20000 AND matchid = 0 AND winlostdate < @BalanceUpDay
UNION
SELECT refno, winlostdate FROM bettrans b WITH (NOLOCK)
	INNER join #InternalAccList c WITH (NOLOCK) ON b.custid = c.custid
WHERE c.RoleID = 4 AND bettype > 20000 AND matchid = 0 AND winlostdate < @BalanceUpDay


	
	
--INSERT INTO DBSUM.bodb_Summary.dbo.transfer_fi
--    (
--        transid, 
--        custid, 
--        transdate, 
--        bettype, 
--        actual_stake, 
--        winlost, 
--        ActualRate, 
--        TransDesc, 
--        winlostdate, 
--        recommend, 
--        mrecommend, 
--        srecommend, 
--        currency, 
--        refno,
--        creator,
--        CheckerID,
--        CheckerName,
--        checkTime,
--        isReversal
--    )
    SELECT 
        b.transid, 
        custid, 
        transdate, 
        bettype, 
        actual_stake, 
        winlost, 
        ActualRate, 
        TransDesc, 
        b.winlostdate, 
        recommend, 
        mrecommend, 
        srecommend, 
        currency, 
        b.refno,
        creator,
        betid, --CheckerID
        betcheck, --CheckerName
        checkTime,
        liveindicator isReversal
    FROM dbo.bettrans b WITH (NOLOCK, INDEX=CIX_matchid_bettype)
        INNER JOIN #Refno_temp r ON b.refno = r.refno AND b.winlostdate=r.winlostdate
    WHERE b.matchid = 0 AND b.bettype > 20000
    
    
DROP TABLE #Refno_temp
END 

GO



