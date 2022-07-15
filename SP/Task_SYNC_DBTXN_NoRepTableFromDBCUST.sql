/*<info serverAlias="DBTXN-CustDB" executers="" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Task_SYNC_DBTXN_NoRepTableFromDBCUST]
AS
/*
	Created : Tina@20210702
	Task : sync data of UUS account for table CustProductStatus to support testing on UAT
	DB : DBTXN.CustDB

	Revisions :	
		- 20210702@Tina: All Sites - Lock account & indirect close account [RedmineID: #148600]
		- 20220714@Johnson: Declare structure for temp table [RedmineID: #174035]
*/

BEGIN
	CREATE TABLE #tmpListInsertCust (CustID INT)
	CREATE TABLE #tmpListInsertCust_Batch (CustID INT PRIMARY KEY)
	CREATE TABLE #tmpListUpdateCust 
	(   CustID INT NOT NULL,
		bitmapHasSynced BINARY(32) NOT NULL,
		bitmapIsHidden BINARY(32) NOT NULL,
		bitmapIsDisabled BINARY(32) NOT NULL,
		SuspendInfo TINYINT NULL,
		Locked TINYINT NULL,
		CloseInfo TINYINT NULL
	)	
	
	CREATE TABLE #tmpListUpdateCust_Batch
	(   CustID INT NOT NULL PRIMARY KEY,
		bitmapHasSynced BINARY(32) NOT NULL,
		bitmapIsHidden BINARY(32) NOT NULL,
		bitmapIsDisabled BINARY(32) NOT NULL,
		SuspendInfo TINYINT NULL,
		Locked TINYINT NULL,
		CloseInfo TINYINT NULL
	)
	
	CREATE TABLE #tmpCustProductStatus (
	[CustID] [int] NOT NULL PRIMARY KEY,
	[bitmapHasSynced] [binary](32) NOT NULL,
	[bitmapIsHidden] [binary](32) NOT NULL,
	[bitmapIsDisabled] [binary](32) NOT NULL,
	[SuspendInfo] [tinyint] NULL,
	[Locked] [tinyint] NULL,
	[CloseInfo] [tinyint] NULL
	)
	
	INSERT INTO #tmpCustProductStatus(CustID, bitmapHasSynced, bitmapIsDisabled, bitmapIsHidden, SuspendInfo, CloseInfo, Locked) 
	SELECT CustID, bitmapHasSynced, bitmapIsDisabled, bitmapIsHidden, SuspendInfo, CloseInfo, Locked
	FROM OPENQUERY(DBACC, '
	SELECT cps.CustID, cps.bitmapHasSynced, cps.bitmapIsDisabled, cps.bitmapIsHidden, cps.SuspendInfo, cps.CloseInfo, cps.Locked
	FROM bodb02.dbo.CustProductStatus cps WITH (NOLOCK)
		INNER JOIN bodb02.dbo.custInfo ci WITH (NOLOCK) ON ci.custid = cps.CustID 
	where ci.currency = 20')

	--Get list update
	INSERT INTO #tmpListUpdateCust(CustID, bitmapHasSynced, bitmapIsDisabled, bitmapIsHidden, SuspendInfo, CloseInfo, Locked)
	SELECT cps.CustID, cps.bitmapHasSynced, cps.bitmapIsDisabled, cps.bitmapIsHidden, cps.SuspendInfo, cps.CloseInfo, cps.Locked
	FROM #tmpCustProductStatus cps
		INNER JOIN dbo.CustProductStatus cs WITH (NOLOCK) ON cps.CustID = cs.CustID
	WHERE cps.bitmapHasSynced <> cs.bitmapHasSynced
		OR cps.bitmapIsDisabled <> cs.bitmapIsDisabled
		OR cps.bitmapIsHidden <> cs.bitmapIsHidden
		OR ISNULL(cps.SuspendInfo,0) <> ISNULL(cs.SuspendInfo,0)
		OR ISNULL(cps.CloseInfo,0) <> ISNULL(cs.CloseInfo,0)
		OR ISNULL(cps.Locked,0) <> ISNULL(cs.Locked,0)

	--Update
	WHILE (1=1)
	BEGIN			
		DELETE TOP (4500) c 
		OUTPUT deleted.CustID, deleted.bitmapHasSynced, deleted.bitmapIsDisabled, deleted.bitmapIsHidden, deleted.SuspendInfo, deleted.CloseInfo, deleted.Locked
		INTO #tmpListUpdateCust_Batch(CustID, bitmapHasSynced, bitmapIsDisabled, bitmapIsHidden, SuspendInfo, CloseInfo, Locked) 
		FROM #tmpListUpdateCust c
		
		IF @@ROWCOUNT = 0
			BREAK

		UPDATE cps
		SET bitmapHasSynced = b.bitmapHasSynced, 
			bitmapIsDisabled = b.bitmapIsDisabled, 
			bitmapIsHidden = b.bitmapIsHidden, 
			SuspendInfo = b.SuspendInfo, 
			CloseInfo = b.CloseInfo, 
			Locked = b.Locked
		FROM #tmpListUpdateCust_Batch b
			INNER JOIN CustProductStatus cps WITH (NOLOCK) ON b.CustID = cps.CustID
		
		DELETE #tmpListUpdateCust_Batch
	END
	
	--Get list insert for UUS account only
	INSERT INTO #tmpListInsertCust(CustID)
	SELECT cps.CustID
	FROM #tmpCustProductStatus cps
	WHERE NOT EXISTS (SELECT 1 FROM CustProductStatus cs WITH (NOLOCK) WHERE cs.CustID = cps.CustID)

	--Insert
	WHILE (1=1)
	BEGIN			
		DELETE TOP (4500) c OUTPUT deleted.CustID INTO #tmpListInsertCust_Batch(CustID) FROM #tmpListInsertCust c
		
		IF @@ROWCOUNT = 0
			BREAK

		INSERT INTO CustProductStatus(CustID, bitmapHasSynced, bitmapIsDisabled, bitmapIsHidden, SuspendInfo, CloseInfo, Locked)
		SELECT cps.CustID, cps.bitmapHasSynced, cps.bitmapIsDisabled, cps.bitmapIsHidden, cps.SuspendInfo, cps.CloseInfo, cps.Locked
		FROM #tmpListInsertCust_Batch b
			INNER JOIN #tmpCustProductStatus cps WITH (NOLOCK) ON b.CustID = cps.CustID
		
		DELETE #tmpListInsertCust_Batch
	END
	
	DROP TABLE #tmpListInsertCust
	DROP TABLE #tmpListInsertCust_Batch
	DROP TABLE #tmpCustProductStatus
	DROP TABLE #tmpListUpdateCust
	DROP TABLE #tmpListUpdateCust_Batch
	
END
