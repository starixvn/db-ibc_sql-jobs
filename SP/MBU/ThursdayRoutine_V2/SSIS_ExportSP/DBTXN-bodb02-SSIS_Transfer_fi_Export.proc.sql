/*<info serverAlias="DBTXN-bodb02" executers="" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[SSIS_Transfer_fi_Export]
	@BUDate smalldatetime=null
AS
/*
	Created by:	20130831@Bobby
	Task:		Revise SSIS Archiving Data Project [Redmine: #166146]	
	Database: DBTXN.bodb02
	Original: Task_Archive_SelectTransfer_Fi
	
	Revisions:
 */
 BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @Refno_temp AS TABLE ( refno BIGINT, winlostdate SMALLDATETIME) 

	DECLARE @BalanceUpDay SMALLDATETIME

	SET @BalanceUpDay = @BUDate;
	
	--SELECT TOP 1 @BalanceUpDay = winlostdate + 7
	--FROM dbo.Bettrans WITH(NOLOCK)
	--WHERE bettype = 20000 AND matchid = 0 AND custid = 3

	DECLARE @InternalAccList AS TABLE (CustID INT, RoleID TINYINT)
	--INSERT INTO @InternalAccList (CustID, RoleID)
	--SELECT 	CustID, 2 
	--FROM 	DBCUST.CustDB.dbo.custAgent c WITH (NOLOCK)
	--WHERE 	c.isInternal = 1
	--UNION ALL 
	--SELECT 	CustID, 3
	--FROM 	DBCUST.CustDB.dbo.CustMaster c WITH (NOLOCK)
	--WHERE 	c.isInternal = 1
	--UNION ALL
	--SELECT 	CustID, 4 
	--FROM 	DBCUST.CustDB.dbo.CustSuper c WITH (NOLOCK)
	--WHERE 	c.isInternal = 1


	INSERT INTO @Refno_temp
	SELECT refno, winlostdate 
	FROM dbo.bettrans b WITH (NOLOCK)
		INNER join @InternalAccList c ON b.recommend = c.custid
	WHERE c.RoleID = 2 AND bettype > 20000 AND matchid = 0 AND winlostdate < @BalanceUpDay
	UNION
	SELECT refno, winlostdate 
	FROM dbo.bettrans b WITH (NOLOCK)
		INNER join @InternalAccList c ON b.custid = c.custid
	WHERE c.RoleID = 3 AND bettype > 20000 AND matchid = 0 AND winlostdate < @BalanceUpDay
	UNION
	SELECT refno, winlostdate 
	FROM dbo.bettrans b WITH (NOLOCK)
		INNER join @InternalAccList c ON b.custid = c.custid
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
			CONVERT (NVARCHAR(300),TransDesc) AS TransDesc, 
			b.winlostdate, 
			recommend, 
			mrecommend, 
			srecommend, 
			currency, 
			b.refno,
			creator,
			betid as CheckerID,
			CONVERT ( VARCHAR(50),betcheck) as CheckerName,
			checkTime,
			liveindicator isReversal
		FROM dbo.bettrans b WITH (NOLOCK) --(NOLOCK, INDEX=CIX_matchid_bettype)
			INNER JOIN @Refno_temp r ON b.refno = r.refno AND b.winlostdate=r.winlostdate
		WHERE b.matchid = 0 AND b.bettype > 20000
    
	
END
GO
