USE [bodb02]
GO

/****** Object:  StoredProcedure [dbo].[SR_CustSetting]    Script Date: 01/27/2015 00:14:38 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[SR_CustSetting]
	@Action nchar(1) = '',
	@DB varchar(20),
	@rid bigint = NULL
AS

-- DELETE (3)
-- call to delete the change that already applied
IF @Action = 'D' -- Delete
BEGIN
	IF @rid IS NULL RETURN
	
	DELETE FROM dbo.tmp_SR_CustSetting
	WHERE DB = @DB AND rid <= @rid

	RETURN
END


IF @Action <> 'P' -- Prepare
	RETURN


-- PREPARE (1)
-- call to prepare data to be obtain later by GET

-- still have data? so last round not successful yet. let it continue with existing data first
IF EXISTS (SELECT 1 FROM dbo.tmp_SR_CustSetting WHERE DB = @DB) RETURN

Declare @OID int
Declare @LastVersion bigint
Declare @CurrentVersion bigint

SELECT @LastVersion = LastVersion, @CurrentVersion = CHANGE_TRACKING_CURRENT_VERSION()
FROM dbo.Self_Replicate_LastVersion
WHERE DB = @DB AND OID = OBJECT_ID('CustSetting')

-- no row? so did we not config it for this one.
IF @@ROWCOUNT = 0 RETURN

INSERT INTO dbo.tmp_SR_CustSetting (SYS_CHANGE_VERSION, SYS_CHANGE_OPERATION, DB, custid, bettype, sporttype)
SELECT SYS_CHANGE_VERSION, SYS_CHANGE_OPERATION, @DB, custid, bettype, sporttype
FROM CHANGETABLE(CHANGES CustSetting, @LastVersion) CT
ORDER BY SYS_CHANGE_VERSION

UPDATE dbo.Self_Replicate_LastVersion
SET LastVersion = @CurrentVersion
WHERE DB = @DB AND OID = OBJECT_ID('CustSetting')


GO


