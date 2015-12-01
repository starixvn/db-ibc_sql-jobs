
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

/****** Object:  Stored Procedure dbo.GET_DepositDataToValidate_Compare    Script Date: 12/1/2015 2:38:01 AM ******/
/****** Object:  Stored Procedure dbo.GET_DepositDataToValidate_Compare    Script Date: 29/04/2014 5:56:44 PM ******/
CREATE PROCEDURE [dbo].[GET_DepositDataToValidate_Compare] 
    @Date smalldatetime = null
	,@DrawFilter tinyint = 1
AS
/*
Created: 20140312@Florent
Task : Compare data from 4 table sum

DB: bodb_Licensee
Original:

Revisions:		
	- 20140429@Florent: fix bug and change message error
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
Examples:


*/
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
	   ,CS bigint
	   )

CREATE TABLE #Data1 
		(Typeid iNT
		,ID INT
	   ,Sportbook bigint
       ,Racing bigint
       ,NumberGame bigint
	   ,BA bigint
	   ,CS bigint
	   )

--exec 
--rptLicWinloss2
INSERT INTO #TempData(ID,Sportbook,Racing,NumberGame,BA,CS)
exec dbo.GET_DepositDataToValidate_LicenseeWL @Date=@Date
INSERT INTO #Data1(Typeid,ID,Sportbook,Racing,NumberGame,BA,CS)
SELECT @id,* from #TempData
DELETE  #tempdata
SET @id=@id+1
----


--rptCustomerTurnover
INSERT INTO #TempData(ID,Sportbook,Racing,NumberGame,BA,CS)
exec dbo.GET_DepositDataToValidate_CustomerTurnover @Date=@Date
INSERT INTO #Data1(Typeid,ID,Sportbook,Racing,NumberGame,BA,CS)
SELECT @id,* from #TempData
DELETE  #tempdata
SET @id=@id+1

--rptCustomerMatch
INSERT INTO #TempData(ID,Sportbook,Racing,NumberGame,BA,CS)
exec dbo.GET_DepositDataToValidate_CustomerMatch @Date=@Date
INSERT INTO #Data1(Typeid,ID,Sportbook,Racing,NumberGame,BA,CS)
SELECT @id,* from #TempData
DELETE  #tempdata
SET @id=@id+1


--rptWinlossByLeague
INSERT INTO #TempData(ID,Sportbook,Racing,NumberGame,BA,CS)
exec dbo.GET_DepositDataToValidate_WLByLeague @Date=@Date
INSERT INTO #Data1(Typeid,ID,Sportbook,Racing,NumberGame,BA,CS)
SELECT @id,* from #TempData
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
					@PivotNumb_CS=CS,
					@PivotNumb_BA=BA
			FROM #Data1 WHERE Typeid=@typeid and id=@id
		IF @typeid<>1 		
			BEGIN					
				SELECT  @NumberTemp_SB=Sportbook,
						@NumberTemp_RB=Racing,
						@NumberTemp_NG=NumberGame,
						@NumberTemp_CS=CS,
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
		 RAISERROR (@output,16,1); 
	END 

DROP TABLE #Data1
DROP TABLE #TempData 

SET NOCOUNT OFF
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO


GO 
 GRANT VIEW DEFINITION ON [dbo].[GET_DepositDataToValidate_Compare] TO [vnteam]
GO 
 GRANT EXECUTE ON [dbo].[GET_DepositDataToValidate_Compare] TO [bodbLicenseeNet]
GO 
