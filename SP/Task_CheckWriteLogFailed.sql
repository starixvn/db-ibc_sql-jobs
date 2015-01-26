USE [bodb_CustomerLog]
GO

/****** Object:  StoredProcedure [dbo].[Task_CheckWriteLogFailed]    Script Date: 01/26/2015 03:26:52 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Task_CheckWriteLogFailed]

AS
BEGIN
	SET NOCOUNT ON	
	
	DECLARE	@ErrMsg	VARCHAR(8000)
	SELECT	@ErrMsg =''
	
	IF EXISTS(	SELECT TOP 1 1 FROM UserLog_Login WITH (NOLOCK))
	BEGIN
		SELECT	@ErrMsg='WARNING: Writting Login LOG failed! '
	END
	
	IF EXISTS(	SELECT TOP 1 1 FROM UserLog_RunSP WITH (NOLOCK))
	BEGIN
		SELECT	@ErrMsg= @ErrMsg +'WARNING: Writting RunSP LOG failed!'
	END
	
	IF EXISTS(	SELECT TOP 1 1 FROM UserLog_Settle WITH (NOLOCK))
	BEGIN
		SELECT	@ErrMsg= @ErrMsg +'WARNING: Writting Settlement LOG failed!'
	END

	IF EXISTS(	SELECT TOP 1 1 FROM UserLog_Transfer WITH (NOLOCK))
	BEGIN
		SELECT	@ErrMsg= @ErrMsg +'WARNING: Writting TRANSFER LOG failed!'
	END
	
	IF EXISTS(	SELECT TOP 1 1 FROM UserLog_Credit WITH (NOLOCK))
	BEGIN
		SELECT	@ErrMsg= @ErrMsg +'WARNING: Writting Credit LOG failed!'
	END
	
	IF @ErrMsg <> '' 
	BEGIN
		RAISERROR(@ErrMsg,16,1)
	END
	
END
GO

GRANT VIEW DEFINITION ON [dbo].[Task_CheckWriteLogFailed] TO [vnteam] AS [dbo]
GO


