/*<info serverAlias="DBPRO-bodb02" executers="" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[ExecRep_APL_07] 
		@MBDate			SMALLDATETIME = NULL,
		@IsBackDay1		BIT = 0,
		@IsBackDay2		BIT = 0,
		@IsBackDay3		BIT = 0,
		@IsBackDay4		BIT = 0,
		@IsBackDay5		BIT = 0,
		@IsBackDay6		BIT = 0,
		@IsBackDay7		BIT = 0,
		-----------------------
		@BUDate			SMALLDATETIME = NULL,
		@TableName		VARCHAR(128)

AS
/*
 	Creator: 20220811@Danny
	Task: ExecRep_APL_07
	DB: DBPRO/bodb02
	Revisions:
		- 20220811@Danny: Replicate data dbo.Acc_ManualMovebetConfig [Redmine: #176449] 

 */

BEGIN
	SET NOCOUNT ON;
	-- TODO: Acc_ManualMovebetConfig
	IF (@TableName='Acc_ManualMovebetConfig' AND OBJECT_ID(N'dbo.Acc_ManualMovebetConfig', N'U') IS NOT NULL AND OBJECT_ID(N'dbo.f_Get_SiteDBGroupID', N'FN') IS NOT NULL)
	BEGIN
	IF  (@@SERVERNAME = 'DBBAL' OR dbo.f_Get_SiteDBGroupID() <> 1023)
		BEGIN
			IF EXISTS (SELECT 1 FROM dbo.Acc_ManualMovebetConfig WITH(NOLOCK) WHERE MBDate = @MBDate)
			BEGIN
				UPDATE  t
				SET		t.IsBackDay1 = @IsBackDay1,
						t.IsBackDay2 = @IsBackDay2,
						t.IsBackDay3 = @IsBackDay3,
						t.IsBackDay4 = @IsBackDay4,
						t.IsBackDay5 = @IsBackDay5,
						t.IsBackDay6 = @IsBackDay6,
						t.IsBackDay7 = @IsBackDay7
				FROM	dbo.Acc_ManualMovebetConfig t WITH(ROWLOCK, UPDLOCK)
				WHERE	t.MBDate = @MBDate

			END
			ELSE
			BEGIN
				INSERT INTO dbo.Acc_ManualMovebetConfig (MBDate, IsBackDay1, IsBackDay2, IsBackDay3, IsBackDay4, IsBackDay5, IsBackDay6, IsBackDay7)
				VALUES (@MBDate, @IsBackDay1, @IsBackDay2, @IsBackDay3, @IsBackDay4, @IsBackDay5, @IsBackDay6, @IsBackDay7)
			END
		END
	END

	-- TODO: Task_ArchiveDate
	IF (@TableName = 'Task_ArchiveDate'	AND OBJECT_ID(N'dbo.Task_ArchiveDate', N'U') IS NOT NULL AND OBJECT_ID(N'dbo.f_Get_SiteDBGroupID', N'FN') IS NOT NULL)
	BEGIN
		BEGIN TRY
			BEGIN TRAN
			IF  (@@SERVERNAME = 'DBBAL' OR dbo.f_Get_SiteDBGroupID() <> 1023)
			BEGIN
				DELETE bodb02.dbo.Task_ArchiveDate;

				WITH cte
				AS (
					SELECT @BUDate AS winlostdate,1 AS Idx
					UNION ALL
			
					SELECT DATEADD(DAY, 1, winlostdate), Idx + 1
					FROM cte
					WHERE Idx < 7
				)
				INSERT INTO bodb02.dbo.Task_ArchiveDate (Winlostdate)
				SELECT Winlostdate
				FROM cte
				COMMIT
			END
		END TRY

		BEGIN CATCH
			IF @@TRANCOUNT > 0
				ROLLBACK
		END CATCH
	END

END

