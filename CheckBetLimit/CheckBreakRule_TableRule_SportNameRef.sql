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
(311,'min bet > max bet', @ModifiedDate),	
(312,'max bet > max per match', @ModifiedDate),	
(313,'Missing bet limit setting', @ModifiedDate),	
(314,'minbet < 0', @ModifiedDate),	
(315,'maxbet < 0', @ModifiedDate),	
(316,'max per match < 0', @ModifiedDate)	
GO