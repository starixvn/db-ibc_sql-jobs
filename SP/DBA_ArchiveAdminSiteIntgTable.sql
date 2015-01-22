USE [bodb02]
GO

/****** Object:  StoredProcedure [dbo].[DBA_ArchiveAdminSiteIntgTable]    Script Date: 01/21/2015 02:46:14 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[DBA_ArchiveAdminSiteIntgTable]
	@ArchiveDays smalldatetime = null
AS
--20141209@Cooper(DB06):Archive AdminSite Intg Group Table to ArchiveDB
BEGIN
	-- Archive
	IF @ArchiveDays is null Set @ArchiveDays = Getdate () - 28
			
	CREATE TABLE #Ext_Match_MaxKickoff ( Ext_Matchid varchar(50),Ext_Kickoff datetime  )
	
	--get will archive Ext_matchid list
	INSERT INTO #Ext_Match_MaxKickoff
	SELECT Ext_Matchid , MAX(Ext_Kickoff) 
	FROM Dot_Admin_Intg_MetaFile with(nolock)
	WHERE [Type] in (1,2) 
	GROUP BY Ext_MatchID having convert(char(8),MAX(Ext_Kickoff),112) = convert(char(8),@ArchiveDays,112)

	IF @@ROWCOUNT > 0
	BEGIN
		--copy to db06 bodb_Archive	
		DELETE [bodb_Archive].[dbo].[Dot_Admin_Intg_MetaFile_bk] 
		WHERE Ext_Matchid IN ( SELECT Ext_MatchID FROM #Ext_Match_MaxKickoff )
			
		INSERT INTO [bodb_Archive].[dbo].[Dot_Admin_Intg_MetaFile_bk] 
			(MetaID, [Type], FullPath, Ext_SourceID, Ext_LeagueID, Ext_HomeID, Ext_AwayID,Ext_MatchID, Ext_Kickoff, Ext_BetType, Completed, Confirmed, CreateDate, ModifiedDate, Extra, SportType, Ext_OddsID)
		SELECT MetaID, [Type], FullPath, Ext_SourceID, Ext_LeagueID, Ext_HomeID, Ext_AwayID, MF.Ext_MatchID, MF.Ext_Kickoff, Ext_BetType, Completed, Confirmed, CreateDate, ModifiedDate, Extra, SportType, Ext_OddsID
		FROM dbo.Dot_Admin_Intg_MetaFile MF with(nolock)
			INNER JOIN #Ext_Match_MaxKickoff MD ON MF.Ext_Matchid = MD.Ext_MatchID

		--copy to db06 bodb_Archive		
		DELETE [bodb_Archive].[dbo].Dot_Admin_Intg_MatchMapping_bk 
		WHERE Ext_Matchid IN ( SELECT Ext_MatchID FROM #Ext_Match_MaxKickoff )
			
		INSERT INTO [bodb_Archive].[dbo].[Dot_Admin_Intg_MatchMapping_bk]
			(MetaID, RemarkID, Ext_SourceID, Ext_LeagueID, mm.Ext_MatchID, MatchID, ModifiedDate, MatchMappingID, Confirmed, MatchCode, ShowTime, SyncScore)
		SELECT MetaID, RemarkID, Ext_SourceID, Ext_LeagueID, mm.Ext_MatchID, MatchID, ModifiedDate, MatchMappingID, Confirmed, MatchCode, ShowTime, SyncScore
		FROM dbo.Dot_Admin_Intg_MatchMapping MM with(nolock)
			INNER JOIN #Ext_Match_MaxKickoff MD ON MM.Ext_Matchid = MD.Ext_MatchID	
		
	END
	DROP TABLE #Ext_Match_MaxKickoff
	
END

GO


