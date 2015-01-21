USE [bodb02]
GO

/****** Object:  StoredProcedure [dbo].[SR_Replicate_CustSetting]    Script Date: 01/21/2015 00:16:38 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[SR_Replicate_CustSetting]
	@Step int
AS

Declare @DB varchar(20)
SET @DB = @@SERVERNAME

IF @Step = 1 -- Prepare
	EXEC DBTrans.bodb02.dbo.SR_CustSetting 'P', @DB

IF @Step = 2 -- Get
BEGIN
	INSERT INTO dbo.tmp_SR_CustSetting
	SELECT * FROM DBTrans.bodb02.dbo.View_SR_CustSetting WHERE DB = @DB

	IF @@ROWCOUNT = 0
	BEGIN
		-- raiserror here to continue to next step of jobs
		RAISERROR ('* No Data *', -- Message text.
				   16, -- Severity.
				   1 -- State.
				   );
				   
		RETURN	
	END
END
	
IF @Step = 3 -- applied command
BEGIN
	Declare @rid bigint, @maxrid bigint, @rc bigint, @cnt int
	Declare @Operation nchar(1), @ErrNum int
	Declare @icnt int, @ucnt int, @dcnt int    -- insert/update/delete count
	Declare @eicnt int, @eucnt int, @edcnt int -- error insert/update/delete count

	SELECT @rid = MIN(rid), @maxrid = MAX(rid), @cnt = COUNT(*) FROM dbo.tmp_SR_CustSetting
	SELECT @rc = 0, @icnt = 0, @ucnt = 0, @dcnt = 0, @eicnt = 0, @eucnt = 0, @edcnt = 0
	
	IF ISNULL(@cnt, 0) = 0
	BEGIN
		-- raiserror here to continue to next step of jobs
		RAISERROR ('* Finish Round *', -- Message text.
				   16, -- Severity.
				   1 -- State.
				   );
				   
		RETURN	
	END
	
	SET NOCOUNT ON
	
LoopAgain:
	SELECT @Operation = SYS_CHANGE_OPERATION FROM dbo.tmp_SR_CustSetting WHERE rid = @rid
	
	IF @@ROWCOUNT > 0
	BEGIN
		IF @Operation = 'I'
		BEGIN
			SET @icnt = @icnt + 1
			
			BEGIN TRY
				INSERT INTO dbo.CustSetting (
					[custid],[bettype],[sporttype]
					,[apositiontaking],[mpositiontaking],[spositiontaking],[alivepositiontaking],[mlivepositiontaking],[slivepositiontaking]
					,[playerdiscount],[discount],[adiscount],[sdiscount]
					,[groupa],[groupb],[groupc],[groupd],[groupe],[groupf],[minbet],[maxbet]
					,[autopositiontaking],[autolivepositiontaking],[isautopositiontaking],[isautolivepositiontaking]
					,[autompositiontaking],[autolivempositiontaking],[isautompositiontaking],[isautolivempositiontaking]
				) SELECT
					[custid],[bettype],[sporttype]
					,[apositiontaking],[mpositiontaking],[spositiontaking],[alivepositiontaking],[mlivepositiontaking],[slivepositiontaking]
					,[playerdiscount],[discount],[adiscount],[sdiscount]
					,[groupa],[groupb],[groupc],[groupd],[groupe],[groupf],[minbet],[maxbet]
					,[autopositiontaking],[autolivepositiontaking],[isautopositiontaking],[isautolivepositiontaking]
					,[autompositiontaking],[autolivempositiontaking],[isautompositiontaking],[isautolivempositiontaking]
				FROM dbo.tmp_SR_CustSetting
				WHERE rid = @rid
			END TRY
			BEGIN CATCH
				SET @ErrNum = ERROR_NUMBER()
				SET @eicnt = @eicnt + 1
			END CATCH
		END
		ELSE IF @Operation = 'D'
		BEGIN
			SET @dcnt = @dcnt + 1
			
			DELETE obj
			FROM dbo.CustSetting obj
				INNER JOIN dbo.tmp_SR_CustSetting t ON obj.custid = t.custid AND obj.bettype = t.bettype AND obj.sporttype = t.sporttype
			WHERE t.rid = @rid
			
			IF @@ROWCOUNT = 0 SET @edcnt = @edcnt + 1
		END
		ELSE IF @Operation = 'U'
		BEGIN
			SET @ucnt = @ucnt + 1
			
			UPDATE obj
			SET 
				[apositiontaking] = t.[apositiontaking],
				[mpositiontaking] = t.[mpositiontaking],
				[spositiontaking] = t.[spositiontaking],
				[alivepositiontaking] = t.[alivepositiontaking],
				[mlivepositiontaking] = t.[mlivepositiontaking],
				[slivepositiontaking] = t.[slivepositiontaking],
				[playerdiscount] = t.[playerdiscount],
				[discount]  = t.[discount],
				[adiscount] = t.[adiscount],
				[sdiscount] = t.[sdiscount],
				[groupa] = t.[groupa],
				[groupb] = t.[groupb],
				[groupc] = t.[groupc],
				[groupd] = t.[groupd],
				[groupe] = t.[groupe],
				[groupf] = t.[groupf],
				[minbet] = t.[minbet],
				[maxbet] = t.[maxbet],
				[autopositiontaking]       = t.[autopositiontaking],
				[autolivepositiontaking]   = t.[autolivepositiontaking],
				[isautopositiontaking]     = t.[isautopositiontaking],
				[isautolivepositiontaking] = t.[isautolivepositiontaking],
				[autompositiontaking]      = t.[autompositiontaking],
				[autolivempositiontaking]  = t.[autolivempositiontaking],
				[isautompositiontaking]    = t.[isautompositiontaking],
				[isautolivempositiontaking]= t.[isautolivempositiontaking]
			FROM dbo.CustSetting obj
				INNER JOIN dbo.tmp_SR_CustSetting t ON obj.custid = t.custid AND obj.bettype = t.bettype AND obj.sporttype = t.sporttype
			WHERE t.rid = @rid
			
			IF @@ROWCOUNT = 0 SET @eucnt = @eucnt + 1
		END
		
		SET @rc = @rc + 1
	END
	
	SET @rid = @rid + 1
	
	IF @rc >= 10000 GOTO Halt
	IF @rid <= @maxrid GOTO LoopAgain
	
Halt:
	SET NOCOUNT OFF

	SET @rid = @rid - 1
	EXEC DBTrans.bodb02.dbo.SR_CustSetting 'D', @DB, @rid
	DELETE FROM dbo.tmp_SR_CustSetting WHERE rid <= @rid
	
	PRINT ' ** I/U/D : ' + CAST(@icnt as varchar(20)) + '/' + CAST(@ucnt as varchar(20)) + '/' + CAST(@dcnt as varchar(20)) + ' ** '
		+ ' Err: ' + CAST(@eicnt as varchar(20)) + '/' + CAST(@eucnt as varchar(20)) + '/' + CAST(@edcnt as varchar(20)) + ' ** '
END


GO


