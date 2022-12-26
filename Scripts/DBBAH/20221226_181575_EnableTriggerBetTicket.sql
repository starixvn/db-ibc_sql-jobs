/*<info serverAlias="DBBAH-bodb02" executers="" viewers="" isFunction="0"></info>*/

/*
    Created by: 20221229@July
    Task: Data Migration - Disable Trigger
    DB: DBBAH.bodb02

	Revisions:
		- 20221229@July: Disable Trigger for bettransX tables [Redmineid:#181575] 

*/
USE bodb02
GO

ENABLE TRIGGER [dbo].[Bettrans_After_Update] ON [dbo].[bettrans]
GO
ENABLE TRIGGER [dbo].[bettransLC_After_Update] ON [dbo].[bettransLC]
GO
ENABLE TRIGGER [dbo].[BettransRNG_After_Update] ON [dbo].[bettransRnG]
GO
ENABLE TRIGGER [dbo].[TransLog_After_Update] ON [dbo].[translog]
