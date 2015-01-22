USE [bodb_Archive]
GO

/****** Object:  StoredProcedure [dbo].[findit]    Script Date: 01/21/2015 23:25:48 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[findit]
as

declare @rn int, @wl smalldatetime

select @rn = rn, @wl = wldate
from dd

INSERT INTO data
SELECT b.* FROM bettrans_bk b with (nolock)
WHERE
	winlostdate = @wl
	AND IP IN (SELECT IP FROM xip with (nolock))

DELETE FROM dd
WHERE rn = @rn

GO


