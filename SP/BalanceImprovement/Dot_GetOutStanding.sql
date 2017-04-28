ALTER PROCEDURE [dbo].[Dot_GetOutStanding]
    @custid int,
    @OutStanding money = 0 out,
    @MaxTrans datetime out
AS
    -- 20160112@TWJoe(DBTrans): Create SP
	-- 20170203@Cooper(DBtrans) : hint index use ix_custid on translog/bettransRng/bettransLC table
	-- 20170209@Leon(DBtrans) : remove index hint of ix_custid on translog/bettransRng/bettransLC table
BEGIN
    SET NOCOUNT ON;    
      
    SELECT    
            @OutStanding = isnull(SUM(CASE ruben  WHEN 0 THEN actual_stake ELSE 0 END),0),
            @MaxTrans = MAX(transdate)
    FROM bettrans with (nolock) 
    WHERE custid=@custid

    SELECT 
            @OutStanding = @OutStanding + isnull(SUM(actual_stake),0),
			@MaxTrans = case when MAX(transdate) is null then @MaxTrans
			                 when isnull(@MaxTrans,MAX(transdate))>MAX(transdate) then @MaxTrans
			                 else MAX(transdate) end              		                 
    FROM    translog with (nolock) 
    WHERE custid=@custid and statusid=0

    SELECT 
			@OutStanding = @OutStanding + isnull(SUM(CASE statusid WHEN 0 THEN actual_stake ELSE 0 END),0),
			@MaxTrans = case when MAX(transdate) is null then @MaxTrans 
							 when isnull(@MaxTrans,MAX(transdate))>MAX(transdate) then @MaxTrans 
							 else MAX(transdate) end		
    FROM dbo.BettransRNG with (nolock) 
    WHERE custid = @custid and IsSum=0

    SELECT 
			@OutStanding = @OutStanding + isnull(SUM(CASE statusid WHEN 0 THEN actual_stake ELSE 0 END),0),
			@MaxTrans = case when MAX(transdate) is null then @MaxTrans 
							 when isnull(@MaxTrans,MAX(transdate))>MAX(transdate) then @MaxTrans 
							 else MAX(transdate) end		
    FROM dbo.BettransLC with (nolock) 
    WHERE custid = @custid and IsSum=0

	SET @MaxTrans=isnull(@MaxTrans,getdate())
END