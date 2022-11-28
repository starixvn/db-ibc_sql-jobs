/*<info serverAlias="DBCONSISTENCY-bodb_Consistency, DBSIG-bodb02" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[CheckSumTicket_ByRecommendList]
(
	@CurrentTime		DATETIME
   ,@RecommendList		VARCHAR(MAX) 
   ,@TableName		    VARCHAR(50)
   ,@before_yesterday	SMALLDATETIME
   ,@yesterday			SMALLDATETIME
)
AS 
/*
	Created by: 20221124@July
	Task: CheckSum ticket
	DB: DBCONSISTENCY-bodb_Consistency, DBSIG-bodb02
	Revisions:
		- 20221124@July: Clone SP - Support filter recommend list [Redmine:#178864]
*/
BEGIN
	SET NOCOUNT ON

	IF @TableName = 'bettrans'
	BEGIN
		EXEC dbo.CheckSumTicket_ByRecommendList_bettrans
				@CurrentTime = @CurrentTime
			  , @RecommendList = @RecommendList
			  , @before_yesterday = @before_yesterday
			  , @yesterday = @yesterday 
		RETURN;
	END

	ELSE IF @TableName = 'bettransRnG'
	BEGIN
		EXEC dbo.CheckSumTicket_ByRecommendList_bettransRnG
				@CurrentTime = @CurrentTime
			  , @RecommendList = @RecommendList
			  , @before_yesterday = @before_yesterday
			  , @yesterday = @yesterday 
		RETURN;
	END

	ELSE IF @TableName = 'bettransLC'
	BEGIN
		EXEC dbo.CheckSumTicket_ByRecommendList_bettransLC
				@CurrentTime = @CurrentTime
			  , @RecommendList = @RecommendList
			  , @before_yesterday = @before_yesterday
			  , @yesterday = @yesterday 
		RETURN;
	END

	ELSE IF @TableName = 'translog'
	BEGIN
		EXEC dbo.CheckSumTicket_ByRecommendList_translog
				@CurrentTime = @CurrentTime
			  , @RecommendList = @RecommendList
			  , @before_yesterday = @before_yesterday
			  , @yesterday = @yesterday 
		RETURN;
	END
	
END


