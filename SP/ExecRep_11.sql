/*<info serverAlias="DBTXN-bodb02,DBBAL-bodb02" executers="" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[ExecRep_11] 
		@MBDate			SMALLDATETIME = NULL,
		@IsBackDay1		BIT = 0,
		@IsBackDay2		BIT = 0,
		@IsBackDay3		BIT = 0,
		@IsBackDay4		BIT = 0,
		@IsBackDay5		BIT = 0,
		@IsBackDay6		BIT = 0 ,
		@IsBackDay7		BIT = 0
AS
/*
 	Creator: 20210323@Patrick
	Task: ExecRep_11
	DB: DBTXN/bodb02
	Revisions:
		- 20210323@Patrick: Initial [Redmine: #149927] 
		- 20210604@Danny: Replicate data dbo.Acc_ManualMovebetConfig [Redmine: #150053] 
		- 20210816@Sophia: add DBBAL [Redmine: #154300]
 */

BEGIN
	SET NOCOUNT ON;
	IF  (@@SERVERNAME IN ('SITDBTRANS', 'DBTRANS', 'DB230', 'DB206', 'DBBAL') AND OBJECT_ID(N'dbo.Acc_ManualMovebetConfig', N'U') IS NOT NULL)
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

