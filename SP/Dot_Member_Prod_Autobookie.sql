USE [bodb02]
GO

/****** Object:  StoredProcedure [dbo].[Dot_Member_Prod_Autobookie]    Script Date: 01/27/2015 03:40:51 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[Dot_Member_Prod_Autobookie]
	@custid int,
	@oddsid int,
	@matchid int,
	@odds smallmoney,
	@bettype int,
	@betteam nvarchar(10),
	--@betfrom nvarchar(11) = 'i',
	@stake_to_company float,		-- pass from Dot_Member_CheckCustSetting
	@OriginalOdds float = NULL,
	@currency int,					-- pass from Dot_Member_CheckCustSetting
	@autosuspend bit,
	@liveindicator bit,
	@isPhoneBetting bit = 0,
	@isThirdParty bit = 0
AS
BEGIN

	SET NOCOUNT ON;

	Declare 
	@gapodds float,
	@newodds float,
	@odds1a float,
	@odds2a float,
	@diffbalance float,
	@newoffersetup bit,
	@temp_rowcount int,
	@temp_error int,
	--@hometotal float, -- moved to insertbet 
	--@awaytotal float, -- moved to insertbet 
	@oddsstatusnew nvarchar(50),
	@result varchar(50),
	@str varchar(500),
	--@autobookie_strlog varchar(500),
	--@autosuspend_strlog varchar(500),
	@shiftDiffbalance float,
	@oldchangetime datetime,
	@newchangetime datetime,
	@gapodds1 float,
	@gapodds2 float,
	@allowance2 float --autobookie gapodds: bet team home - bet team away

	set @oldchangetime = CURRENT_TIMESTAMP
	set @newchangetime = CURRENT_TIMESTAMP
	set @gapodds1 = 0
	set @gapodds2 = 0
	set @allowance2 = 0
	set @shiftDiffbalance=  0 -- used to record diffBal if needing rollback in insertbet
	
	-- 20110823@Tim(DB02): requested by Ah Pau,Ah Siong,JackyTing that autobookie need to consider odds
	-- 20130723@TWJoe(DB02): add @isPhoneBetting , @isThirdParty and no use @betfrom
	-- 20130903@TWJoe(DB02): @isThirdParty using autobookie as normal user
	-- 20131216@Stanley(DB02): risk + ((stakerange-risk)/2) ==> stakerange , risk2 + ((stakerange2-risk2)/2) ==> stakerange2
	-- 20131223@Vivi(DB02): if new odds < -1 or > 1 then closed odds. (request by Tim)
	-- 20140825@TWJoe(DB02): betteam add o/u o/e
	
	set @stake_to_company = @stake_to_company*case when abs(@odds)>1 then abs(@odds) else 1 end 
 
	if @betteam in ('h','o')
	begin      
	 ----auto bookie update ----  
		
		  update odds with (rowlock,updlock)       
		  set 
			@gapodds1 = gapodds1,
			@gapodds2 = gapodds2,
			@allowance2 = allowance2,
			@gapodds = CASE
	     	when @isPhoneBetting=1
				then 0 
			when @stake_to_company + IsNull(diffbalance, 0) >= stakerange
				then gapodds1
			when @stake_to_company + IsNull(diffbalance, 0) >= risk
				then gapodds2
	     	else
				0
			end,
		   @Odds1a=odds1a=(case     
			  when abs(odds1a-@gapodds)>1 then 2-abs(odds1a-@gapodds) else odds1a-@gapodds   
			 end),      
		   @Odds2a=odds2a=(case       
			  when abs(odds2a+@gapodds)>1 then -(2-abs(odds2a+@gapodds)) else odds2a+@gapodds
			 end), 
			@Oldchangetime = changetime,
			@Newchangetime = changetime =	CASE 
									when @isPhoneBetting=1 then changetime
									when @stake_to_company+diffbalance>=risk then CURRENT_TIMESTAMP
		     						else changetime
								end,
		   @DiffBalance = diffbalance=	case 
											when @isPhoneBetting=1 and @currency <> 20 then 0
											when @stake_to_company+diffbalance>=risk then 0 
											else diffbalance+@stake_to_company 
										end,
			--allowance=case when  @stake_to_company+diffbalance>=risk then  diffbalance+@stake_to_company else 0 end,      
		@oddsstatusnew = oddsstatus = CASE 
			when (@odds1a >= 0 AND @odds1a < 0.02) OR (@OriginalOdds >= 0 AND @odds1a < 0) OR (@odds1a < -1) OR (@odds1a > 1) then 'closed' 
			when @odds1a < 0 AND @odds1a > maxodds then 'closed' 
			when @odds2a < 0 AND @odds2a > maxodds then 'closed' 
			when @odds1a >= 0 AND @odds1a < minodds then 'closed' 
			when @odds2a >= 0 AND @odds2a < minodds then 'closed' 
			when autobookie  = 0 AND @gapodds > 0 then 'suspend' 
			when autosuspend = 1 AND @autosuspend = 1 then 'suspend' 
			else oddsstatus END,
			--@hometotal=hometotal=hometotal+@stake_to_company*case when 
		   --abs(@odds)>1 then abs(@odds) else 1 end , -- moved to insertbet 
		  @newoffersetup=newoffersetup 
		  where 
		   oddsid=@oddsid and (round(@OriginalOdds,3)=round(odds1a,3) or @isThirdParty=1)

		   set @temp_rowcount=@@rowcount      
		   set @temp_error =@@error
			set @newodds=@Odds1a      
	   		if (@temp_rowcount=0)      
			begin
				--set @transid=-2
				set @result='Odds-changed'
			end
		
	end        
	else      
	begin      
		  
		   update odds with (rowlock,updlock)       
		   set 
			@gapodds1 = com1,
			@gapodds2 = com2,
			@allowance2 = allowance2, 
			@gapodds = CASE
	     	when @isPhoneBetting=1
				then 0
			when @stake_to_company - IsNull(diffbalance, 0) >= stakerange2
				then com1
			when @stake_to_company - IsNull(diffbalance, 0) >= risk2
				then com2
	     	else
				0
			end,    
		   @Odds2a = odds2a=(case       
				when abs(odds2a-@gapodds)>1 then 2-abs(odds2a-@gapodds) else odds2a-@gapodds  end),      
		   @Odds1a = odds1a=(case       
				when abs(odds1a+@gapodds)>1 then -(2-abs(odds1a+@gapodds)) else odds1a+@gapodds end),   
			@Oldchangetime = changetime,
			@Newchangetime = changetime =
						CASE
							when @isPhoneBetting=1 then changetime
							when @stake_to_company-diffbalance>=risk2 then CURRENT_TIMESTAMP
		     				else changetime
						 end,    
			@DiffBalance = diffbalance=	case 
											when @isPhoneBetting=1 and @currency <> 20 then 0
											when (@stake_to_company-diffbalance)>=risk2 then 0 
											else diffbalance-@stake_to_company 
										end,
			--allowance2=case when (@stake_to_company-diffbalance)>=risk2 then  diffbalance-@stake_to_company else 0 end,      
			@oddsstatusnew=oddsstatus = CASE
					when (@odds2a >= 0 AND @odds2a < 0.02) OR (@OriginalOdds >= 0 AND @odds2a < 0) OR (@odds2a < -1) OR (@odds2a > 1) then 'closed'
					when @odds1a < 0 AND @odds1a > maxodds then 'closed'
					when @odds2a < 0 AND @odds2a > maxodds then 'closed'
					when @odds1a >= 0 AND @odds1a < minodds then 'closed'
					when @odds2a >= 0 AND @odds2a < minodds then 'closed'
					when autobookie  = 0 AND @gapodds <> 0 then 'suspend'
					when autosuspend = 1 AND @autosuspend = 1 then 'suspend'
					else oddsstatus end,
	 		--@awaytotal=awaytotal=awaytotal+@stake_to_company*case when abs(@odds)>1 then abs(@odds) else 1 end, -- moved to insertbet 
	 		@newoffersetup=newoffersetup      
	   		where       
	    		oddsid=@oddsid        
	    		and (round(@OriginalOdds,3)=round(odds2a,3) or @isThirdParty=1)

	    		set @temp_rowcount=@@rowcount      
	    		set @temp_error =@@error  
				set @newodds=@Odds2a    
	    	if (@temp_rowcount=0)      
			begin
				set @result='Odds-changed'
			end     
		
	end 
	
	if (@temp_rowcount<>0 and @DiffBalance<>0) 
		set @shiftDiffbalance=@stake_to_company
		
	-- autobookie
	IF IsNull(@gapodds, 0) <> 0 and (@liveindicator=1)
	BEGIN
		-- if odds change in more than one second
		IF DATEDIFF(s, @Oldchangetime, @Newchangetime) > 1
		BEGIN
			-- reset allowance2
			update odds with (rowlock,updlock)       
			set allowance2 = CASE WHEN @betteam in ('h','o') THEN @gapodds ELSE @gapodds*-1 END
			where oddsid = @oddsid
		END
		ELSE
		BEGIN
			IF (ABS(@allowance2+CASE WHEN @betteam in ('h','o') THEN @gapodds ELSE @gapodds*-1 END) >= (@gapodds1*2+@gapodds2))
			BEGIN
				-- suspend odds, clear allowance2, write log
				update odds with (rowlock,updlock)       
				set allowance2 = 0, oddsstatus = 'suspend'
				where oddsid = @oddsid

				select @str = 'Autobookie_Activated and suspend b/c too many autobookie in 1 sec'
				exec dbo.logfile @custid, @str
			END
			ELSE
			BEGIN
				update odds with (rowlock,updlock)       
				set allowance2 = allowance2 + CASE WHEN @betteam in ('h','o') THEN @gapodds ELSE @gapodds*-1 END
				where oddsid = @oddsid
			END
		END
	END


	-- vivi@2010-3-4
	-- autobookie check, either odds go lower than 0.02, or odds been switch between positive to negative
	IF CASE 
		when @betteam in ('h','o') AND ( (@odds1a >= 0 AND @odds1a < 0.02) OR (@OriginalOdds >= 0 AND (@odds1a < 0)) ) THEN 1
		when @betteam in ('a','u','e') AND ( (@odds2a >= 0 AND @odds2a < 0.02) OR (@OriginalOdds >= 0 AND (@odds2a < 0)) ) THEN 1
		ELSE 0 END
		= 1
	BEGIN
		UPDATE odds with (rowlock, updlock)
		SET
			odds1a = 0, odds2a = 0,
			changetime = CURRENT_TIMESTAMP
		WHERE oddsid = @oddsid

		
		select @str = 'Autobookie matchid:' + CAST(@matchid as nvarchar(50)) + ' oddsid:' + CAST(@oddsid as nvarchar(50)) + ' either odds go lower than 0.02, or odds been switch between positive to negative, update odds1a,odds2a to zero'
		exec dbo.logfile @custid, @str
	END

	IF IsNull(@gapodds, 0) <> 0
	BEGIN
		set @str = 'Autobookie_Activated matchid:' + CAST(@matchid as nvarchar(50)) + ' creator:' + CAST(@custid as nvarchar(50))  + ' oddsid:' + CAST(@oddsid as nvarchar(50)) + ' bettype:' + CAST(@bettype as nvarchar(20)) + ' betteam:' + @betteam + ' gap:' + CONVERT(nvarchar(10), @gapodds) + ' odds1:' + CONVERT(nvarchar(10), @Odds1a) + ' odds2:' + CONVERT(nvarchar(10), @Odds2a) + ' status:' + @oddsstatusnew
		
		exec dbo.logfile @custid, @str
		
		----Autosuspend 1st odds, dead ball only	
		UPDATE odds with (rowlock,updlock)
			SET oddsstatus = 'suspend' 
		WHERE matchid = @matchid 
			AND bettype = CASE @bettype WHEN 1 THEN 7 WHEN 3 THEN 8 ELSE 0 END
			AND liveindicator = 0
			AND ISNULL(autoreject,1) = 1
			AND oddsstatus NOT IN ('closed','closeprice','internal')
		
		if (@@ROWCOUNT > 0)
		BEGIN
			set @str = 'Auto suspend 1st odds by ft autobookie matchid:' + CAST(@matchid as nvarchar(50)) + ' ft oddsid:' + CAST(@oddsid as nvarchar(50)) + ' bettype:' + CAST(@bettype as nvarchar(20))
			exec dbo.logfile @custid, @str
		END
	END
	
	-- 20110920@Vivi: if odds - parlay profit adjust lower than 0.02 then disabled parlay
	Declare @odds1a_tmp float, @odds2a_tmp float, @ProfitAdjust float
	select @ProfitAdjust = isnull(ProfitAdjust,0) from Dot_ParlayMatchSetting with (nolock)
	where matchid = @matchid and bettype = @bettype and liveindicator=@liveindicator
	IF (@ProfitAdjust<>0)
	BEGIN
		select @odds1a_tmp=@Odds1a, @odds2a_tmp=@Odds2a
		IF (@odds1a_tmp < 0) SELECT @odds1a_tmp = @odds1a_tmp + 2
		IF (@odds2a_tmp < 0) SELECT @odds2a_tmp = @odds2a_tmp + 2

		 IF ((@odds1a_tmp-(@ProfitAdjust*0.005)) < 0.02) OR ((@odds2a_tmp-(@ProfitAdjust*0.005)) < 0.02)
		 BEGIN
			UPDATE Dot_ParlayMatchSetting with (rowlock, updlock) set [enable] = 0 WHERE matchid = @matchid and bettype = @bettype and liveindicator=@liveindicator
				
			SELECT @str = 'Disabled ParlayMatchSetting matchid:' + CAST(@matchid as nvarchar(20)) + ' bettype:' + CAST(@bettype as nvarchar(20)) + ' liveindicator:' + CAST(@liveindicator as nvarchar(10)) 
			exec dbo.logfile @custid, @str
		 END
	END

	select 
		@newodds as newodds,
		@diffbalance as diffbalance, 
		0 as autobookie,
		@shiftDiffbalance as shiftDiffbalance,
		@newoffersetup as newoffersetup,
		@oddsstatusnew as oddsstatusnew,
		--@hometotal as hometotal,
		--@awaytotal as awaytotal,
		IsNull(@result,'') as result
		--IsNull(@autobookie_strlog,'') as autobookie_strlog, IsNull(@autosuspend_strlog,'') as autosuspend_strlog
END

GO

GRANT EXECUTE ON [dbo].[Dot_Member_Prod_Autobookie] TO [Dot_Member] AS [dbo]
GO

GRANT VIEW DEFINITION ON [dbo].[Dot_Member_Prod_Autobookie] TO [vnteam] AS [dbo]
GO


