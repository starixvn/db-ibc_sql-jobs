/*<info serverAlias="DBSIG-bodb02" executers="" viewers="" isFunction="0"></info>*/

/*
    Created by: 20220824@Victoria
	Task: 
	DB: DBSIG-bodb02
	Revisions:
		- 20220824@Victoria:  Inital Writing [Redmine:#175881]
*/

USE [bodb02]
GO

CREATE TABLE [dbo].[SiteDB_DataConsistencyCheck_Config](
	[ConfigName]	[varchar](100) NOT NULL,
	[ConfigValue]	[varchar](100) NOT NULL,
 CONSTRAINT [PK_SiteDB_DataConsistencyCheck_Config] PRIMARY KEY CLUSTERED 
(
	[ConfigName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [DATA]
) ON [DATA]
GO