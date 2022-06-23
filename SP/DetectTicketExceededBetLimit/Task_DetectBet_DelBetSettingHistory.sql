/*<info serverAlias="DBCUST-CustDB" executers="" isFunction="0" isNested="1"></info>*/

ALTER PROCEDURE [dbo].[Task_DetectBet_DelBetSettingHistory] 
			@ID			INT,
			@IsLicensee	BIT,
			@IsGroup	BIT=NULL
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

	IF @IsLicensee=0 AND @IsGroup IS NULL
	BEGIN
		DELETE CustMaxBetSetting_History WITH (ROWLOCK)
		WHERE ID<=@ID
	END
	ELSE IF @IsLicensee=1 AND @IsGroup IS NULL
	BEGIN
		DELETE Dep_CustMaxBetSetting_History WITH (ROWLOCK)
		WHERE ID<=@ID
	END

	IF @IsLicensee=0 AND @IsGroup=0
	BEGIN
		DELETE StakeLevel_History WITH (ROWLOCK)
		WHERE ID<=@ID
	END
	ELSE IF @IsLicensee=0 AND @IsGroup=1
	BEGIN
		DELETE StakeLevelGroupDetail_History WITH (ROWLOCK)
		WHERE ID<=@ID
	END

	IF @IsLicensee=1 AND @IsGroup=0
	BEGIN
		DELETE Dep_StakeLevel_History WITH (ROWLOCK)
		WHERE ID<=@ID
	END
	ELSE IF @IsLicensee=1 AND @IsGroup=1
	BEGIN
		DELETE Dep_StakeLevelGroupDetail_History WITH (ROWLOCK)
		WHERE ID<=@ID
	END
END
GO