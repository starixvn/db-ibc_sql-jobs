USE [bodb02]
GO

/****** Object:  StoredProcedure [dbo].[Task_STDBY_Sync_bodb02_sysSettings]    Script Date: 01/21/2015 00:27:06 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Task_STDBY_Sync_bodb02_sysSettings]

AS 
/*
	Task: Sync SystemSettings table to DBTP/bodb02/systemsettings 
	Date: 2014-04-24
	DB: DBACC/bodb02
*/
BEGIN
	SET NOCOUNT ON 
	UPDATE	stb WITH (UPDLOCK,ROWLOCK)
	SET		VValue = s.VValue
	FROM	SystemSettings s WITH (NOLOCK) 
			INNER JOIN DBACC_STDBY.bodb02.dbo.SystemSettings stb 
				ON s.VID = stb.VID 
	WHERE	s.VID IN (1,2,4)
			AND s.VValue <> stb.VValue

END



GO


