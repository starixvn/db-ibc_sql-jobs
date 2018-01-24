ALTER procedure [dbo].[Task_Missing_Dummy3rdAcc_Check] @DateCheck datetime
	, @IsDebug bit = 0
as
/*   
 Task : Check Sum missing dummy 3rd acc
 DB: DB054.bodb_PlaytechCS
 Revisions:
	- Patrick : initial SP
	- 20180122@Sophia: Add Exchange product, check dummy by new way [Redmine: #89799]
*/  

begin
	set nocount on
	WAITFOR DELAY '000:10:00'   --- wait for the Job insert data from raw tables from API into bettrans table Done
	
	declare @MissingData table (productName varchar(100), LicenseeName varchar(200), currency varchar(50))
	declare @MissingSumData table (productName varchar(100), LicenseeName varchar(200), currency varchar(50), winlostdate date)

	declare @fromDate smalldatetime
	set @fromDate = @DateCheck--dateadd(day, -2, @DateCheck)
	
	DECLARE @DummyCust AS TABLE (CustID INT, LicenseeName Varchar(200), CurrencyName Varchar(50))
	
	;WITH M  AS ( SELECT custid , site, e.currency
				FROM bodb02.dbo.Customer c WITH (NOLOCK) 
				INNER JOIN bodb02.dbo.Exchange (NOLOCK) e ON E.exchangeId = c.currency 
				WHERE Username LIKE '%Acc%' AND Roleid=3 
				) 	
	INSERT INTO @DummyCust (CustID, LicenseeName, CurrencyName )
	SELECT	c.CustId, M.site, M.Currency
	FROM	bodb02.dbo.customer c with(nolock)
	INNER JOIN M ON M.CustID = C.mrecommend
	WHERE   username LIKE '%Dummy3rd%'
			AND roleid = 1
			
			
	insert into @MissingData(productName, LicenseeName, currency)		
	select 'AG Casino' as productName, LicenseeName, currency
	from (
		select l.LicenseeName, e.currency, b.custID
		from dbo.bettrans_AGCasino b with(nolock)
			inner join bodb_licensee.dbo.LicenseeCust lc with(nolock) on b.recommend = lc.custid
			inner join bodb_licensee.dbo.Licensees l with(nolock) on lc.LicenseeID = l.LicenseeId
			inner join bodb02.dbo.Exchange e with(nolock) on lc.currency = e.exchangeId
		where b.winlostdate = @DateCheck
		group by l.LicenseeName, e.currency, b.custID
	) t where not exists (select top 1 1 from @DummyCust ci where ci.LicenseeName = t.LicenseeName AND ci.Currencyname = t.Currency)

	insert into @MissingData(productName, LicenseeName, currency)
	select 'Gold Deluxe' as productName, LicenseeName, currency
	from (
		select l.LicenseeName, e.currency, b.custID
		from dbo.bettrans_GoldDeluxe b with(nolock)
			inner join bodb_licensee.dbo.LicenseeCust lc with(nolock) on b.recommend = lc.custid
			inner join bodb_licensee.dbo.Licensees l with(nolock) on lc.LicenseeID = l.LicenseeId
			inner join bodb02.dbo.Exchange e with(nolock) on lc.currency = e.exchangeId
		where b.winlostdate = @DateCheck
		group by l.LicenseeName, e.currency, b.custID
	) t where not exists (select top 1 1 from @DummyCust ci where ci.LicenseeName = t.LicenseeName AND ci.Currencyname = t.Currency)
	
	insert into @MissingData(productName, LicenseeName, currency)
	select 'Exchange' as productName, LicenseeName, currency
	from (
		select l.LicenseeName, e.currency, b.custID
		from bodb_3rdProduct.dbo.sum_winloss_exchange b with(nolock)
			INNER JOIN bodb_licensee.dbo.LicenseeCustinfo d With (NOLOCK) ON d.CustID = B.CustID
			inner join bodb_licensee.dbo.LicenseeCust lc with(nolock) on d.recommend = lc.custid
			inner join bodb_licensee.dbo.Licensees l with(nolock) on lc.LicenseeID = l.LicenseeId
			inner join bodb02.dbo.Exchange e with(nolock) on lc.currency = e.exchangeId
		where CONVERT(Date,b.SettledDate) = @DateCheck
		group by l.LicenseeName, e.currency, b.custID
	) t where not exists (select top 1 1 from @DummyCust ci where ci.LicenseeName = t.LicenseeName AND ci.Currencyname = t.Currency)
	
	

	insert into @MissingSumData(productName, LicenseeName, currency, winlostdate)
	select 'AG Casino' as productName, LicenseeName, currency, t.Winlostdate
	from (
		select l.LicenseeName, e.currency, Winlostdate
		from dbo.bettrans_AGCasino b with(nolock)
			inner join bodb_licensee.dbo.LicenseeCust lc with(nolock) on b.recommend = lc.custid
			inner join bodb_licensee.dbo.Licensees l with(nolock) on lc.LicenseeID = l.LicenseeId
			inner join bodb02.dbo.Exchange e with(nolock) on lc.currency = e.exchangeId
		where b.winlostdate between @fromDate and @DateCheck
		group by l.LicenseeName, e.currency, Winlostdate
	) t where not exists ( 	select top 1 1 
							from bodb02.dbo.bettrans ci with(nolock) 
							INNER JOIN @DummyCust D	ON D.CustID = ci.CustID
							where ci.winlostdate = t.Winlostdate and bettype = 1800
								AND d.LicenseeName = t.LicenseeName
								AND d.CurrencyName = t.currency
							)

	insert into @MissingSumData(productName, LicenseeName, currency, winlostdate)
	select 'Gold Deluxe' as productName, LicenseeName, currency, @DateCheck
	from (
		select l.LicenseeName, e.currency, Winlostdate
		from dbo.bettrans_GoldDeluxe b with(nolock)
			inner join bodb_licensee.dbo.LicenseeCust lc with(nolock) on b.recommend = lc.custid
			inner join bodb_licensee.dbo.Licensees l with(nolock) on lc.LicenseeID = l.LicenseeId
			inner join bodb02.dbo.Exchange e with(nolock) on lc.currency = e.exchangeId
		where b.winlostdate between @fromDate and @DateCheck
		group by l.LicenseeName, e.currency, Winlostdate
	) t where not exists  ( select top 1 1 
							from bodb02.dbo.bettrans ci with(nolock) 
							INNER JOIN @DummyCust D	ON D.CustID = ci.CustID
							where ci.winlostdate = t.Winlostdate and bettype = 1700
								AND d.LicenseeName = t.LicenseeName
								AND d.CurrencyName = t.currency
							)
							
	insert into @MissingSumData(productName, LicenseeName, currency, winlostdate)
	select 'Exchange' as productName, LicenseeName, currency, @DateCheck
	from (
		select l.LicenseeName, e.currency, CONVERT(Date,b.SettledDate) as Winlostdate 
		from bodb_3rdProduct.dbo.sum_winloss_exchange b with(nolock)
			INNER JOIN bodb_licensee.dbo.LicenseeCustinfo d With (NOLOCK) ON d.CustID = B.CustID
			inner join bodb_licensee.dbo.LicenseeCust lc with(nolock) on d.recommend = lc.custid
			inner join bodb_licensee.dbo.Licensees l with(nolock) on lc.LicenseeID = l.LicenseeId
			inner join bodb02.dbo.Exchange e with(nolock) on lc.currency = e.exchangeId
		where CONVERT(Date,b.SettledDate) between @fromDate and @DateCheck
		group by l.LicenseeName, e.currency, CONVERT(Date,b.SettledDate) 
	) t where not exists  ( select top 1 1 
							from bodb02.dbo.bettrans ci with(nolock) 
							INNER JOIN @DummyCust D	ON D.CustID = ci.CustID
							where ci.winlostdate = t.Winlostdate and bettype = 8000
								AND d.LicenseeName = t.LicenseeName
								AND d.CurrencyName = t.currency
							)



	declare @email_body nvarchar(max), @subject nvarchar(200), @RowData varchar(max), @hasError bit = 0

	set @email_body = '
		<html>
			<body>
  			<style>
				table {border-collapse: collapse;}
				table, td, th {border: 1px solid black;}
				/*tr:nth-child(even) {background-color: #f2f2f2}*/
				th {text-align: left; padding: 8px;}
				/*th {background-color: #4CAF50; color: white;}*/
			</style>

			<h1>Missing Dummy 3rd Account Check!</h1>
			<p><b>Check time: ' + convert(varchar(50), getdate(), 121) + '</p>
			<div style="background-color:red;color:white;text-align:center">Failure</div>
    
			<p></p>
            {<table1>}
            {<table2>}
			</body>
		</html>'

	SELECT @subject	= N'Missing Dummy 3rd Account Check - KBT@' + @@SERVERNAME

	if exists (select top 1 1 from @MissingData)
	begin
		--send out the mail to notify
		declare @table1 varchar(max)
		set @table1 = '<p> Missing dummy 3rd account </p>
			<table>
				<tr>
				<th style="text-align:center">Product Name</th>
				<th style="text-align:center">Licensee Name</th>
				<th style="text-align:center">Currency</th>
				</tr>
				{<row>}
			</table>'

		SET @RowData = CONVERT(VARCHAR(MAX), (SELECT productName AS 'td1'
													, LicenseeName AS 'td2'
													, currency AS 'td1'
												FROM @MissingData
												ORDER BY productName, LicenseeName 
											   FOR XML PATH('tr'), TYPE
											  ))    
		SET  @RowData = REPLACE(REPLACE(@RowData, 'td1>', 'td>'), 'td2>', 'td>')
		SET @table1 = REPLACE(@table1, '{<row>}', @RowData)
		SET @email_body = REPLACE(@email_body, '{<table1>}', @table1)
		set @hasError = 1
	end
	else
	begin
		set @email_body = REPLACE(@email_body, '{<table1>}', '')
	end

	if exists (select top 1 1 from @MissingSumData)
	begin
		declare @table2 varchar(max)
		set @table2 = '<hr />
            <p> Missing sum data to bettrans for dummy 3rd account </p>
            <table>
				<tr>
				<th style="text-align:center">Product Name</th>
				<th style="text-align:center">Licensee Name</th>
				<th style="text-align:center">Currency</th>
                <th style="text-align:center">Winlost Date</th>
				</tr>
				{<row>}
			</table>'

		SET @RowData = CONVERT(VARCHAR(MAX), (SELECT productName AS 'td1'
													, LicenseeName AS 'td2'
													, currency AS 'td1'
													, WinlostDate AS 'td2'
												FROM @MissingSumData
												ORDER BY productName, LicenseeName 
											   FOR XML PATH('tr'), TYPE
											  ))    
		set  @RowData = REPLACE(REPLACE(@RowData, 'td1>', 'td>'), 'td2>', 'td>')
		set @table2 = REPLACE(@table2, '{<row>}', @RowData)
		set @email_body = REPLACE(@email_body, '{<table2>}', @table2)
		set @hasError = 1
	end
	else
	begin
		set @email_body = REPLACE(@email_body, '{<table2>}', '')
	end
	
	
	IF @IsDebug = 0 and @hasError = 1
	BEGIN
		EXECUTE msdb.dbo.sp_send_dbmail @profile_name	= DEFAULT
			, @recipients			 = 'pontus@starixsoft.com'
			, @copy_recipients		 = ''
			, @blind_copy_recipients	 = ''
			, @subject				 = @subject
			, @body					 = @email_body
			, @body_format			 = 'HTML';
	END

	if @IsDebug = 1
	BEGIN
		SELECT @email_body AS '@email_body'
	END
END

