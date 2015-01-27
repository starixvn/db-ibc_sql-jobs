USE [bodb02]
GO

/****** Object:  StoredProcedure [dbo].[ExecRep_07]    Script Date: 01/26/2015 23:23:14 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[ExecRep_07]
	@custids varchar(2000),
	@custid int,
	@roleid int,
	@winlostdate smalldatetime
AS
--SET NOCOUNT ON
-- called from procedure BBU
	BEGIN TRANSACTION

	IF @roleid = 44
		DELETE FROM bettrans
		WHERE recommend = 0 AND srecommend IN (SELECT val FROM dbo.strSplit(@custids, ','))
		AND ruben = 1 AND winlostdate < @winlostdate
	ELSE IF @roleid = 22
		DELETE FROM dbo.bettrans
		WHERE recommend IN (SELECT val FROM dbo.strSplit(@custids, ','))
		AND ruben = 1 AND winlostdate < @winlostdate
	ELSE IF @roleid = 11
		DELETE FROM bettrans
		WHERE recommend = @custid AND custid IN (SELECT val FROM dbo.strSplit(@custids, ','))
		AND ruben = 1 AND winlostdate < @winlostdate
	ELSE IF @roleid = 2
		DELETE FROM bettrans
		WHERE recommend = @custid
		AND ruben = 1 AND winlostdate < @winlostdate

	COMMIT TRANSACTION

GO

GRANT EXECUTE ON [dbo].[ExecRep_07] TO [vnteam] AS [dbo]
GO

GRANT VIEW DEFINITION ON [dbo].[ExecRep_07] TO [vnteam] AS [dbo]
GO


