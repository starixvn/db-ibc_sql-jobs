/*<info serverAlias="DBTXN-bodb02" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Task_Execute_TicketVoiding_RoutineTasks]
(
	 @stepNo		TINYINT,
	 @custIDs		VARCHAR(MAX) = '', 
	 @winlostdate	DATETIME,
	 @errmsg		VARCHAR(1000) = '' OUTPUT
)
AS
/*
	Created: 20190906@Lukas
	Task: routine task after void/recover tickets in bet14 - execute the task case by case 
	DB: DBTXN.bodb02

	Revisions:
		- 20190906@Lukas: Initialize SP [RedmineID: #115377]
		- 20191210@Bobby: Integrate Saba Promotion  [RedmineID: #115377]
			+ Added step 6.94: DBLIC.bodb_LicenseeReport.dbo.Task_DailySummaryLicPromotion_Bettrans14
		- 20201019@Sol: LAP - Licensee Spread Setting - Added new step 1.2 - Calculate original licensee winlost - [RedmineID: #142532]
		- 20200106@Sol: Recover/Void - add missing sub-steps to step 6 - [RedmineID: #148325]
		- 20220422@Sol: LAP - Enhance database jobs - [RedmineID: #171747]
		- 20220805@Sol: LAP - Scale out DBTrans phase 1 - Check siteDB or central to run specific code - [RedmineID: #175297]
		- 20230522@Lewis: Database - Abnormal Account - call sum Sps on other servers - [RedmineID: #188463]
		- 20230612@Evan: remove code related to Saba Promotion report - [RedmineID: #189234]
		- 20220603@Sol: Database - Sync-up Standby Server data - [RedmineID: #167261]
		- 20230629@Sol: Database - Sync-up Standby Server data - exclude step 7/8 (logshipping synced) - [RedmineID: #190438]
		- 20220614@Danny: Database - scale out credit [RedmineID: #181595]
		- 20230808@Lewis: Change redundant recipient in Reset Winning - notification email [RedmineID: #192448]
		- 20230822@Evan: Integrate Parlay Boost - [RedmineID: #192238]

*/
BEGIN
	DECLARE @GenerateData TINYINT,
			--@localErrmsg VARCHAR(100),
			@result VARCHAR(20),
			@BetTypes VARCHAR(8000)
	
	DECLARE @Subject VARCHAR(1000) = '', @body VARCHAR(MAX) = '', 
			@ProductList VARCHAR(1000)  , @ProductVariance VARCHAR(1000),
			@recipients VARCHAR(MAX), @copy_recipients VARCHAR(MAX), @blind_copy_recipients VARCHAR(MAX)

	DECLARE 
		@alias VARCHAR(100), 
		@sqlCommand VARCHAR(MAX),
		@params VARCHAR(MAX),
		@doNotRunInServer VARCHAR(1000)

	DECLARE @Acc_ResetWinning_SelByDate14 TABLE 
	(
		seq			INT primary key Identity (1,1),
		Winlostdate SMALLDATETIME,
		custid		INT,
		amount		MONEY,
		transdesc	NVARCHAR(1000),
		creator		INT,
		ip			VARCHAR(45),
		WinlostAfterExtraPT MONEY,
		reset       		MONEY,
		product     		VARCHAR(250)
	)

	DECLARE	@WLdate SMALLDATETIME,
			@custid		INT,
			@amount		MONEY,
			@transdesc	NVARCHAR(1000),
			@creator	INT,
			@ip			VARCHAR(45),
			@seq		INT = 1,
			@resetData	VARCHAR(MAX) = '',
			@resetData_XML XML = NULL,
			@resetData1		VARCHAR(8000) = '' ,
			@resetData2		VARCHAR(8000) = '' ,
			@resetData3		VARCHAR(8000) = '' ,
			@resetData4		VARCHAR(8000) = '' ,
			@resetData5		VARCHAR(8000) = '' 

	DECLARE @ResetWinning_ExtraPT14 TABLE 
	(
		seq			INT primary key Identity (1,1),
		WLDate		SMALLDATETIME,
		custID		INT,
		amount		MONEY,
		transdesc	NVARCHAR(1000),
		creator		INT,
		ip			VARCHAR(45)

	)
	DECLARE	@WLdate_ExtraPT SMALLDATETIME,
		@custid_ExtraPT		INT,
		@amount_ExtraPT		MONEY,
		@transdesc_ExtraPT	NVARCHAR(1000),
		@creator_ExtraPT	INT,
		@ip_ExtraPT		VARCHAR(45),
		@seq_ExtraPT		INT = 1,
		@resetData_ExtraPT	VARCHAR(MAX) = '',
		@resetData_ExtraPT_XML XML = NULL,
		@resetData1_ExtraPT		VARCHAR(8000) = '' ,
		@resetData2_ExtraPT		VARCHAR(8000) = '' ,
		@resetData3_ExtraPT		VARCHAR(8000) = '' ,
		@resetData4_ExtraPT		VARCHAR(8000) = '' ,
		@resetData5_ExtraPT		VARCHAR(8000) = '' 
	
	DECLARE @SiteDBGroupID SMALLINT = 0 
	SELECT @SiteDBGroupID = dbo.f_Get_SiteDBGroupID()
	DECLARE @isTest BIT = 0

	DECLARE @SQL NVARCHAR(100) = ISNULL(OBJECT_NAME(@@PROCID),'')
	SELECT @Istest = CASE WHEN @SQL like '%_xtest%' THEN 1 ELSE 0 END

	IF (@SiteDBGroupID <> 0) ---run at SiteDB -> only need exec step 1 at sitedb because it update bettrans14
	BEGIN
		IF @stepNo = 1
		BEGIN
			SET @errmsg = 'step 1.1'
			EXEC bodb02.dbo.Task_Dep_DailySum_OddsAdjustment_14 
				@WinlostDate = @winlostdate,
				@CustIds = @custIDs

			SET @errmsg = 'step 1.2'
			EXEC bodb02.dbo.Task_Dep_DailySum_ParlayBoostAdjust_14 
				@WinlostDate = @winlostdate,
				@CustIds = @custIDs
		END

		IF @stepNo = 5
		BEGIN
			SET @errmsg = 'step 5.1'
			---keep call sp by linked server to DBACC
			IF (	
					@isTest = 0 AND 
					(
						EXISTS (
							SELECT TOP 1 1 
							FROM  DBCUST.CustDB.dbo.Acc_DWLList ad WITH (NOLOCK)  
							INNER JOIN CustDB.dbo.Customer c WITH (NOLOCK)  ON ad.CustID = c.CustID
							INNER JOIN CustDb.dbo.Site s WITH (NOLOCK) ON c.site = s.site
							WHERE ad.IsDeleted = 0   AND s.SiteDBGroupID = @SiteDBGroupID 
							)
						OR 
						EXISTS (
							SELECT TOP 1 1 
							FROM  DBCUST.CustDB.dbo.Acc_DWLList_ExtraPT ad WITH (NOLOCK)  
							INNER JOIN CustDB.dbo.Customer c WITH (NOLOCK)  ON ad.CustID = c.CustID
							INNER JOIN CustDb.dbo.Site s WITH (NOLOCK) ON c.site = s.site
							WHERE s.SiteDBGroupID = @SiteDBGroupID 
							)
				
					)
				)
				OR 
				(
					@isTest = 1 AND 
					(
						EXISTS (
							SELECT TOP 1 1 
							FROM  DBCUST.CustDB.dbo.Acc_DWLList_xtest ad WITH (NOLOCK)  
							INNER JOIN CustDB.dbo.Customer c WITH (NOLOCK)  ON ad.CustID = c.CustID
							INNER JOIN CustDb.dbo.Site s WITH (NOLOCK) ON c.site = s.site
							WHERE ad.IsDeleted = 0   AND s.SiteDBGroupID = @SiteDBGroupID 
							)
						OR 
						EXISTS (
							SELECT TOP 1 1 
							FROM  DBCUST.CustDB.dbo.Acc_DWLList_ExtraPT_xtest ad WITH (NOLOCK)  
							INNER JOIN CustDB.dbo.Customer c WITH (NOLOCK)  ON ad.CustID = c.CustID
							INNER JOIN CustDb.dbo.Site s WITH (NOLOCK) ON c.site = s.site
							WHERE s.SiteDBGroupID = @SiteDBGroupID 
							)
					)
				)
			BEGIN
				EXEC DBACC.bodb02.dbo.Acc_ResetWinning_SelByDate14
					   @Winlostdate = @Winlostdate,
					   @Mode = 1,
					   @SiteDBGroupID = @SiteDBGroupID,
					   @resetData1 = @resetData1 OUTPUT,
					   @resetData2 = @resetData2 OUTPUT,
					   @resetData3 = @resetData3 OUTPUT,
					   @resetData4 = @resetData4 OUTPUT,
					   @resetData5 = @resetData5 OUTPUT

				SELECT @resetData = @resetData1 + @resetData2 + @resetData3 + @resetData4 + @resetData5
				SELECT @resetData_XML = CAST(@resetData AS XML)
				
				INSERT INTO @Acc_ResetWinning_SelByDate14 (Winlostdate, custid, amount, transdesc, creator, ip, WinlostAfterExtraPT, reset, product)
				SELECT 
					t.c.value('@Winlostdate', 'SMALLDATETIME')	AS Winlostdate
					,t.c.value('@custid', 'INT')	AS custid
					,t.c.value('@amount', 'MONEY')	AS amount
					,t.c.value('@transdesc', 'NVARCHAR(1000)')	AS transdesc
					,t.c.value('@creator', 'INT')	AS creator
					,t.c.value('@ip', 'VARCHAR(45)')	AS ip
					,t.c.value('@WinlostAfterExtraPT', 'MONEY')	AS WinlostAfterExtraPT
					,t.c.value('@reset', 'MONEY')	AS reset
					,t.c.value('@product', 'VARCHAR(250)')	AS product
				FROM @resetData_XML.nodes('/ROOT/z') t(c)
				OPTION (OPTIMIZE FOR (@resetData_XML = NULL))

				WHILE EXISTS (SELECT TOP 1 1 FROM @Acc_ResetWinning_SelByDate14 WHERE seq = @seq)
				BEGIN
					SELECT  @WLdate		= Winlostdate,
							@custid		= custid,
							@amount		= amount,
							@transdesc	= transdesc,
							@creator	= creator,
							@ip			= ip
					FROM @Acc_ResetWinning_SelByDate14 WHERE seq = @seq

					EXEC dbo.Task_ResetWinning_Non3rdParty_Add
							@Winlostdate = @WLdate,
							@custid = @custid,
							@amount = @amount,
							@transdesc = @transDesc,
							@creator = @creator,
							@ip			= @ip

					SELECT @seq = @seq + 1
				
				END

				-- Send email
				IF EXISTS (SELECT TOP 1 1 FROM @Acc_ResetWinning_SelByDate14)
				BEGIN
					SELECT @ProductList = COALESCE(@ProductList + ', ', '') + Product,
						   @ProductVariance = COALESCE(@ProductVariance + ', ', '') + Product +' : '
											+  CONVERT(VARCHAR(100),	ISNULL( (-(ISNULL(r.WinlostAfterExtraPT, 0)) - ISNULL(r.reset, 0)),0) )
											+ ' RM'
					FROM  @Acc_ResetWinning_SelByDate14 r
					WHERE ISNULL( (-(ISNULL(r.WinlostAfterExtraPT, 0)) - ISNULL(r.reset, 0)),0) <> 0
				 					 
					SELECT @Subject = 'Reset Winning report changed on ' + CONVERT(VARCHAR(20),@Winlostdate, 107)
					
					SELECT @body = 'Dear Ah Wan, </br> 
									Kindly be informed that the Reset Winning report has been changed on '+ CONVERT(VARCHAR(20),@Winlostdate, 107) + '</br>
									Time of Reset Winning: '+ CONVERT(VARCHAR(20),Getdate(),109) +' (GMT-4) </br></br> 

									Product: '+ @ProductList + ' </br> </br> 

									Reason: void/recovered tickets </br> 
									Variance: '+ @ProductVariance + '</br> 
									Performed by IT. </br></br>  

									Best regards, </br> 
									This is an auto-mail from ONEworks Report System. Please do not reply.'									 
										
					IF @Istest = 0 AND @@SERVERNAME IN ('DBGRP01N1','DBGRP01N2','DBGRP02N1','DBGRP02N2','DBGRP03N1','DBGRP03N2','DBTRANS')
						SELECT	@recipients = 'kudanaga@enpine.com'
								,@copy_recipients = 'jetyee88@enpine.com;kwongyong@enpine.com;seanlau@enpine.com;tp@enpine.com;it@starixsoft.com;jackyting@enpine.com;vh@enpine.com'
								,@blind_copy_recipients = 'automail@enpine.com'
					ELSE
						SELECT  @recipients = 'dba_local@starixsoft.com'
								,@copy_recipients = ''
								,@blind_copy_recipients = ''
					
					EXEC msdb.dbo.sp_send_dbmail
						@recipients = @recipients
						, @copy_recipients = @copy_recipients
						, @blind_copy_recipients = @blind_copy_recipients
						, @subject = @subject
						, @body = @body
						, @body_format = 'HTML' 
				END
			END

			-------------------------
			SET @errmsg = 'step 5.2'
			---keep call sp by linked server to DBACC
			IF (
					@isTest = 0 
					AND EXISTS (
						SELECT TOP 1 1 
						FROM  DBCUST.CustDB.dbo.Acc_DWLList_ExtraPT e WITH (NOLOCK)
						INNER JOIN CustDB.dbo.Customer c WITH (NOLOCK) ON e.CustID = c.CustID
						INNER JOIN CustDb.dbo.Site s WITH (NOLOCK) ON c.site = s.site
						WHERE e.IsDisabled = 0   AND s.SiteDBGroupID = @SiteDBGroupID
						)
				)
				OR
				(
					@isTest = 1
					AND EXISTS (
						SELECT TOP 1 1 
						FROM  DBCUST.CustDB.dbo.Acc_DWLList_ExtraPT_xtest e WITH (NOLOCK)
						INNER JOIN CustDB.dbo.Customer c WITH (NOLOCK) ON e.CustID = c.CustID
						INNER JOIN CustDb.dbo.Site s WITH (NOLOCK) ON c.site = s.site
						WHERE e.IsDisabled = 0   AND s.SiteDBGroupID = @SiteDBGroupID
						)
				)
			BEGIN
				
				EXEC DBACC.bodb02.dbo.Task_ResetWinning_ExtraPT14
				  @FromDate= @WinlostDate,
				  @ToDate = @WinlostDate,
				  @Mode = 1	,
				  @SiteDBGroupID = @SiteDBGroupID,
				  @resetData1 = @resetData1_ExtraPT OUTPUT,
				  @resetData2 = @resetData2_ExtraPT OUTPUT,
				  @resetData3 = @resetData3_ExtraPT OUTPUT,
				  @resetData4 = @resetData4_ExtraPT OUTPUT,
				  @resetData5 = @resetData5_ExtraPT OUTPUT

				SELECT @resetData_ExtraPT = @resetData1_ExtraPT + @resetData2_ExtraPT + @resetData3_ExtraPT + @resetData4_ExtraPT + @resetData5_ExtraPT

				SELECT @resetData_ExtraPT_XML = CAST(@resetData_ExtraPT AS XML)

				INSERT INTO @ResetWinning_ExtraPT14 (WLDate, custID, amount, transdesc, creator, ip)
				SELECT 
					t.c.value('@WLDate', 'SMALLDATETIME')	AS WLDate
					,t.c.value('@CustID', 'INT')	AS custid
					,t.c.value('@amount', 'MONEY')	AS amount
					,t.c.value('@transdesc', 'NVARCHAR(1000)')	AS transdesc
					,t.c.value('@creator', 'INT')	AS creator
					,t.c.value('@ip', 'VARCHAR(45)')	AS ip
				FROM @resetData_ExtraPT_XML.nodes('/ROOT/z') t(c)
				OPTION (OPTIMIZE FOR (@resetData_ExtraPT_XML = NULL))

				WHILE EXISTS (SELECT TOP 1 1 FROM @ResetWinning_ExtraPT14 WHERE seq = @seq_ExtraPT)
				BEGIN
					SELECT @WLdate_ExtraPT		= WLDate,
							@custid_ExtraPT		= custID,
							@amount_ExtraPT		= amount,
							@transdesc_ExtraPT	= transdesc,
							@creator_ExtraPT	= creator,
							@ip_ExtraPT			= ip
					FROM @ResetWinning_ExtraPT14 WHERE seq = @seq_ExtraPT
					
				   EXEC bodb02.dbo.Task_ResetWinning_Non3rdParty_Add
							@winlostdate = @WLdate_ExtraPT,
							@custid = @custid_ExtraPT,
							@amount = @amount_ExtraPT,
							@transdesc = @transdesc_ExtraPT,
							@creator = @creator_ExtraPT,
							@ip = @ip_ExtraPT,
							@isExtraPT = 1

					SELECT @seq_ExtraPT = @seq_ExtraPT + 1
				END
			END
		END
	END
	ELSE --- run at central DB
	BEGIN
		--select @winlostdate, @custIDs
		IF @stepNo = 1
		BEGIN
			SET @errmsg = 'step 1.1'
			EXEC bodb02.dbo.Task_Dep_DailySum_OddsAdjustment_14
					@WinlostDate = @winlostdate,
					@CustIds = @custIDs
			
			SET @errmsg = 'step 1.2'
			EXEC bodb02.dbo.Task_Dep_DailySum_ParlayBoostAdjust_14 
				@WinlostDate = @winlostdate,
				@CustIds = @custIDs

			SET @errmsg = 'step 1.3'
			EXEC bodb02.dbo.Task_sum_winloss_14
					@WinlostDate = @WinlostDate,
					@CustIds = @CustIds 
		
		END
		IF @stepNo = 2
		BEGIN
			SET @errmsg = 'step 2.1'
			EXEC dbo.Get_ServerName_By_Alias @Alias  = 'DBTXN', @ServerName = @doNotRunInServer OUTPUT
	
			SELECT 
				@alias = 'DBSUM', 
				@SqlCommand = CONCAT('EXEC bodb_summary.dbo.Task_CS_SumWinloss_14 ', ' @WinlostDate = ''',CONVERT(VARCHAR(50), @winlostdate, 121),''' ,@CustIds = ''',@CustIds,'''')

			EXEC ExecRep_NAP_Admin_05 @ServerName = '', @AliasName = @alias, @SqlCommand = @SqlCommand, @doNotRunInServer = @doNotRunInServer, @Remark = @errmsg

			SET @errmsg = 'step 2.2'

			SELECT 
				@alias = 'DBSUM', 
				@SqlCommand = CONCAT('EXEC bodb_summary.dbo.Task_CS_SumCancelled_14 ', ' @WinlostDate = ''',CONVERT(VARCHAR(50), @winlostdate, 121),''' ,@CustIds = ''',@CustIds,'''')
			EXEC ExecRep_NAP_Admin_05 @ServerName = '', @AliasName = @alias, @SqlCommand = @SqlCommand, @doNotRunInServer = @doNotRunInServer, @Remark = @errmsg
		END
		IF @stepNo = 3
		BEGIN
			
			SET @errmsg = 'step 3'
			EXEC dbo.Get_ServerName_By_Alias @Alias  = 'DBTXN', @ServerName = @doNotRunInServer OUTPUT 
	
			SELECT 
				@alias = 'DBACC', 
				@SqlCommand = CONCAT('EXEC bodb02.dbo.Task_CS_HeadlineBalance14 ', ' @WinlostDate = ''',CONVERT(VARCHAR(50), @winlostdate, 121),''' ,@CustIds = ''',@CustIds,'''')
			EXEC ExecRep_NAP_Admin_05 @ServerName = '', @AliasName = @alias, @SqlCommand = @SqlCommand, @doNotRunInServer = @doNotRunInServer, @Remark = @errmsg
		END
		IF @stepNo = 4
		BEGIN
			
			SET @errmsg = 'step 4'
			EXEC dbo.Get_ServerName_By_Alias @Alias  = 'DBTXN', @ServerName = @doNotRunInServer OUTPUT
	
			SELECT 
				@alias = 'DBRPT', 
				@SqlCommand = CONCAT('EXEC bodb_report.dbo.Task_rptStatement_14 ', ' @WinlostDate = ''',CONVERT(VARCHAR(50), @winlostdate, 121),''' ,@CustIds = ''',@CustIds,'''')
			EXEC ExecRep_NAP_Admin_05 @ServerName = '', @AliasName = @alias, @SqlCommand = @SqlCommand, @doNotRunInServer = @doNotRunInServer, @Remark = @errmsg
		END
		IF @stepNo = 5
		BEGIN
		
			SET @errmsg = 'step 5.1'
			---keep call sp by linked server to DBACC
			IF (	
					@isTest = 0 AND 
					(
						EXISTS (
							SELECT TOP 1 1 
							FROM  DBCUST.CustDB.dbo.Acc_DWLList ad WITH (NOLOCK)  
							INNER JOIN CustDB.dbo.Customer c WITH (NOLOCK)  ON ad.CustID = c.CustID
							INNER JOIN CustDb.dbo.Site s WITH (NOLOCK) ON c.site = s.site
							WHERE ad.IsDeleted = 0   AND s.SiteDBGroupID = @SiteDBGroupID 
							)
						OR 
						EXISTS (
							SELECT TOP 1 1 
							FROM  DBCUST.CustDB.dbo.Acc_DWLList_ExtraPT ad WITH (NOLOCK)  
							INNER JOIN CustDB.dbo.Customer c WITH (NOLOCK)  ON ad.CustID = c.CustID
							INNER JOIN CustDb.dbo.Site s WITH (NOLOCK) ON c.site = s.site
							WHERE s.SiteDBGroupID = @SiteDBGroupID 
							)
				
					)
				)
				OR 
				(
					@isTest = 1 AND 
					(
						EXISTS (
							SELECT TOP 1 1 
							FROM  DBCUST.CustDB.dbo.Acc_DWLList_xtest ad WITH (NOLOCK)  
							INNER JOIN CustDB.dbo.Customer c WITH (NOLOCK)  ON ad.CustID = c.CustID
							INNER JOIN CustDb.dbo.Site s WITH (NOLOCK) ON c.site = s.site
							WHERE ad.IsDeleted = 0   AND s.SiteDBGroupID = @SiteDBGroupID 
							)
						OR 
						EXISTS (
							SELECT TOP 1 1 
							FROM  DBCUST.CustDB.dbo.Acc_DWLList_ExtraPT_xtest ad WITH (NOLOCK)  
							INNER JOIN CustDB.dbo.Customer c WITH (NOLOCK)  ON ad.CustID = c.CustID
							INNER JOIN CustDb.dbo.Site s WITH (NOLOCK) ON c.site = s.site
							WHERE s.SiteDBGroupID = @SiteDBGroupID 
							)
				
					)
				)
			BEGIN
				EXEC DBACC.bodb02.dbo.Acc_ResetWinning_SelByDate14
					   @Winlostdate = @Winlostdate,
					   @Mode = 1,
					   @SiteDBGroupID = @SiteDBGroupID,
					   @resetData1 = @resetData1 OUTPUT,
					   @resetData2 = @resetData2 OUTPUT,
					   @resetData3 = @resetData3 OUTPUT,
					   @resetData4 = @resetData4 OUTPUT,
					   @resetData5 = @resetData5 OUTPUT

				SELECT @resetData = @resetData1 + @resetData2 + @resetData3 + @resetData4 + @resetData5

				SELECT @resetData_XML = CAST(@resetData AS XML)

				INSERT INTO @Acc_ResetWinning_SelByDate14 (Winlostdate, custid, amount, transdesc, creator, ip, WinlostAfterExtraPT, reset, product)
				SELECT 
					t.c.value('@Winlostdate', 'SMALLDATETIME')	AS Winlostdate
					,t.c.value('@custid', 'INT')	AS custid
					,t.c.value('@amount', 'MONEY')	AS amount
					,t.c.value('@transdesc', 'NVARCHAR(1000)')	AS transdesc
					,t.c.value('@creator', 'INT')	AS creator
					,t.c.value('@ip', 'VARCHAR(45)')	AS ip
					,t.c.value('@WinlostAfterExtraPT', 'MONEY')	AS WinlostAfterExtraPT
					,t.c.value('@reset', 'MONEY')	AS reset
					,t.c.value('@product', 'VARCHAR(250)')	AS product
				FROM @resetData_XML.nodes('/ROOT/z') t(c)
				OPTION (OPTIMIZE FOR (@resetData_XML = NULL))
			
				WHILE EXISTS (SELECT TOP 1 1 FROM @Acc_ResetWinning_SelByDate14 WHERE seq = @seq)
				BEGIN
					SELECT  @WLdate		= Winlostdate,
							@custid		= custid,
							@amount		= amount,
							@transdesc	= transdesc,
							@creator	= creator,
							@ip			= ip
					FROM @Acc_ResetWinning_SelByDate14 WHERE seq = @seq

					EXEC dbo.Task_ResetWinning_Non3rdParty_Add
							@Winlostdate = @WLdate,
							@custid = @custid,
							@amount = @amount,
							@transdesc = @transDesc,
							@creator = @creator,
							@ip			= @ip

					SELECT @seq = @seq + 1
				
				END

				-- Send email
				IF EXISTS (SELECT TOP 1 1 FROM @Acc_ResetWinning_SelByDate14)
				BEGIN
					SELECT @ProductList = COALESCE(@ProductList + ', ', '') + Product,
						   @ProductVariance = COALESCE(@ProductVariance + ', ', '') + Product +' : '
											+  CONVERT(VARCHAR(100),	ISNULL( (-(ISNULL(r.WinlostAfterExtraPT, 0)) - ISNULL(r.reset, 0)),0) )
											+ ' RM'
					FROM  @Acc_ResetWinning_SelByDate14 r
					WHERE ISNULL( (-(ISNULL(r.WinlostAfterExtraPT, 0)) - ISNULL(r.reset, 0)),0) <> 0
				 					 
					SELECT @Subject = 'Reset Winning report changed on ' + CONVERT(VARCHAR(20),@Winlostdate, 107)
					
					SELECT @body = 'Dear Ah Wan, </br> 
									Kindly be informed that the Reset Winning report has been changed on '+ CONVERT(VARCHAR(20),@Winlostdate, 107) + '</br>
									Time of Reset Winning: '+ CONVERT(VARCHAR(20),Getdate(),109) +' (GMT-4) </br></br> 

									Product: '+ @ProductList + ' </br> </br> 

									Reason: void/recovered tickets </br> 
									Variance: '+ @ProductVariance + '</br> 
									Performed by IT. </br></br>  

									Best regards, </br> 
									This is an auto-mail from ONEworks Report System. Please do not reply.'									 
										
					IF @Istest = 0 AND @@SERVERNAME IN ('DBGRP01N1','DBGRP01N2','DBGRP02N1','DBGRP02N2','DBGRP03N1','DBGRP03N2','DBTRANS')
						SELECT	@recipients = 'kudanaga@enpine.com'
								,@copy_recipients = 'jetyee88@enpine.com;kwongyong@enpine.com;seanlau@enpine.com;tp@enpine.com;it@starixsoft.com;jackyting@enpine.com;vh@enpine.com'
								,@blind_copy_recipients = 'automail@enpine.com'
					ELSE
						SELECT  @recipients = 'dba_local@starixsoft.com'
								,@copy_recipients = ''
								,@blind_copy_recipients = ''
					
					EXEC msdb.dbo.sp_send_dbmail
						@recipients = @recipients
						, @copy_recipients = @copy_recipients
						, @blind_copy_recipients = @blind_copy_recipients
						, @subject = @subject
						, @body = @body
						, @body_format = 'HTML' 
				END
			END
			-------------------------
			SET @errmsg = 'step 5.2'
			---keep call sp by linked server to DBACC
			IF (
					@isTest = 0 
					AND EXISTS (
						SELECT TOP 1 1 
						FROM  DBCUST.CustDB.dbo.Acc_DWLList_ExtraPT e WITH (NOLOCK)
						INNER JOIN CustDB.dbo.Customer c WITH (NOLOCK) ON e.CustID = c.CustID
						INNER JOIN CustDb.dbo.Site s WITH (NOLOCK) ON c.site = s.site
						WHERE e.IsDisabled = 0   AND s.SiteDBGroupID = @SiteDBGroupID
						)
				)
				OR
				(
					@isTest = 1
					AND EXISTS (
						SELECT TOP 1 1 
						FROM  DBCUST.CustDB.dbo.Acc_DWLList_ExtraPT_xtest e WITH (NOLOCK)
						INNER JOIN CustDB.dbo.Customer c WITH (NOLOCK) ON e.CustID = c.CustID
						INNER JOIN CustDb.dbo.Site s WITH (NOLOCK) ON c.site = s.site
						WHERE e.IsDisabled = 0   AND s.SiteDBGroupID = @SiteDBGroupID
						)
				)
			BEGIN
				EXEC DBACC.bodb02.dbo.Task_ResetWinning_ExtraPT14
				  @FromDate= @WinlostDate,
				  @ToDate = @WinlostDate,
				  @Mode = 1	,
				  @SiteDBGroupID = @SiteDBGroupID,
				  @resetData1 = @resetData1_ExtraPT OUTPUT,
				  @resetData2 = @resetData2_ExtraPT OUTPUT,
				  @resetData3 = @resetData3_ExtraPT OUTPUT,
				  @resetData4 = @resetData4_ExtraPT OUTPUT,
				  @resetData5 = @resetData5_ExtraPT OUTPUT

				SELECT @resetData_ExtraPT = @resetData1_ExtraPT + @resetData2_ExtraPT + @resetData3_ExtraPT + @resetData4_ExtraPT + @resetData5_ExtraPT
				SELECT @resetData_ExtraPT_XML = CAST(@resetData_ExtraPT AS XML)

				INSERT INTO @ResetWinning_ExtraPT14 (WLDate, custID, amount, transdesc, creator, ip)
				SELECT 
					t.c.value('@WLDate', 'SMALLDATETIME')	AS WLDate
					,t.c.value('@CustID', 'INT')	AS custID
					,t.c.value('@amount', 'MONEY')	AS amount
					,t.c.value('@transdesc', 'NVARCHAR(1000)')	AS transdesc
					,t.c.value('@creator', 'INT')	AS creator
					,t.c.value('@ip', 'VARCHAR(45)')	AS ip
				FROM @resetData_ExtraPT_XML.nodes('/ROOT/z') t(c)
				OPTION (OPTIMIZE FOR (@resetData_ExtraPT_XML = NULL))

				WHILE EXISTS (SELECT TOP 1 1 FROM @ResetWinning_ExtraPT14 WHERE seq = @seq_ExtraPT)
				BEGIN
					SELECT @WLdate_ExtraPT		= WLDate,
							@custid_ExtraPT		= custID,
							@amount_ExtraPT		= amount,
							@transdesc_ExtraPT	= transdesc,
							@creator_ExtraPT	= creator,
							@ip_ExtraPT			= ip
					FROM @ResetWinning_ExtraPT14 WHERE seq = @seq_ExtraPT
					
				   EXEC bodb02.dbo.Task_ResetWinning_Non3rdParty_Add
							@winlostdate = @WLdate_ExtraPT,
							@custid = @custid_ExtraPT,
							@amount = @amount_ExtraPT,
							@transdesc = @transdesc_ExtraPT,
							@creator = @creator_ExtraPT,
							@ip = @ip_ExtraPT,
							@isExtraPT = 1

					SELECT @seq_ExtraPT = @seq_ExtraPT + 1
				END
			END
		END
		IF @stepNo = 6
		BEGIN

			BEGIN TRY
				SET @errmsg = 'step 6.01'
				
				EXEC dbo.Get_ServerName_By_Alias @Alias  = 'DBTXN', @ServerName = @doNotRunInServer OUTPUT 
				SELECT 
					@alias = 'DBLIC', 
					@SqlCommand = CONCAT('EXEC bodb_LicenseeReport.dbo.Task_PrepareStaging ', ' @datefrom = ''',CONVERT(VARCHAR(50), @winlostdate, 121),''' ,@dateto = ''',CONVERT(VARCHAR(50), @winlostdate, 121),'''')
				EXEC ExecRep_NAP_Admin_05 @ServerName = '', @AliasName = @alias, @SqlCommand = @SqlCommand, @doNotRunInServer = @doNotRunInServer, @Remark = @errmsg

			END TRY
			BEGIN CATCH
				SET @errmsg = 'step 6.01' + '--' + ERROR_MESSAGE()			
				RAISERROR(@errmsg,16,1)
			END CATCH

			BEGIN TRY			 
				
				SET @ErrMsg = 'step 6.02'
				;WITH rs AS 
				(
					SELECT (SELECT * FROM (VALUES (@WinlostDate)) t(wld) for XML RAW('root') ) AS cxml
				)
				SELECT @params = cxml FROM rs

				EXEC dbo.Get_ServerName_By_Alias @Alias  = 'DBTXN', @ServerName = @doNotRunInServer OUTPUT
				SELECT 
					@alias = 'DBLIC', 
					@SqlCommand = CONCAT('EXEC bodb_LicenseeReport.dbo.Task_rptBetting_CheckData ', ' @WinlostDate = ''',CONVERT(VARCHAR(50), @winlostdate, 121),'''',',@HasDataMismatch = @GenerateData OUTPUT, @BetTypes = @BetTypes OUTPUT')
				EXEC ExecRep_NAP_Admin_05 @ServerName = '', @AliasName = @alias, @SqlCommand = @SqlCommand, @doNotRunInServer = @doNotRunInServer, @Remark = @errmsg, @Params = @params

			END TRY
			BEGIN CATCH
				SET @errmsg = 'step 6.02' + '--' + ERROR_MESSAGE()			
				RAISERROR(@errmsg,16,1)
			END CATCH

			BEGIN TRY
				
				SELECT @params = '', @ErrMsg = 'step 6.05'
				
				EXEC dbo.Get_ServerName_By_Alias @Alias  = 'DBTXN', @ServerName = @doNotRunInServer OUTPUT
				SELECT 
					@alias = 'DBLIC', 
					@SqlCommand = 'EXEC bodb_LicenseeReport.dbo.Task_PostStaging '
				EXEC ExecRep_NAP_Admin_05 @ServerName = '', @AliasName = @alias, @SqlCommand = @SqlCommand, @doNotRunInServer = @doNotRunInServer, @Remark = @errmsg

			END TRY
			BEGIN CATCH
				SET @errmsg = 'step 6.05' + '--' + ERROR_MESSAGE()			
				RAISERROR(@errmsg,16,1)
			END CATCH

			BEGIN TRY
				
				SET @ErrMsg  = 'step 6.06'

				;WITH rs AS 
				(
					SELECT (SELECT * FROM (VALUES (@WinlostDate)) t(wld) for XML RAW('root') ) AS cxml
				)
				SELECT @params = cxml FROM rs
			
				EXEC dbo.Get_ServerName_By_Alias @Alias  = 'DBTXN', @ServerName = @doNotRunInServer OUTPUT
				SELECT 
					@alias = 'DBLIC', 
					@SqlCommand = CONCAT('EXEC bodb_LicenseeReport.dbo.Task_rptBettingBySport_CheckData ', ' @WinlostDate = ''',CONVERT(VARCHAR(50), @winlostdate, 121),'''',',@HasDataMismatch = @GenerateData OUTPUT, @IsParlay = @IsParlay OUTPUT')
				EXEC ExecRep_NAP_Admin_05 @ServerName = '', @AliasName = @alias, @SqlCommand = @SqlCommand, @doNotRunInServer = @doNotRunInServer, @Remark = @errmsg, @Params = @params

			END TRY
			BEGIN CATCH
				SET @errmsg = 'step 6.06' + '--' + ERROR_MESSAGE()			
				RAISERROR(@errmsg,16,1)
			END CATCH

			BEGIN TRY
				
				SET @ErrMsg  = 'step 6.08'
				
				EXEC dbo.Get_ServerName_By_Alias @Alias  = 'DBTXN', @ServerName = @doNotRunInServer OUTPUT
				SELECT 
					@alias = 'DBLIC', 
					@SqlCommand = CONCAT('EXEC bodb_LicenseeReport.dbo.Task_DailyRptLicWinloss2 ', ' @WinlostDate = ''',CONVERT(VARCHAR(50), @winlostdate, 121),'''')
				EXEC ExecRep_NAP_Admin_05 @ServerName = '', @AliasName = @alias, @SqlCommand = @SqlCommand, @doNotRunInServer = @doNotRunInServer, @Remark = @errmsg

			END TRY
			BEGIN CATCH
				SET @errmsg = 'step 6.08' + '--' + ERROR_MESSAGE()			
				RAISERROR(@errmsg,16,1)
			END CATCH

			BEGIN TRY
				
				SET @ErrMsg  = 'step 6.09'

				EXEC dbo.Get_ServerName_By_Alias @Alias  = 'DBTXN', @ServerName = @doNotRunInServer OUTPUT
				SELECT 
					@alias = 'DBLIC', 
					@SqlCommand = CONCAT('EXEC bodb_LicenseeReport.dbo.Task_rptCustomerTurnOver_Bettrans14 ', ' @Date = ''',CONVERT(VARCHAR(50), @winlostdate, 121),'''')
				EXEC ExecRep_NAP_Admin_05 @ServerName = '', @AliasName = @alias, @SqlCommand = @SqlCommand, @doNotRunInServer = @doNotRunInServer, @Remark = @errmsg

			END TRY
			BEGIN CATCH
				SET @errmsg = 'step 6.09' + '--' + ERROR_MESSAGE()			
				RAISERROR(@errmsg,16,1)
			END CATCH

			BEGIN TRY 
				
				SET @ErrMsg  = 'step 6.10'
			
				EXEC dbo.Get_ServerName_By_Alias @Alias  = 'DBTXN', @ServerName = @doNotRunInServer OUTPUT
				SELECT 
					@alias = 'DBLIC', 
					@SqlCommand = CONCAT('EXEC bodb_LicenseeReport.dbo.Task_rptWinlostbyleague_Bettrans14 ', ' @Date = ''',CONVERT(VARCHAR(50), @winlostdate, 121),'''')
				EXEC ExecRep_NAP_Admin_05 @ServerName = '', @AliasName = @alias, @SqlCommand = @SqlCommand, @doNotRunInServer = @doNotRunInServer, @Remark = @errmsg

			END TRY
			BEGIN CATCH
				SET @errmsg = 'step 6.10' + '--' + ERROR_MESSAGE()			
				RAISERROR(@errmsg,16,1)
			END CATCH

			BEGIN TRY
				
				SET @ErrMsg  = 'step 6.11'
				
				EXEC dbo.Get_ServerName_By_Alias @Alias  = 'DBTXN', @ServerName = @doNotRunInServer OUTPUT
				SELECT 
					@alias = 'DBLIC', 
					@SqlCommand = CONCAT('EXEC bodb_LicenseeReport.dbo.Task_rptCustomerMatch_Bettrans14 ', ' @Date = ''',CONVERT(VARCHAR(50), @winlostdate, 121),'''')
				EXEC ExecRep_NAP_Admin_05 @ServerName = '', @AliasName = @alias, @SqlCommand = @SqlCommand, @doNotRunInServer = @doNotRunInServer, @Remark = @errmsg

			END TRY
			BEGIN CATCH
				SET @errmsg = 'step 6.11' + '--' + ERROR_MESSAGE()			
				RAISERROR(@errmsg,16,1)
			END CATCH

			BEGIN TRY
				
				SET @ErrMsg  = 'step 6.12'
				
				EXEC dbo.Get_ServerName_By_Alias @Alias  = 'DBTXN', @ServerName = @doNotRunInServer OUTPUT
				SELECT 
					@alias = 'DBLIC', 
					@SqlCommand = CONCAT('EXEC bodb_LicenseeReport.dbo.GEN_rptBetting_Parlay14 ', ' @datefrom = ''',CONVERT(VARCHAR(50), @winlostdate, 121),''' ,@dateto = ''',CONVERT(VARCHAR(50), @winlostdate, 121),'''')
				EXEC ExecRep_NAP_Admin_05 @ServerName = '', @AliasName = @alias, @SqlCommand = @SqlCommand, @doNotRunInServer = @doNotRunInServer, @Remark = @errmsg

			END TRY
			BEGIN CATCH
				SET @errmsg = 'step 6.12' + '--' + ERROR_MESSAGE()			
				RAISERROR(@errmsg,16,1)
			END CATCH

			BEGIN TRY
				
				SET @ErrMsg  = 'step 6.13'
								
				EXEC dbo.Get_ServerName_By_Alias @Alias  = 'DBTXN', @ServerName = @doNotRunInServer OUTPUT
				SELECT 
					@alias = 'DBLIC', 
					@SqlCommand = CONCAT('EXEC bodb_LicenseeReport.dbo.Task_DailyRptLicWinlossGMT_Bettrans14 ', ' @FromDate = ''',CONVERT(VARCHAR(50), @winlostdate, 121),'''')
				EXEC ExecRep_NAP_Admin_05 @ServerName = '', @AliasName = @alias, @SqlCommand = @SqlCommand, @doNotRunInServer = @doNotRunInServer, @Remark = @errmsg

			END TRY
			BEGIN CATCH
				SET @errmsg = 'step 6.13' + '--' + ERROR_MESSAGE()			
				RAISERROR(@errmsg,16,1)
			END CATCH

			BEGIN TRY
			
				SET @ErrMsg  = 'step 6.14'
				
				EXEC dbo.Get_ServerName_By_Alias @Alias  = 'DBTXN', @ServerName = @doNotRunInServer OUTPUT
				SELECT 
					@alias = 'DBLIC', 
					@SqlCommand = CONCAT('EXEC bodb_LicenseeReport.dbo.Task_Microgaming_Bettrans14 ', ' @Fromdate = ''',CONVERT(VARCHAR(50), @winlostdate, 121),''', @Todate = ''', CONVERT(VARCHAR(50), @winlostdate, 121), '''')
				EXEC ExecRep_NAP_Admin_05 @ServerName = '', @AliasName = @alias, @SqlCommand = @SqlCommand, @doNotRunInServer = @doNotRunInServer, @Remark = @errmsg

			END TRY
			BEGIN CATCH
				SET @errmsg = 'step 6.14' + '--' + ERROR_MESSAGE()			
				RAISERROR(@errmsg,16,1)
			END CATCH

			BEGIN TRY
			
				SET @ErrMsg  = 'step 6.15'
				
				EXEC dbo.Get_ServerName_By_Alias @Alias  = 'DBTXN', @ServerName = @doNotRunInServer OUTPUT
				SELECT 
					@alias = 'DBLIC', 
					@SqlCommand = CONCAT('EXEC bodb_LicenseeReport.dbo.Task_rptLicenseeWinloss_Bettrans14 ', ' @winlostdate = ''', CONVERT(VARCHAR(50), @winlostdate, 121), '''')
				EXEC ExecRep_NAP_Admin_05 @ServerName = '', @AliasName = @alias, @SqlCommand = @SqlCommand, @doNotRunInServer = @doNotRunInServer, @Remark = @errmsg

			END TRY
			BEGIN CATCH
				SET @errmsg = 'step 6.15' + '--' + ERROR_MESSAGE()			
				RAISERROR(@errmsg,16,1)
			END CATCH

		END

		IF @stepNo = 7
		BEGIN
			EXECUTE DBFS.bodb_FraudSensor.dbo.FS_Task_MatchDailyDataCapture @GenerateFromDate = @winlostdate, @GenerateToDate = @winlostdate
		END
		IF @stepNo = 8
		BEGIN
			EXECUTE DBTGRS.bodb_TGRS.dbo.Task_RegenerateTGRSData @FromDate = @winlostdate, @ToDate = @winlostdate, @Flagged = 0
		END
	END
END
GO