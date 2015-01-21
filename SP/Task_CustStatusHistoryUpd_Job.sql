USE [bodb_Report]
GO

/****** Object:  StoredProcedure [dbo].[Task_CustStatusHistoryUpd_Job]    Script Date: 01/21/2015 01:49:26 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[Task_CustStatusHistoryUpd_Job]
AS
/*    
	Created: 20130720@Lukas
	Task: record customer status 
	DB: DBACC/bodb_report	  
	
	Revisions:     
	
	Param's Explanation:	
*/    
BEGIN
	SET NOCOUNT ON 
	
	DECLARE @maxCustID INT,
			@maxHistory INT
	
	SELECT @maxCustID = ISNULL(MAX(custid),0)
	FROM bodb02.dbo.custinfo WITH(NOLOCK)
	
	SELECT @maxHistory = ISNULL(MAX(custid),0)
	FROM CustStatusHistory WITH(NOLOCK)
	
	-- check for new customers
	IF EXISTS (	SELECT TOP 1 1 
				FROM bodb02.dbo.custinfo WITH(NOLOCK) 
				WHERE custid > @maxHistory AND custid <= @maxCustID
					AND srecommend NOT IN (SELECT custid FROM bodb02.dbo.f_depsuper_1('ALL'))
					AND roleid IN (2,3,4)
			   )
	BEGIN
		INSERT INTO CustStatusHistory
		SELECT custid, 0, 0, 0
		FROM bodb02.dbo.custinfo WITH(NOLOCK)
		WHERE custid > @maxHistory AND custid <= @maxCustID
			AND srecommend NOT IN (SELECT custid FROM bodb02.dbo.f_depsuper_1('ALL'))
			AND roleid IN (2,3,4)
	END
	
	/* record yesterday customer status */
	DECLARE @onDay INT,
			@yesterday DATETIME
	
	-- get day record
	SET @yesterday = DATEADD(DAY,-1,GETDATE())   
	
	-- position start: bit 0
	SET @onDay = POWER(2,DAY(@yesterday)-1)      	
	
	IF DATEPART(DAY,@yesterday) =  1  -- when record for 1st day of a month
	BEGIN
		-- archive data of last month
		INSERT INTO CustStatusHistory_bk(custid, enabled, reject,closed, arcdate)
		SELECT custid , enabled, reject, closed, CONVERT(VARCHAR(20),DATEADD(DAY,-1,@yesterday),110)
		FROM CustStatusHistory WITH(NOLOCK)
		WHERE custid <= @maxHistory
		
		-- reset & set yesterday status
		UPDATE csh WITH(ROWLOCK,UPDLOCK)
		SET	reject  = @onDay*c.reject, 
			closed  = @onDay*c.closed,
			enabled = @onDay*c.enabled
		FROM CustStatusHistory csh 
			INNER JOIN bodb02.dbo.custinfo c WITH(NOLOCK) ON csh.custid = c.custid		
	END
	ELSE	-- set yesterday status
	BEGIN
		UPDATE csh WITH(ROWLOCK,UPDLOCK)
		SET	reject  = csh.reject | @onDay*c.reject, 
			closed  = csh.closed | @onDay*c.closed,
			enabled = csh.enabled | @onDay*c.enabled
		FROM CustStatusHistory csh 
			INNER JOIN bodb02.dbo.custinfo c WITH(NOLOCK) ON csh.custid = c.custid
	END	
END

GO


