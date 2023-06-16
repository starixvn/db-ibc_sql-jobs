/*<info serverAlias="DBBAH-bodb02" executers="" viewers="" isFunction="0"></info>*/

/*
	Created by: 20230616@July
	Task : Check ticket data consistency - detect abnormal winlost date vs settlement time (Rule #59) [Redmine:#189723]
	DB: DBBAH-bodb02 

*/

USE bodb02
GO

ALTER TABLE [dbo].[StatementMovementHistory] ADD LogDate DATETIME
GO
ALTER TABLE [dbo].[StatementMovementHistory] ADD CONSTRAINT [DF_StatementMovementHistory_LogDate] DEFAULT(GETDATE()) FOR [LogDate]
GO

CREATE NONCLUSTERED INDEX [IX_LogDate] ON [dbo].[StatementMovementHistory]
(
	[LogDate] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [Others_index]
GO

CREATE NONCLUSTERED INDEX [IX_TransId] ON [dbo].[StatementMovementHistory]
(
	[TransId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [Others_index]
GO