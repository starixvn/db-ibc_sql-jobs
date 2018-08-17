ALTER PROCEDURE [dbo].[DBA_PrepareKenoGameType]
AS 
	/*
	Created: 20180817@Johnson
	Task: Prepare GameType table for keno - [Redmine:73556]
	DB: DB054.CheckResultDB
	Revisions:
		
	Param's Explanation: 

	*/
BEGIN
	IF Object_ID('CheckCustDB..GameType') IS NOT NULL
		DROP TABLE CheckCustDB..GameType
		
	DECLARE @tmpID TABLE(ID INT IDENTITY(1,1),custID INT)
	DECLARE	@GameTypeID_max INT
			
	INSERT INTO @tmpID(custID)
	SELECT TOP(100) custid--keno only has 100 games from 1 to 100
	FROM CheckCustDB.dbo.custInfo WITH(NOLOCK)
	
	SELECT @GameTypeID_max = max(GameTypeID)
	FROM CheckCustDB.dbo.CustGameType CPS (NOLOCK)
	WHERE GameTypeID < 100--keno
			
	SELECT 202 as sporType, ID as GameTypeID
	INTO CheckCustDB.dbo.GameType
	FROM @tmpID
	WHERE ID <= @GameTypeID_max
		AND ID NOT IN (2,6,7,9,10,12,18,23)-- exclude not offered games
	
END	