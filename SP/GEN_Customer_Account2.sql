USE [bodb_Licensee]
GO

/****** Object:  StoredProcedure [dbo].[GEN_Customer_Account2]    Script Date: 01/19/2015 03:38:03 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



CREATE PROCEDURE [dbo].[GEN_Customer_Account2] 
    @datefrom datetime=null
    ,@dateto datetime=null
AS  
/*
Created: 20110617@Elly.Nguyen
Task : Generate data for Customer Account
DB: DB052.bodb_licensee

Revisions:
    20111129@Don: 
        + Just take care of bettpye 22001,22002
    20120116@Don:
        + Take care of extra bettype 22003 (Withdrawal Cancelled)
        + Improve performance
Param's Explanation:
*/
BEGIN
	SET NOCOUNT ON	
	
	-- Process input value @datefrom, @dateto
	DECLARE @today datetime, @thedaybefore datetime
	SELECT @today=@dateto, @thedaybefore=@datefrom
	
	IF (NOT (@today IS NULL OR @thedaybefore IS NULL))
        SELECT @today=CONVERT(varchar(10),DATEADD(day,1,@today),120), @thedaybefore=CONVERT(varchar(10),@thedaybefore,120)
    ELSE
        SELECT @today=CONVERT(varchar(10),current_timestamp,120), @thedaybefore=DATEADD(day,-3,@today)
    -- END of Process input value @datefrom, @dateto
	
	DECLARE @Recommend_List TABLE (t_recommend int PRIMARY KEY)
	
	INSERT INTO @Recommend_List
        SELECT DISTINCT recommend 
        FROM bodb02.dbo.bettrans (NOLOCK) 
        WHERE bettype IN (22001,22002,22003)
            AND matchid=0
	
	/*DELETE ca
	FROM dbo.tbl_Customer_Account ca WITH(READPAST)
		INNER JOIN bodb02.dbo.bettrans b WITH(READPAST) ON b.transid = ca.transid
	WHERE b.bettype IN (22001,22002) AND b.matchid = 0 */
	DELETE ca
	FROM dbo.tbl_Customer_Account ca
	WHERE ca.transid IN (
	        SELECT b.transid
	        FROM bodb02.dbo.bettrans b (NOLOCK)
	            INNER JOIN @Recommend_List r ON b.recommend=r.t_recommend
	        WHERE b.bettype IN (22001,22002,22003) 
	            AND b.matchid = 0 
                AND b.transdate >= @thedaybefore AND transdate < @today
	    )

	INSERT INTO dbo.tbl_Customer_Account 
    (
        [transid]
        ,[refno]
        ,[transtype]
        ,[custid]
        ,currency
        ,recommend
        ,mrecommend
        ,srecommend
        ,[transdate]
        ,[amount]
        ,[creator]
        ,[TransDesc]
        ,balanceduppreviousday
    )
	    SELECT 
	        b.transid
	        ,b.refno
	        ,b.bettype
	        ,b.custid
	        ,b.currency
	        ,ISNULL(b.recommend,0) recommend
	        ,ISNULL(b.mrecommend,0) mrecommend
	        ,ISNULL(b.srecommend,0) srecommend
	        ,b.transdate
	        ,(b.winlost-b.actual_Stake) Amount
	        ,b.creator
	        ,CASE WHEN CHARINDEX('(',b.transdesc) = 0 THEN NULL ELSE SUBSTRING(b.transdesc,CHARINDEX('(',b.transdesc)+1,LEN(b.transdesc)-CHARINDEX('(',b.transdesc)-1) END TransDesc
	        ,CASE WHEN (b.winlostdate+1)<=b.transdate THEN 1 ELSE 0 END balanceduppreviousday
	    FROM bodb02.dbo.bettrans b (NOLOCK) 
	        INNER JOIN @Recommend_List r ON b.recommend=r.t_recommend
	    WHERE b.bettype IN (22001,22002,22003)
	        AND b.matchid = 0 
		    AND b.custid <> 0
		    AND b.transdate >= @thedaybefore AND transdate < @today

	SET NOCOUNT OFF
END

GO


