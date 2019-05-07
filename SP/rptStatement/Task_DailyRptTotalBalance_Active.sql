/*<info serverAlias="DBRPT-bodb_Report" executers="" viewers="" isFunction="0" isNested="0"></info>*/
 
ALTER PROCEDURE [dbo].[Task_DailyRptTotalBalance_Active]
	@Winlostdate DATE
AS

/*
	Created by:20190507@Sophia
	Task: insert/ update data on RptTotalBalance_Active , data form MoveBetDay to today
	DB: DBRPT.bodb_Report
	Revisions:
		- 20190507@Sophia:  Initial data [redmine: #109293]
 */

BEGIN

	SET NOCOUNT ON

	DECLARE @rptStatementTable TABLE(
		Winlostdate			DATE
		,Custid				INT
		,OpeningBalance		MONEY	NULL		
		,TransferAmt		MONEY	NULL
		,Winlost			MONEY	NULL
		,Comm				MONEY	NULL
		,ClosingBalance		MONEY	NULL		
	)

	-- 1: get sum data from Bettrans into rptStatement
		-- Member
		INSERT INTO @rptStatementTable(
			Winlostdate
			,Custid			
			,Winlost
			,Comm
		)
		SELECT
			winlostdate
			,custid
			,SUM(winlost - actual_stake) AS winlost
			,SUM(playercomm) AS comm
		FROM
			bodb02.dbo.Bettrans WITH(NOLOCK)
		WHERE
			winlostdate = @Winlostdate
			AND statusID NOT IN (0,1,102,101) -- 'running','waiting','VOID','REJECT'
			AND bettype <= 19999
			AND ruben = 1
		GROUP BY
			winlostdate, custid
			
		-- Agent
		INSERT INTO @rptStatementTable(
			Winlostdate
			,Custid		
			,Winlost
			,Comm
		)
		SELECT
			winlostdate
			,recommend		
			,SUM(awinlost) AS winlost
			,SUM(comm - playercomm) AS comm
		FROM
			bodb02.dbo.Bettrans WITH(NOLOCK)
		WHERE
			winlostdate = @Winlostdate
			AND statusID NOT IN (0,1,102,101) -- 'running','waiting','VOID','REJECT'
			AND bettype <= 19999
			AND ruben = 1
		GROUP BY
			winlostdate, recommend
		
		-- Master
		INSERT INTO @rptStatementTable(
			Winlostdate
			,Custid			
			,Winlost
			,Comm
		)
		SELECT
			winlostdate
			,mrecommend			
			,SUM(mwinlost) AS winlost
			,SUM(acomm - comm) AS comm		
		FROM
			bodb02.dbo.Bettrans WITH(NOLOCK)
		WHERE
			winlostdate = @Winlostdate
			AND statusID NOT IN (0,1,102,101) -- 'running','waiting','VOID','REJECT'
			AND bettype <= 19999
			AND ruben = 1
		GROUP BY
			winlostdate, mrecommend
		
		-- Super
		INSERT INTO @rptStatementTable(
			Winlostdate
			,Custid
			,Winlost
			,Comm
		)
		SELECT
			winlostdate
			,srecommend
			,SUM(swinlost) AS winlost
			,SUM(scomm - acomm) AS comm
		FROM
			bodb02.dbo.Bettrans WITH(NOLOCK)
		WHERE
			winlostdate = @Winlostdate
			AND statusID NOT IN (0,1,102,101) -- 'running','waiting','VOID','REJECT'
			AND bettype <= 19999
			AND ruben = 1
		GROUP BY
			winlostdate, srecommend
		
		    
		--3: Transfer rptStatement	
		INSERT INTO @rptStatementTable(
			Winlostdate
			,Custid
			,TransferAmt 
		)
		SELECT 
			winlostdate
			,custid
			,SUM(winlost - actual_stake) AS TransferAmt 
		FROM  
			bodb02.dbo.bettrans WITH(NOLOCK)
		WHERE  
			matchid = 0 
			AND bettype > 20000  
			AND bettype NOT IN (23001,23002,23101,23102,23201,23202)
			AND winlostdate = @Winlostdate  
		GROUP BY 
			winlostdate, custid
			
		--4: Opening Balance for rptStatement
		DECLARE @CurrentBU_Date DATETIME  

		SELECT TOP 1 @CurrentBU_Date = winlostdate
		FROM bodb02.dbo.bettrans WITH(NOLOCK) 
		WHERE matchid = 0 AND bettype = 20000

		/*IF (@Winlostdate = @CurrentBU_Date)
		BEGIN
			--get Opening Balance with bettype = 20000 from bettrans
			INSERT INTO @rptStatementTable(
				Winlostdate
				,Custid
				,OpeningBalance
			)
			SELECT
				@Winlostdate
				,custid
				,SUM(winlost - actual_stake) AS OpeningBalance
			FROM 
				bodb02.dbo.bettrans WITH(NOLOCK)
			WHERE 
				winlostdate = @CurrentBU_Date
				AND bettype = 20000
			GROUP BY custid
			
		END
		ELSE -- winlostdate > CurrentBU_Date
		*/
		BEGIN
			-- Opening Balance for Member
			INSERT INTO @rptStatementTable(
				Winlostdate
				,custid
				,OpeningBalance
			)
			SELECT
				@Winlostdate
				,custid
				,SUM(winlost - actual_stake + playercomm) AS OpeningBalance
			FROM
				bodb02.dbo.bettrans WITH(NOLOCK)
			WHERE
				ruben = 1
				AND winlostdate >= @CurrentBU_Date 
				AND winlostdate < @Winlostdate 
				AND	custid <> recommend
				AND custid <> mrecommend
				AND custid <> srecommend
			GROUP BY custid
			
			-- Opening Balance for Agent
			INSERT INTO @rptStatementTable(
				Winlostdate
				,custid
				,OpeningBalance
			)
			SELECT	
				@Winlostdate
				,recommend
				,SUM(CASE WHEN custid = recommend THEN winlost - actual_stake ELSE awinlost + comm - playercomm END) AS OpeningBalance
			FROM
				bodb02.dbo.bettrans WITH(NOLOCK)
			WHERE
				ruben = 1 
				AND winlostdate >= @CurrentBU_Date 
				AND winlostdate < @Winlostdate 
			GROUP BY recommend

			-- Opening Balance for Master
			INSERT INTO @rptStatementTable(
				Winlostdate
				,custid
				,OpeningBalance
			)
			SELECT
				@Winlostdate	
				,mrecommend
				,SUM(CASE WHEN custid = mrecommend THEN winlost - actual_stake ELSE mwinlost + acomm - comm END) AS OpeningBalance
			FROM
				bodb02.dbo.bettrans WITH(NOLOCK)
			WHERE
				ruben = 1 
				AND winlostdate >= @CurrentBU_Date 
				AND winlostdate < @Winlostdate 
			GROUP BY mrecommend

			-- Opening Balance for Super
			INSERT INTO @rptStatementTable(
				Winlostdate
				,custid
				,OpeningBalance
			)
			SELECT
				@Winlostdate
				,srecommend
				,SUM(CASE WHEN custid = srecommend THEN winlost - actual_stake ELSE swinlost + scomm - acomm END) AS OpeningBalance
			FROM
				bodb02.dbo.bettrans WITH(NOLOCK)
			WHERE
				ruben = 1 
				AND winlostdate >= @CurrentBU_Date 
				AND winlostdate < @Winlostdate
			GROUP BY srecommend
		END			
				

		-- UPDATE data rptTotalBalance_Active
		IF EXISTS(SELECT TOP 1 1 FROM rptTotalBalance_Active WITH(NOLOCK) WHERE winlostdate = @Winlostdate)
		BEGIN
			DELETE dbo.rptTotalBalance_Active WITH (ROWLOCK)
			WHERE  winlostdate = @Winlostdate
		END

		-- INSERT INTO rptTotalBalance_Active
		INSERT INTO dbo.rptTotalBalance_Active(
			Winlostdate
			,Custid
			,OpeningBalance			
			,TransferAmt
			,Winlost
			,Comm
			,ClosingBalance		
		)
		SELECT 
			tmp.Winlostdate
			,tmp.Custid
			,SUM(ISNULL(tmp.Openingbalance, 0)) AS [OpeningBalance]		
			,SUM(tmp.Transferamt) AS [TransferAmt]
			,SUM(CASE WHEN tmp.BetCount > 0 THEN tmp.Winlost ELSE NULL END) AS [Winlost]
			,SUM(CASE WHEN tmp.BetCount > 0 THEN tmp.Comm ELSE NULL END) AS [Comm]
			,SUM(ISNULL(tmp.Openingbalance, 0) + ISNULL(tmp.[Winlost], 0) + ISNULL(tmp.[Comm], 0) + ISNULL(tmp.[TransferAmt], 0)) AS ClosingBalance 
		FROM 
			@rptStatementTable tmp
		GROUP BY 
			tmp.Winlostdate
			,tmp.Custid
		HAVING
			DATEPART(DW,tmp.Winlostdate)=7
			OR
			(SUM(tmp.BetCount) 
			+ SUM(tmp.VoidCount)
			+ SUM(tmp.TransCount)) <> 0		

	 
END
GO