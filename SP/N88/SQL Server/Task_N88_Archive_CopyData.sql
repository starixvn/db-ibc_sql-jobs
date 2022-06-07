/*<info serverAlias="DBN88-bodb_N88" isFunction="0" isNested="1"></info>*/
ALTER PROCEDURE [dbo].[Task_N88_Archive_CopyData]
	@WinlostDate SMALLDATETIME
AS

/*
	Created: 20220222@Percy
	DB: DBN88-bodb_N88
	Task: Job - Archive data for TpBetRecord - Copy data

	Revisions:
		- 20220222@Percy: Initialize SP [RedmineID: #167823]
		- 20220601@Percy: Handle duplicate primary key [RedmineID: #173790]
*/

BEGIN
	SET NOCOUNT ON

	-- 1. Clean up old data (in case re-run job)
	IF EXISTS (SELECT 1 FROM bodb_N88_Archive.dbo.TpBetRecord_bk WITH (NOLOCK) WHERE WinlostDate = @WinlostDate)
		DELETE bodb_N88_Archive.dbo.TpBetRecord_bk WITH (ROWLOCK, UPDLOCK) WHERE WinlostDate = @WinlostDate

	-- 2. Start copy data
	BEGIN
		-- Get data from table TpBetRecord
		CREATE TABLE #__TpBetRecord (
			TpId INT, TransId VARCHAR(50), GameType INT, CustId VARCHAR(45), UserName VARCHAR(30), CurrencyId INT, SiteId INT, TpUserName VARCHAR(50)
			,TransTime DATETIME, SettledTime DATETIME, Stake DECIMAL(20, 4), WinlostAmount DECIMAL(20, 4), SettlementType TINYINT, TicketStatus TINYINT
			,OriginalState VARCHAR(10), TicketKey BIGINT, CreateTime DATETIME, WinlostDate SMALLDATETIME, ValidBet DECIMAL(20, 4), BonusId INT, Revenue DECIMAL(20, 4)
			,ProgressiveBet DECIMAL(20, 4), ProgressiveWin DECIMAL(20, 4)
			,PRIMARY KEY (TpId, TransId, GameType)
		)

		INSERT INTO #__TpBetRecord
		(
			TpId,TransId,GameType,CustId,UserName,CurrencyId,SiteId,TpUserName,TransTime,SettledTime
			,Stake,WinlostAmount,SettlementType,TicketStatus,OriginalState,TicketKey,CreateTime,WinlostDate
			,ValidBet,BonusId,Revenue,ProgressiveBet,ProgressiveWin
		)
		SELECT
			TpId,TransId,GameType,CustId,UserName,CurrencyId,SiteId,TpUserName,TransTime,SettledTime
			,Stake,WinlostAmount,SettlementType,TicketStatus,OriginalState,TicketKey,CreateTime,WinlostDate
			,ValidBet,BonusId,Revenue,ProgressiveBet,ProgressiveWin
		FROM dbo.TpBetRecord WITH (NOLOCK)
		WHERE WinlostDate = @WinlostDate

		-- Start insert data into TpBetRecord_bk, every 5k rows
		DECLARE @tmpTpBetRecord TABLE (
			TpId INT, TransId VARCHAR(50), GameType INT, CustId VARCHAR(45), UserName VARCHAR(30), CurrencyId INT, SiteId INT, TpUserName VARCHAR(50)
			,TransTime DATETIME, SettledTime DATETIME, Stake DECIMAL(20, 4), WinlostAmount DECIMAL(20, 4), SettlementType TINYINT, TicketStatus TINYINT
			,OriginalState VARCHAR(10), TicketKey BIGINT, CreateTime DATETIME, WinlostDate SMALLDATETIME, ValidBet DECIMAL(20, 4), BonusId INT, Revenue DECIMAL(20, 4)
			,ProgressiveBet DECIMAL(20, 4), ProgressiveWin DECIMAL(20, 4)
			,IsUpdated BIT DEFAULT(0)
			,PRIMARY KEY (TpId, TransId, GameType)
		)

		DECLARE @ErrMsg VARCHAR(100), @IsBreak BIT = 0

		WHILE @IsBreak = 0
		BEGIN
			DELETE TOP (5000) FROM #__TpBetRecord
			OUTPUT
				DELETED.TpId,DELETED.TransId,DELETED.GameType,DELETED.CustId,DELETED.UserName,DELETED.CurrencyId,DELETED.SiteId,DELETED.TpUserName,DELETED.TransTime,DELETED.SettledTime
				,DELETED.Stake,DELETED.WinlostAmount,DELETED.SettlementType,DELETED.TicketStatus,DELETED.OriginalState,DELETED.TicketKey,DELETED.CreateTime,DELETED.WinlostDate
				,DELETED.ValidBet,DELETED.BonusId,DELETED.Revenue,DELETED.ProgressiveBet,DELETED.ProgressiveWin
			INTO @tmpTpBetRecord (
				TpId,TransId,GameType,CustId,UserName,CurrencyId,SiteId,TpUserName,TransTime,SettledTime
				,Stake,WinlostAmount,SettlementType,TicketStatus,OriginalState,TicketKey,CreateTime,WinlostDate
				,ValidBet,BonusId,Revenue,ProgressiveBet,ProgressiveWin
			)

			IF @@ROWCOUNT < 5000
				SET @IsBreak = 1

			BEGIN TRY
				DELETE @tmpTpBetRecord
				OUTPUT
					DELETED.TpId,DELETED.TransId,DELETED.GameType,DELETED.CustId,DELETED.UserName,DELETED.CurrencyId,DELETED.SiteId,DELETED.TpUserName,DELETED.TransTime,DELETED.SettledTime
					,DELETED.Stake,DELETED.WinlostAmount,DELETED.SettlementType,DELETED.TicketStatus,DELETED.OriginalState,DELETED.TicketKey,DELETED.CreateTime,DELETED.WinlostDate
					,DELETED.ValidBet,DELETED.BonusId,DELETED.Revenue,DELETED.ProgressiveBet,DELETED.ProgressiveWin
				INTO bodb_N88_Archive.dbo.TpBetRecord_bk (
					TpId,TransId,GameType,CustId,UserName,CurrencyId,SiteId,TpUserName,TransTime,SettledTime
					,Stake,WinlostAmount,SettlementType,TicketStatus,OriginalState,TicketKey,CreateTime,WinlostDate
					,ValidBet,BonusId,Revenue,ProgressiveBet,ProgressiveWin
				)
				WHERE IsUpdated = 0
			END TRY
			BEGIN CATCH
				IF ERROR_NUMBER() = 2627  -- Violates Primary Key
				BEGIN
					UPDATE t
					SET t.IsUpdated = 1
					FROM @tmpTpBetRecord t
						INNER JOIN bodb_N88_Archive.dbo.TpBetRecord_bk b WITH (NOLOCK) ON t.TpId = b.TpId AND t.TransId = b.TransId AND t.GameType = b.GameType
					WHERE t.IsUpdated = 0

					DELETE @tmpTpBetRecord
					OUTPUT
						DELETED.TpId,DELETED.TransId,DELETED.GameType,DELETED.CustId,DELETED.UserName,DELETED.CurrencyId,DELETED.SiteId,DELETED.TpUserName,DELETED.TransTime,DELETED.SettledTime
						,DELETED.Stake,DELETED.WinlostAmount,DELETED.SettlementType,DELETED.TicketStatus,DELETED.OriginalState,DELETED.TicketKey,DELETED.CreateTime,DELETED.WinlostDate
						,DELETED.ValidBet,DELETED.BonusId,DELETED.Revenue,DELETED.ProgressiveBet,DELETED.ProgressiveWin
					INTO bodb_N88_Archive.dbo.TpBetRecord_bk (
						TpId,TransId,GameType,CustId,UserName,CurrencyId,SiteId,TpUserName,TransTime,SettledTime
						,Stake,WinlostAmount,SettlementType,TicketStatus,OriginalState,TicketKey,CreateTime,WinlostDate
						,ValidBet,BonusId,Revenue,ProgressiveBet,ProgressiveWin
					)
					WHERE IsUpdated = 0
				END
				ELSE
				BEGIN
					SELECT @ErrMsg = ERROR_MESSAGE()
					RAISERROR(16, 1, @ErrMsg)
				END
			END CATCH
		END

		-- If data is updated, input to log
		INSERT INTO dbo.JobLog (DataSource, WinlostDate, OldData, NewData)
		SELECT
			'TpBetRecord_bk'	AS DataSource
			,@WinlostDate		AS WinlostDate
			,CONVERT(VARCHAR(MAX)
				,(SELECT
					b.TpId				AS '@tid'
					,b.TransId			AS '@trid'
					,b.GameType			AS '@gt'
					,b.CustId			AS '@cid'
					,b.UserName			AS '@usr'
					,b.CurrencyId		AS '@cur'
					,b.SiteId			AS '@sid'
					,b.TpUserName		AS '@tpu'
					,b.TransTime		AS '@tt'
					,b.SettledTime		AS '@st'
					,b.Stake			AS '@s'
					,b.WinlostAmount	AS '@wl'
					,b.TicketStatus		AS '@ts'
					,b.OriginalState	AS '@os'
					,b.CreateTime		AS '@ct'
					,b.WinlostDate		AS '@wld'
					,b.ValidBet			AS '@vb'
					,b.BonusId			AS '@bid'
					,b.Revenue			AS '@r'
					,b.ProgressiveBet	AS '@pb'
					,b.ProgressiveWin	AS '@pw'
					FOR XML PATH ('r'))
				) AS OldData
			,CONVERT(VARCHAR(MAX)
				,(SELECT
					t.TpId				AS '@tid'
					,t.TransId			AS '@trid'
					,t.GameType			AS '@gt'
					,t.CustId			AS '@cid'
					,t.UserName			AS '@usr'
					,t.CurrencyId		AS '@cur'
					,t.SiteId			AS '@sid'
					,t.TpUserName		AS '@tpu'
					,t.TransTime		AS '@tt'
					,t.SettledTime		AS '@st'
					,t.Stake			AS '@s'
					,t.WinlostAmount	AS '@wl'
					,t.TicketStatus		AS '@ts'
					,t.OriginalState	AS '@os'
					,t.CreateTime		AS '@ct'
					,t.WinlostDate		AS '@wld'
					,t.ValidBet			AS '@vb'
					,t.BonusId			AS '@bid'
					,t.Revenue			AS '@r'
					,t.ProgressiveBet	AS '@pb'
					,t.ProgressiveWin	AS '@pw'
					FOR XML PATH ('r'))
			) AS NewData
		FROM @tmpTpBetRecord t
			INNER JOIN bodb_N88_Archive.dbo.TpBetRecord_bk b WITH (NOLOCK) ON t.TpId = b.TpId AND t.TransId = b.TransId AND t.GameType = b.GameType
		WHERE t.IsUpdated = 1

		UPDATE b WITH (ROWLOCK)
		SET b.CustId = t.CustId
			,b.UserName = t.UserName
			,b.CurrencyId = t.CurrencyId
			,b.SiteId = t.SiteId
			,b.TpUserName = t.TpUserName
			,b.TransTime = t.TransTime
			,b.SettledTime = t.SettledTime
			,b.Stake = t.Stake
			,b.WinlostAmount = t.WinlostAmount
			,b.SettlementType = t.SettlementType
			,b.TicketStatus = t.TicketStatus
			,b.OriginalState = t.OriginalState
			,b.TicketKey = t.TicketKey
			,b.CreateTime = t.CreateTime
			,b.WinlostDate = t.WinlostDate
			,b.ValidBet = t.ValidBet
			,b.BonusId = t.BonusId
			,b.Revenue = t.Revenue
			,b.ProgressiveBet = t.ProgressiveBet
			,b.ProgressiveWin = t.ProgressiveWin
		FROM bodb_N88_Archive.dbo.TpBetRecord_bk b
			INNER JOIN @tmpTpBetRecord t ON t.TpId = b.TpId AND t.TransId = b.TransId AND t.GameType = b.GameType
		WHERE t.IsUpdated = 1
	END

	DROP TABLE #__TpBetRecord
END
GO