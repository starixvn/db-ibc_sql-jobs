USE [bodb_AGE]
GO

/****** Object:  StoredProcedure [dbo].[Task_STDBY_Sync_AGE_Del]    Script Date: 01/20/2015 23:21:34 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Task_STDBY_Sync_AGE_Del]

AS
/*
	Created by:Jamie
	Date: 2013-07-19
	Task: Delete STDBY 
*/

BEGIN
	SET NOCOUNT ON 
	
	IF EXISTS(
		SELECT TOP 1 1 
		FROM	DBAGE_STDBY.bodb_AGE.dbo.Acc_CustGroup g WITH (NOLOCK)
				LEFT JOIN bodb_AGE.dbo.Acc_CustGroup c WITH (NOLOCK) ON g.CustID = C.CustID ANd g.GroupName = C.GroupName
		WHERE	c.CustID IS NULL 
	)
	BEGIN
		DELETE	G WITH (ROWLOCK)	
		FROM	DBAGE_STDBY.bodb_AGE.dbo.Acc_CustGroup G WITH (ROWLOCK)
				LEFT JOIN bodb_AGE.dbo.Acc_CustGroup c WITH (NOLOCK) ON g.CustID = C.CustID ANd g.GroupName = C.GroupName
		WHERE	c.CustID IS NULL 
	END

	IF EXISTS(
		SELECT TOP 1 1 
		FROM	DBAGE_STDBY.bodb_AGE.dbo.Age_CustProfilePicture WITH (NOLOCK)
		WHERE	CustID NOT IN (
					SELECT	CustID
					FROM	bodb_AGE.dbo.Age_CustProfilePicture WITH (NOLOCK) 
				)	
	)
	BEGIN
		DELETE	FROM DBAGE_STDBY.bodb_AGE.dbo.Age_CustProfilePicture WITH (ROWLOCK)
		WHERE	CustID NOT IN (
				SELECT	CustID
				FROM	bodb_AGE.dbo.Age_CustProfilePicture WITH (NOLOCK) 
		)	
	END

END 
GO

GRANT VIEW DEFINITION ON [dbo].[Task_STDBY_Sync_AGE_Del] TO [vnteam] AS [dbo]
GO


