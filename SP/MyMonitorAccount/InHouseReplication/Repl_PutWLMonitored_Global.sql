/*<info serverAlias="DBAGE-bodb02,DBTP-bodb02" executers="repl_ap" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Repl_PutWLMonitored_Global]
    @tvp_param TVP_ReplWLMonitored_Global READONLY
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
    MERGE [dbo].[WLMonitored_Global] [t]
    USING @tvp_param [tvp] 
		ON [t].AgentID = [tvp].AgentID
		AND [t].Sporttype = [tvp].Sporttype
    WHEN MATCHED AND [tvp].isDeleted = 0 THEN
        UPDATE SET
				 WinningThreshold	= tvp.WinningThreshold
				,WinningUpdateTime	= tvp.WinningUpdateTime
				,LosingThreshold	= tvp.LosingThreshold
				,LosingUpdateTime	= tvp.LosingUpdateTime
				,InitSettingTime	= tvp.InitSettingTime
				,RepUpdateTime		= CASE WHEN tvp.RepUpdateTime > t.RepUpdateTime THEN tvp.RepUpdateTime ELSE t.RepUpdateTime END
	WHEN MATCHED AND [tvp].isDeleted = 1 THEN 
		DELETE
    WHEN NOT MATCHED AND [tvp].isDeleted = 0 THEN
        INSERT (
             AgentID
			,Sporttype
			,WinningThreshold
			,WinningUpdateTime
			,LosingThreshold
			,LosingUpdateTime
			,InitSettingTime
			,RepUpdateTime
        ) VALUES (
             tvp.AgentID
			,tvp.Sporttype
			,tvp.WinningThreshold
			,tvp.WinningUpdateTime
			,tvp.LosingThreshold
			,tvp.LosingUpdateTime
			,tvp.InitSettingTime
			,tvp.RepUpdateTime
        );
END
GO
