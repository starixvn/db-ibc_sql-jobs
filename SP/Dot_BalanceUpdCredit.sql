USE [bodb02]
GO

/****** Object:  StoredProcedure [dbo].[Dot_BalanceUpdCredit]    Script Date: 01/27/2015 22:57:02 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Dot_BalanceUpdCredit]
	@custid int,
	@balance money,
	@stoptest bit = 0
AS

-- 20111220@Vivi: place bet SPs will input @stoptest=1, if want stop test then un-comment
-- IF @stoptest=1 return

Declare @Retry int, @Success bit
SET @Retry = 0

TryAgain:

BEGIN TRY
	SET @Retry = @Retry + 1
	SET @Success = 1
	BEGIN TRANSACTION
	
		UPDATE dbo.BalanceCredit WITH (rowlock, updlock)
		SET Balance = Balance + @balance
		WHERE custid = @custid
		
		IF @@ROWCOUNT = 0
		BEGIN
			INSERT INTO dbo.BalanceCredit (custid, balance) VALUES (@custid, @balance)
			
			EXEC dbo.[Dot_BalanceUpdDebit] @custid, 0
		END
		
	COMMIT TRANSACTION
END TRY
BEGIN CATCH
	SET @Success = 0
	ROLLBACK TRANSACTION
END CATCH

IF @Success = 0 AND @Retry < 3 GOTO TryAgain


GO

GRANT VIEW DEFINITION ON [dbo].[Dot_BalanceUpdCredit] TO [vnteam] AS [dbo]
GO


