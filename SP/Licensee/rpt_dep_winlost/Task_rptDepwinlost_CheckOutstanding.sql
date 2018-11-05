/*<info serverAlias="DBRPT-bodb_Report" executers="" viewers="" isFunction="0" isNested="0"></info>*/
USE [bodb_Report]
GO

ALTER PROCEDURE [dbo].[Task_rptDepwinlost_CheckOutstanding]
AS

/*
	Created: Jim
	Date: 2016-08-26
	Task: Check Invalid Outstanding
	DB: DBRPT/bodb_report

	Revisions:
		- 20181031@Percy: Remove linked-server DBLIC [RedmineID: #103660]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @Body VARCHAR(MAX)
			,@TableHead VARCHAR(MAX)
			,@TableTail VARCHAR(MAX)
			,@CurrentDate DATETIME
			,@BeginDate  DATETIME
			,@Date 		 DATETIME

	SET @TableTail = '</table></body></html>';
	--HTML layout--
	SET @TableHead = '<html><head>' +
	'<H1 style="color: #000000">Pending Fund Ticket List Out (rptDepWinlost)</H1>' +
	'<style>' +
	'td {border: solid black 1px;padding-left:5px;padding-right:5px;padding-top:1px;padding-bottom:1px;font-size:9pt;color:Black;} ' +
	'</style>' +
	'</head>' +
	'<body><table cellpadding=0 cellspacing=0 border=0>' +
	'<tr bgcolor=#F6AC5D>'+
	'<td align=center><b>WinlostDate</b></td>' +
	'<td align=center><b>LicenseeName</b></td>' +
	'<td align=center><b>Recommend</b></td>' +
	'<td align=center><b>CustID</b></td>' +
	'<td align=center><b>Outstanding</b></td></tr>';

	SELECT 
			@CurrentDate = DATEADD (D,-1,GETDATE())
		   ,@BeginDate   = MAX(Winlostdate)
	FROM dbo.rptDepwinlost_SUM WITH (NOLOCK)	   

	SET @BeginDate = DATEADD(D,1,@BeginDate)
	IF @BeginDate > @CurrentDate
		RETURN;	
	
	DECLARE @LicenseeCust AS TABLE (LicenseeName VARCHAR(20) ,CustID INT)	  
	DECLARE @tmpTrans AS TABLE (Winlostdate DATETIME ,CustID INT,Outstanding MONEY)
	DECLARE @tmpTrans_fi AS TABLE (Winlostdate DATETIME ,CustID INT,Outstanding MONEY)
	DECLARE @Data AS TABLE (Winlostdate DATETIME, Recommend INT,CustID INT, Outstanding MONEY)		

	INSERT INTO @Data (Winlostdate, Recommend,CustID, Outstanding)		
	SELECT WinlostDate  
		   ,Recommend
		   ,CustID
		   ,Outstanding
	FROM dbo.rptDepWinlost WITH (NOLOCK)
	WHERE winlostdate BETWEEN @BeginDate AND @CurrentDate	
		  AND ISNULL(Outstanding,0) <> 0

	IF @@ROWCOUNT =0
	RETURN
	  
	INSERT INTO @tmpTrans (Winlostdate,CustID,Outstanding )
	SELECT Winlostdate
		   ,CustID 
		   ,SUM(actual_stake) Outstanding
	FROM bodb02.dbo.bettrans WITH (NOLOCK)
	WHERE Winlostdate BETWEEN @BeginDate AND @CurrentDate	
		AND  (bettype < 19999 OR bettype = 23002) 
		AND ruben=0
		AND CustID IN (SELECT CustID FROM @Data)
	GROUP BY  Winlostdate
			 ,CustID 	

	INSERT INTO @tmpTrans (Winlostdate,CustID,Outstanding )
	SELECT Winlostdate
		   ,CustID 
		   ,SUM(actual_stake) Outstanding
	FROM bodb02.dbo.translog WITH (NOLOCK)
	WHERE Winlostdate BETWEEN @BeginDate AND @CurrentDate
		  AND productID IN (202,203)   		 
		  AND statusID IN (0,1)
		  AND CustID IN (SELECT CustID FROM @Data)	
	GROUP BY Winlostdate
			 ,CustID

	INSERT INTO @tmpTrans (Winlostdate,CustID,Outstanding )
	SELECT Winlostdate
		   ,CustID 
		   ,SUM(actual_stake) Outstanding
	FROM bodb02.dbo.bettransRnG WITH (NOLOCK)
	WHERE Winlostdate BETWEEN @BeginDate AND @CurrentDate
		  AND statusID IN (0,1)
		  AND CustID IN (SELECT CustID FROM @Data)	
	GROUP BY Winlostdate
			 ,CustID

	INSERT INTO @tmpTrans (Winlostdate,CustID,Outstanding )
	SELECT Winlostdate
		   ,CustID 
		   ,SUM(actual_stake) Outstanding
	FROM bodb02.dbo.bettransLC WITH (NOLOCK)
	WHERE Winlostdate BETWEEN @BeginDate AND @CurrentDate
		  AND statusID IN (0,1)
		  AND CustID IN (SELECT CustID FROM @Data)	
	GROUP BY Winlostdate
			 ,CustID

	INSERT INTO @tmpTrans_fi (Winlostdate,CustID,Outstanding )
	SELECT Winlostdate
		   ,CustID 
		   ,SUM(Outstanding) Outstanding
	FROM 	@tmpTrans   
	GROUP BY Winlostdate
		   ,CustID 
	   
	DELETE d
	FROM @Data d 
		 INNER JOIN @tmpTrans_fi f ON d.Winlostdate = f.Winlostdate
								   AND d.CustID = f.CustID
								   AND d.Outstanding = f.Outstanding
	IF NOT EXISTS (SELECT TOP 1 1 FROM @Data)							   
	RETURN;

	INSERT INTO  @LicenseeCust (LicenseeName, CustID )	  
	SELECT DISTINCT l.LicenseeName,lc.CustID
	FROM bodb_licensee.dbo.LicenseeCust lc WITH (NOLOCK)
		INNER JOIN bodb_licensee.dbo.Licensees l WITH (NOLOCK) ON l.LicenseeID = lc.licenseeID
	WHERE lc.CustID IN (SELECT Recommend FROM @Data)	
 
	--Select information for the Report-- 
	SELECT @Body=  (SELECT 
					CONVERT(Date,d.Winlostdate) AS [TD],
					lc.LicenseeName AS [TD],	
					d.Recommend     AS [TD],
					d.CustID        AS [TD],
					d.Outstanding   AS [TD] 

	FROM @Data d
	INNER JOIN @LicenseeCust lc ON d.Recommend = lc.CustID
	ORDER BY Lc.LicenseeName ASC,d.Winlostdate DESC	
	For XML raw('tr'), Elements)

	-- Replace the entity codes and row numbers
	SET @Body = Replace(@Body, '_x0020_', space(1))
	SET @Body = Replace(@Body, '_x003D_', '=')
	SET @Body = Replace(@Body, '<tr><TRRow>1</TRRow>', '<tr bgcolor=#C6CFFF>')
	SET @Body = Replace(@Body, '<TRRow>0</TRRow>', '')
	SET @Body = @TableHead + @Body + @TableTail
 
	-- return output--
	-- select @body	
	--Email
	IF ISNULL(@Body,'') <> ''
	BEGIN
		DECLARE @profile_name SYSNAME
		SELECT TOP (1) @profile_name = name FROM MSDB.dbo.sysmail_profile

		EXEC msdb.dbo.sp_send_dbmail
			@profile_name= @profile_name
			,@recipients='don.pham@starixsoft.com'
			,@copy_recipients='jim.tran@starixsoft.com'
			,@subject='Invalid Pending fund ticket on table rptDepWinlost'
			,@body= @Body
			,@body_format = 'HTML'
	END
END
GO