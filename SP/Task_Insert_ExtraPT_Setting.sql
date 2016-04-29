-- execute on DB06
CREATE PROCEDURE [dbo].[Task_Insert_ExtraPT_Setting]
AS
BEGIN
	/*
	DB: DB06 / bodb_acc
	Author: Harris
	Purpose:	- Manually insert Setting for new added Super into ExtraPT Groups
				- DO NOT USE for new created ExtraPT Groups
	
	Revision:
		20160429@Harris: initialize SP
	*/
	DECLARE @groupName VARCHAR(50)
		,@custId INT
		,@srecommend INT
		,@effectivedate DATE

	CREATE TABLE #tmp (
		custID INT
		,groupname VARCHAR(50)
		,isfinish TINYINT DEFAULT 0
		,effectivedate DATE
		)

	INSERT INTO #tmp (
		custid
		,groupname
		)
	SELECT CustId, groupname
	FROM DBAGE.bodb_age.dbo.Acc_CustGroup WITH (NOLOCK)
	WHERE groupname IN (
			SELECT groupname
			FROM Acc_DWLList_ExtraPT WITH (NOLOCK)
			)
		AND ispayout = 0

	IF @@ROWCOUNT = 0 RETURN

	UPDATE T
	SET T.effectivedate = u.logdate
	FROM #tmp t
		JOIN DBLOG.bodb_customerlog.dbo.userlog_runSP u WITH (NOLOCK) ON T.custid = u.custid
		AND u.actionID = 618 -- Add Ext Account
	WHERE u.trackingvalue LIKE '%' + t.groupname + '%'

	--select * from #tmp
	WHILE 1 = 1
	BEGIN
		UPDATE TOP (1) T
		SET isfinish = 1
			,@custid = custid
			,@groupname = groupname
			,@effectivedate = effectivedate
		FROM #tmp T
		WHERE isfinish = 0

		IF @@ROWCOUNT = 0
			BREAK

		SELECT TOP 1 @srecommend = SuperId
		FROM Acc_GroupExtraPTSetting WITH (NOLOCK)
		WHERE GroupName = @groupName

		IF NOT EXISTS (
				SELECT 1
				FROM Acc_GroupExtraPTSetting WITH (NOLOCK)
				WHERE superID = @custId
					AND groupname = @groupname
				)
		BEGIN
			INSERT INTO Acc_GroupExtraPTSetting (
				[SuperId]
				,[GroupId]
				,[GroupName]
				,[ProductId]
				,[Sporttype]
				,[SubProduct]
				,[ExtraPT]
				,[FromDate]
				,[ToDate]
				)
			SELECT @custId
				,groupID
				,groupname
				,ProductId
				,Sporttype
				,SubProduct
				,ExtraPT
				,CASE 
					WHEN FromDate <= @effectivedate THEN @effectivedate
					ELSE fromdate
					END
				,todate
			FROM Acc_GroupExtraPTSetting WITH (NOLOCK)
			WHERE superId = @srecommend

			UPDATE T
			SET ispayout = 1
			FROM DBAGE.bodb_age.dbo.Acc_Custgroup T WITH (ROWLOCK, UPDLOCK)
			WHERE Custid = @custId
				AND groupname = @groupName
		END
		ELSE
			UPDATE #tmp
			SET isfinish = 2
			WHERE custID = @custId
				AND groupname = @groupName
	END

	IF EXISTS (
			SELECT 1
			FROM #tmp WITH (NOLOCK)
			WHERE isfinish = 2
			)
		BEGIN
			SELECT * FROM #tmp	WHERE isfinish = 2
			RAISERROR ('Unable to insert some accounts.',16,1)
		END
	DROP TABLE #tmp
END
