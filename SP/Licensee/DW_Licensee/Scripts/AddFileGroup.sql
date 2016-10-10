USE bodb_Licensee
GO
DECLARE @path nvarchar(256), @rptPath nvarchar(256)
SELECT @path ='G:\IBC_DB\bodb_Licensee\'
		,@RPTpath ='G:\IBC_DB\bodb_Licensee\DW_rpt_Betting'

--licensee_staging file
IF NOT EXISTS(
	SELECT 1
	FROM sys.filegroups 
	WHERE name ='DW_staging'
	)
BEGIN
	ALTER DATABASE bodb_Licensee
	ADD FILEGROUP DW_staging
	
	EXEC('ALTER DATABASE bodb_Licensee
		ADD FILE
		(NAME =''DW_staging_DATA''
		,FILENAME='''+@path+'DW_staging_DATA.ndf''
		,SIZE = 2MB, FILEGROWTH = 32MB)
		TO FILEGROUP DW_staging'
	)
END

--licensee_transfer file
IF NOT EXISTS(
	SELECT 1
	FROM sys.filegroups 
	WHERE name ='DW_transfer'
	)
BEGIN
	ALTER DATABASE bodb_Licensee
	ADD FILEGROUP DW_transfer
	
	EXEC('ALTER DATABASE bodb_Licensee
		ADD FILE
		(NAME =''DW_transfer_DATA''
		,FILENAME='''+@path+'DW_transfer_DATA.ndf''
		,SIZE = 2MB, FILEGROWTH = 32MB)
		TO FILEGROUP DW_transfer'
	)
END

--licensee_DW file
IF NOT EXISTS(
	SELECT 1
	FROM sys.filegroups 
	WHERE name ='DW_KPI_DATA'
	)
BEGIN
	ALTER DATABASE bodb_Licensee
	ADD FILEGROUP DW_KPI_DATA
	
	EXEC('ALTER DATABASE bodb_Licensee
		ADD FILE
		(NAME =''DW_KPI_DATA''
		,FILENAME='''+@path+'DW_KPI_DATA.ndf'' ,SIZE = 2MB, FILEGROWTH = 32MB)
		TO FILEGROUP DW_KPI_DATA'
	)
END

--rptBetting_[YY]M[MM] file
	IF NOT EXISTS(
		SELECT 1
		FROM sys.filegroups 
		WHERE name ='rptBetting_MAX'
		)
	BEGIN
		ALTER DATABASE bodb_Licensee
		ADD FILEGROUP rptBetting_MAX
		
		EXEC('ALTER DATABASE bodb_Licensee
			ADD FILE
			(NAME =''rptBetting_MAX_DATA''
			,FILENAME='''+@rptPath+'rptBetting_MAX_DATA.ndf'' ,SIZE = 2MB, FILEGROWTH = 32MB)
			TO FILEGROUP rptBetting_MAX'
		)
	END
	
	IF NOT EXISTS(
		SELECT 1
		FROM sys.filegroups 
		WHERE name ='rptBetting_Before09M01'
		)
	BEGIN
		ALTER DATABASE bodb_Licensee
		ADD FILEGROUP rptBetting_Before09M01
		
		EXEC('ALTER DATABASE bodb_Licensee
			ADD FILE
			(NAME =''rptBetting_Before09M01_DATA''
			,FILENAME='''+@rptPath+'rptBetting_Before09M01_DATA.ndf'' ,SIZE = 2MB, FILEGROWTH = 32MB)
			TO FILEGROUP rptBetting_Before09M01'
		)
	END
	------------------2009----------------------------
		
	IF NOT EXISTS(
		SELECT 1
		FROM sys.filegroups 
		WHERE name ='rptBetting_09M01'
		)
	BEGIN
		ALTER DATABASE bodb_Licensee
		ADD FILEGROUP rptBetting_09M01
		
		EXEC('ALTER DATABASE bodb_Licensee
			ADD FILE
			(NAME =''rptBetting_09M01_DATA''
			,FILENAME='''+@rptPath+'rptBetting_09M01_DATA.ndf'' ,SIZE = 2MB, FILEGROWTH = 32MB)
			TO FILEGROUP rptBetting_09M01'
		)
	END

	IF NOT EXISTS(
		SELECT 1
		FROM sys.filegroups 
		WHERE name ='rptBetting_09M02'
		)
	BEGIN
		ALTER DATABASE bodb_Licensee
		ADD FILEGROUP rptBetting_09M02
		
		EXEC('ALTER DATABASE bodb_Licensee
			ADD FILE
			(NAME =''rptBetting_09M02_DATA''
			,FILENAME='''+@rptPath+'rptBetting_09M02_DATA.ndf'' ,SIZE = 2MB, FILEGROWTH = 32MB)
			TO FILEGROUP rptBetting_09M02'
		)
	END

	IF NOT EXISTS(
		SELECT 1
		FROM sys.filegroups 
		WHERE name ='rptBetting_09M03'
		)
	BEGIN
		ALTER DATABASE bodb_Licensee
		ADD FILEGROUP rptBetting_09M03
		
		EXEC('ALTER DATABASE bodb_Licensee
			ADD FILE
			(NAME =''rptBetting_09M03_DATA''
			,FILENAME='''+@rptPath+'rptBetting_09M03_DATA.ndf'' ,SIZE = 2MB, FILEGROWTH = 32MB)
			TO FILEGROUP rptBetting_09M03'
		)
	END

	IF NOT EXISTS(
		SELECT 1
		FROM sys.filegroups 
		WHERE name ='rptBetting_09M04'
		)
	BEGIN
		ALTER DATABASE bodb_Licensee
		ADD FILEGROUP rptBetting_09M04
		
		EXEC('ALTER DATABASE bodb_Licensee
			ADD FILE
			(NAME =''rptBetting_09M04_DATA''
			,FILENAME='''+@rptPath+'rptBetting_09M04_DATA.ndf'' ,SIZE = 2MB, FILEGROWTH = 32MB)
			TO FILEGROUP rptBetting_09M04'
		)
	END

	IF NOT EXISTS(
		SELECT 1
		FROM sys.filegroups 
		WHERE name ='rptBetting_09M05'
		)
	BEGIN
		ALTER DATABASE bodb_Licensee
		ADD FILEGROUP rptBetting_09M05
		
		EXEC('ALTER DATABASE bodb_Licensee
			ADD FILE
			(NAME =''rptBetting_09M05_DATA''
			,FILENAME='''+@rptPath+'rptBetting_09M05_DATA.ndf'' ,SIZE = 2MB, FILEGROWTH = 32MB)
			TO FILEGROUP rptBetting_09M05'
		)
	END

	IF NOT EXISTS(
		SELECT 1
		FROM sys.filegroups 
		WHERE name ='rptBetting_09M06'
		)
	BEGIN
		ALTER DATABASE bodb_Licensee
		ADD FILEGROUP rptBetting_09M06
		
		EXEC('ALTER DATABASE bodb_Licensee
			ADD FILE
			(NAME =''rptBetting_09M06_DATA''
			,FILENAME='''+@rptPath+'rptBetting_09M06_DATA.ndf'' ,SIZE = 2MB, FILEGROWTH = 32MB)
			TO FILEGROUP rptBetting_09M06'
		)
	END

	IF NOT EXISTS(
		SELECT 1
		FROM sys.filegroups 
		WHERE name ='rptBetting_09M07'
		)
	BEGIN
		ALTER DATABASE bodb_Licensee
		ADD FILEGROUP rptBetting_09M07
		
		EXEC('ALTER DATABASE bodb_Licensee
			ADD FILE
			(NAME =''rptBetting_09M07_DATA''
			,FILENAME='''+@rptPath+'rptBetting_09M07_DATA.ndf'' ,SIZE = 2MB, FILEGROWTH = 32MB)
			TO FILEGROUP rptBetting_09M07'
		)
	END

	IF NOT EXISTS(
		SELECT 1
		FROM sys.filegroups 
		WHERE name ='rptBetting_09M08'
		)
	BEGIN
		ALTER DATABASE bodb_Licensee
		ADD FILEGROUP rptBetting_09M08
		
		EXEC('ALTER DATABASE bodb_Licensee
			ADD FILE
			(NAME =''rptBetting_09M08_DATA''
			,FILENAME='''+@rptPath+'rptBetting_09M08_DATA.ndf'' ,SIZE = 2MB, FILEGROWTH = 32MB)
			TO FILEGROUP rptBetting_09M08'
		)
	END

	IF NOT EXISTS(
		SELECT 1
		FROM sys.filegroups 
		WHERE name ='rptBetting_09M09'
		)
	BEGIN
		ALTER DATABASE bodb_Licensee
		ADD FILEGROUP rptBetting_09M09
		
		EXEC('ALTER DATABASE bodb_Licensee
			ADD FILE
			(NAME =''rptBetting_09M09_DATA''
			,FILENAME='''+@rptPath+'rptBetting_09M09_DATA.ndf'' ,SIZE = 2MB, FILEGROWTH = 32MB)
			TO FILEGROUP rptBetting_09M09'
		)
	END

	IF NOT EXISTS(
		SELECT 1
		FROM sys.filegroups 
		WHERE name ='rptBetting_09M10'
		)
	BEGIN
		ALTER DATABASE bodb_Licensee
		ADD FILEGROUP rptBetting_09M10
		
		EXEC('ALTER DATABASE bodb_Licensee
			ADD FILE
			(NAME =''rptBetting_09M10_DATA''
			,FILENAME='''+@rptPath+'rptBetting_09M10_DATA.ndf'' ,SIZE = 2MB, FILEGROWTH = 32MB)
			TO FILEGROUP rptBetting_09M10'
		)
	END

	IF NOT EXISTS(
		SELECT 1
		FROM sys.filegroups 
		WHERE name ='rptBetting_09M11'
		)
	BEGIN
		ALTER DATABASE bodb_Licensee
		ADD FILEGROUP rptBetting_09M11
		
		EXEC('ALTER DATABASE bodb_Licensee
			ADD FILE
			(NAME =''rptBetting_09M11_DATA''
			,FILENAME='''+@rptPath+'rptBetting_09M11_DATA.ndf'' ,SIZE = 2MB, FILEGROWTH = 32MB)
			TO FILEGROUP rptBetting_09M11'
		)
	END

	IF NOT EXISTS(
		SELECT 1
		FROM sys.filegroups 
		WHERE name ='rptBetting_09M12'
		)
	BEGIN
		ALTER DATABASE bodb_Licensee
		ADD FILEGROUP rptBetting_09M12
		
		EXEC('ALTER DATABASE bodb_Licensee
			ADD FILE
			(NAME =''rptBetting_09M12_DATA''
			,FILENAME='''+@rptPath+'rptBetting_09M12_DATA.ndf'' ,SIZE = 2MB, FILEGROWTH = 32MB)
			TO FILEGROUP rptBetting_09M12'
		)
	END

	------------------2010----------------------------
	IF NOT EXISTS(
		SELECT 1
		FROM sys.filegroups 
		WHERE name ='rptBetting_10M01'
		)
	BEGIN
		ALTER DATABASE bodb_Licensee
		ADD FILEGROUP rptBetting_10M01
		
		EXEC('ALTER DATABASE bodb_Licensee
			ADD FILE
			(NAME =''rptBetting_10M01_DATA''
			,FILENAME='''+@rptPath+'rptBetting_10M01_DATA.ndf'' ,SIZE = 2MB, FILEGROWTH = 32MB)
			TO FILEGROUP rptBetting_10M01'
		)
	END

	IF NOT EXISTS(
		SELECT 1
		FROM sys.filegroups 
		WHERE name ='rptBetting_10M02'
		)
	BEGIN
		ALTER DATABASE bodb_Licensee
		ADD FILEGROUP rptBetting_10M02
		
		EXEC('ALTER DATABASE bodb_Licensee
			ADD FILE
			(NAME =''rptBetting_10M02_DATA''
			,FILENAME='''+@rptPath+'rptBetting_10M02_DATA.ndf'' ,SIZE = 2MB, FILEGROWTH = 32MB)
			TO FILEGROUP rptBetting_10M02'
		)
	END

	IF NOT EXISTS(
		SELECT 1
		FROM sys.filegroups 
		WHERE name ='rptBetting_10M03'
		)
	BEGIN
		ALTER DATABASE bodb_Licensee
		ADD FILEGROUP rptBetting_10M03
		
		EXEC('ALTER DATABASE bodb_Licensee
			ADD FILE
			(NAME =''rptBetting_10M03_DATA''
			,FILENAME='''+@rptPath+'rptBetting_10M03_DATA.ndf'' ,SIZE = 2MB, FILEGROWTH = 32MB)
			TO FILEGROUP rptBetting_10M03'
		)
	END

	IF NOT EXISTS(
		SELECT 1
		FROM sys.filegroups 
		WHERE name ='rptBetting_10M04'
		)
	BEGIN
		ALTER DATABASE bodb_Licensee
		ADD FILEGROUP rptBetting_10M04
		
		EXEC('ALTER DATABASE bodb_Licensee
			ADD FILE
			(NAME =''rptBetting_10M04_DATA''
			,FILENAME='''+@rptPath+'rptBetting_10M04_DATA.ndf'' ,SIZE = 2MB, FILEGROWTH = 32MB)
			TO FILEGROUP rptBetting_10M04'
		)
	END

	IF NOT EXISTS(
		SELECT 1
		FROM sys.filegroups 
		WHERE name ='rptBetting_10M05'
		)
	BEGIN
		ALTER DATABASE bodb_Licensee
		ADD FILEGROUP rptBetting_10M05
		
		EXEC('ALTER DATABASE bodb_Licensee
			ADD FILE
			(NAME =''rptBetting_10M05_DATA''
			,FILENAME='''+@rptPath+'rptBetting_10M05_DATA.ndf'' ,SIZE = 2MB, FILEGROWTH = 32MB)
			TO FILEGROUP rptBetting_10M05'
		)
	END

	IF NOT EXISTS(
		SELECT 1
		FROM sys.filegroups 
		WHERE name ='rptBetting_10M06'
		)
	BEGIN
		ALTER DATABASE bodb_Licensee
		ADD FILEGROUP rptBetting_10M06
		
		EXEC('ALTER DATABASE bodb_Licensee
			ADD FILE
			(NAME =''rptBetting_10M06_DATA''
			,FILENAME='''+@rptPath+'rptBetting_10M06_DATA.ndf'' ,SIZE = 2MB, FILEGROWTH = 32MB)
			TO FILEGROUP rptBetting_10M06'
		)
	END

	IF NOT EXISTS(
		SELECT 1
		FROM sys.filegroups 
		WHERE name ='rptBetting_10M07'
		)
	BEGIN
		ALTER DATABASE bodb_Licensee
		ADD FILEGROUP rptBetting_10M07
		
		EXEC('ALTER DATABASE bodb_Licensee
			ADD FILE
			(NAME =''rptBetting_10M07_DATA''
			,FILENAME='''+@rptPath+'rptBetting_10M07_DATA.ndf'' ,SIZE = 2MB, FILEGROWTH = 32MB)
			TO FILEGROUP rptBetting_10M07'
		)
	END

	IF NOT EXISTS(
		SELECT 1
		FROM sys.filegroups 
		WHERE name ='rptBetting_10M08'
		)
	BEGIN
		ALTER DATABASE bodb_Licensee
		ADD FILEGROUP rptBetting_10M08
		
		EXEC('ALTER DATABASE bodb_Licensee
			ADD FILE
			(NAME =''rptBetting_10M08_DATA''
			,FILENAME='''+@rptPath+'rptBetting_10M08_DATA.ndf'' ,SIZE = 2MB, FILEGROWTH = 32MB)
			TO FILEGROUP rptBetting_10M08'
		)
	END

	IF NOT EXISTS(
		SELECT 1
		FROM sys.filegroups 
		WHERE name ='rptBetting_10M09'
		)
	BEGIN
		ALTER DATABASE bodb_Licensee
		ADD FILEGROUP rptBetting_10M09
		
		EXEC('ALTER DATABASE bodb_Licensee
			ADD FILE
			(NAME =''rptBetting_10M09_DATA''
			,FILENAME='''+@rptPath+'rptBetting_10M09_DATA.ndf'' ,SIZE = 2MB, FILEGROWTH = 32MB)
			TO FILEGROUP rptBetting_10M09'
		)
	END

	IF NOT EXISTS(
		SELECT 1
		FROM sys.filegroups 
		WHERE name ='rptBetting_10M10'
		)
	BEGIN
		ALTER DATABASE bodb_Licensee
		ADD FILEGROUP rptBetting_10M10
		
		EXEC('ALTER DATABASE bodb_Licensee
			ADD FILE
			(NAME =''rptBetting_10M10_DATA''
			,FILENAME='''+@rptPath+'rptBetting_10M10_DATA.ndf'' ,SIZE = 2MB, FILEGROWTH = 32MB)
			TO FILEGROUP rptBetting_10M10'
		)
	END

	IF NOT EXISTS(
		SELECT 1
		FROM sys.filegroups 
		WHERE name ='rptBetting_10M11'
		)
	BEGIN
		ALTER DATABASE bodb_Licensee
		ADD FILEGROUP rptBetting_10M11
		
		EXEC('ALTER DATABASE bodb_Licensee
			ADD FILE
			(NAME =''rptBetting_10M11_DATA''
			,FILENAME='''+@rptPath+'rptBetting_10M11_DATA.ndf'' ,SIZE = 2MB, FILEGROWTH = 32MB)
			TO FILEGROUP rptBetting_10M11'
		)
	END

	IF NOT EXISTS(
		SELECT 1
		FROM sys.filegroups 
		WHERE name ='rptBetting_10M12'
		)
	BEGIN
		ALTER DATABASE bodb_Licensee
		ADD FILEGROUP rptBetting_10M12
		
		EXEC('ALTER DATABASE bodb_Licensee
			ADD FILE
			(NAME =''rptBetting_10M12_DATA''
			,FILENAME='''+@rptPath+'rptBetting_10M12_DATA.ndf'' ,SIZE = 2MB, FILEGROWTH = 32MB)
			TO FILEGROUP rptBetting_10M12'
		)
	END

	------------------2011----------------------------
	IF NOT EXISTS(
		SELECT 1
		FROM sys.filegroups 
		WHERE name ='rptBetting_11M01'
		)
	BEGIN
		ALTER DATABASE bodb_Licensee
		ADD FILEGROUP rptBetting_11M01
		
		EXEC('ALTER DATABASE bodb_Licensee
			ADD FILE
			(NAME =''rptBetting_11M01_DATA''
			,FILENAME='''+@rptPath+'rptBetting_11M01_DATA.ndf'' ,SIZE = 2MB, FILEGROWTH = 32MB)
			TO FILEGROUP rptBetting_11M01'
		)
	END

	IF NOT EXISTS(
		SELECT 1
		FROM sys.filegroups 
		WHERE name ='rptBetting_11M02'
		)
	BEGIN
		ALTER DATABASE bodb_Licensee
		ADD FILEGROUP rptBetting_11M02
		
		EXEC('ALTER DATABASE bodb_Licensee
			ADD FILE
			(NAME =''rptBetting_11M02_DATA''
			,FILENAME='''+@rptPath+'rptBetting_11M02_DATA.ndf'' ,SIZE = 2MB, FILEGROWTH = 32MB)
			TO FILEGROUP rptBetting_11M02'
		)
	END

	IF NOT EXISTS(
		SELECT 1
		FROM sys.filegroups 
		WHERE name ='rptBetting_11M03'
		)
	BEGIN
		ALTER DATABASE bodb_Licensee
		ADD FILEGROUP rptBetting_11M03
		
		EXEC('ALTER DATABASE bodb_Licensee
			ADD FILE
			(NAME =''rptBetting_11M03_DATA''
			,FILENAME='''+@rptPath+'rptBetting_11M03_DATA.ndf'' ,SIZE = 2MB, FILEGROWTH = 32MB)
			TO FILEGROUP rptBetting_11M03'
		)
	END

	IF NOT EXISTS(
		SELECT 1
		FROM sys.filegroups 
		WHERE name ='rptBetting_11M04'
		)
	BEGIN
		ALTER DATABASE bodb_Licensee
		ADD FILEGROUP rptBetting_11M04
		
		EXEC('ALTER DATABASE bodb_Licensee
			ADD FILE
			(NAME =''rptBetting_11M04_DATA''
			,FILENAME='''+@rptPath+'rptBetting_11M04_DATA.ndf'' ,SIZE = 2MB, FILEGROWTH = 32MB)
			TO FILEGROUP rptBetting_11M04'
		)
	END

	IF NOT EXISTS(
		SELECT 1
		FROM sys.filegroups 
		WHERE name ='rptBetting_11M05'
		)
	BEGIN
		ALTER DATABASE bodb_Licensee
		ADD FILEGROUP rptBetting_11M05
		
		EXEC('ALTER DATABASE bodb_Licensee
			ADD FILE
			(NAME =''rptBetting_11M05_DATA''
			,FILENAME='''+@rptPath+'rptBetting_11M05_DATA.ndf'' ,SIZE = 2MB, FILEGROWTH = 32MB)
			TO FILEGROUP rptBetting_11M05'
		)
	END

	IF NOT EXISTS(
		SELECT 1
		FROM sys.filegroups 
		WHERE name ='rptBetting_11M06'
		)
	BEGIN
		ALTER DATABASE bodb_Licensee
		ADD FILEGROUP rptBetting_11M06
		
		EXEC('ALTER DATABASE bodb_Licensee
			ADD FILE
			(NAME =''rptBetting_11M06_DATA''
			,FILENAME='''+@rptPath+'rptBetting_11M06_DATA.ndf'' ,SIZE = 2MB, FILEGROWTH = 32MB)
			TO FILEGROUP rptBetting_11M06'
		)
	END

	IF NOT EXISTS(
		SELECT 1
		FROM sys.filegroups 
		WHERE name ='rptBetting_11M07'
		)
	BEGIN
		ALTER DATABASE bodb_Licensee
		ADD FILEGROUP rptBetting_11M07
		
		EXEC('ALTER DATABASE bodb_Licensee
			ADD FILE
			(NAME =''rptBetting_11M07_DATA''
			,FILENAME='''+@rptPath+'rptBetting_11M07_DATA.ndf'' ,SIZE = 2MB, FILEGROWTH = 32MB)
			TO FILEGROUP rptBetting_11M07'
		)
	END

	IF NOT EXISTS(
		SELECT 1
		FROM sys.filegroups 
		WHERE name ='rptBetting_11M08'
		)
	BEGIN
		ALTER DATABASE bodb_Licensee
		ADD FILEGROUP rptBetting_11M08
		
		EXEC('ALTER DATABASE bodb_Licensee
			ADD FILE
			(NAME =''rptBetting_11M08_DATA''
			,FILENAME='''+@rptPath+'rptBetting_11M08_DATA.ndf'' ,SIZE = 2MB, FILEGROWTH = 32MB)
			TO FILEGROUP rptBetting_11M08'
		)
	END

	IF NOT EXISTS(
		SELECT 1
		FROM sys.filegroups 
		WHERE name ='rptBetting_11M09'
		)
	BEGIN
		ALTER DATABASE bodb_Licensee
		ADD FILEGROUP rptBetting_11M09
		
		EXEC('ALTER DATABASE bodb_Licensee
			ADD FILE
			(NAME =''rptBetting_11M09_DATA''
			,FILENAME='''+@rptPath+'rptBetting_11M09_DATA.ndf'' ,SIZE = 2MB, FILEGROWTH = 32MB)
			TO FILEGROUP rptBetting_11M09'
		)
	END

	IF NOT EXISTS(
		SELECT 1
		FROM sys.filegroups 
		WHERE name ='rptBetting_11M10'
		)
	BEGIN
		ALTER DATABASE bodb_Licensee
		ADD FILEGROUP rptBetting_11M10
		
		EXEC('ALTER DATABASE bodb_Licensee
			ADD FILE
			(NAME =''rptBetting_11M10_DATA''
			,FILENAME='''+@rptPath+'rptBetting_11M10_DATA.ndf'' ,SIZE = 2MB, FILEGROWTH = 32MB)
			TO FILEGROUP rptBetting_11M10'
		)
	END

	IF NOT EXISTS(
		SELECT 1
		FROM sys.filegroups 
		WHERE name ='rptBetting_11M11'
		)
	BEGIN
		ALTER DATABASE bodb_Licensee
		ADD FILEGROUP rptBetting_11M11
		
		EXEC('ALTER DATABASE bodb_Licensee
			ADD FILE
			(NAME =''rptBetting_11M11_DATA''
			,FILENAME='''+@rptPath+'rptBetting_11M11_DATA.ndf'' ,SIZE = 2MB, FILEGROWTH = 32MB)
			TO FILEGROUP rptBetting_11M11'
		)
	END

	IF NOT EXISTS(
		SELECT 1
		FROM sys.filegroups 
		WHERE name ='rptBetting_11M12'
		)
	BEGIN
		ALTER DATABASE bodb_Licensee
		ADD FILEGROUP rptBetting_11M12
		
		EXEC('ALTER DATABASE bodb_Licensee
			ADD FILE
			(NAME =''rptBetting_11M12_DATA''
			,FILENAME='''+@rptPath+'rptBetting_11M12_DATA.ndf'' ,SIZE = 2MB, FILEGROWTH = 32MB)
			TO FILEGROUP rptBetting_11M12'
		)
	END

	------------------2012----------------------------
	IF NOT EXISTS(
		SELECT 1
		FROM sys.filegroups 
		WHERE name ='rptBetting_12M01'
		)
	BEGIN
		ALTER DATABASE bodb_Licensee
		ADD FILEGROUP rptBetting_12M01
		
		EXEC('ALTER DATABASE bodb_Licensee
			ADD FILE
			(NAME =''rptBetting_12M01_DATA''
			,FILENAME='''+@rptPath+'rptBetting_12M01_DATA.ndf'' ,SIZE = 2MB, FILEGROWTH = 32MB)
			TO FILEGROUP rptBetting_12M01'
		)
	END

	IF NOT EXISTS(
		SELECT 1
		FROM sys.filegroups 
		WHERE name ='rptBetting_12M02'
		)
	BEGIN
		ALTER DATABASE bodb_Licensee
		ADD FILEGROUP rptBetting_12M02
		
		EXEC('ALTER DATABASE bodb_Licensee
			ADD FILE
			(NAME =''rptBetting_12M02_DATA''
			,FILENAME='''+@rptPath+'rptBetting_12M02_DATA.ndf'' ,SIZE = 2MB, FILEGROWTH = 32MB)
			TO FILEGROUP rptBetting_12M02'
		)
	END

	IF NOT EXISTS(
		SELECT 1
		FROM sys.filegroups 
		WHERE name ='rptBetting_12M03'
		)
	BEGIN
		ALTER DATABASE bodb_Licensee
		ADD FILEGROUP rptBetting_12M03
		
		EXEC('ALTER DATABASE bodb_Licensee
			ADD FILE
			(NAME =''rptBetting_12M03_DATA''
			,FILENAME='''+@rptPath+'rptBetting_12M03_DATA.ndf'' ,SIZE = 2MB, FILEGROWTH = 32MB)
			TO FILEGROUP rptBetting_12M03'
		)
	END

	IF NOT EXISTS(
		SELECT 1
		FROM sys.filegroups 
		WHERE name ='rptBetting_12M04'
		)
	BEGIN
		ALTER DATABASE bodb_Licensee
		ADD FILEGROUP rptBetting_12M04
		
		EXEC('ALTER DATABASE bodb_Licensee
			ADD FILE
			(NAME =''rptBetting_12M04_DATA''
			,FILENAME='''+@rptPath+'rptBetting_12M04_DATA.ndf'' ,SIZE = 2MB, FILEGROWTH = 32MB)
			TO FILEGROUP rptBetting_12M04'
		)
	END

	IF NOT EXISTS(
		SELECT 1
		FROM sys.filegroups 
		WHERE name ='rptBetting_12M05'
		)
	BEGIN
		ALTER DATABASE bodb_Licensee
		ADD FILEGROUP rptBetting_12M05
		
		EXEC('ALTER DATABASE bodb_Licensee
			ADD FILE
			(NAME =''rptBetting_12M05_DATA''
			,FILENAME='''+@rptPath+'rptBetting_12M05_DATA.ndf'' ,SIZE = 2MB, FILEGROWTH = 32MB)
			TO FILEGROUP rptBetting_12M05'
		)
	END

	IF NOT EXISTS(
		SELECT 1
		FROM sys.filegroups 
		WHERE name ='rptBetting_12M06'
		)
	BEGIN
		ALTER DATABASE bodb_Licensee
		ADD FILEGROUP rptBetting_12M06
		
		EXEC('ALTER DATABASE bodb_Licensee
			ADD FILE
			(NAME =''rptBetting_12M06_DATA''
			,FILENAME='''+@rptPath+'rptBetting_12M06_DATA.ndf'' ,SIZE = 2MB, FILEGROWTH = 32MB)
			TO FILEGROUP rptBetting_12M06'
		)
	END

	IF NOT EXISTS(
		SELECT 1
		FROM sys.filegroups 
		WHERE name ='rptBetting_12M07'
		)
	BEGIN
		ALTER DATABASE bodb_Licensee
		ADD FILEGROUP rptBetting_12M07
		
		EXEC('ALTER DATABASE bodb_Licensee
			ADD FILE
			(NAME =''rptBetting_12M07_DATA''
			,FILENAME='''+@rptPath+'rptBetting_12M07_DATA.ndf'' ,SIZE = 2MB, FILEGROWTH = 32MB)
			TO FILEGROUP rptBetting_12M07'
		)
	END

	IF NOT EXISTS(
		SELECT 1
		FROM sys.filegroups 
		WHERE name ='rptBetting_12M08'
		)
	BEGIN
		ALTER DATABASE bodb_Licensee
		ADD FILEGROUP rptBetting_12M08
		
		EXEC('ALTER DATABASE bodb_Licensee
			ADD FILE
			(NAME =''rptBetting_12M08_DATA''
			,FILENAME='''+@rptPath+'rptBetting_12M08_DATA.ndf'' ,SIZE = 2MB, FILEGROWTH = 32MB)
			TO FILEGROUP rptBetting_12M08'
		)
	END

	IF NOT EXISTS(
		SELECT 1
		FROM sys.filegroups 
		WHERE name ='rptBetting_12M09'
		)
	BEGIN
		ALTER DATABASE bodb_Licensee
		ADD FILEGROUP rptBetting_12M09
		
		EXEC('ALTER DATABASE bodb_Licensee
			ADD FILE
			(NAME =''rptBetting_12M09_DATA''
			,FILENAME='''+@rptPath+'rptBetting_12M09_DATA.ndf'' ,SIZE = 2MB, FILEGROWTH = 32MB)
			TO FILEGROUP rptBetting_12M09'
		)
	END

	IF NOT EXISTS(
		SELECT 1
		FROM sys.filegroups 
		WHERE name ='rptBetting_12M10'
		)
	BEGIN
		ALTER DATABASE bodb_Licensee
		ADD FILEGROUP rptBetting_12M10
		
		EXEC('ALTER DATABASE bodb_Licensee
			ADD FILE
			(NAME =''rptBetting_12M10_DATA''
			,FILENAME='''+@rptPath+'rptBetting_12M10_DATA.ndf'' ,SIZE = 2MB, FILEGROWTH = 32MB)
			TO FILEGROUP rptBetting_12M10'
		)
	END

	IF NOT EXISTS(
		SELECT 1
		FROM sys.filegroups 
		WHERE name ='rptBetting_12M11'
		)
	BEGIN
		ALTER DATABASE bodb_Licensee
		ADD FILEGROUP rptBetting_12M11
		
		EXEC('ALTER DATABASE bodb_Licensee
			ADD FILE
			(NAME =''rptBetting_12M11_DATA''
			,FILENAME='''+@rptPath+'rptBetting_12M11_DATA.ndf'' ,SIZE = 2MB, FILEGROWTH = 32MB)
			TO FILEGROUP rptBetting_12M11'
		)
	END

	IF NOT EXISTS(
		SELECT 1
		FROM sys.filegroups 
		WHERE name ='rptBetting_12M12'
		)
	BEGIN
		ALTER DATABASE bodb_Licensee
		ADD FILEGROUP rptBetting_12M12
		
		EXEC('ALTER DATABASE bodb_Licensee
			ADD FILE
			(NAME =''rptBetting_12M12_DATA''
			,FILENAME='''+@rptPath+'rptBetting_12M12_DATA.ndf'' ,SIZE = 2MB, FILEGROWTH = 32MB)
			TO FILEGROUP rptBetting_12M12'
		)
	END

	------------------2013----------------------------
	IF NOT EXISTS(
		SELECT 1
		FROM sys.filegroups 
		WHERE name ='rptBetting_13M01'
		)
	BEGIN
		ALTER DATABASE bodb_Licensee
		ADD FILEGROUP rptBetting_13M01
		
		EXEC('ALTER DATABASE bodb_Licensee
			ADD FILE
			(NAME =''rptBetting_13M01_DATA''
			,FILENAME='''+@rptPath+'rptBetting_13M01_DATA.ndf'' ,SIZE = 2MB, FILEGROWTH = 32MB)
			TO FILEGROUP rptBetting_13M01'
		)
	END

	IF NOT EXISTS(
		SELECT 1
		FROM sys.filegroups 
		WHERE name ='rptBetting_13M02'
		)
	BEGIN
		ALTER DATABASE bodb_Licensee
		ADD FILEGROUP rptBetting_13M02
		
		EXEC('ALTER DATABASE bodb_Licensee
			ADD FILE
			(NAME =''rptBetting_13M02_DATA''
			,FILENAME='''+@rptPath+'rptBetting_13M02_DATA.ndf'' ,SIZE = 2MB, FILEGROWTH = 32MB)
			TO FILEGROUP rptBetting_13M02'
		)
	END

	IF NOT EXISTS(
		SELECT 1
		FROM sys.filegroups 
		WHERE name ='rptBetting_13M03'
		)
	BEGIN
		ALTER DATABASE bodb_Licensee
		ADD FILEGROUP rptBetting_13M03
		
		EXEC('ALTER DATABASE bodb_Licensee
			ADD FILE
			(NAME =''rptBetting_13M03_DATA''
			,FILENAME='''+@rptPath+'rptBetting_13M03_DATA.ndf'' ,SIZE = 2MB, FILEGROWTH = 32MB)
			TO FILEGROUP rptBetting_13M03'
		)
	END

	IF NOT EXISTS(
		SELECT 1
		FROM sys.filegroups 
		WHERE name ='rptBetting_13M04'
		)
	BEGIN
		ALTER DATABASE bodb_Licensee
		ADD FILEGROUP rptBetting_13M04
		
		EXEC('ALTER DATABASE bodb_Licensee
			ADD FILE
			(NAME =''rptBetting_13M04_DATA''
			,FILENAME='''+@rptPath+'rptBetting_13M04_DATA.ndf'' ,SIZE = 2MB, FILEGROWTH = 32MB)
			TO FILEGROUP rptBetting_13M04'
		)
	END

	IF NOT EXISTS(
		SELECT 1
		FROM sys.filegroups 
		WHERE name ='rptBetting_13M05'
		)
	BEGIN
		ALTER DATABASE bodb_Licensee
		ADD FILEGROUP rptBetting_13M05
		
		EXEC('ALTER DATABASE bodb_Licensee
			ADD FILE
			(NAME =''rptBetting_13M05_DATA''
			,FILENAME='''+@rptPath+'rptBetting_13M05_DATA.ndf'' ,SIZE = 2MB, FILEGROWTH = 32MB)
			TO FILEGROUP rptBetting_13M05'
		)
	END

	IF NOT EXISTS(
		SELECT 1
		FROM sys.filegroups 
		WHERE name ='rptBetting_13M06'
		)
	BEGIN
		ALTER DATABASE bodb_Licensee
		ADD FILEGROUP rptBetting_13M06
		
		EXEC('ALTER DATABASE bodb_Licensee
			ADD FILE
			(NAME =''rptBetting_13M06_DATA''
			,FILENAME='''+@rptPath+'rptBetting_13M06_DATA.ndf'' ,SIZE = 2MB, FILEGROWTH = 32MB)
			TO FILEGROUP rptBetting_13M06'
		)
	END

	IF NOT EXISTS(
		SELECT 1
		FROM sys.filegroups 
		WHERE name ='rptBetting_13M07'
		)
	BEGIN
		ALTER DATABASE bodb_Licensee
		ADD FILEGROUP rptBetting_13M07
		
		EXEC('ALTER DATABASE bodb_Licensee
			ADD FILE
			(NAME =''rptBetting_13M07_DATA''
			,FILENAME='''+@rptPath+'rptBetting_13M07_DATA.ndf'' ,SIZE = 2MB, FILEGROWTH = 32MB)
			TO FILEGROUP rptBetting_13M07'
		)
	END

	IF NOT EXISTS(
		SELECT 1
		FROM sys.filegroups 
		WHERE name ='rptBetting_13M08'
		)
	BEGIN
		ALTER DATABASE bodb_Licensee
		ADD FILEGROUP rptBetting_13M08
		
		EXEC('ALTER DATABASE bodb_Licensee
			ADD FILE
			(NAME =''rptBetting_13M08_DATA''
			,FILENAME='''+@rptPath+'rptBetting_13M08_DATA.ndf'' ,SIZE = 2MB, FILEGROWTH = 32MB)
			TO FILEGROUP rptBetting_13M08'
		)
	END

	IF NOT EXISTS(
		SELECT 1
		FROM sys.filegroups 
		WHERE name ='rptBetting_13M09'
		)
	BEGIN
		ALTER DATABASE bodb_Licensee
		ADD FILEGROUP rptBetting_13M09
		
		EXEC('ALTER DATABASE bodb_Licensee
			ADD FILE
			(NAME =''rptBetting_13M09_DATA''
			,FILENAME='''+@rptPath+'rptBetting_13M09_DATA.ndf'' ,SIZE = 2MB, FILEGROWTH = 32MB)
			TO FILEGROUP rptBetting_13M09'
		)
	END

	IF NOT EXISTS(
		SELECT 1
		FROM sys.filegroups 
		WHERE name ='rptBetting_13M10'
		)
	BEGIN
		ALTER DATABASE bodb_Licensee
		ADD FILEGROUP rptBetting_13M10
		
		EXEC('ALTER DATABASE bodb_Licensee
			ADD FILE
			(NAME =''rptBetting_13M10_DATA''
			,FILENAME='''+@rptPath+'rptBetting_13M10_DATA.ndf'' ,SIZE = 2MB, FILEGROWTH = 32MB)
			TO FILEGROUP rptBetting_13M10'
		)
	END

	IF NOT EXISTS(
		SELECT 1
		FROM sys.filegroups 
		WHERE name ='rptBetting_13M11'
		)
	BEGIN
		ALTER DATABASE bodb_Licensee
		ADD FILEGROUP rptBetting_13M11
		
		EXEC('ALTER DATABASE bodb_Licensee
			ADD FILE
			(NAME =''rptBetting_13M11_DATA''
			,FILENAME='''+@rptPath+'rptBetting_13M11_DATA.ndf'' ,SIZE = 2MB, FILEGROWTH = 32MB)
			TO FILEGROUP rptBetting_13M11'
		)
	END

	IF NOT EXISTS(
		SELECT 1
		FROM sys.filegroups 
		WHERE name ='rptBetting_13M12'
		)
	BEGIN
		ALTER DATABASE bodb_Licensee
		ADD FILEGROUP rptBetting_13M12
		
		EXEC('ALTER DATABASE bodb_Licensee
			ADD FILE
			(NAME =''rptBetting_13M12_DATA''
			,FILENAME='''+@rptPath+'rptBetting_13M12_DATA.ndf'' ,SIZE = 2MB, FILEGROWTH = 32MB)
			TO FILEGROUP rptBetting_13M12'
		)
	END

----------add partition for rptBetting
CREATE PARTITION FUNCTION pf_rptBetting_monthly (datetime)
AS RANGE RIGHT FOR VALUES(
N'2009-01-01',N'2009-02-01',N'2009-03-01',N'2009-04-01',N'2009-05-01',N'2009-06-01',N'2009-07-01',N'2009-08-01',N'2009-09-01',N'2009-10-01',N'2009-11-01',N'2009-12-01'
,N'2010-01-01',N'2010-02-01',N'2010-03-01',N'2010-04-01',N'2010-05-01',N'2010-06-01',N'2010-07-01',N'2010-08-01',N'2010-09-01',N'2010-10-01',N'2010-11-01',N'2010-12-01'
,N'2011-01-01',N'2011-02-01',N'2011-03-01',N'2011-04-01',N'2011-05-01',N'2011-06-01',N'2011-07-01',N'2011-08-01',N'2011-09-01',N'2011-10-01',N'2011-11-01',N'2011-12-01'
,N'2012-01-01',N'2012-02-01',N'2012-03-01',N'2012-04-01',N'2012-05-01',N'2012-06-01',N'2012-07-01',N'2012-08-01',N'2012-09-01',N'2012-10-01',N'2012-11-01',N'2012-12-01'
,N'2013-01-01',N'2013-02-01',N'2013-03-01',N'2013-04-01',N'2013-05-01',N'2013-06-01',N'2013-07-01',N'2013-08-01',N'2013-09-01',N'2013-10-01',N'2013-11-01',N'2013-12-01'
)

CREATE PARTITION SCHEME ps_rptBetting_monthly 
AS PARTITION pf_rptBetting_monthly TO 
(rptBetting_Before09M01
,rptBetting_09M01,rptBetting_09M02,rptBetting_09M03,rptBetting_09M04,rptBetting_09M05,rptBetting_09M06,rptBetting_09M07,rptBetting_09M08,rptBetting_09M09,rptBetting_09M10,rptBetting_09M11,rptBetting_09M12
,rptBetting_10M01,rptBetting_10M02,rptBetting_10M03,rptBetting_10M04,rptBetting_10M05,rptBetting_10M06,rptBetting_10M07,rptBetting_10M08,rptBetting_10M09,rptBetting_10M10,rptBetting_10M11,rptBetting_10M12
,rptBetting_11M01,rptBetting_11M02,rptBetting_11M03,rptBetting_11M04,rptBetting_11M05,rptBetting_11M06,rptBetting_11M07,rptBetting_11M08,rptBetting_11M09,rptBetting_11M10,rptBetting_11M11,rptBetting_11M12
,rptBetting_12M01,rptBetting_12M02,rptBetting_12M03,rptBetting_12M04,rptBetting_12M05,rptBetting_12M06,rptBetting_12M07,rptBetting_12M08,rptBetting_12M09,rptBetting_12M10,rptBetting_12M11,rptBetting_12M12
,rptBetting_13M01,rptBetting_13M02,rptBetting_13M03,rptBetting_13M04,rptBetting_13M05,rptBetting_13M06,rptBetting_13M07,rptBetting_13M08,rptBetting_13M09,rptBetting_13M10,rptBetting_13M11,rptBetting_13M12
,rptBetting_MAX
)