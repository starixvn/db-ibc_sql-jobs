USE [Affiliate_12BET]
GO

/****** Object:  StoredProcedure [dbo].[Task_Aff_MonthlyTransfer]    Script Date: 01/19/2015 23:20:46 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/****** Object:  Stored Procedure dbo.Task_Aff_MonthlyTransfer    Script Date: 5/22/2013 8:34:10 AM ******/
  
CREATE PROCEDURE [dbo].[Task_Aff_MonthlyTransfer]  
 @Month int,   
 @Year int   
   
AS  
/*  
Created: 20090812@DungTong  
Task : Monthly transfer for all Affiliate  
DB: DB052.Affiliate_12BET  
Original:  
  
Revisions:   
 - 200900217@Dung:   
   + Use Tier Commission to calculate monthly earning for each Affiliate based on Aff's member winlosts.  
	  To get commission value on what tier we do 3 phases:  
	 .Calculate Number Of Qualified members on this month (member that have the turn over for this month is greater than or equal to 100$)  
	 .Calculate winlost for each member on this month.  
	 .Calculate Deductions (based on deduction setting from affiliate's Group)  
	 .we have NetWinlost=WinLost-Deduction, TotalQMs  
	 .For each Affiliate we get commission value by this way:  
	   When TotalWinlost>0  
		 Commission=Commission by Net Winlost  
	   When TotalWinlost<=0                              
	  Commission=Min(Commission got by |NetWinlost| between MiAmount and MaxAmount, Commission got by TotalQMs between MinQM and MaxQMs)    
	 . Aff's Earning=NetWinlost * Commission  
   + We have only one place to get Winlost and Other Data from MemberDaily. and the day excute this task must greater than the last day of selected month                  
   + Qualifying member: Get Setting AFF_QMTurnOver from SystemSettings. Each member has  TurnOver>AFF_QMTurnOver --> qualified member  
   + All the transactions have the status=completed  
  - 20091203@Peter: Add Auto deduct transactions for Marketing fee  
	  Deduction=Affiliate Net Earning * 20%  
  - 20100115@Peter : Remove Auto deduct transactions for Marketing fee  
	  http://ccs.sunplus.vn/viewtopic.php?f=4&t=2890&sid=58e8c31d51dac7ddbef907a7a258c6cf&p=14064#p14064  
		
  -20100211@Peter: #381 IRP - AffSite - Revise the calculations of the tier commission and PSP charge fee    
	   http://ccs.sunplus.vn/viewtopic.php?f=4&t=2890        
		 
	  CNW=sum[(your total member's lost- your total member's won- bonus  - adjustment -  Marketing Fee)  * ExRate2].              
	  AComm= Min(commission get by |CNW|, commission get by TQM)  
	  MF= |Total Member's Lost-Total Member's Won| *  5%  
	  AE = CNW * Acomm  
	  AFE = AE -  PSP * 50%  
		
	  Reupdate table AffDaily.   
		
  -20100709@Peter:  
	 http://ccs.sunplus.vn/viewtopic.php?f=4&t=2890&st=0&sk=t&sd=a&start=10  
	 Change the way to calculation:  
  
	 if CNW <0 then we must also use the condition of Qualifying Members ( old way does not have)  
	  and the minimum commission in this case is 10%  if the qualifying members <5.  
   -20100927@Peter:  
	 http://ccs.sunplus.vn/viewtopic.php?f=4&t=3845&p=19236#p19236    
	 Change the way to calculation:  
	   PSP=deposit * depositpercent + withdrawal * withdrawalpercent  
	   For European Currencies: EURO,AUD,GBP, US$  
		+ depositpercent=0.06  
		+ withdrawalpercent=0.03  
	   For Asian Currencies:  
		+ depositpercent=0.02  
		+ withdrawalpercent=0.02  
	   PSP now follow tier commission  
	   New Fee:  Odds Management Fee = 17 % MemberWinlost  
	   CNW= MemberWinlost - Odds Management Fee - Marketing Fee - PSP Fee  
	   From CNW => AComm  
	   Affiliate Earning=(CNW - Bonus - Adjustement)* AComm                  
   - 20120223@Peter:  
	  http://ccs.nexcel.vn/viewtopic.php?f=4&t=6247  
	 Final decision confirmed by our Management :  
	 1)To take away the ‘Adjustment’ formula in the Affiliate System : Affiliate Monthly Commission = (Company Net Winloss - Bonus) * commission percent  
	 2) Although the ‘Adjustment’ is taken out from the formula but we still maintain this column inside the system.  
   - 20120511@Peter : Add Casino Commission to formula  
	 http://ccs.nexcel.vn/viewtopic.php?f=4&t=6320  
   - 20120115@Peter : Modify Casino negative commission  
	  http://ccs.nexcel.vn/viewtopic.php?f=6&t=7524&p=35897#p35897   

	- 20120514@Peter : Apply new formula according to Joycee's request

			 IF Winloss in SPORTSBOOK > winloss in Casino then 
				 
				   CNW in sportspook=Member Winlost In SB - Marketing Fee- Odds Fee - PSP Fe
					Net Winlost for Casino = Member Winlost In Casino - Marketing Casino - Playtech Royalty Fee
			 else
				   CNW in sportspook=Member Winlost In SB - Marketing Fee- Odds Fee
				   Net Winlost for Casino = Member Winlost In Casino - Marketing Casino - Playtech Royalty Fee - PSP Fee

Param's Explanation:  
• @Month: The month to transfer  
• @Year :  The year to transfer       
*/  
SET NOCOUNT ON  
  
  
Declare @FirstDay smalldatetime,@LastDay smalldatetime,@TransType int,@SportsBookID int,@HorseRacingID int,@CasinoID int,@MarketingTransType int,@DeductionPercent float, @MinimumNegativeCommission float, @MinimumNegativeCasinoCommission float  
  
select @MinimumNegativeCommission = 0.1,  @MinimumNegativeCasinoCommission=0.05  
  
select @SportsBookID=dbo.Aff_GetSportID('SportsBook'),@HorseRacingID=dbo.Aff_GetSportID('Horse Racing'),@CasinoID=dbo.Aff_GetSportID('Casino')  
  
Select @FirstDay = cast(cast(@Year as varchar(5)) + '-' + cast(@Month as varchar(5)) + '-' +'1' as smalldatetime)  
--Get last day of inputted month  
Select @LastDay = DATEADD(d,-1,DATEADD(mm, DATEDIFF(m,0,@FirstDay)+1,0)),  
 @TransType = 201,@MarketingTransType=204,@DeductionPercent=0.2 --201 Monthy Affiliate Transfer  
  
if @LastDay > Current_TimeStamp  
BEGIN  
 SELECT 'The month is not completed yet. So you cannot transfer!' Result  
 SELECT @FirstDay as FirstDay,@LastDay as LastDay  
 RETURN  
END  
  
--Check group History data is inserted  
if(not exists(select top(1) 1 from CommGroupHistory (nolock) where monthdate=@LastDay)   
   or not exists(select top(1) 1 from GroupSettingHistory (nolock) where monthdate=@LastDay)  
   or not exists(select top(1) 1 from DeductionSettingHistory (nolock) where monthdate=@LastDay)  
   or  not exists(select top(1) 1 from AffGroupHistory (nolock) where monthdate=@LastDay)  
  )  
 BEGIN  
 SELECT 'All group setting history data for selected month have not been updated yet. Please update data first by executing Task_Aff_GroupSettingBackup @Month,@Year!' Result  
 SELECT @FirstDay as FirstDay,@LastDay as LastDay  
 RETURN  
 END  

IF EXISTS (select top(1) 1 from AffCommission with(nolock)  
   where WinlostDate=@LastDay)  
BEGIN  
 SELECT 'Please check the data. Transfers have been done for this month!' Result   
 SELECT @FirstDay as FirstDay,@LastDay as LastDay  
 RETURN  
END  

--Get all Affiliates that is approved and IsClosed=false  
declare /*@AFF_QMTurnOver money,*/@Status varchar(30)  
select @Status='Approved'  
  
/*select @AFF_QMTurnOver=cast(SValue as money)  
 from SystemSettings (nolock)  
 where SName ='AFF_QMTurnover'    
*/  
  
 
--Create temp table to get summary data for each affiliate  
CREATE TABLE #AffSummary  
(  
   /* [No] int IDENTITY(1,1),*/  
 AffID int,  
 Currency int,     
 GroupID int,  
 SportID int,  
 MemWinlost money,  
 MemBonus money,  
 MemAdjustment money,  
 MemPSP money,  
 Marketing money,  
 MemDeposit money,  
 MemTurnover money,  
 Commission decimal(9,8),  
 TotalQM int,    
 NetWinlost money,   
 BonusPercent float,  
 MarketingPercent float,  
 AdjustmentPercent float,  
 PSPPercent float,  
 OddsFeePercent float,  
 PlayTechRoyaltiesPercent float,
 IsPSPIncluded int -- flag to check PSP Fee is included or not for this product    
 /*CONSTRAINT [PK_#AffSummary] PRIMARY KEY CLUSTERED (AffID,SportID) */  
)  
  
/*  
  select distinct ai.AffId,coalesce(gh.GroupID,ai.GroupID) as GroupID,Currency, g.SportType as SportType  
	 from AffInfo ai with (nolock)  
	inner join AffGroupHistory gh(nolock) on gh.AffID=ai.AffID and gh.MonthDate='Jun 30 2013 12:00AM'
	inner join GroupSettingHistory g with (nolock) on ai.GroupId = g.GroupId and g.MonthDate='Jun 30 2013 12:00AM'
	 where ai.AffID= 1222876*/
	 
	 
INSERT INTO #AffSummary(AffID,Currency,GroupID,SportID,MemWinlost,MemBonus,MemAdjustment,MemPSP,Marketing,
MemDeposit,MemTurnover,
TotalQM,BonusPercent,AdjustmentPercent,MarketingPercent,PSPPercent,OddsFeePercent,PlayTechRoyaltiesPercent,IsPSPIncluded)  
  
Select t.AffID as AffID  
	,t.Currency as Currency  
	,t.GroupID as GroupID  
	,t.SportType as SportID  
	,sum(isnull(r.Winlost,0)) as MemWinlost  
	,sum(isnull(r.Bonus,0)) as MemBonus  
	,sum(isnull(r.Adjustment,0)) as MemAdjustment  
	,sum(isnull(r.PSP,0)) as MemPSP  
	,sum(isnull(r.Marketing,0)) as Marketing  
	,sum(isnull(r.Deposit,0)) as MemDeposit  
	,sum(isnull(r.Turnover,0)) as MemTurnover  
	,sum(case when r.TurnOver>=s.QMTurnOver and r.Deposit>=s.QMDeposit then 1 else 0 end) as TotalQM         
	,dbo.Aff_GetDeductionPercent(t.AffID,t.SportType,'Bonus',@LastDay) as BonusPercent  
	,dbo.Aff_GetDeductionPercent(t.AffID,t.SportType,'Adjustment',@LastDay) as AdjustmentPercent  
	,dbo.Aff_GetDeductionPercent(t.AffID,t.SportType,'Marketing',@LastDay) as MarketingPercent  
	,dbo.Aff_GetDeductionPercent(t.AffID,t.SportType,'PSP',@LastDay) as PercentPSP  
	,dbo.Aff_GetDeductionPercent(t.AffID,t.SportType,'Odds Fee',@LastDay) as OddsFeePercent  
	,dbo.Aff_GetDeductionPercent(t.AffID,t.SportType,'PlayTech Royalties',@LastDay) as PlayTechRoyaltiesPercent    
	,0 as IsPSPIncluded  
FROM   
  (select distinct ai.AffId,gh.GroupID,Currency, g.SportType as SportType  
	 from AffInfo ai with (nolock)  
	inner join AffGroupHistory gh(nolock) on gh.AffID=ai.AffID and gh.MonthDate=@LastDay  
	inner join GroupSettingHistory g with (nolock) on ai.GroupId = g.GroupId and g.MonthDate=@LastDay  
	 where ai.status=@Status-- and IsClosed=0  
	
   ) t        
   left join   
   (  
  select IBCCustID,SportType,AffID  
	,sum(isnull(Winlost,0) * isnull(AffExRate,1)) as Winlost  
	  ,sum(isnull(Bonus,0) * isnull(AffExRate,1)) as Bonus  
	  ,sum(isnull(Adjustment,0) * isnull(AffExRate,1)) as Adjustment  
	  ,sum(isnull(PSP,0) * isnull(AffExRate,1)) as PSP  
	  ,sum(isnull(Marketing,0) * isnull(AffExRate,1)) as Marketing  
	  ,sum(isnull(TurnOver,0) * isnull(AffExRate,1)) as TurnOver  
	  ,sum(isnull(Deposit,0) * isnull(AffExRate,1)) as Deposit  
  from MemberDaily md  (nolock)   
  where WinlostDate between @FirstDay and @LastDay   
  group by IBCCustID,SportType,AffID  
  
   ) r on r.AffID=t.AffID and t.SportType = r.SportType  
   left join SportType s (nolock) on s.SportID=r.SportType  
  --where  r.SportType in (select distinct SportType from GroupSettingHistory (nolock) where GroupID=t.GroupID and MonthDate=@LastDay)  
  
group by t.AffID,t.GroupID, t.SportType,t.Currency  
  
   
if(@@ROWCOUNT=0)  
  begin  
  Select 'There was no data for selected month to transfer!' as Result  
  SELECT @FirstDay as FirstDay,@LastDay as LastDay    
  drop table #AffSummary  
  return  
  end  
--Delete all Aff with all value=0  
/*Delete #AffSummary  
where MemTurnover=0 and MemWinlost =0 and MemBonus=0 and MemAdjustment=0 and MemPSP=0 and Marketing=0*/  
  
update #AffSummary with (rowlock,updlock)  
set SportID=@SportsBookID  
where SportID is null and MemTurnover=0 and MemWinlost =0 and MemBonus=0 and MemAdjustment=0 and MemPSP=0 and Marketing=0  

 
-- Decide which SportID should include PSP
declare @AffSummary table(affid int, maxwinlost money,psp money,PSPPercent float,maxWinlostSportID int)

insert into @AffSummary (affid ,psp,PSPPercent)
select affid,isnull(MemPSP,0),PSPPercent
from #AffSummary (nolock)
where SportID=@SportsBookID

update a
set a.maxwinlost=(select max(abs(a1.MemWinlost)) 
				   from #AffSummary (nolock) a1 
				   where a1.affid=a.affid
				  )
from  @AffSummary a

update a
set a.maxWinlostSportID= coalesce((select top(1) a1.sportid
								 from #AffSummary a1
								 where a1.affid=a.affid and abs(a1.MemWinlost)=a.maxwinlost and a1.SportID <> @SportsBookID)
								,@SportsBookID)
from  @AffSummary a

-- reupdate PSP for which sport has maximum abs(winlost)
update a
set a.IsPSPIncluded=1,
	a.MemPSP=a1.psp,
	a.PSPPercent=a1.PSPPercent
from #AffSummary a
	inner join @AffSummary a1 on a1.affid=a.affid

where a.sportid=a1.maxWinlostSportID




  
--Choose commission value and calculate Total Balance after deduction for each Affiliate and SportID  
  
update a  
set  a.NetWinlost=(-isnull(a.MemWinlost,0)   
	 - isnull(a.MemPSP,0)*isnull(a.PSPPercent,0)  * a.IsPSPIncluded 
	 - abs(isnull(a.MemWinlost,0)) * isnull(a.OddsFeePercent,0)   
	- abs(isnull(a.MemWinlost,0)) * isnull(a.MarketingPercent,0)   
	- abs(isnull(a.MemWinlost,0)) * isnull(a.PlayTechRoyaltiesPercent,0)   
	),  
	  
  a.commission=isnull((select  top(1) Commission  
		from   
	   (  
		select isnull((select Commission  
			 from GroupSettingHistory(nolock)  
			 where GroupID=a.GroupID   
			 and SportType=a.SportID  
			 and MonthDate=@LastDay  
			 and floor(  
			   abs( -isnull(a.MemWinlost,0)   
				 - isnull(a.MemPSP,0)*isnull(a.PSPPercent,0)  * a.IsPSPIncluded  
				 - abs(isnull(a.MemWinlost,0)) * isnull(a.OddsFeePercent,0)   
				- abs(isnull(a.MemWinlost,0)) * isnull(a.MarketingPercent,0)   
				- abs(isnull(a.MemWinlost,0)) * isnull(a.PlayTechRoyaltiesPercent,0)                   
			   )   
			   )  
			  between MinAmount and MaxAmount),0) as Commission  
		union all                               
		  select isnull((select top(1) Commission   
			   from GroupSettingHistory(nolock)  
			   where GroupID=a.GroupID   
			   and SportType=a.SportID   
			   and MonthDate=@LastDay  
			   and a.TotalQM between MinQM and MaxQM  
			   ),0)  
			 as Commission  
	   ) t    
	   order by t.Commission asc  
	 ),0)  
from #AffSummary a  
  
update a  
set a.Commission = (case when a.SportID=@CasinoID then @MinimumNegativeCasinoCommission else @MinimumNegativeCommission end)  
from #AffSummary a  
where a.NetWinlost < 0 and a.Commission = 0  
	and [dbo].[IsZeroCommissionGroup](a.GroupID,@LastDay)=0    
	 and a.SportID in (
		select distinct SportID from GroupSettingHistory (nolock) where GroupID=a.GroupID and DATEDIFF(m,MonthDate,@LastDay)=0
	  )    
  
  
--Insert transaction to AffTrans and AffCommission  
declare @WinlostDate smalldatetime  
select @WinlostDate=current_timestamp  
  
begin transaction  
  
BEGIN TRY  
 declare @Temp table(RefID int, AffID int, SportID tinyint)   
 Insert into AffCommission(AffID,GroupID,SportID,WinlostDate,QualifiedMember,Commission,AffWinlost  
	   ,Status,MemberWinlost,MemberBonus,MemberAdjustment,MemberPSP,MemberSum  
		,Marketing,HasBonus,HasAdjustment,HasMarketing,HasPSP,MemberDeposit,MemberTurnover  
		,HasOddsFee,MemOddsFee,HasPlayTechFee,MemPlayTechFee)  
 output inserted.RefID,inserted.AffID,inserted.SportID into @Temp   
 select AffID,GroupID,SportID,@LastDay,TotalQM,Commission   
	,(NetWinlost- isnull(a.MemBonus,0)*isnull(a.BonusPercent,0))  * isnull(Commission,0)   
	, @Status  
	,MemWinlost  
	,MemBonus  
	,MemAdjustment  
	,MemPSP  
	,-NetWinlost  
	, abs(isnull(MemWinlost,0)) * isnull(MarketingPercent,0)  
	,(case when isnull(a.BonusPercent,0)<>0 then 1 else 0 end)  
	,(case when isnull(a.AdjustmentPercent,0)<>0 then 1 else 0 end)  
	,(case when isnull(a.MarketingPercent,0)<>0 then 1 else 0 end)   
	,(case when isnull(a.PSPPercent,0)<>0 then 1 else 0 end)    
	,MemDeposit  
	,MemTurnover  
	,(case when isnull(a.OddsFeePercent,0)<>0 then 1 else 0 end)    
	, abs(isnull(MemWinlost,0)) * isnull(OddsFeePercent,0)  
	, (case when isnull(a.PlayTechRoyaltiesPercent,0)<>0 then 1 else 0 end)     
	, abs(isnull(MemWinlost,0)) * isnull(a.PlayTechRoyaltiesPercent,0)  
 from #AffSummary a (nolock)  
   
 update d  
 set d.RelNo=(select top(1) RefID from @Temp d1 where d1.AffID=d.AffID and d1.SportID=d1.SportID)  
   from AffCommission d with (rowlock,updlock)         
   where d.WinlostDate=@LastDay  
  
 insert into AffTrans(AffID,TransDate,CompletedDate,Amount,Status,Description,Creator,Currency,TransType)  
   
 select a.AffID,@LastDay,@WinlostDate,sum((NetWinlost-isnull(a.MemBonus,0)*isnull(a.BonusPercent,1))  * isnull(Commission,0)),@Status, 'Monthly Earning',  
   148,a.Currency,@TransType  
 from #AffSummary a (nolock)     
 group by a.AffID,a.Currency  
   
  
 update d  
 set d.RefID=(select top(1) RefID from @Temp d1 where d1.AffID=d.AffID and d1.SportID=@SportsBookID)  
   from AffTrans d with (rowlock,updlock)         
   where d.TransDate=@LastDay and d.TransType=@TransType /*in (@TransType,@MarketingTransType)*/  
   /*Reupdate table AffDaily      
   */  
	
	  
   update ad   
  set   
  ad.AffWinlost = -isnull(ad.MemWinlost,0) *  isnull(a.commission,0),  
  ad.HouseWinlost=-isnull(ad.MemWinlost,0) * (1-isnull(a.commission,0)),  
  ad.AffNetWinlost=(  -isnull(ad.MemWinlost,0)   
	   - isnull(ad.MemPSP,0)*isnull(a.PSPPercent,0)  
	   - abs(isnull(ad.MemWinlost,0)) * isnull(a.OddsFeePercent,0)   
	   - abs(isnull(ad.MemWinlost,0)) * isnull(a.MarketingPercent,0)   
	   - abs(isnull(ad.MemWinlost,0)) * isnull(a.PlayTechRoyaltiesPercent,0)         
		  
		) * isnull(a.commission,0),  
		  
	ad.HouseNetWinlost= ( -isnull(ad.MemWinlost,0)   
	   - isnull(ad.MemPSP,0)*isnull(a.PSPPercent,0)  
	   - abs(isnull(ad.MemWinlost,0)) * isnull(a.OddsFeePercent,0)   
	   - abs(isnull(ad.MemWinlost,0)) * isnull(a.MarketingPercent,0)   
	   - abs(isnull(ad.MemWinlost,0)) * isnull(a.PlayTechRoyaltiesPercent,0)          
		 ) * (1-isnull(a.commission,0))   
	  
   from AffDaily ad with (rowlock,updlock)    
   left join #AffSummary a with (nolock) on a.AffID=ad.AffID and a.SportID=ad.SportID       
   where datediff (mm,ad.Winlostdate, @FirstDay)=0    
	 
   update ad   
  set /*ad.MemMarketing=Cast(isnull(a.HasMarketing,0) as int) *  abs(isnull(ad.MemWinlost,0)) * isnull(a.MarketingPercent,0) ,  
   ad.MemOddsFee=Cast(isnull(a.HasOddsFee,0) as int) *  abs(isnull(ad.MemWinlost,0)) * isnull(a.OddsFeePercent,0) ,         */  
  ad.AffWinlost = -isnull(ad.MemWinlost,0) *  isnull(a.commission,0),  
  ad.HouseWinlost=-isnull(ad.MemWinlost,0) * (1-isnull(a.commission,0)),  
  ad.AffNetWinlost=(  -isnull(ad.MemWinlost,0)   
	   - isnull(ad.MemPSP,0)*isnull(a.PSPPercent,0)  
	   - abs(isnull(ad.MemWinlost,0)) * isnull(a.OddsFeePercent,0)   
	   - abs(isnull(ad.MemWinlost,0)) * isnull(a.MarketingPercent,0)   
	   - abs(isnull(ad.MemWinlost,0)) * isnull(a.PlayTechRoyaltiesPercent,0)          
		  
		) * isnull(a.commission,0),  
		  
	ad.HouseNetWinlost= ( -isnull(ad.MemWinlost,0)   
	   - isnull(ad.MemPSP,0)*isnull(a.PSPPercent,0)  
	   - abs(isnull(ad.MemWinlost,0)) * isnull(a.OddsFeePercent,0)   
	   - abs(isnull(ad.MemWinlost,0)) * isnull(a.MarketingPercent,0)   
	   - abs(isnull(ad.MemWinlost,0)) * isnull(a.PlayTechRoyaltiesPercent,0)          
		 ) * (1-isnull(a.commission,0))   
	  
   from AffDailySummary ad with (rowlock,updlock)    
   left join #AffSummary a with (nolock) on a.AffID=ad.AffID and a.SportID=ad.SportID       
   where datediff (mm,ad.Winlostdate, @FirstDay)=0    
	 
	 
	 
END TRY  
  
BEGIN CATCH  
 rollback transaction   
 drop table #AffSummary  
 PRINT ERROR_MESSAGE()  
 RETURN  
END CATCH  
  
commit transaction


GO

GRANT VIEW DEFINITION ON [dbo].[Task_Aff_MonthlyTransfer] TO [vnAffiliate] AS [dbo]
GO

GRANT VIEW DEFINITION ON [dbo].[Task_Aff_MonthlyTransfer] TO [vnteam] AS [dbo]
GO


