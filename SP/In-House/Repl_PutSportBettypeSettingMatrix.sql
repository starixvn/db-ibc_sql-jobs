/*<info serverAlias="DBAGE-bodb02, DBBOF-bodb02, DBTXN-custdb,DBACC-bodb02,DBTP-bodb02" executers="repl_ap" viewers="" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Repl_PutSportBettypeSettingMatrix]
	@tvp_param TVP_RepSportBettypeSettingMatrix READONLY
AS

/*
	Task: In-House
	Revision:
		-- 20230817@Patrick: create SP for in-house replication use [Redmine:#189389]
*/
BEGIN

	SET NOCOUNT ON;
	MERGE [dbo].[SportBettypeSettingMatrix] [t]
	USING @tvp_param [tvp] ON [t].[SportType] = [tvp].[SportType]
							AND [t].[BetType] = [tvp].[BetType]
							AND [t].[isLicensee] = [tvp].[isLicensee]
							AND [t].[isLive] = [tvp].[isLive]
							AND [t].[Site] = [tvp].[Site]
	WHEN MATCHED THEN
		UPDATE SET
			[isActive]							= [tvp].[isActive]
			,[SportTypeRefPT]					= [tvp].[SportTypeRefPT]
			,[BetTypeRefPT]						= [tvp].[BetTypeRefPT]
			,[isLivePT]							= [tvp].[isLivePT]
			,[TablePT]							= [tvp].[TablePT]
			,[SportTypeRefComm]					= [tvp].[SportTypeRefComm]
			,[BetTypeRefComm]					= [tvp].[BetTypeRefComm]
			,[TableComm]						= [tvp].[TableComm]
			,[SportTypeRefBetSetting]			= [tvp].[SportTypeRefBetSetting]
			,[BetTypeRefBetSetting]				= [tvp].[BetTypeRefBetSetting]
			,[TableBetSetting]					= [tvp].[TableBetSetting]
			,[IsLiveComm]						= [tvp].[IsLiveComm]
			,[IsLiveBetSetting]					= [tvp].[IsLiveBetSetting]
			,[TableBettrans]					= [tvp].[TableBettrans]
			,[RealProductId]					= [tvp].[RealProductId]
			,[SporttypeRefWinlossLimit]			= [tvp].[SporttypeRefWinlossLimit]
			,[BettypeRefWinlossLimit]			= [tvp].[BettypeRefWinlossLimit]
			,[ProductID]						= [tvp].[ProductID]
			,[isDeleted]						= [tvp].[isDeleted]
			,[RepUpdateTime] = CASE WHEN [tvp].[RepUpdateTime] > [t].[RepUpdateTime] THEN [tvp].[RepUpdateTime] ELSE [t].[RepUpdateTime] END
	WHEN NOT MATCHED THEN
		INSERT (
			[SportType]
			,[BetType]
			,[isLicensee]
			,[isLive]
			,[Site]
			,[isActive]
			,[SportTypeRefPT]
			,[BetTypeRefPT]
			,[isLivePT]
			,[TablePT]
			,[SportTypeRefComm]
			,[BetTypeRefComm]
			,[TableComm]
			,[SportTypeRefBetSetting]
			,[BetTypeRefBetSetting]
			,[TableBetSetting]
			,[IsLiveComm]
			,[IsLiveBetSetting]
			,[TableBettrans]
			,[RealProductId]
			,[SporttypeRefWinlossLimit]
			,[BettypeRefWinlossLimit]
			,[ProductID]
			,[isDeleted]
			,[RepUpdateTime]
		) VALUES (
			[tvp].[SportType]
			,[tvp].[BetType]
			,[tvp].[isLicensee]
			,[tvp].[isLive]
			,[tvp].[Site]
			,[tvp].[isActive]
			,[tvp].[SportTypeRefPT]
			,[tvp].[BetTypeRefPT]
			,[tvp].[isLivePT]
			,[tvp].[TablePT]
			,[tvp].[SportTypeRefComm]
			,[tvp].[BetTypeRefComm]
			,[tvp].[TableComm]
			,[tvp].[SportTypeRefBetSetting]
			,[tvp].[BetTypeRefBetSetting]
			,[tvp].[TableBetSetting]
			,[tvp].[IsLiveComm]
			,[tvp].[IsLiveBetSetting]
			,[tvp].[TableBettrans]
			,[tvp].[RealProductId]
			,[tvp].[SporttypeRefWinlossLimit]
			,[tvp].[BettypeRefWinlossLimit]
			,[tvp].[ProductID]
			,[tvp].[isDeleted]
			,[tvp].[RepUpdateTime]
		);
END
GO
