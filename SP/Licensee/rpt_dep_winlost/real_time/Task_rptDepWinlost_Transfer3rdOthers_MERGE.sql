
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

/****** Object:  Stored Procedure dbo.Task_rptDepWinlost_Transfer3rdOthers_MERGE    Script Date: 12/1/2015 2:38:01 AM ******/
/****** Object:  Stored Procedure dbo.Task_rptDepWinlost_Transfer3rdOthers_MERGE    Script Date: 3/4/2015 1:17:47 PM ******/
CREATE PROCEDURE [dbo].[Task_rptDepWinlost_Transfer3rdOthers_MERGE] 	
	@strXML varchar(MAX)
AS
/*   
 Task : Summary data for deposit member  
 DB: DB06.bodb_report
 Revisions:   
	- 20130626@Don: Creating SP
	- 20150116@Winnie: get tranferin tranferout for AG Casino
                 
 Param's Explanation:  

*/  
SET NOCOUNT ON
SET DEADLOCK_PRIORITY LOW	

--IF @strXML IS NULL OR EXISTS(SELECT 1 FROM bodb02.dbo.SystemSettings WITH(NOLOCK) WHERE VValue = 1 AND VName = 'isCalculatingDEPdata')
--BEGIN	
--	RETURN
--END

DECLARE @_xml XML
SELECT @_xml = CONVERT(XML, @strXML)
SELECT	
	CAST(T.C.value('./@d0', 'int') as smalldatetime) winlostdate, 
	T.C.value('./@d1', 'int') custid, 
	T.C.value('./@d2', 'int') currency,
	T.C.value('./@d3', 'int') partnerid,
	T.C.value('./@d4', 'int') recommend,
	T.C.value('./@d5', 'int') mrecommend,
	T.C.value('./@d6', 'int') srecommend,
	ISNULL(T.C.value('./@d7', 'money'), 0) transferamount,
	ISNULL(T.C.value('./@d8', 'money'), 0) transferin,
	ISNULL(T.C.value('./@d9', 'money'), 0) transferout
INTO #TEMP		
FROM @_xml.nodes('/root/r') AS [T](C)

DECLARE @updated_list AS TABLE(custid int, winlostdate smalldatetime)
UPDATE d
	SET winlostdate = s.winlostdate
		,CustId = s.custid
		,Currency = s.currency
		,PartnerId = s.partnerid
		,Recommend = s.recommend
		,MRecommend = s.mrecommend
		,SRecommend = s.srecommend
		,TransferAmount = s.transferamount
		,transferin=s.transferin
		,transferout=s.transferout
OUTPUT inserted.custid, inserted.winlostdate INTO @updated_list		
FROM dbo.rptDepWinlost_Transfer3rdOthers d WITH(ROWLOCK, UPDLOCK)
	INNER JOIN #TEMP s on d.custid = s.custid and d.winlostdate = s.winlostdate

DELETE D
FROM #TEMP D
	INNER JOIN @updated_list s on d.custid = s.custid and d.winlostdate = s.winlostdate

INSERT INTO dbo.rptDepWinlost_Transfer3rdOthers(winlostdate,CustId,Currency,PartnerId,Recommend,MRecommend,SRecommend,TransferAmount,transferin,transferout)
	SELECT winlostdate,CustId,Currency,PartnerId,Recommend,MRecommend,SRecommend,TransferAmount,transferin,transferout
	FROM #TEMP

DROP TABLE #TEMP

SET NOCOUNT OFF
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO


GO 
