/*<info serverAlias="DBAGE-bodb_AGE" isFunction="1" isNested="1"></info>*/
ALTER FUNCTION [dbo].[Age_f_SabaSportRef]()
RETURNS TABLE
AS
/*
	Created by: 20240602@Bobby
	Task: 153357 - Alpha - CDC bettrans_compact
	DB: DBAGE.bodb_AGE
	Revisions:
		- 20240602@Bobby: Enhance check & correct process [RedmineID: #205973]
*/
RETURN (
	SELECT SportType, LeagueGroupId
	FROM (
		VALUES (1, 42, CAST('SABA Soccer' AS VARCHAR(100)))
		,(1, 74, 'SABA Soccer') 
		,(1, 108, 'SABA Futsal')
		,(1, 113, 'SABA Soccer PinGoal')
		,(2, 42, 'SABA Basketball')
		,(2, 122, 'SABA Basketball PinGoal')
		,(4, 42, 'SABA Ice Hockey')
		,(5, 42, 'SABA Tennis')
		,(43, 151, 'SABA ESports PinGoal')
		,(47, 42, 'SABA Kabaddi')
		,(50, 42, 'SABA Cricket')
	) 
	AS t (SportType, LeagueGroupId, SabaSportName)
)
GO