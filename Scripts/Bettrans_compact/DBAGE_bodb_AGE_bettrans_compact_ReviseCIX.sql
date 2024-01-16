/*<info serverAlias="DBAGE-bodb_AGE" isNested="0"></info>*/
/*
	Created by: 20231201@Bobby
	Task: 153357 - Alpha - CDC bettrans_compact - GEN data
	DB: DBAGE.bodb_AGE
	Revisions:
		- 20240116@Bobby: CheckSum data from bettrans
		
*/

USE [bodb_Age]
GO

TRUNCATE TABLE [dbo].[bettrans_compact];
GO

/****** Object:  Index [CIX_bettrans_compact]    Script Date: 1/16/2024 5:23:14 PM ******/
DROP INDEX [CIX_bettrans_compact] ON [dbo].[bettrans_compact] WITH ( ONLINE = OFF )
GO

/****** Object:  Index [CIX_bettrans_compact]    Script Date: 1/16/2024 5:23:16 PM ******/
CREATE CLUSTERED INDEX [CIX_bettrans_compact] ON [dbo].[bettrans_compact]
(
	[custid] ASC,
	[winlostdate] ASC,
	[bettype] ASC
) ON [cdc_bettrans_data]
GO