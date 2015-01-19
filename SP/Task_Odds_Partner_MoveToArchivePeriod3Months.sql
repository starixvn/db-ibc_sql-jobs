USE [bodb_oddsfeed]
GO

/****** Object:  StoredProcedure [dbo].[Task_Odds_Partner_MoveToArchivePeriod3Months]    Script Date: 01/19/2015 04:12:52 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[Task_Odds_Partner_MoveToArchivePeriod3Months]  
 @date smalldatetime = null  
AS  
/**    
 * Created : 20130319@Thai
 * Task  : Move PartnerStatistics to PartnerStatistics_Archive with period of 3 months
 * DB  : bodb_oddsfeed 
 *    
 * Revisions:       
 * Param's Explanation:   
*/  
 
SET NOCOUNT ON   
  
select @date = convert(varchar(10), ISNULL(@date, dateAdd(m, -3, current_timestamp)), 120)  

BEGIN TRANSACTION
  
	insert into dbo.PartnerStatistics_Archive
	select * from dbo.PartnerStatistics
	where datediff(m, @date, [date])=0  
	  
	if @@Error <> 0
	BEGIN				
		ROLLBACK TRANSACTION
		RETURN
	END

	delete dbo.PartnerStatistics
	where datediff(m, @date, [date])=0  

COMMIT TRANSACTION

--Write the log 
DECLARE @SPName VARCHAR(50)
SELECT @SPName = OBJECT_NAME(@@ProcID) 

DECLARE @LogData NVARCHAR(4000)
SELECT @LogData = 'Move PartnerStatistics to PartnerStatisticsArchive' +
		', Moved Date: ' + dbo.Is_Odds_ToString(@date) +		
		', Action Date: ' + dbo.Is_Odds_ToString(current_timestamp) +		
		', ExcutingSPName ' + dbo.Is_Odds_ToString(@SPName) 
	
EXEC [dbo].[Odds_WriteLog]
	@Creator=0,	
	@PartnerID =0,
	@TypeName= 'Partner',	
	@SPName=@SPName,
	@IP ='',
	@Detail=@LogData



GO

GRANT EXECUTE ON [dbo].[Task_Odds_Partner_MoveToArchivePeriod3Months] TO [bodbAdminNet] AS [dbo]
GO


