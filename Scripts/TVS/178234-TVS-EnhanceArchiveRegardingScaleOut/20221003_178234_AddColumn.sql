/*<info serverAlias="DBCTG-bodb02" executers="" viewers="" isFunction="0"></info>*/
/*
	Created by: 20221003@Max
	Task: [TVS] Enhance archive process of TVS data regarding the Scale Out DB project - [Redmine: #178234]
	
	Revisions:
		- 20221003@Max: [TVS] Enhance archive process of TVS data regarding the Scale Out DB project - [Redmine: #178234]

	Param's Explanation:  
		   
*/
 
USE bodb02
GO

ALTER TABLE dbo.Task_Archive_TVS ADD VoidingHistoryIds VARCHAR(MAX)

GO