USE [bodb02]
GO
/****** Object:  StoredProcedure [dbo].[DBA_CheckRunningTickets]    Script Date: 1/20/2016 3:30:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
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
-- 20160118@Sophia: check translog have running tickets of Cockfigting everyday (@vendorID = 8)

	declare @today smalldatetime , @ErrorMsg Varchar(50) , 
	@ErrorCode tinyint , @RDOwner Varchar(30) , @MailTo Varchar(70)
	SET @today = convert(varchar(10), GETDATE(), 120)
	SET @ErrorCode = 0
	SET @ErrorMsg = ''

IF @vendorID = 1 	
BEGIN	
	IF EXISTS (select translogid from translog with (nolock) where winlostdate < @today and statusID = 0 and  vendorID = 1 )
	BEGIN
		SET @ErrorMsg ='JOB FAILED : Keno Have running tickets'
		SET @ErrorCode = 1
		SET @RDOwner = 'Please Call Austin Check Mail'
	END
END

IF @vendorID = 2 	
BEGIN	
	IF EXISTS (select translogid from translog with (nolock) where winlostdate < @today and statusID = 0 and  vendorID = 2 )
	BEGIN
		SET @ErrorMsg ='JOB FAILED : GD Have running tickets'
		SET @ErrorCode = 2
		SET @RDOwner = 'Please Call Tony Check Mail'
	END
END

IF @vendorID = 3	
BEGIN	
	IF EXISTS (select translogid from translog with (nolock) where winlostdate < @today and statusID = 0 and  vendorID = 3 )
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
	IF EXISTS (select translogid from translog with (nolock) where winlostdate < @today and statusID = 0 and vendorID = 8  and currency <> 20 )
	BEGIN
		SET @ErrorMsg ='JOB FAILED : Cockfighting have running tickets'
		SET @ErrorCode = 6
		SET @RDOwner = 'Please Call Tony Check Mail'
	END
END

		IF @ErrorMsg <> ''
		BEGIN

		select @vendorID as vendorID into ##vendorID 
		select @MailTo = Case 
			when @ErrorCode = 1 then ''
			when @ErrorCode = 2 then ''
			when @ErrorCode = 3 then ''
			when @ErrorCode = 4 then''
			end 


			EXEC msdb..sp_send_dbmail
			@recipients = @MailTo,
			@subject = @ErrorMsg,
			@query = '	print ''''
						print ''Translog Data'';
						select translogid,TranId3rd from bodb02.dbo.translog with (nolock) 
						where winlostdate < convert(varchar(10), GETDATE(), 120)
						and statusID = 0 and vendorID in (select vendorID from ##vendorID  ) ',
			@body= @RDOwner

			Print 'Send Mail'

			Drop table ##vendorID 

		End


		

