/*<info serverAlias="DBTXN-bodb02" executers="" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[SSIS_Transfer_Coll_Export]
	@winlostdate smalldatetime=null
AS
/*
	Created by:	20130831@Bobby
	Task:		Revise SSIS Archiving Data Project [Redmine: #166146]	
	Database: DBTXN.bodb02
	Original: Task_Archive_SelectTransfer_Coll
	
	Revisions:
		- 20130831@Bobby: Init
 */
 BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	--Declare @BU_Date datetime -- Next BalanceUp Date  

	--SET @BU_Date=@BUDate;
	--SELECT @BU_Date = DATEADD(day, 1, MAX(winlostdate))
	--FROM dbo.Task_ArchiveDate


	-- Transfer Archive  
	-- INSERT INTO DB06.bodb_Archive.dbo.Transfer_Coll_BK  
	-- (CustId,WinlostDate,TransDate,Bettype,Debit,Credit,Currency,ActualRate,TransID,RefNo,Username,Recommend,MRecommend,SRecommend,Creator,TransDesc,IP)  

	SELECT  
		CustId,
		WinlostDate,
		TransDate,
		Bettype,
		Debit,
		Credit,
		Currency,
		ActualRate,
		TransID,
		RefNo,
		Username,
		Recommend,
		MRecommend,
		SRecommend,
		Creator,
		TransDesc,
		IP
	FROM dbo.Transfer_Coll WITH(NOLOCK)
	WHERE winlostdate = @winlostdate  

	
END
