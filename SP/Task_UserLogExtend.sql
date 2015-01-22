USE [bodb02]
GO

/****** Object:  StoredProcedure [dbo].[Task_UserLogExtend]    Script Date: 01/21/2015 23:33:02 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Task_UserLogExtend]
	@string nvarchar(300),
	@result int OUTPUT
AS

IF @string LIKE 'Customer%' RETURN 0
--IF @string LIKE 'Customer%enter to server%' RETURN 0
--IF @string LIKE 'Customer%IP%SID%' RETURN 0
--IF @string LIKE 'Customer%logout' RETURN 0
--IF @string LIKE 'Customer%kicked out%' RETURN 0
--IF @string LIKE 'Agent%Result%' RETURN 0
--IF @string LIKE 'Insert trans%' RETURN 0

Declare @res TABLE (val bigint)

Declare @i int, @len int
Declare @word nvarchar(20), @c nvarchar(1)

SELECT @i = 1, @len = len(@string), @word = N''

WHILE @i <= @len
BEGIN
	SET @c = substring(@string, @i, 1)
	IF ASCII(@c) BETWEEN 48 AND 57
		SET @word = @word + @c
	ELSE
		IF @word <> N''
		BEGIN
			IF LEN(@word) > 4 INSERT INTO @res VALUES (  CAST(RIGHT(@word,12) as varchar(15)) )
			SET @word = N''
		END
	SET @i = @i + 1
END
IF @word <> N'' AND LEN(@word) > 4 INSERT INTO @res VALUES (RIGHT(@word,12))

-- remove anything bigger than INT
DELETE FROM @res WHERE val > 2147483647


Declare @cat tinyint
--CREATE TABLE tmp_Task_UserLogExtend (vid int, cat tinyint)
SELECT TOP 1 @result = t.vid FROM dbo.tmp_Task_UserLogExtend t with (nolock) INNER JOIN @res AS r ON t.vid = r.val ORDER BY cat
IF @@ROWCOUNT = 0
BEGIN
	SELECT @result = o.oddsid, @cat = 1 FROM dbo.odds o with (nolock) INNER JOIN @res AS r ON o.oddsid = r.val
	IF @@ROWCOUNT > 0
		INSERT INTO dbo.tmp_Task_UserLogExtend (vid, cat) VALUES (@result, @cat)
	ELSE
	BEGIN
		SELECT @result = m.matchid, @cat = 2 FROM dbo.match m with (nolock) INNER JOIN @res AS r ON m.matchid = r.val
		IF @@ROWCOUNT > 0
			INSERT INTO dbo.tmp_Task_UserLogExtend (vid, cat) VALUES (@result, @cat)
		ELSE
		BEGIN
			SELECT @result = o.orid, @cat = 3 FROM dbo.outright o with (nolock) INNER JOIN @res AS r ON o.orid = r.val
			IF @@ROWCOUNT > 0
				INSERT INTO dbo.tmp_Task_UserLogExtend (vid, cat) VALUES (@result, @cat)
			ELSE
				SET @result = 0
		END
	END
END


GO


