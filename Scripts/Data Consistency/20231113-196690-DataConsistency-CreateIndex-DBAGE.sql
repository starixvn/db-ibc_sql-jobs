/*<info serverAlias="DBAGE-bodb02"></info>*/
/*
	Created: 20231113@Helen
	Task: Check consistency on all replicated servers
	DB: DBAGE-bodb02

	Revisions:
		20231113@Helen - Check consistency on all replicated servers - create index on db052/db053 - [Redmine: 196690]

*/
USE bodb02
GO
CREATE NONCLUSTERED INDEX [IX_winlostdate] ON [dbo].[bettransm]
(
	[winlostdate] ASC
)
INCLUDE([custid]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = ON, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [BettransM_index]
GO
