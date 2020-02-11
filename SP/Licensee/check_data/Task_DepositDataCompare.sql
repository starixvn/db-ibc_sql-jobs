/*<info serverAlias="DBLIC-bodb_LicenseeReport" executers="bodbLicenseeNet" viewers="" isFunction="0" isNested="0"></info>*/

ALTER PROCEDURE [dbo].[Task_DepositDataCompare] 
	@Date		SMALLDATETIME	= NULL,
	@DrawFilter	TINYINT			= 1
AS

/*
	Created: 20140312@Florent
	Task : Compare data from 5 tables sum
	DB: bodb_LicenseeReport
	Original:

	Revisions:
		- 20140429@Florent: fix bug and change message error
		- 20160726@Francis: Move SP to bodb_LicenseeReport - [Redmine: #60449]
		- 20160805@Jim: Revise SP due to [Redmine: #62052]
		- 20170822@Harper: Add missing products CB, AB, NG2, FW, CO, VS2, LT into data validation email [RedmineID: #81708]
		- 20180418@Joseph: Integrate new product PP [Redmine: #92318]
		- 20190715@Amanda: Integrate Card Club [RedmineID: #115449]
		- 20191106@Amanda: Integrate NPHP [RedmineID: #120333]
		- 20191204@Amanda: Change name of NPH Promotion to Saba Promotion [Redmine: #124612]
		- 20191212@Vickie: Integrate SpadeGaming [RedmineID: #124103]

	Param's Explanation:
		@DrawFilter, 1:Normal - 2:No Draws - 3:No Draws For Turnover Only

	TypeID: table sum
		1 rptLicWinloss2 -- default
		2 rptCustomerTurnover
		3 rptCustomerMatch
		4 rptWinlossbyLeague
	ID : 
		1 Turnover
		2 Customer Winlost
		3 Betcount
*/

BEGIN
	SET NOCOUNT ON

	DECLARE
		@flag bit=0
		,@NumberTemp_SB BIGINT
		,@PivotNumb_SB BIGINT
		,@NumberTemp_RB BIGINT
		,@PivotNumb_RB BIGINT
		,@NumberTemp_NG BIGINT
		,@PivotNumb_NG BIGINT
		,@NumberTemp_BA BIGINT
		,@PivotNumb_BA BIGINT
		,@NumberTemp_CS BIGINT
		,@PivotNumb_CS BIGINT
		,@id INT=1
		,@mesg Nvarchar (Max)=''
	   
		--Number of table must compare
		,@table_num INT =0
		,@output NVARCHAR(4000)=''

	CREATE TABLE #TempData 
		(ID INT
		,Sportbook bigint
		,Racing bigint
		,NumberGame bigint
		,BA bigint
		,LC bigint
		)

	CREATE TABLE #Data1 
		(Typeid iNT
		,ID INT
		,Sportbook bigint
		,Racing bigint
		,NumberGame bigint
		,BA bigint
		,LC bigint
		)

	DECLARE @tblTmp AS TABLE (ID INT
							   ,Sportbook bigint
							   ,Racing bigint
							   ,NumberGame bigint
							   ,BA bigint
							   ,CS bigint
							   ,BT bigint
							   ,LC bigint
							   ,AG bigint
							   ,GD bigint
							   ,KN bigint
							   ,VG bigint
							   ,VB bigint
							   ,MGCLC bigint
							   ,MGCRNG bigint
							   ,VS BIGINT
							   ,CB BIGINT
							   ,AB BIGINT
							   ,NG2 BIGINT
							   ,FW BIGINT
							   ,CO BIGINT
							   ,VS2 BIGINT
							   ,LT BIGINT
							   ,PP BIGINT
							   ,CC BIGINT
							   ,SPR BIGINT
							   ,SG BIGINT)
						   
	--exec 
	--rptLicWinloss2
	INSERT INTO @tblTmp	(ID
						,Sportbook  
						,Racing  
						,NumberGame  
						,BA  
						,CS  
						,BT  
						,LC  
						,AG  
						,GD  
						,KN  
						,VG  
						,VB  
						,MGCLC  
						,MGCRNG  
						,VS
						,CB
						,AB
						,NG2
						,FW
						,CO
						,VS2
						,LT
						,PP
						,CC
						,SPR
						,SG)	
	EXEC dbo.GET_DepositDataToValidate_LicenseeWL @Date=@Date	
				
	INSERT INTO #TempData(ID,Sportbook,Racing,NumberGame,BA,LC)
	SELECT ID,Sportbook,Racing,NumberGame,BA,LC FROM @tblTmp
 
	INSERT INTO #Data1(Typeid,ID,Sportbook,Racing,NumberGame,BA,LC)
	SELECT @id,* from #TempData
	DELETE  #tempdata
	SET @id=@id+1
	----

	--rptCustomerTurnover
	INSERT INTO #TempData(ID,Sportbook,Racing,NumberGame,BA,LC)
	exec dbo.GET_DepositDataToValidate_CustomerTurnover @Date=@Date

	INSERT INTO #Data1(Typeid,ID,Sportbook,Racing,NumberGame,BA,LC)
	SELECT @id,* from #TempData
	DELETE  #tempdata
	SET @id=@id+1

	--rptCustomerMatch
	INSERT INTO #TempData(ID,Sportbook,Racing,NumberGame,BA,LC)
	exec dbo.GET_DepositDataToValidate_CustomerMatch @Date=@Date

	INSERT INTO #Data1(Typeid,ID,Sportbook,Racing,NumberGame,BA,LC)
	SELECT @id,* from #TempData
	DELETE  #tempdata
	SET @id=@id+1

	--rptWinlossByLeague
	INSERT INTO #TempData(ID,Sportbook,Racing,NumberGame,BA,LC)
	exec dbo.GET_DepositDataToValidate_WLByLeague @Date=@Date

	INSERT INTO #Data1(Typeid,ID,Sportbook,Racing,NumberGame,BA,LC)
	SELECT @id,* from #TempData
	DELETE  #tempdata
	SET @id=@id+1

	--rpt_Betting
	DELETE @tblTmp
 
	INSERT INTO @tblTmp	(ID
						,Sportbook  
						,Racing  
						,NumberGame  
						,BA  
						,CS  
						,BT  
						,LC  
						,AG  
						,GD  
						,KN  
						,VG  
						,VB  
						,MGCLC  
						,MGCRNG  
						,VS
						,CB
						,AB
						,NG2
						,FW
						,CO
						,VS2
						,LT
						,PP
						,CC
						,SPR
						,SG)					   
	EXEC dbo.GET_DepositDataToValidate_Betting @Date=@Date
					
	INSERT INTO #TempData(ID,Sportbook,Racing,NumberGame,BA,LC)
	SELECT ID,Sportbook,Racing,NumberGame,BA,LC FROM @tblTmp
 
	INSERT INTO #Data1(Typeid,ID,Sportbook,Racing,NumberGame,BA,LC)
	SELECT @id,ID,Sportbook,Racing,NumberGame,BA,LC from #TempData
	DELETE  #tempdata

	SET @table_num=@id
	SET @id=1 
	--compare Turnover
	WHILE (@id<4)--1.turnover 2.CustWL 3.Betcount
	BEGIN
		DECLARE @typeid int =1
		WHILE (@typeid<=@table_num)--1.rptLicWinlost2 2.CustomerTurnover 3. CustomerMatch 4.WinlostByLeague
		BEGIN		
			DECLARE @mesg2 nvarchar(1000)=''
			IF @typeid=1 --get pivot number ner
				SELECT  @PivotNumb_SB=Sportbook,
						@PivotNumb_RB=Racing,
						@PivotNumb_NG=NumberGame,
						@PivotNumb_CS=LC,
						@PivotNumb_BA=BA
				FROM #Data1 WHERE Typeid=@typeid and id=@id
			IF @typeid<>1 		
				BEGIN					
					SELECT  @NumberTemp_SB=Sportbook,
							@NumberTemp_RB=Racing,
							@NumberTemp_NG=NumberGame,
							@NumberTemp_CS=LC,
							@NumberTemp_BA=BA
					FROM #Data1 WHERE Typeid=@typeid and id=@id					
					SET @mesg2='' 
					IF (@PivotNumb_SB<>@NumberTemp_SB)--check SB
						BEGIN						
							if ((@id= 2 and ABS(@NumberTemp_SB-@PivotNumb_SB)>1) OR (@id<>2))
								begin 
									set @flag=1
									select @mesg2=@mesg2+Convert(nvarchar,@typeid,102)
								end 
						END 
					IF (@PivotNumb_RB<>@NumberTemp_RB)--check RB
						BEGIN
							if ((@id= 2 and ABS(@NumberTemp_SB-@PivotNumb_SB)>1) OR (@id<>2))
								begin 
									set @flag=1
									select @mesg2=@mesg2+Convert(nvarchar,@typeid,102)						
								end 
						END
					IF (@PivotNumb_NG<>@NumberTemp_NG)--check NG					
						BEGIN 
							if ((@id= 2 and ABS(@NumberTemp_SB-@PivotNumb_SB)>1) OR (@id<>2))			
								begin 
									set @flag=1
									select @mesg2=@mesg2+Convert(nvarchar,@typeid,102)
								end 
						END
					IF (@PivotNumb_BA<>@NumberTemp_BA)--check BA					
						BEGIN 
							if ((@id= 2 and ABS(@NumberTemp_SB-@PivotNumb_SB)<=1) OR (@id<>2))
								begin 
									set @flag=1
									select @mesg2=@mesg2+Convert(nvarchar,@typeid,102)
								end 
						END
					IF (@PivotNumb_CS<>@NumberTemp_CS)--check Live Casino
						BEGIN 
							if ((@id= 2 and ABS(@NumberTemp_SB-@PivotNumb_SB)>1) OR (@id<>2))
								begin 
									set @flag=1
									select @mesg2=@mesg2+Convert(nvarchar,@typeid,102)
								END
						END
				END	
			IF @mesg2!=''
			SET @mesg=@mesg+@mesg2+';'	
			SET @typeid=@typeid+1
		END  
		SET @id=@id+1
	END

	 if (@flag=1)
		 BEGIN
			IF(CHARINDEX('2',@mesg)>=1)
				SET @output=@output+'Table rptCustomerTurnover, Date: '+Convert(nvarchar,@Date,102) +' ; '
			IF(CHARINDEX('3',@mesg)>=1)
				SET @output=@output+'Table rptCustomerMatch, Date: '+Convert(nvarchar,@Date,102)+ ' ; '
			IF(CHARINDEX('4',@mesg)>=1)	
				SET @output=@output+'Table rptWinlossbyLeague, Date: '+Convert(nvarchar,@Date,102)+' ; '
			IF(CHARINDEX('5',@mesg)>=1)	
				SET @output=@output+'Table rpt_Betting, Date: '+Convert(nvarchar,@Date,102)+' ; '
			 RAISERROR (@output,16,1); 
		END 
	/*-- Test Email
	if (@flag=0)
		BEGIN
			SET @output='Don Test'
			RAISERROR (@output,16,1); 
		END*/

	DROP TABLE #Data1
	DROP TABLE #TempData 

	SET NOCOUNT OFF
END
GO