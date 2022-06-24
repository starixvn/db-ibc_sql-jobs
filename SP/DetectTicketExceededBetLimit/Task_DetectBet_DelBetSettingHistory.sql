/*<info serverAlias="DBCUST-CustDB" executers="" isFunction="0" isNested="1"></info>*/

ALTER PROCEDURE [dbo].[Task_DetectBet_DelBetSettingHistory] 
			@StakeLevel_Time				DATETIME=NULL,
			@StakeLevelGroupDetail_Time		DATETIME=NULL,
			@Dep_StakeLevel_Time			DATETIME=NULL,
			@Dep_StakeLevelGroupDetail_Time	DATETIME=NULL,
			@CustMaxBetSetting_Time			DATETIME=NULL,
			@Dep_CustMaxBetSetting_Time		DATETIME=NULL
AS
/*
	Created: 20220623@Tacy
	Task: Delete history of bet setting - DBcust.CustDB 
	DB: DBCUST/CustDB
	Original:

	Revisions:
		- 20220623@Tacy: Initial SP [RedmineID: #170739]

	Param's Explanation:

*/
BEGIN
	SET NOCOUNT ON 

	IF @CustMaxBetSetting_Time IS NOT NULL
	BEGIN
		DELETE CustMaxBetSetting_History WITH (ROWLOCK)
		WHERE UpdateTime<@CustMaxBetSetting_Time
	END
	IF @Dep_CustMaxBetSetting_Time IS NOT NULL
	BEGIN
		DELETE Dep_CustMaxBetSetting_History WITH (ROWLOCK)
		WHERE UpdateTime<@Dep_CustMaxBetSetting_Time
	END
	IF @StakeLevel_Time IS NOT NULL
	BEGIN
		DELETE StakeLevel_History WITH (ROWLOCK)
		WHERE UpdateTime<@StakeLevel_Time
	END
	IF @StakeLevelGroupDetail_Time IS NOT NULL
	BEGIN
		DELETE StakeLevelGroupDetail_History WITH (ROWLOCK)
		WHERE UpdateTime<@StakeLevelGroupDetail_Time
	END
	IF @Dep_StakeLevel_Time IS NOT NULL
	BEGIN
		DELETE Dep_StakeLevel_History WITH (ROWLOCK)
		WHERE UpdateTime<@Dep_StakeLevel_Time
	END
	IF @Dep_StakeLevelGroupDetail_Time IS NOT NULL
	BEGIN
		DELETE Dep_StakeLevelGroupDetail_History WITH (ROWLOCK)
		WHERE UpdateTime<@Dep_StakeLevelGroupDetail_Time
	END
END
GO