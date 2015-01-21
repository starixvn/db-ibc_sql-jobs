USE [serviceBrokerDB]
GO

/****** Object:  StoredProcedure [sb].[TASK_SBGetMessages]    Script Date: 01/21/2015 00:10:43 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [sb].[TASK_SBGetMessages]
AS
/*  Created: Viet @ 20140625	
	DB: DB05x.serviceBrokerDB
	Revisions:  
			
*/
BEGIN 
	SET NOCOUNT ON	
	
	DECLARE @x AS TABLE(transid bigint)
	DECLARE @rCount int
	DECLARE @batchSize int
	DECLARE @message nvarchar(MAX)
	
	SET @batchSize = 10
	
	WHILE (1=1)
	BEGIN
		DELETE @x
		
		;WITH s AS(
			SELECT TOP (@batchSize) transid
			FROM sb.bettrans_running_temp WITH(ROWLOCK, READPAST)
			ORDER BY seqID
		)
		DELETE
		FROM s
		OUTPUT deleted.transid INTO @x(transid)
		
		SET @rCount = @@rowcount
		IF @rCount = 0 BREAK						
		
		SELECT @message = STUFF((
			SELECT ',' + cast(transid as varchar(15)) 
			FROM @x 
			FOR XML PATH('')
		), 1,1,'')
		
		EXEC [sb].[SBInputMessage]  
			@fromService = N'//Service/bettransRunning_send',
			@toService = N'//Service/bettransRunning_receive',
			@onContract = N'//Contract/bettransRunning',
			@messageType = N'//Message/bettrans_update',
			@messageBody = @message
		
		--SELECT @rcount, @batchsize, @message
		--BREAK
		IF @rCount < @batchSize BREAK
	END
	
END

GO


