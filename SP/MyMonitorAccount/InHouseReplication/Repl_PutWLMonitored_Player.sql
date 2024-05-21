/*<info serverAlias="DBAGE-bodb02,DBTP-bodb02" executers="repl_ap" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Repl_PutWLMonitored_Player]
    @tvp_param TVP_ReplWLMonitored_Player READONLY
AS
/*
	Created: 20240415@Eden
	Task: In-House
	DB: DBAGE-bodb02,DBTP-bodb02
	
	Revisions:
		- 20240415@Eden: Alpha - Link WL Detail to My Watchlist [RedmineID: #201733]
*/
BEGIN
    SET NOCOUNT ON;
    MERGE [dbo].[WLMonitored_Player] [t]
    USING @tvp_param [tvp] 
		ON [t].CustID = [tvp].CustID
		AND [t].Sporttype = [tvp].Sporttype
    WHEN MATCHED AND [tvp].isDeleted = 0 THEN
        UPDATE SET
				 AgentID			= tvp.AgentID
				,WinningThreshold	= tvp.WinningThreshold
				,WinningUpdateTime	= tvp.WinningUpdateTime
				,LosingThreshold	= tvp.LosingThreshold
				,LosingUpdateTime	= tvp.LosingUpdateTime
				,InitSettingTime	= tvp.InitSettingTime
				,RepUpdateTime		= CASE WHEN tvp.RepUpdateTime > t.RepUpdateTime THEN tvp.RepUpdateTime ELSE t.RepUpdateTime END
				,CreatedDate		= tvp.CreatedDate
	WHEN MATCHED AND [tvp].isDeleted = 1 THEN 
		DELETE
    WHEN NOT MATCHED AND [tvp].isDeleted = 0 THEN
        INSERT (
             CustID
			,Sporttype
			,AgentID
			,WinningThreshold
			,WinningUpdateTime
			,LosingThreshold
			,LosingUpdateTime
			,InitSettingTime
			,RepUpdateTime
			,CreatedDate
        ) VALUES (
             tvp.CustID
			,tvp.Sporttype
			,tvp.AgentID
			,tvp.WinningThreshold
			,tvp.WinningUpdateTime
			,tvp.LosingThreshold
			,tvp.LosingUpdateTime
			,tvp.InitSettingTime
			,tvp.RepUpdateTime
			,tvp.CreatedDate
        );
END
GO
