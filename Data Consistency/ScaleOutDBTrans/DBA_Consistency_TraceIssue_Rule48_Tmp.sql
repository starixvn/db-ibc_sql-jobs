/*<info serverAlias="DBCONSISTENCY-bodb_Consistency,DBSIG-bodb02" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[DBA_Consistency_TraceIssue_Rule48_Tmp]
(
	@Recommend INT,
	@Status NVARCHAR(10),
	@CurrentTime DATETIME
)
AS 
/*
Created by: 20221028@Victoria
Task: Data Consistency - Trace issue unmatch number of tickets between DBTP and SiteDB with rule #48
DB: DBCONSISTENCY-bodb_Consistency,DBSIG-bodb02
Revisions:
	- 20221028@Victoria: Initial Writing [Redmine:#178864]
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @before_yesterday SMALLDATETIME, @yesterday SMALLDATETIME
	SELECT  @before_yesterday = CONVERT(DATE, DATEADD(DAY, -2, GETDATE()))
	SELECT  @yesterday = CONVERT(DATE, DATEADD(DAY, -1, GETDATE()))

	SELECT	Transid
	FROM	bodb02.dbo.bettrans WITH (NOLOCK)
	WHERE	recommend = @Recommend
		AND status = @Status
		AND winlostdate IN (@before_yesterday,@yesterday)
		AND transdate < @CurrentTime

END
