ALTER PROCEDURE [dbo].[Task_ReportCheckSum]
AS
/*
Created: 20110630@Don
Task : perform checksum data between SA and IBC and notify us about the discrepancy of data between SA & IBC (if have)
DB: DB052.bodb_Licensee

Revisions:
	
Param's Explanation:

*/

declare	@datestart smalldatetime,
		@dateend smalldatetime,
		@bettrans14_end smalldatetime

declare	@betcount_sa int,
		@betcount_ibc int
		
declare @distance smallint,
		@date smalldatetime,
		@error_msg varchar(500)
		
DECLARE @bettrans_ibc TABLE
(
    winlostdate smalldatetime,
    betcount int
)



select 
	@datestart = min(winlostdate), 
	@dateend = DATEADD(day, -1, CONVERT(varchar(10),current_timestamp,120)),
	@bettrans14_end = max(winlostdate), 
	@distance = cast((@dateend - @datestart) as tinyint) 
FROM db06.bodb02.dbo.bettrans14 with(nolock)
WHERE custid<>0 and status not in ('void','reject','running') 

-- for test
/*
select 
	@datestart = '20110418', 
	@dateend = '20110418',
	@bettrans14_end = '20110418', 
	@distance = cast((@dateend - @datestart) as tinyint) 
*/



if (isnull(@distance,0) < 0)
begin
	RAISERROR('Data is not available to check BetCount.',16,1)
end

declare @max_distance tinyint
select @max_distance = 12
IF (@distance > @max_distance)
    SELECT @distance = @max_distance, @datestart = DATEADD(DAY, ((-1)*@max_distance), @dateend)



/* ***** Check sum of bet count without currency UUS ***** */
while (1=1)
begin
	
	set @date = dateadd(day, @distance, @datestart)

	if (@date > @bettrans14_end)
	    INSERT INTO @bettrans_ibc (winlostdate, betcount) 
		select @date, count(*) betcount
		from db06.bodb02.dbo.bettrans with(nolock)
		where winlostdate = @date
			and bettype < 19999
			and ruben = 1
			AND statusID NOT IN (1,101,102,103,121) -- ('waiting','REJECT','Void','REFUND','done')
			AND currency <> 20
	else
		INSERT INTO @bettrans_ibc (winlostdate, betcount) 
		select @date, count(*) betcount
			from db06.bodb02.dbo.bettrans14 with(nolock)
			where winlostdate = @date
				and bettype < 19999
				and ruben = 1
			    AND statusID NOT IN (1,101,102,103,121) 
				AND currency <> 20

	set @distance = @distance - 1
	if (@distance < 0)
		break

	waitfor delay '000:00:00.200'
	
END


-- Check for rpt_Betting
SELECT TOP 1 @date = ibc.winlostdate, @betcount_ibc = ibc.betcount, @betcount_sa = [CUBE].betcount
FROM @bettrans_ibc ibc 
    INNER JOIN (
        select rptDate, sum(BetCount) BetCount
        from dbo.rpt_Betting (nolock)
        where rptDate >= @datestart AND rptDate <= @dateend 
			AND [status] NOT IN (1,101,102,103,121) 
            AND CurrencyID <> 20
        GROUP BY rptDate ) [CUBE] ON ibc.winlostdate = [CUBE].rptDate
WHERE ibc.betcount <> CUBE.betcount

if (ISNULL(@betcount_ibc,0) <> ISNULL(@betcount_sa,0))
begin
	select @error_msg = 'There is still discrepancy in BetCount between IBC and SA (rpt_Betting) - ' + 
	    '(' + CAST(@betcount_ibc AS varchar(50)) + ',' + CAST(@betcount_sa AS varchar(50)) + ') - ' + cast(@date as varchar(50))
	RAISERROR(@error_msg, 16, 1)
END
