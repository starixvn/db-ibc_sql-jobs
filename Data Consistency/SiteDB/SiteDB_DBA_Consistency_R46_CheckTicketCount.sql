/*<info serverAlias="DBSIG-bodb02" executers="" viewers="" isFunction="0"></info>*/
CREATE PROCEDURE [dbo].[SiteDB_DBA_Consistency_R46_CheckTicketCount]
(
	@SiteDBGroupID SMALLINT OUTPUT,
	@TransferLastTransId BIGINT OUTPUT,
	@TransferCollLastTransId BIGINT OUTPUT,
	@NewTransferLastTransId BIGINT OUTPUT,
	@NewTransferCollLastTransId BIGINT OUTPUT
)
AS
/*
	Created: 20220823@Sol
	Task: Data consistency
	DB: DBSIG-bodb02

	Revisions: 
		- 20220823@Sol: Scale out DBTrans - Detect data consistency SiteDB and CentralDB 
						- Check total ticket between SiteDB and central DB - [Redmine:#155714]

	Param's Expanation:
*/
BEGIN
	SET NOCOUNT ON

	--parameters
	DECLARE 
		@rowPerCall INT = 5000
		,@transferKey VARCHAR(50) = 'SiteDB_CheckConsistency_Transfer_LastTransId'
		,@transferCollKey VARCHAR(50) = 'SiteDB_CheckConsistency_TransferColl_LastTransId'
		,@minTransID BIGINT = 0 --- for the first time run sp, 

	--check if the setting exists or not, if exists, get the value, if not, select min transid and insert the setting
	--this is for the first time that sp run, next time will get the last transid
	BEGIN
		IF NOT EXists ( select 1 from bodb02.dbo.SystemSettings s with(nolock) where s.VName = @transferKey)
		begin
			select @minTransID = MIN(t.TransId) from Transfer t with(nolock)

			---insert to table setting
			INsert into bodb02.dbo.SystemSettings(VName, VValue)
			values (@transferKey, CAST(@minTransID AS VARCHAR(200)))
		end
		ELSE --get value from system setting
		BEGIN
			select @transferLastTransId = CAST(VValue AS BIGINT) 
			from bodb02.dbo.SystemSettings s with(nolock) 
			where VName = @transferKey
		end

		--transferCollection
		IF NOT EXists ( select 1 from bodb02.dbo.SystemSettings s with(nolock) where s.VName = @transferCollKey)
		begin
			select @minTransID = MIN(t.TransId) 
			from Transfer_Coll t with(nolock)

			---insert to table setting
			INsert into bodb02.dbo.SystemSettings(VName, VValue)
			values (@transferCollKey, CAST(@minTransID AS VARCHAR(200)))
		end
		ELSE --get value from system setting
		BEGIN
			select @transferCollLastTransId = CAST(VValue AS BIGINT) 
			from bodb02.dbo.SystemSettings s with(nolock) 
			where VName = @transferCollKey
		end
	END

	---get site group id
	SELECT @SiteDBGroupID = dbo.f_Get_SiteDBGroupID()

	---get last transid
	BEGIN
		SELECT @NewTransferLastTransId = MAX(t.TransId)
		FROM dbo.Transfer t WITH (NOLOCK)
		WHERE t.TransId > @transferLastTransId

		SELECT @NewTransferCollLastTransId = MAX(tc.TransId)
		FROM dbo.Transfer_Coll tc WITH (NOLOCK)
		WHERE	tc.TransId > @transferCollLastTransId

	END
	---get total ticket by recommend
	BEGIN
		
		SELECT --TOP(@rowPerCall)
			'Transfer' AS TableName,
			@SiteDBGroupID AS SiteDBGroupID, 
			Recommend,
			COUNT(1) AS TicketCount
		FROM dbo.Transfer t WITH (NOLOCK)
		WHERE t.TransId > @transferLastTransId
		GROUP BY Recommend 
			
		UNION ALL

		SELECT --TOP(@rowPerCall)
			'TransferInfo' AS TableName,
			@SiteDBGroupID AS SiteDBGroupID, 
			t.Recommend, 
			COUNT(1) AS TicketCount
		FROM dbo.TransferInfo ti WITH (NOLOCK)
			inner join Transfer t with(nolock)
				on ti.TransId = t.TransId
		WHERE	t.TransId > @transferLastTransId
		GROUP BY t.Recommend 

		UNION ALL

		SELECT --TOP(@rowPerCall)
			'Transfer_Coll' AS TableName,
			@SiteDBGroupID AS SiteDBGroupID, 
			tc.Recommend, 
			COUNT(1) AS TicketCount
		FROM dbo.Transfer_Coll tc WITH (NOLOCK)
		WHERE	tc.TransId > @transferCollLastTransId
		GROUP BY tc.Recommend 

	END
END
GO