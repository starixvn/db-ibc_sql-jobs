USE [Affiliate_12bet]
GO

/****** Object:  StoredProcedure [dbo].[Task_Aff_GroupSettingBackup]    Script Date: 01/19/2015 22:18:28 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Task_Aff_GroupSettingBackup]
	@Month int, 
	@Year int	
AS
/*
Created: 20090812@DungTong
Task : Backup all group settings monthly on last day of selected month
DB: DB052.Affiliate_12BET
Original:

Revisions:		             

Param's Explanation:
• @Month: The month to transfer
• @Year :  The year to transfer     
*/
SET NOCOUNT ON

Declare @FirstDay smalldatetime,@LastDay smalldatetime,@TransType int


Select @FirstDay = cast(cast(@Year as varchar(5)) + '-' + cast(@Month as varchar(5)) + '-' +'1' as smalldatetime)
--Get last day of inputted month
Select @LastDay = DATEADD(d,-1,DATEADD(mm, DATEDIFF(m,0,@FirstDay)+1,0))
	

if datediff(d,Current_TimeStamp,@LastDay) > 0
BEGIN
	SELECT 'The month is not completed yet. So you cannot backup data!' Result
	SELECT @FirstDay as FirstDay,@LastDay as LastDay
	RETURN
END

--Check group History data is inserted
if(exists(select top(1) 1 from CommGroupHistory (nolock) where monthdate=@LastDay) 
   or exists(select top(1) 1 from GroupSettingHistory (nolock) where monthdate=@LastDay)
   or exists(select top(1) 1 from DeductionSettingHistory (nolock) where monthdate=@LastDay)
   or exists(select top(1) 1 from AffGroupHistory (nolock) where monthdate=@LastDay)
  )
 BEGIN
	delete 	CommGroupHistory where monthdate=@LastDay
	delete GroupSettingHistory where monthdate=@LastDay
	delete DeductionSettingHistory where monthdate=@LastDay
	delete AffGroupHistory where monthdate=@LastDay
 END
 
 
Insert into CommGroupHistory (GroupID,MonthDate,GroupName,CreatedDate,Creator,IsDeleted,Description) 
select GroupID,@LastDay,GroupName,CreatedDate,Creator,IsDeleted,Description
from CommGroup (nolock)

Insert Into GroupSettingHistory(GroupID,SportType,TierID,MonthDate,MinAmount,MaxAmount,MinQM,MaxQM,Commission)
select GroupID,SportType,TierID,@LastDay,MinAmount,MaxAmount,MinQM,MaxQM,Commission
from GroupSetting (nolock)
   
Insert Into DeductionSettingHistory(GroupID,MonthDate,DeductionID,DeductedPercentage)
select GroupID,@LastDay,DeductionID,DeductedPercentage
from DeductionSetting (nolock)

Insert Into AffGroupHistory(AffID,MonthDate,GroupID)
select AffID,@LastDay,GroupID
from AffInfo (nolock)
where GroupID is not null and GroupID>0



GO

GRANT VIEW DEFINITION ON [dbo].[Task_Aff_GroupSettingBackup] TO [vnAffiliate] AS [dbo]
GO

GRANT VIEW DEFINITION ON [dbo].[Task_Aff_GroupSettingBackup] TO [vnteam] AS [dbo]
GO


