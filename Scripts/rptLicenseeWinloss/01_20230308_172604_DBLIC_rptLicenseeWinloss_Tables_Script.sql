
/*<info serverAlias="DBLIC-bodb_LicenseeReport"></info>*/
/*
	Created: 20230209@Bobby
	Task: 172604 - LAP - Winloss Analysis - Setup DB structure
	DB: DBLIC.bodb_LicenseeReport
	Remark: 
		- Run on pair DB052-DB053
		- Create the sub folder rptLicenseeWinloss under the database folder F:\USER_DB\bodb_LicenseeReport\
*/
USE master;
GO
-- TODO: GEN T-SQL commands for 4 years partition files by Month
/**
;WITH cte_WLD (Winlostdate) AS
(
	SELECT CAST('2020-01-01 23:59:00' AS datetime)
	UNION ALL
	SELECT DATEADD(MONTH, 1, Winlostdate)
	FROM cte_WLD
	WHERE Winlostdate < '2023-12-01'
)
SELECT PF_Winlostdate
	,CONCAT('N''',FORMAT(PF_Winlostdate, 'yyyy-MM-ddTHH:mm:ss'), ''',') AS PF_Name
	,CONCAT('[', f.RptYearMonth, '],') AS PS_Name
	,CONCAT('ALTER DATABASE ', DB_NAME(), ' ADD FILEGROUP [', f.RptYearMonth, '];') AS ADD_FileGroupName
	--, df.DataFile
FROM cte_WLD
cross apply ( select DATEADD(DAY, -1, DATEADD(MONTH, 1, Winlostdate)) ) AS rpt (PF_Winlostdate)
cross apply (
	SELECT CONCAT('rptLicenseeWinloss_',FORMAT(PF_Winlostdate, 'yyyy'),'M',FORMAT(PF_Winlostdate, 'MM'), '')
) as f (RptYearMonth)
--cross apply (
--	VALUES ('ALTER DATABASE ' + DB_NAME() + ' ADD FILE')
--		, ('(NAME = N'''+f.RptYearMonth+'_Data'', FILENAME = N''F:\USER_DB\bodb_LicenseeReport\rptLicenseeWinloss\'+f.RptYearMonth+'_Data.ndf'' , SIZE = 8192KB , MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB )')
--		, ('TO FILEGROUP [' + f.RptYearMonth + '];')
--) AS df (DataFile)
OPTION (MAXRECURSION 1000);
**/
GO

-- TODO: Create filegroups
ALTER DATABASE bodb_LicenseeReport ADD FILEGROUP [rptLicenseeWinloss_2020M01];
ALTER DATABASE bodb_LicenseeReport ADD FILEGROUP [rptLicenseeWinloss_2020M02];
ALTER DATABASE bodb_LicenseeReport ADD FILEGROUP [rptLicenseeWinloss_2020M03];
ALTER DATABASE bodb_LicenseeReport ADD FILEGROUP [rptLicenseeWinloss_2020M04];
ALTER DATABASE bodb_LicenseeReport ADD FILEGROUP [rptLicenseeWinloss_2020M05];
ALTER DATABASE bodb_LicenseeReport ADD FILEGROUP [rptLicenseeWinloss_2020M06];
ALTER DATABASE bodb_LicenseeReport ADD FILEGROUP [rptLicenseeWinloss_2020M07];
ALTER DATABASE bodb_LicenseeReport ADD FILEGROUP [rptLicenseeWinloss_2020M08];
ALTER DATABASE bodb_LicenseeReport ADD FILEGROUP [rptLicenseeWinloss_2020M09];
ALTER DATABASE bodb_LicenseeReport ADD FILEGROUP [rptLicenseeWinloss_2020M10];
ALTER DATABASE bodb_LicenseeReport ADD FILEGROUP [rptLicenseeWinloss_2020M11];
ALTER DATABASE bodb_LicenseeReport ADD FILEGROUP [rptLicenseeWinloss_2020M12];
ALTER DATABASE bodb_LicenseeReport ADD FILEGROUP [rptLicenseeWinloss_2021M01];
ALTER DATABASE bodb_LicenseeReport ADD FILEGROUP [rptLicenseeWinloss_2021M02];
ALTER DATABASE bodb_LicenseeReport ADD FILEGROUP [rptLicenseeWinloss_2021M03];
ALTER DATABASE bodb_LicenseeReport ADD FILEGROUP [rptLicenseeWinloss_2021M04];
ALTER DATABASE bodb_LicenseeReport ADD FILEGROUP [rptLicenseeWinloss_2021M05];
ALTER DATABASE bodb_LicenseeReport ADD FILEGROUP [rptLicenseeWinloss_2021M06];
ALTER DATABASE bodb_LicenseeReport ADD FILEGROUP [rptLicenseeWinloss_2021M07];
ALTER DATABASE bodb_LicenseeReport ADD FILEGROUP [rptLicenseeWinloss_2021M08];
ALTER DATABASE bodb_LicenseeReport ADD FILEGROUP [rptLicenseeWinloss_2021M09];
ALTER DATABASE bodb_LicenseeReport ADD FILEGROUP [rptLicenseeWinloss_2021M10];
ALTER DATABASE bodb_LicenseeReport ADD FILEGROUP [rptLicenseeWinloss_2021M11];
ALTER DATABASE bodb_LicenseeReport ADD FILEGROUP [rptLicenseeWinloss_2021M12];
ALTER DATABASE bodb_LicenseeReport ADD FILEGROUP [rptLicenseeWinloss_2022M01];
ALTER DATABASE bodb_LicenseeReport ADD FILEGROUP [rptLicenseeWinloss_2022M02];
ALTER DATABASE bodb_LicenseeReport ADD FILEGROUP [rptLicenseeWinloss_2022M03];
ALTER DATABASE bodb_LicenseeReport ADD FILEGROUP [rptLicenseeWinloss_2022M04];
ALTER DATABASE bodb_LicenseeReport ADD FILEGROUP [rptLicenseeWinloss_2022M05];
ALTER DATABASE bodb_LicenseeReport ADD FILEGROUP [rptLicenseeWinloss_2022M06];
ALTER DATABASE bodb_LicenseeReport ADD FILEGROUP [rptLicenseeWinloss_2022M07];
ALTER DATABASE bodb_LicenseeReport ADD FILEGROUP [rptLicenseeWinloss_2022M08];
ALTER DATABASE bodb_LicenseeReport ADD FILEGROUP [rptLicenseeWinloss_2022M09];
ALTER DATABASE bodb_LicenseeReport ADD FILEGROUP [rptLicenseeWinloss_2022M10];
ALTER DATABASE bodb_LicenseeReport ADD FILEGROUP [rptLicenseeWinloss_2022M11];
ALTER DATABASE bodb_LicenseeReport ADD FILEGROUP [rptLicenseeWinloss_2022M12];
ALTER DATABASE bodb_LicenseeReport ADD FILEGROUP [rptLicenseeWinloss_2023M01];
ALTER DATABASE bodb_LicenseeReport ADD FILEGROUP [rptLicenseeWinloss_2023M02];
ALTER DATABASE bodb_LicenseeReport ADD FILEGROUP [rptLicenseeWinloss_2023M03];
ALTER DATABASE bodb_LicenseeReport ADD FILEGROUP [rptLicenseeWinloss_2023M04];
ALTER DATABASE bodb_LicenseeReport ADD FILEGROUP [rptLicenseeWinloss_2023M05];
ALTER DATABASE bodb_LicenseeReport ADD FILEGROUP [rptLicenseeWinloss_2023M06];
ALTER DATABASE bodb_LicenseeReport ADD FILEGROUP [rptLicenseeWinloss_2023M07];
ALTER DATABASE bodb_LicenseeReport ADD FILEGROUP [rptLicenseeWinloss_2023M08];
ALTER DATABASE bodb_LicenseeReport ADD FILEGROUP [rptLicenseeWinloss_2023M09];
ALTER DATABASE bodb_LicenseeReport ADD FILEGROUP [rptLicenseeWinloss_2023M10];
ALTER DATABASE bodb_LicenseeReport ADD FILEGROUP [rptLicenseeWinloss_2023M11];
ALTER DATABASE bodb_LicenseeReport ADD FILEGROUP [rptLicenseeWinloss_2023M12];
ALTER DATABASE bodb_LicenseeReport ADD FILEGROUP [rptLicenseeWinloss_2024M01];
ALTER DATABASE bodb_LicenseeReport ADD FILEGROUP [rptLicenseeWinloss_MAX];
GO

-- TODO: Create data files
USE [master]
GO
ALTER DATABASE bodb_LicenseeReport ADD FILE
(NAME = N'rptLicenseeWinloss_2020M01_Data', FILENAME = N'F:\USER_DB\bodb_LicenseeReport\rptLicenseeWinloss\rptLicenseeWinloss_2020M01_Data.ndf' , SIZE = 8192KB , MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB )
TO FILEGROUP [rptLicenseeWinloss_2020M01];
ALTER DATABASE bodb_LicenseeReport ADD FILE
(NAME = N'rptLicenseeWinloss_2020M02_Data', FILENAME = N'F:\USER_DB\bodb_LicenseeReport\rptLicenseeWinloss\rptLicenseeWinloss_2020M02_Data.ndf' , SIZE = 8192KB , MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB )
TO FILEGROUP [rptLicenseeWinloss_2020M02];
ALTER DATABASE bodb_LicenseeReport ADD FILE
(NAME = N'rptLicenseeWinloss_2020M03_Data', FILENAME = N'F:\USER_DB\bodb_LicenseeReport\rptLicenseeWinloss\rptLicenseeWinloss_2020M03_Data.ndf' , SIZE = 8192KB , MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB )
TO FILEGROUP [rptLicenseeWinloss_2020M03];
ALTER DATABASE bodb_LicenseeReport ADD FILE
(NAME = N'rptLicenseeWinloss_2020M04_Data', FILENAME = N'F:\USER_DB\bodb_LicenseeReport\rptLicenseeWinloss\rptLicenseeWinloss_2020M04_Data.ndf' , SIZE = 8192KB , MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB )
TO FILEGROUP [rptLicenseeWinloss_2020M04];
ALTER DATABASE bodb_LicenseeReport ADD FILE
(NAME = N'rptLicenseeWinloss_2020M05_Data', FILENAME = N'F:\USER_DB\bodb_LicenseeReport\rptLicenseeWinloss\rptLicenseeWinloss_2020M05_Data.ndf' , SIZE = 8192KB , MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB )
TO FILEGROUP [rptLicenseeWinloss_2020M05];
ALTER DATABASE bodb_LicenseeReport ADD FILE
(NAME = N'rptLicenseeWinloss_2020M06_Data', FILENAME = N'F:\USER_DB\bodb_LicenseeReport\rptLicenseeWinloss\rptLicenseeWinloss_2020M06_Data.ndf' , SIZE = 8192KB , MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB )
TO FILEGROUP [rptLicenseeWinloss_2020M06];
ALTER DATABASE bodb_LicenseeReport ADD FILE
(NAME = N'rptLicenseeWinloss_2020M07_Data', FILENAME = N'F:\USER_DB\bodb_LicenseeReport\rptLicenseeWinloss\rptLicenseeWinloss_2020M07_Data.ndf' , SIZE = 8192KB , MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB )
TO FILEGROUP [rptLicenseeWinloss_2020M07];
ALTER DATABASE bodb_LicenseeReport ADD FILE
(NAME = N'rptLicenseeWinloss_2020M08_Data', FILENAME = N'F:\USER_DB\bodb_LicenseeReport\rptLicenseeWinloss\rptLicenseeWinloss_2020M08_Data.ndf' , SIZE = 8192KB , MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB )
TO FILEGROUP [rptLicenseeWinloss_2020M08];
ALTER DATABASE bodb_LicenseeReport ADD FILE
(NAME = N'rptLicenseeWinloss_2020M09_Data', FILENAME = N'F:\USER_DB\bodb_LicenseeReport\rptLicenseeWinloss\rptLicenseeWinloss_2020M09_Data.ndf' , SIZE = 8192KB , MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB )
TO FILEGROUP [rptLicenseeWinloss_2020M09];
ALTER DATABASE bodb_LicenseeReport ADD FILE
(NAME = N'rptLicenseeWinloss_2020M10_Data', FILENAME = N'F:\USER_DB\bodb_LicenseeReport\rptLicenseeWinloss\rptLicenseeWinloss_2020M10_Data.ndf' , SIZE = 8192KB , MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB )
TO FILEGROUP [rptLicenseeWinloss_2020M10];
ALTER DATABASE bodb_LicenseeReport ADD FILE
(NAME = N'rptLicenseeWinloss_2020M11_Data', FILENAME = N'F:\USER_DB\bodb_LicenseeReport\rptLicenseeWinloss\rptLicenseeWinloss_2020M11_Data.ndf' , SIZE = 8192KB , MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB )
TO FILEGROUP [rptLicenseeWinloss_2020M11];
ALTER DATABASE bodb_LicenseeReport ADD FILE
(NAME = N'rptLicenseeWinloss_2020M12_Data', FILENAME = N'F:\USER_DB\bodb_LicenseeReport\rptLicenseeWinloss\rptLicenseeWinloss_2020M12_Data.ndf' , SIZE = 8192KB , MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB )
TO FILEGROUP [rptLicenseeWinloss_2020M12];
ALTER DATABASE bodb_LicenseeReport ADD FILE
(NAME = N'rptLicenseeWinloss_2021M01_Data', FILENAME = N'F:\USER_DB\bodb_LicenseeReport\rptLicenseeWinloss\rptLicenseeWinloss_2021M01_Data.ndf' , SIZE = 8192KB , MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB )
TO FILEGROUP [rptLicenseeWinloss_2021M01];
ALTER DATABASE bodb_LicenseeReport ADD FILE
(NAME = N'rptLicenseeWinloss_2021M02_Data', FILENAME = N'F:\USER_DB\bodb_LicenseeReport\rptLicenseeWinloss\rptLicenseeWinloss_2021M02_Data.ndf' , SIZE = 8192KB , MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB )
TO FILEGROUP [rptLicenseeWinloss_2021M02];
ALTER DATABASE bodb_LicenseeReport ADD FILE
(NAME = N'rptLicenseeWinloss_2021M03_Data', FILENAME = N'F:\USER_DB\bodb_LicenseeReport\rptLicenseeWinloss\rptLicenseeWinloss_2021M03_Data.ndf' , SIZE = 8192KB , MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB )
TO FILEGROUP [rptLicenseeWinloss_2021M03];
ALTER DATABASE bodb_LicenseeReport ADD FILE
(NAME = N'rptLicenseeWinloss_2021M04_Data', FILENAME = N'F:\USER_DB\bodb_LicenseeReport\rptLicenseeWinloss\rptLicenseeWinloss_2021M04_Data.ndf' , SIZE = 8192KB , MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB )
TO FILEGROUP [rptLicenseeWinloss_2021M04];
ALTER DATABASE bodb_LicenseeReport ADD FILE
(NAME = N'rptLicenseeWinloss_2021M05_Data', FILENAME = N'F:\USER_DB\bodb_LicenseeReport\rptLicenseeWinloss\rptLicenseeWinloss_2021M05_Data.ndf' , SIZE = 8192KB , MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB )
TO FILEGROUP [rptLicenseeWinloss_2021M05];
ALTER DATABASE bodb_LicenseeReport ADD FILE
(NAME = N'rptLicenseeWinloss_2021M06_Data', FILENAME = N'F:\USER_DB\bodb_LicenseeReport\rptLicenseeWinloss\rptLicenseeWinloss_2021M06_Data.ndf' , SIZE = 8192KB , MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB )
TO FILEGROUP [rptLicenseeWinloss_2021M06];
ALTER DATABASE bodb_LicenseeReport ADD FILE
(NAME = N'rptLicenseeWinloss_2021M07_Data', FILENAME = N'F:\USER_DB\bodb_LicenseeReport\rptLicenseeWinloss\rptLicenseeWinloss_2021M07_Data.ndf' , SIZE = 8192KB , MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB )
TO FILEGROUP [rptLicenseeWinloss_2021M07];
ALTER DATABASE bodb_LicenseeReport ADD FILE
(NAME = N'rptLicenseeWinloss_2021M08_Data', FILENAME = N'F:\USER_DB\bodb_LicenseeReport\rptLicenseeWinloss\rptLicenseeWinloss_2021M08_Data.ndf' , SIZE = 8192KB , MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB )
TO FILEGROUP [rptLicenseeWinloss_2021M08];
ALTER DATABASE bodb_LicenseeReport ADD FILE
(NAME = N'rptLicenseeWinloss_2021M09_Data', FILENAME = N'F:\USER_DB\bodb_LicenseeReport\rptLicenseeWinloss\rptLicenseeWinloss_2021M09_Data.ndf' , SIZE = 8192KB , MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB )
TO FILEGROUP [rptLicenseeWinloss_2021M09];
ALTER DATABASE bodb_LicenseeReport ADD FILE
(NAME = N'rptLicenseeWinloss_2021M10_Data', FILENAME = N'F:\USER_DB\bodb_LicenseeReport\rptLicenseeWinloss\rptLicenseeWinloss_2021M10_Data.ndf' , SIZE = 8192KB , MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB )
TO FILEGROUP [rptLicenseeWinloss_2021M10];
ALTER DATABASE bodb_LicenseeReport ADD FILE
(NAME = N'rptLicenseeWinloss_2021M11_Data', FILENAME = N'F:\USER_DB\bodb_LicenseeReport\rptLicenseeWinloss\rptLicenseeWinloss_2021M11_Data.ndf' , SIZE = 8192KB , MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB )
TO FILEGROUP [rptLicenseeWinloss_2021M11];
ALTER DATABASE bodb_LicenseeReport ADD FILE
(NAME = N'rptLicenseeWinloss_2021M12_Data', FILENAME = N'F:\USER_DB\bodb_LicenseeReport\rptLicenseeWinloss\rptLicenseeWinloss_2021M12_Data.ndf' , SIZE = 8192KB , MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB )
TO FILEGROUP [rptLicenseeWinloss_2021M12];
ALTER DATABASE bodb_LicenseeReport ADD FILE
(NAME = N'rptLicenseeWinloss_2022M01_Data', FILENAME = N'F:\USER_DB\bodb_LicenseeReport\rptLicenseeWinloss\rptLicenseeWinloss_2022M01_Data.ndf' , SIZE = 8192KB , MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB )
TO FILEGROUP [rptLicenseeWinloss_2022M01];
ALTER DATABASE bodb_LicenseeReport ADD FILE
(NAME = N'rptLicenseeWinloss_2022M02_Data', FILENAME = N'F:\USER_DB\bodb_LicenseeReport\rptLicenseeWinloss\rptLicenseeWinloss_2022M02_Data.ndf' , SIZE = 8192KB , MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB )
TO FILEGROUP [rptLicenseeWinloss_2022M02];
ALTER DATABASE bodb_LicenseeReport ADD FILE
(NAME = N'rptLicenseeWinloss_2022M03_Data', FILENAME = N'F:\USER_DB\bodb_LicenseeReport\rptLicenseeWinloss\rptLicenseeWinloss_2022M03_Data.ndf' , SIZE = 8192KB , MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB )
TO FILEGROUP [rptLicenseeWinloss_2022M03];
ALTER DATABASE bodb_LicenseeReport ADD FILE
(NAME = N'rptLicenseeWinloss_2022M04_Data', FILENAME = N'F:\USER_DB\bodb_LicenseeReport\rptLicenseeWinloss\rptLicenseeWinloss_2022M04_Data.ndf' , SIZE = 8192KB , MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB )
TO FILEGROUP [rptLicenseeWinloss_2022M04];
ALTER DATABASE bodb_LicenseeReport ADD FILE
(NAME = N'rptLicenseeWinloss_2022M05_Data', FILENAME = N'F:\USER_DB\bodb_LicenseeReport\rptLicenseeWinloss\rptLicenseeWinloss_2022M05_Data.ndf' , SIZE = 8192KB , MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB )
TO FILEGROUP [rptLicenseeWinloss_2022M05];
ALTER DATABASE bodb_LicenseeReport ADD FILE
(NAME = N'rptLicenseeWinloss_2022M06_Data', FILENAME = N'F:\USER_DB\bodb_LicenseeReport\rptLicenseeWinloss\rptLicenseeWinloss_2022M06_Data.ndf' , SIZE = 8192KB , MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB )
TO FILEGROUP [rptLicenseeWinloss_2022M06];
ALTER DATABASE bodb_LicenseeReport ADD FILE
(NAME = N'rptLicenseeWinloss_2022M07_Data', FILENAME = N'F:\USER_DB\bodb_LicenseeReport\rptLicenseeWinloss\rptLicenseeWinloss_2022M07_Data.ndf' , SIZE = 8192KB , MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB )
TO FILEGROUP [rptLicenseeWinloss_2022M07];
ALTER DATABASE bodb_LicenseeReport ADD FILE
(NAME = N'rptLicenseeWinloss_2022M08_Data', FILENAME = N'F:\USER_DB\bodb_LicenseeReport\rptLicenseeWinloss\rptLicenseeWinloss_2022M08_Data.ndf' , SIZE = 8192KB , MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB )
TO FILEGROUP [rptLicenseeWinloss_2022M08];
ALTER DATABASE bodb_LicenseeReport ADD FILE
(NAME = N'rptLicenseeWinloss_2022M09_Data', FILENAME = N'F:\USER_DB\bodb_LicenseeReport\rptLicenseeWinloss\rptLicenseeWinloss_2022M09_Data.ndf' , SIZE = 8192KB , MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB )
TO FILEGROUP [rptLicenseeWinloss_2022M09];
ALTER DATABASE bodb_LicenseeReport ADD FILE
(NAME = N'rptLicenseeWinloss_2022M10_Data', FILENAME = N'F:\USER_DB\bodb_LicenseeReport\rptLicenseeWinloss\rptLicenseeWinloss_2022M10_Data.ndf' , SIZE = 8192KB , MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB )
TO FILEGROUP [rptLicenseeWinloss_2022M10];
ALTER DATABASE bodb_LicenseeReport ADD FILE
(NAME = N'rptLicenseeWinloss_2022M11_Data', FILENAME = N'F:\USER_DB\bodb_LicenseeReport\rptLicenseeWinloss\rptLicenseeWinloss_2022M11_Data.ndf' , SIZE = 8192KB , MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB )
TO FILEGROUP [rptLicenseeWinloss_2022M11];
ALTER DATABASE bodb_LicenseeReport ADD FILE
(NAME = N'rptLicenseeWinloss_2022M12_Data', FILENAME = N'F:\USER_DB\bodb_LicenseeReport\rptLicenseeWinloss\rptLicenseeWinloss_2022M12_Data.ndf' , SIZE = 8192KB , MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB )
TO FILEGROUP [rptLicenseeWinloss_2022M12];
ALTER DATABASE bodb_LicenseeReport ADD FILE
(NAME = N'rptLicenseeWinloss_2023M01_Data', FILENAME = N'F:\USER_DB\bodb_LicenseeReport\rptLicenseeWinloss\rptLicenseeWinloss_2023M01_Data.ndf' , SIZE = 8192KB , MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB )
TO FILEGROUP [rptLicenseeWinloss_2023M01];
ALTER DATABASE bodb_LicenseeReport ADD FILE
(NAME = N'rptLicenseeWinloss_2023M02_Data', FILENAME = N'F:\USER_DB\bodb_LicenseeReport\rptLicenseeWinloss\rptLicenseeWinloss_2023M02_Data.ndf' , SIZE = 8192KB , MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB )
TO FILEGROUP [rptLicenseeWinloss_2023M02];
ALTER DATABASE bodb_LicenseeReport ADD FILE
(NAME = N'rptLicenseeWinloss_2023M03_Data', FILENAME = N'F:\USER_DB\bodb_LicenseeReport\rptLicenseeWinloss\rptLicenseeWinloss_2023M03_Data.ndf' , SIZE = 8192KB , MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB )
TO FILEGROUP [rptLicenseeWinloss_2023M03];
ALTER DATABASE bodb_LicenseeReport ADD FILE
(NAME = N'rptLicenseeWinloss_2023M04_Data', FILENAME = N'F:\USER_DB\bodb_LicenseeReport\rptLicenseeWinloss\rptLicenseeWinloss_2023M04_Data.ndf' , SIZE = 8192KB , MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB )
TO FILEGROUP [rptLicenseeWinloss_2023M04];
ALTER DATABASE bodb_LicenseeReport ADD FILE
(NAME = N'rptLicenseeWinloss_2023M05_Data', FILENAME = N'F:\USER_DB\bodb_LicenseeReport\rptLicenseeWinloss\rptLicenseeWinloss_2023M05_Data.ndf' , SIZE = 8192KB , MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB )
TO FILEGROUP [rptLicenseeWinloss_2023M05];
ALTER DATABASE bodb_LicenseeReport ADD FILE
(NAME = N'rptLicenseeWinloss_2023M06_Data', FILENAME = N'F:\USER_DB\bodb_LicenseeReport\rptLicenseeWinloss\rptLicenseeWinloss_2023M06_Data.ndf' , SIZE = 8192KB , MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB )
TO FILEGROUP [rptLicenseeWinloss_2023M06];
ALTER DATABASE bodb_LicenseeReport ADD FILE
(NAME = N'rptLicenseeWinloss_2023M07_Data', FILENAME = N'F:\USER_DB\bodb_LicenseeReport\rptLicenseeWinloss\rptLicenseeWinloss_2023M07_Data.ndf' , SIZE = 8192KB , MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB )
TO FILEGROUP [rptLicenseeWinloss_2023M07];
ALTER DATABASE bodb_LicenseeReport ADD FILE
(NAME = N'rptLicenseeWinloss_2023M08_Data', FILENAME = N'F:\USER_DB\bodb_LicenseeReport\rptLicenseeWinloss\rptLicenseeWinloss_2023M08_Data.ndf' , SIZE = 8192KB , MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB )
TO FILEGROUP [rptLicenseeWinloss_2023M08];
ALTER DATABASE bodb_LicenseeReport ADD FILE
(NAME = N'rptLicenseeWinloss_2023M09_Data', FILENAME = N'F:\USER_DB\bodb_LicenseeReport\rptLicenseeWinloss\rptLicenseeWinloss_2023M09_Data.ndf' , SIZE = 8192KB , MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB )
TO FILEGROUP [rptLicenseeWinloss_2023M09];
ALTER DATABASE bodb_LicenseeReport ADD FILE
(NAME = N'rptLicenseeWinloss_2023M10_Data', FILENAME = N'F:\USER_DB\bodb_LicenseeReport\rptLicenseeWinloss\rptLicenseeWinloss_2023M10_Data.ndf' , SIZE = 8192KB , MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB )
TO FILEGROUP [rptLicenseeWinloss_2023M10];
ALTER DATABASE bodb_LicenseeReport ADD FILE
(NAME = N'rptLicenseeWinloss_2023M11_Data', FILENAME = N'F:\USER_DB\bodb_LicenseeReport\rptLicenseeWinloss\rptLicenseeWinloss_2023M11_Data.ndf' , SIZE = 8192KB , MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB )
TO FILEGROUP [rptLicenseeWinloss_2023M11];
ALTER DATABASE bodb_LicenseeReport ADD FILE
(NAME = N'rptLicenseeWinloss_2023M12_Data', FILENAME = N'F:\USER_DB\bodb_LicenseeReport\rptLicenseeWinloss\rptLicenseeWinloss_2023M12_Data.ndf' , SIZE = 8192KB , MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB )
TO FILEGROUP [rptLicenseeWinloss_2023M12];
ALTER DATABASE bodb_LicenseeReport ADD FILE
(NAME = N'rptLicenseeWinloss_2024M01_Data', FILENAME = N'F:\USER_DB\bodb_LicenseeReport\rptLicenseeWinloss\rptLicenseeWinloss_2024M01_Data.ndf' , SIZE = 8192KB , MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB )
TO FILEGROUP [rptLicenseeWinloss_2024M01];
ALTER DATABASE bodb_LicenseeReport ADD FILE
(NAME = N'rptLicenseeWinloss_Max_Data', FILENAME = N'F:\USER_DB\bodb_LicenseeReport\rptLicenseeWinloss\rptLicenseeWinloss_Max_Data.ndf' , SIZE = 8192KB , MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB )
TO FILEGROUP [rptLicenseeWinloss_MAX];
GO

USE bodb_LicenseeReport;
GO

/**
DROP TABLE IF EXISTS [dbo].[rptLicenseeWinloss];
GO
DROP PARTITION SCHEME [PS_rptLicenseeWinloss_Monthly];
GO
DROP PARTITION FUNCTION [PF_rptLicenseeWinloss_Monthly];
GO
**/

/****** Object:  PartitionFunction [PF_rptLicenseeWinloss_Monthly]    Script Date: 3/17/2023 4:24:23 PM ******/
CREATE PARTITION FUNCTION [PF_rptLicenseeWinloss_Monthly](SMALLDATETIME) 
AS RANGE LEFT 
FOR VALUES (
	N'2020-01-31T23:59:00',
	N'2020-02-29T23:59:00',
	N'2020-03-31T23:59:00',
	N'2020-04-30T23:59:00',
	N'2020-05-31T23:59:00',
	N'2020-06-30T23:59:00',
	N'2020-07-31T23:59:00',
	N'2020-08-31T23:59:00',
	N'2020-09-30T23:59:00',
	N'2020-10-31T23:59:00',
	N'2020-11-30T23:59:00',
	N'2020-12-31T23:59:00',
	N'2021-01-31T23:59:00',
	N'2021-02-28T23:59:00',
	N'2021-03-31T23:59:00',
	N'2021-04-30T23:59:00',
	N'2021-05-31T23:59:00',
	N'2021-06-30T23:59:00',
	N'2021-07-31T23:59:00',
	N'2021-08-31T23:59:00',
	N'2021-09-30T23:59:00',
	N'2021-10-31T23:59:00',
	N'2021-11-30T23:59:00',
	N'2021-12-31T23:59:00',
	N'2022-01-31T23:59:00',
	N'2022-02-28T23:59:00',
	N'2022-03-31T23:59:00',
	N'2022-04-30T23:59:00',
	N'2022-05-31T23:59:00',
	N'2022-06-30T23:59:00',
	N'2022-07-31T23:59:00',
	N'2022-08-31T23:59:00',
	N'2022-09-30T23:59:00',
	N'2022-10-31T23:59:00',
	N'2022-11-30T23:59:00',
	N'2022-12-31T23:59:00',
	N'2023-01-31T23:59:00',
	N'2023-02-28T23:59:00',
	N'2023-03-31T23:59:00',
	N'2023-04-30T23:59:00',
	N'2023-05-31T23:59:00',
	N'2023-06-30T23:59:00',
	N'2023-07-31T23:59:00',
	N'2023-08-31T23:59:00',
	N'2023-09-30T23:59:00',
	N'2023-10-31T23:59:00',
	N'2023-11-30T23:59:00',
	N'2023-12-31T23:59:00'
);
GO

/****** Object:  PartitionScheme [PS_rptLicenseeWinloss_Monthly]    Script Date: 3/17/2023 4:24:34 PM ******/
CREATE PARTITION SCHEME [PS_rptLicenseeWinloss_Monthly] AS PARTITION [PF_rptLicenseeWinloss_Monthly] 
TO (
	[rptLicenseeWinloss_2020M01],
	[rptLicenseeWinloss_2020M02],
	[rptLicenseeWinloss_2020M03],
	[rptLicenseeWinloss_2020M04],
	[rptLicenseeWinloss_2020M05],
	[rptLicenseeWinloss_2020M06],
	[rptLicenseeWinloss_2020M07],
	[rptLicenseeWinloss_2020M08],
	[rptLicenseeWinloss_2020M09],
	[rptLicenseeWinloss_2020M10],
	[rptLicenseeWinloss_2020M11],
	[rptLicenseeWinloss_2020M12],
	[rptLicenseeWinloss_2021M01],
	[rptLicenseeWinloss_2021M02],
	[rptLicenseeWinloss_2021M03],
	[rptLicenseeWinloss_2021M04],
	[rptLicenseeWinloss_2021M05],
	[rptLicenseeWinloss_2021M06],
	[rptLicenseeWinloss_2021M07],
	[rptLicenseeWinloss_2021M08],
	[rptLicenseeWinloss_2021M09],
	[rptLicenseeWinloss_2021M10],
	[rptLicenseeWinloss_2021M11],
	[rptLicenseeWinloss_2021M12],
	[rptLicenseeWinloss_2022M01],
	[rptLicenseeWinloss_2022M02],
	[rptLicenseeWinloss_2022M03],
	[rptLicenseeWinloss_2022M04],
	[rptLicenseeWinloss_2022M05],
	[rptLicenseeWinloss_2022M06],
	[rptLicenseeWinloss_2022M07],
	[rptLicenseeWinloss_2022M08],
	[rptLicenseeWinloss_2022M09],
	[rptLicenseeWinloss_2022M10],
	[rptLicenseeWinloss_2022M11],
	[rptLicenseeWinloss_2022M12],
	[rptLicenseeWinloss_2023M01],
	[rptLicenseeWinloss_2023M02],
	[rptLicenseeWinloss_2023M03],
	[rptLicenseeWinloss_2023M04],
	[rptLicenseeWinloss_2023M05],
	[rptLicenseeWinloss_2023M06],
	[rptLicenseeWinloss_2023M07],
	[rptLicenseeWinloss_2023M08],
	[rptLicenseeWinloss_2023M09],
	[rptLicenseeWinloss_2023M10],
	[rptLicenseeWinloss_2023M11],
	[rptLicenseeWinloss_2023M12],
	[rptLicenseeWinloss_MAX]
);
GO

USE [bodb_LicenseeReport]
GO

CREATE TABLE [dbo].[rptLicenseeWinloss](
	[Recommend] [int] NOT NULL,
	[WinlostDate] [smalldatetime] NOT NULL,
	[Product3rdId] [tinyint] NOT NULL,
	[Sporttype] [smallint] NOT NULL,
	[Bettype] [smallint] NOT NULL,
	[CustId] [int] NOT NULL,
	[StatusId] [smallint] NOT NULL,
	[LiveIndicator] [tinyint] NOT NULL,
	[LeagueGroupId] [smallint] NOT NULL,
	[TicketType] [tinyint] NOT NULL,
	[Betfrom] [nvarchar](1) NOT NULL,
	[APositiontaking] [smallmoney] NULL,
	[BetCount] [int] NULL,
	[Turnover] [money] NULL,
	[NetTurnover] [money] NULL,
	[Winlost] [money] NULL,
	[AWinlost] [money] NULL,
	[PComm] [money] NULL,
	[AComm] [money] NULL,
	INDEX CCI_rptLicenseeWinloss CLUSTERED COLUMNSTORE
) ON [PS_rptLicenseeWinloss_Monthly]([WinlostDate])
GO

CREATE NONCLUSTERED INDEX IX_CustID ON rptLicenseeWinloss(CustID, WinlostDate) 
ON [PS_rptLicenseeWinloss_Monthly](WinlostDate);
