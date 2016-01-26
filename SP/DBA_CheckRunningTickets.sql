ALTER PROCEDURE [dbo].[DBA_CheckRunningTickets]
@vendorID tinyint
AS
-- 20140310@Vivi: check translog have running tickets everydate
-- 20150604@Victor: check GD have running tickets everydate
-- 20150724@Victor: check MG have running tickets everydate
-- 20150811@Victor: check SuperLive have running tickets everydate
-- 20150922@Victor: add if have running ticket mail to RD
-- 20150923@Victor: add return ticket info translogid,TranId3rd
-- 20151110@Sylvia: check CB have running tickets everydate
-- 20151119@Sylvia: add where confition for CB to filter UUS tickets

	declare @today smalldatetime ,@2day smalldatetime , @ErrorMsg Varchar(50) , 
	@ErrorCode tinyint , @RDOwner Varchar(30) , @MailTo Varchar(70)
	SET @today = convert(varchar(10), GETDATE(), 120)
	SET @2day = convert(varchar(10), GETDATE()-7, 120)
	SET @ErrorCode = 0
	SET @ErrorMsg = ''

IF @vendorID = 1 	
BEGIN	
	IF EXISTS (select translogid from translog with (nolock) where winlostdate < @today and statusID = 0 and  vendorID = 1 and currency <> 20 )
	BEGIN
		SET @ErrorMsg ='JOB FAILED : Keno Have running tickets'
		SET @ErrorCode = 1
		SET @RDOwner = 'Please Call Austin Check Mail'
	END
END

IF @vendorID = 2 	
BEGIN	
	IF EXISTS (select translogid from translog with (nolock) where winlostdate < @today and statusID = 0 and  vendorID = 2 and currency <> 20 )
	BEGIN
		SET @ErrorMsg ='JOB FAILED : GD Have running tickets'
		SET @ErrorCode = 2
		SET @RDOwner = 'Please Call Tony Check Mail'
	END
END

IF @vendorID = 3	
BEGIN	
	IF EXISTS (select transid from bettransRNG with (nolock) where winlostdate < @2day and statusID = 0 and  vendorID = 3 and currency <> 20 )
	BEGIN
		SET @ErrorMsg ='JOB FAILED : MG Have running tickets'
		SET @ErrorCode = 3
		SET @RDOwner = 'Please Call Walter Check Mail'
	END
END

IF @vendorID = 4	
BEGIN	
	IF EXISTS (select translogid from translog with (nolock) where winlostdate < @today and statusID = 0 and  vendorID = 4 and currency <> 20 )
	BEGIN
		SET @ErrorMsg ='JOB FAILED : CB Have running tickets'
		SET @ErrorCode = 4
		SET @RDOwner = 'Please Call Tony/Austin Check Mail'
	END
END

IF @vendorID = 5 	
BEGIN	
	IF EXISTS (select translogid from translog with (nolock) where winlostdate < @today and statusID = 0 and  vendorID = 5  and currency <> 20 )
	BEGIN
		SET @ErrorMsg ='JOB FAILED : SuperLive Have running tickets'
		SET @ErrorCode = 2
		SET @RDOwner = 'Please Call Tony Check Mail'
	END
END

IF @vendorID = 8 	
BEGIN	
	IF EXISTS (select translogid from translog with (nolock) where winlostdate < @today and statusID = 0 and  vendorID = 8  and currency <> 20 )
	BEGIN
		SET @ErrorMsg ='JOB FAILED : Cockfighting Have running tickets'
		SET @ErrorCode = 2
		SET @RDOwner = 'Please Call Tony Check Mail'
	END
END

IF @vendorID = 10	
BEGIN	
	IF EXISTS (select transid from bettransRNG with (nolock) where winlostdate < @2day and statusID = 0 and  vendorID = 10  and currency <> 20 )
	BEGIN
		SET @ErrorMsg ='JOB FAILED : One RNG Have running tickets'
		SET @ErrorCode = 5
		SET @RDOwner = 'Please Call Johnny Check Mail'
	END
END




		IF @ErrorMsg <> ''
		BEGIN

		select @vendorID as vendorID into ##vendorID 
		select @MailTo = Case 
			when @ErrorCode = 1 then 'DBATW@onelab.tw ; austin.su@onelab.tw'
			when @ErrorCode = 2 then 'DBATW@onelab.tw ; tony.yu@onelab.tw ; sobi.chen@onelab.tw'
			when @ErrorCode = 3 then 'DBATW@onelab.tw ; walter.hsu@onelab.tw'
			when @ErrorCode = 4 then 'DBATW@onelab.tw ; tony.yu@onelab.tw ; austin.su@onelab.tw'  
			when @ErrorCode = 5 then 'DBATW@onelab.tw ; johnny.yang@onelab.tw'
			end 

			IF @vendorID in (1,2,4,5,8)
			Begin
				EXEC msdb..sp_send_dbmail
				@recipients = @MailTo,
				@subject = @ErrorMsg,
				@query = '	print ''''
							print ''Translog Data'';
							select translogid,TranId3rd from bodb02.dbo.translog with (nolock) 
							where winlostdate < convert(varchar(10), GETDATE(), 120)
							and statusID = 0 and vendorID in (select vendorID from ##vendorID  ) ',
				@body= @RDOwner
			End


			IF @vendorID in (3,10)
			Begin
				EXEC msdb..sp_send_dbmail
				@recipients = @MailTo,
				@subject = @ErrorMsg,
				@query = '	print ''''
							print ''BettransRNG Data'';
							select transid,TranId3rd from bodb02.dbo.BettransRNG with (nolock) 
							where winlostdate < convert(varchar(10), GETDATE(), 120)
							and statusID = 0 and vendorID in (select vendorID from ##vendorID  ) ',
				@body= @RDOwner
			End

			Print 'Send Mail'

			Drop table ##vendorID 

		End


		

