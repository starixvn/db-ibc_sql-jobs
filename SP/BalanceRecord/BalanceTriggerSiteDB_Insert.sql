/*<info serverAlias="DBBAH-bodb02" executers="bodbAdminNet" viewers="" isFunction="0"></info>*/  
ALTER PROCEDURE [dbo].[BalanceTriggerSiteDB_Insert] 
(
	@SiteDBGroupID	SMALLINT
	,@TransInfo		VARBINARY(MAX)
	,@IsTest		BIT
	,@ErrorMsg		VARCHAR(MAX) = '' OUTPUT
)
AS
/*
	Created: 20220130@Louisa
    DB: DBBAH/bodb02
   
   Revisions:
		- 20220130@Louisa: Phase 2 - use Web Service to pull ticket from SiteDB to DB05/DB05BK1 [176932]

	Param's explaination:

*/
BEGIN
	
	SET XACT_ABORT ON
	
	IF ISNULL(@SiteDBGroupID,0) = 0
	BEGIN
		SELECT @ErrorMsg = 'Wrong SiteDBGroupID'
		RETURN
	END

	DECLARE @MaxRowID		BIGINT
			,@VNameStatus	VARCHAR(50)
			,@VNameLastRow	VARCHAR(50)
			,@Sufix			VARCHAR(2)

	SET @Sufix = RIGHT ('0' + CAST(@SiteDBGroupID AS VARCHAR(2)),2)

	SELECT @VNameLastRow = CASE @IsTest WHEN 0 THEN 'BT_SiteDB' + @Sufix + '_Sync'
										ELSE 'BT_SiteDB' + @Sufix + '_Sync' + '_UAT'
										END

	SELECT @VNameStatus = CASE @IsTest WHEN 0 THEN 'BT_SiteDB' + @Sufix + '_InsStatus'
											  ELSE 'BT_SiteDB' + @Sufix + '_InsStatus_UAT'
											  END
	SELECT @MaxRowID =    MAX(r) FROM  OPENJSON (  CAST( DECOMPRESS(@TransInfo)   AS NVARCHAR(MAX)) )
								 WITH ( r bigint) 

	IF ISNULL(@MaxRowID,0) = 0 
	RETURN

	BEGIN TRY
		BEGIN TRANSACTION
			UPDATE dbo.SystemSettings WITH(ROWLOCK, UPDLOCK)
			SET VValue = '1'
			WHERE VName = @VNameStatus
			
			IF @IsTest = 0
			BEGIN
				INSERT INTO [dbo].[BalanceTrigger] (custid, transid, bettype, actual_stake, winlost, playercomm, BalanceChanged, NewBalance, ActionDate, ActionID, Action, BTBalance, StatusId, MatchId, SettlementType, awinlost, mwinlost, swinlost, comm, acomm, scomm, modds)
				SELECT 
				cid
				,t
				,bt
				,act
				,wl
				,pc
				,bc
				,nb
				,ad
				,aid
				,a
				,btb
				,sid
				,mid
				,st
				,aw
				,mw
				,sw
				,c
				,ac
				,sc
				, m
			FROM  OPENJSON (  CAST( DECOMPRESS(@TransInfo)   AS NVARCHAR(MAX)) )
			WITH (
					r bigint
					,cid int
					,t bigint
					,bt smallint
					,act money
					,wl money
					,pc  money
					,bc money
					,nb money
					,ad datetime
					,aid tinyint
					,a varchar(200)
					,btb money
					,sid tinyint
					,mid int
					,st tinyint
					,aw money
					,mw money
					,sw money
					,c money
					,ac money
					,sc money
					, m smallmoney
				)
				ORDER BY r ASC
			END
			ELSE
			BEGIN
				INSERT INTO [dbo].[BalanceTrigger_UAT] (RowId, custid, transid, bettype, actual_stake, winlost, playercomm, BalanceChanged, NewBalance, ActionDate, ActionID, Action, BTBalance, StatusId, MatchId, SettlementType, awinlost, mwinlost, swinlost, comm, acomm, scomm, modds, SiteDBGroupId)
				SELECT 
				r
				,cid
				,t
				,bt
				,act
				,wl
				,pc
				,bc
				,nb
				,ad
				,aid
				,a
				,btb
				,sid
				,mid
				,st
				,aw
				,mw
				,sw
				,c
				,ac
				,sc
				, m
				, @SiteDBGroupID
			FROM  OPENJSON (  CAST( DECOMPRESS(@TransInfo)   AS NVARCHAR(MAX)) )
			WITH (
					r bigint
					,cid int
					,t bigint
					,bt smallint
					,act money
					,wl money
					,pc  money
					,bc money
					,nb money
					,ad datetime
					,aid tinyint
					,a varchar(200)
					,btb money
					,sid tinyint
					,mid int
					,st tinyint
					,aw money
					,mw money
					,sw money
					,c money
					,ac money
					,sc money
					, m smallmoney
				)
				ORDER BY r ASC
			END

			UPDATE dbo.SystemSettings WITH (ROWLOCK,UPDLOCK)
			SET VValue = CAST(@MaxRowID AS VARCHAR(100) )
			WHERE VName = @VNameLastRow

			UPDATE dbo.SystemSettings WITH(ROWLOCK, UPDLOCK)
			SET VValue = '2'
			WHERE VName = @VNameStatus
		
		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		SELECT @ErrorMsg = error_message()
		ROLLBACK TRANSACTION
	END CATCH

END
GO


