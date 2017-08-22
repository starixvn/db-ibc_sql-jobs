/*
	Created: 20170407@Helen
	Task: Improve DB Productivity - Redmine: https://nexdev.net/issues/73556
	DB: DB054/CheckResultDB
*/

USE CheckResultDB
GO

DECLARE @ModifiedDate DATETIME = GETDATE()

INSERT INTO [Rule_Credit] (RuleID,RuleName,ModifiedDate)
VALUES 
(101,'Min bet: Super > Master', @ModifiedDate),
(102,'Min bet: Master > Agent',@ModifiedDate),
(103,'Min bet: Agent > Member',@ModifiedDate),
(104,'max bet: Super < Master',@ModifiedDate),
(105,'max bet: Master < Agent',@ModifiedDate),
(106,'max bet: Agent < Member',@ModifiedDate),
(107,'max per match: Super < Master',@ModifiedDate),
(108,'max per match: Master < Agent',@ModifiedDate),
(109,'max per match: Agent < Member',@ModifiedDate),
(110,'min bet > max bet',@ModifiedDate),
(111,'max per match < max bet',@ModifiedDate),
(112,'Missing bet limit setting',@ModifiedDate),
(113,'minbet < 0',@ModifiedDate),
(114,'maxbet < 0',@ModifiedDate),
(115,'max per match < 0',@ModifiedDate)

GO