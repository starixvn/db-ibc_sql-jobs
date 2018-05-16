USE [CheckResultDB]
GO

ALTER PROCEDURE [dbo].[DBA_CheckRecommend]
	 @srecommend INT 
AS
BEGIN 
/*
Created: 20180514@Winnie
Task: Weekly check recommend setting for customers 
DB: DBCHECK.CheckResultDB
Revisions:
Param's Explanation: 
*/
	SET NOCOUNT ON 
	DECLARE @CurrentDate DATETIME
	SELECT @CurrentDate=GETDATE() 
	INSERT INTO CheckRecommendResult ([CustID],srecommend,mrecommend,recommend,CreatedDate)
	SELECT Custid,ci.srecommend,ci.mrecommend,ci.recommend,GETDATE()
		FROM CheckCustDB.dbo.customer ci WITH(NOLOCK)
	WHERE ci.roleid=2 AND (ci.custid=ci.srecommend OR ci.custid=ci.mrecommend) AND (ci.creatdate BETWEEN @CurrentDate-7 AND @CurrentDate)

	INSERT INTO CheckRecommendResult ([CustID],srecommend,mrecommend,recommend,CreatedDate)
	SELECT Custid,ci.srecommend,ci.mrecommend,ci.recommend,GETDATE()
		FROM CheckCustDB.dbo.customer ci WITH(NOLOCK)
	WHERE ci.roleid=3 AND ci.custid=ci.srecommend AND (ci.creatdate BETWEEN @CurrentDate-7 AND @CurrentDate) 

	INSERT INTO CheckRecommendResult ([CustID],srecommend,mrecommend,recommend,CreatedDate)
	SELECT Custid,ci.srecommend,ci.mrecommend,ci.recommend,GETDATE()
		FROM CheckCustDB.dbo.customer ci WITH(NOLOCK)
	WHERE ci.roleid=1 AND (ci.custid=ci.srecommend OR ci.custid=ci.mrecommend OR ci.custid=ci.recommend) AND (ci.creatdate BETWEEN @CurrentDate-7 AND @CurrentDate)

END 

