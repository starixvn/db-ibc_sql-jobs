/*<info serverAlias="DBCUST-CustDB" executers="" isFunction="0" isNested="1"></info>*/

ALTER PROCEDURE [dbo].[Task_DetectBet_DelBetSettingHistory] 
			@StakeLevel_ID					INT=NULL,
			@StakeLevelGroupDetail_ID		INT=NULL,
			@Dep_StakeLevel_ID				INT=NULL,
			@Dep_StakeLevelGroupDetail_ID	INT=NULL,
			@CustMaxBetSetting_ID			INT=NULL,
			@Dep_CustMaxBetSetting_ID		INT=NULL
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

	IF @CustMaxBetSetting_ID IS NOT NULL
	BEGIN
		DELETE CustMaxBetSetting_History WITH (ROWLOCK)
		WHERE ID<=@CustMaxBetSetting_ID
	END
	ELSE IF @Dep_CustMaxBetSetting_ID IS NOT NULL
	BEGIN
		DELETE Dep_CustMaxBetSetting_History WITH (ROWLOCK)
		WHERE ID<=@Dep_CustMaxBetSetting_ID
	END
	ELSE IF @StakeLevel_ID IS NOT NULL
	BEGIN
		DELETE StakeLevel_History WITH (ROWLOCK)
		WHERE ID<=@StakeLevel_ID
	END
	ELSE IF @StakeLevelGroupDetail_ID IS NOT NULL
	BEGIN
		DELETE StakeLevelGroupDetail_History WITH (ROWLOCK)
		WHERE ID<=@Dep_StakeLevel_ID
	END
	ELSE IF @Dep_StakeLevel_ID IS NOT NULL
	BEGIN
		DELETE Dep_StakeLevel_History WITH (ROWLOCK)
		WHERE ID<=@Dep_StakeLevel_ID
	END
	ELSE IF @Dep_StakeLevelGroupDetail_ID IS NOT NULL
	BEGIN
		DELETE Dep_StakeLevelGroupDetail_History WITH (ROWLOCK)
		WHERE ID<=@Dep_StakeLevelGroupDetail_ID
	END
END
GO