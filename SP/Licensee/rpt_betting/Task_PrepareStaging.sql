/*<info serverAlias="DBLIC-bodb_LicenseeReport,DBBAL-bodb_LicenseeReport" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Task_PrepareStaging]
    @DateFrom		SMALLDATETIME = NULL
    ,@DateTo		SMALLDATETIME = NULL
	,@ErrorMsg		VARCHAR(MAX) = '' OUTPUT
	,@ProductCodes	VARCHAR(1000) = ''
AS

/*
Created:
Task:
DB: DBLIC.bodb_LicenseeReport

Revisions:
    -20120423@Jim: Add more information for BARM agent 
    -20120613@Don: Fixed bug 'custid=0'
    -20150127@Don: Expand bet type ranges for Sportbook when processing BA
	-20150324@Jim: exclude waiting ticket
	-20150623@Patrick: Support BetTrade
	-20150003@Patrick: #42910 (Exclude ticket 901 for BA ticket)
	-20150929@Patrick: Revise code of BetTrade
	-20160118@Patrick: Hotfix: #51053 for bettrade - turn off BA for ticket 901
	-20160318@Victor:  Support Colossus bet - [Redmine: #52575]
	-20160726@Francis: Move SP to bodb_LicenseeReport - [Redmine: #60449]
	-20160727@Jim: LRF - Commercial terms changed for Bet Trade [Redmine: #61342]
	-20160913@Jim: LRF - Implement Colossus Bets [Redmine: #63785 :fix refno issue]
	-20161121@Sophia: Correct formula CashOutAmount,WinPrizeAmount value [RedmineID : #67473]
	-20161205@Jim: LA - GD commercial terms changed for credit sites [RedmineID #67310]
	-20170323@Harper: LA - Implement Cashout Product [Redmine: #73310]
	-20170525@Paul: Check IsStagingBettrans flag before staging bettrans; insert sporttype, eventdate into staging match table [Redmine: #72914]
	-20170619@Harper: LA - Edit formula when cout CO ticket [Redmine: #78085]
	-20180316@Harper: LA - Colossus Bets Free Play Integration [RedmineID: #89768]
	-20180910@Bruce: LA - WL report for Poker Games & Bullfighting [#98487]
	-20181107@Patrick: DB052 Indexes Revolution [Redmine: #103572]
	-20181226@bruce: Implement E-sport 2 [Redmine: #105723]
	-20190306@Parsons: Implement BetBuilder [Redmine: #108995]
	-20190819@Parsons: Provide House Turnover In NG WL Report [Redmine: #117674]
	- 20190910@Amanda: Add bet types that support Half Won/ Half Lose [RedmineID: #118300]
	- 20190923@Amanda: Change the way to handle Half Won/ Half Lose bet types [RedmineID: #119879]
	- 20191205@Percy: Enhance performance [RedmineID: #125028]
	- 20210816@Sophia: add DBBAL [Redmine: #154300]

Param's Explanation:
	EXEC Task_PrepareStaging '2018-02-01', '2018-02-28'
*/
BEGIN
	SET NOCOUNT ON;

	UPDATE bodb02.dbo.SystemSettings WITH(ROWLOCK, UPDLOCK)
	SET VValue = 1
	WHERE VName = 'IsStagingBettrans'
		AND VValue = 0

	IF @@ROWCOUNT = 0
	BEGIN
		SET @ErrorMsg = 'Another task is using staging bettrans';

		RAISERROR(@ErrorMsg, 16, 1)

		RETURN
	END

	DECLARE @FromDate SMALLDATETIME, @ToDate SMALLDATETIME

	IF @DateFrom IS NOT NULL AND @DateTo IS NOT NULL
		SELECT @ToDate = CONVERT(VARCHAR(10), @DateTo, 120), @FromDate = CONVERT(VARCHAR(10), @DateFrom, 120)
	ELSE
		SELECT @ToDate = CONVERT(VARCHAR(10), DATEADD(DAY, -1, GETDATE()), 120), @FromDate = DATEADD(DAY, -2, @ToDate)

	-- outright --
	TRUNCATE TABLE dbo.outright
	
    INSERT INTO dbo.outright(matchid, leagueid)
	SELECT orid AS matchid, leagueid
    FROM bodb02.dbo.outright WITH (NOLOCK)
    WHERE eventdate BETWEEN @FromDate AND @ToDate
    UNION ALL
    SELECT orid AS matchid, leagueid
    FROM bodb02.dbo.outright14 WITH (NOLOCK)
    WHERE eventdate BETWEEN @FromDate AND @ToDate

	-- match --
	TRUNCATE TABLE dbo.match
	
    INSERT INTO dbo.match(matchid, leagueid, sporttype, eventdate)
	SELECT matchid, leagueid, sporttype, eventdate
    FROM bodb02.dbo.match (NOLOCK)
    WHERE eventdate BETWEEN @FromDate AND @ToDate
    UNION ALL
    SELECT matchid, leagueid, sporttype, eventdate
    FROM bodb02.dbo.match14 (NOLOCK)
    WHERE eventdate BETWEEN @FromDate AND @ToDate
	  
	-- bettrans --
	TRUNCATE TABLE dbo.bettrans

	DECLARE @WinlostDate SMALLDATETIME
	SELECT  @WinlostDate = @ToDate

	DECLARE @MaxTryCount TINYINT = 3, @NumberTryCount TINYINT = 0, @IsErr BIT = 1
	
	WHILE @WinlostDate >= @FromDate
	BEGIN
		SET @NumberTryCount = 0
		SET @IsErr = 1

		WHILE @NumberTryCount < @MaxTryCount
		BEGIN
			BEGIN TRY
				EXEC dbo.Task_PrepareStaging_Bettrans @WinlostDate = @WinlostDate, @ErrorMsg = @ErrorMsg OUTPUT, @ProductCodes = @ProductCodes

				SET @IsErr = 0
				BREAK
			END TRY
			BEGIN CATCH
				IF ERROR_NUMBER() = 2627  -- Violates Primary Key
				BEGIN
					DELETE dbo.bettrans WHERE winlostdate = @WinlostDate
					
					SET @NumberTryCount = @NumberTryCount + 1
					SET @IsErr = 1
					SET @ErrorMsg = ERROR_MESSAGE()
				END
				ELSE
				BEGIN
					SET @ErrorMsg = 'Task_PrepareStaging failed on ' + CONVERT(VARCHAR(10), @WinlostDate, 120) + ERROR_MESSAGE()

					RAISERROR(@ErrorMsg, 16, 1)

					RETURN
				END
			END CATCH
		END

		IF @IsErr = 1
		BEGIN
			SET @ErrorMsg = 'Task_PrepareStaging failed on ' + CONVERT(VARCHAR(10), @WinlostDate, 120) + @ErrorMsg

			RAISERROR(@ErrorMsg, 16, 1)
		END

		SELECT @WinlostDate = DATEADD(DAY, -1, @WinlostDate)
	END
END
GO