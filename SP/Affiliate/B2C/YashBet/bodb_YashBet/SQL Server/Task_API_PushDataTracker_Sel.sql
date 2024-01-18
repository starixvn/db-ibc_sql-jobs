/*<info serverAlias="DBYASHBET-bodb_YashBet" executers="bodbLicenseeNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Task_API_PushDataTracker_Sel]
	@PushDataType SMALLINT
	,@StatusId	TINYINT = 2
AS

/*
	Created: 20240115@Sally
	DB: DBYASHBET-bodb_YashBet
	Task:  Get info from API_PushDataTracker

	Revisions:
		- 20240115@Sally: Initialize SP [RedmineID: #198909]

	Param's Explanation:
		- @StatusId
			. 0: InProcess
			. 1: Success
			. 2: Fail
		- @PushDataType
			. 1: Call SP B2C when Aff approved  successfully
*/

BEGIN

	SET NOCOUNT ON

	SELECT PushTrackerId
		,CheckInTime
		,FinishedTime
		,StatusId
		,PushDataType
		,PushDataInfo
	FROM dbo.API_PushDataTracker WITH (NOLOCK)
	WHERE PushDataType = @PushDataType
		AND StatusId = @StatusId
	ORDER BY PushTrackerId DESC

END
GO