/*<info serverAlias="DBAGE-bodb02" executers="bodbLicenseeNet" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE dbo.Task_CustWLMonitored_Setting_Ins
AS  
/*  
	Created:	20221121@Eden
	Task:		Insert data into [CustWLMonitored_Setting] from custdb
	DB:			DBAGE-bodb02
	Original:	
  
	Revisions:  
	    - 20221121@Eden: Enhance run time of trigger to capture data for Pending table [#180716]
	
*/  
BEGIN
	SET NOCOUNT ON
	DECLARE @sql  NVARCHAR(MAX) = ''
	DECLARE @LastID VARCHAR(20) = 0
	DECLARE @MaxID INT
	CREATE TABLE #CustWLMonitored_Setting(
		[ID] [int] PRIMARY KEY,
		[CustID] [int],
		[recommend] [int],
		[IsDeleted] [BIT],
	)

	SELECT @LastID = SettingValue 
	FROM WLMonitored_Service_GlobalSetting WITH(NOLOCK) 
	WHERE ServiceName = 'WLMonitored_Setting_Sync' 
		AND SettingName = 'LastID'

	SET @sql = 'SELECT ID,CustID,recommend,IsDeleted
	FROM OPENQUERY (DBCUST, ''SELECT ID,CustID,recommend,IsDeleted
			FROM CUSTDB.dbo.[CustWLMonitored_Setting_Pending] WITH(NOLOCK) 
			WHERE ID > '+ @LastID +' '')'

	--PRINT @sql

	INSERT INTO #CustWLMonitored_Setting(ID,CustID,recommend,IsDeleted)
	EXEC(@sql)

	SELECT @MaxID = MAX(ID) FROM #CustWLMonitored_Setting

	IF @MaxID IS NULL
	BEGIN
		WAITFOR DELAY '00:00:01' -- delay 1 second if no data found on current batch
		RETURN
	END

	;WITH tmp AS(
		SELECT ID,CustID,recommend,IsDeleted
			, ROW_NUMBER() OVER(PARTITION BY CustID,recommend ORDER BY ID DESC) AS RN
		FROM #CustWLMonitored_Setting
	)
	DELETE t
	FROM tmp
		INNER JOIN #CustWLMonitored_Setting t ON t.ID = tmp.ID
	WHERE tmp.RN <> 1

	INSERT INTO dbo.[CustWLMonitored_Setting](custid,recommend)
	SELECT t.CustID,t.recommend
	FROM #CustWLMonitored_Setting t
		LEFT JOIN [CustWLMonitored_Setting] c WITH(NOLOCK) 
			ON t.CustID = c.CustID AND t.recommend = c.recommend
	WHERE t.IsDeleted = 0
		AND c.CustID IS NULL

	DELETE c
	FROM #CustWLMonitored_Setting t
		INNER JOIN [CustWLMonitored_Setting] c WITH(ROWLOCK,UPDLOCK) 
			ON t.CustID = c.CustID AND t.recommend = c.recommend
	WHERE t.IsDeleted = 1

	EXEC Acc_WLMonitored_Service_GlobalSettingUpd 
		 @ServiceName = 'WLMonitored_Setting_Sync'
		,@SettingName = 'LastID'
		,@SettingValue = @MaxID

END	
GO