SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
CREATE PROCEDURE [dbo].[task_Archive_SelectBettrans14_Done]
AS
/*
Set of SP
	Task_Archive_SelectBettrans14_Init 
	Task_Archive_SelectBettrans14      
	Task_Archive_SelectBettrans14_Done : remove list that already read
*/

;WITH CTE AS (SELECT TOP 1 *
FROM dbo.tmp_Task_Archive_Bettrans14 WITH (NOLOCK)
ORDER BY rn)
DELETE FROM CTE

GO
/*<info serverAlias="DBTXN-bodb02" executers="" viewers="" isFunction="0" isNested="0"></info>*/