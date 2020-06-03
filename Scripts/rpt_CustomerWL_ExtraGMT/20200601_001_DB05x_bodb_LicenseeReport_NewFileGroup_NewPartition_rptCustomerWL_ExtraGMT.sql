/*<info serverAlias="DBLIC-bodb_LicenseeReport"></info>*/
/*	
	Created: 20200601@Percy
	DB: DBLIC-bodb_LicenseeReport
	Task: New table rpt_CustomerWL_ExtraGMT
	RedmineID: #134867 - Calculating pay to supplier for some special customers

	Step 1: Create new file group and partition
*/

USE bodb_LicenseeReport
GO

-- add file group
ALTER DATABASE bodb_LicenseeReport ADD FILEGROUP rpt_CustomerWL_ExtraGMT_20M04
ALTER DATABASE bodb_LicenseeReport ADD FILEGROUP rpt_CustomerWL_ExtraGMT_20M05
ALTER DATABASE bodb_LicenseeReport ADD FILEGROUP rpt_CustomerWL_ExtraGMT_20M06
ALTER DATABASE bodb_LicenseeReport ADD FILEGROUP rpt_CustomerWL_ExtraGMT_20M07
ALTER DATABASE bodb_LicenseeReport ADD FILEGROUP rpt_CustomerWL_ExtraGMT_20M08
ALTER DATABASE bodb_LicenseeReport ADD FILEGROUP rpt_CustomerWL_ExtraGMT_20M09
ALTER DATABASE bodb_LicenseeReport ADD FILEGROUP rpt_CustomerWL_ExtraGMT_20M10
ALTER DATABASE bodb_LicenseeReport ADD FILEGROUP rpt_CustomerWL_ExtraGMT_20M11
ALTER DATABASE bodb_LicenseeReport ADD FILEGROUP rpt_CustomerWL_ExtraGMT_20M12
ALTER DATABASE bodb_LicenseeReport ADD FILEGROUP rpt_CustomerWL_ExtraGMT_21M01
ALTER DATABASE bodb_LicenseeReport ADD FILEGROUP rpt_CustomerWL_ExtraGMT_21M02
ALTER DATABASE bodb_LicenseeReport ADD FILEGROUP rpt_CustomerWL_ExtraGMT_21M03
ALTER DATABASE bodb_LicenseeReport ADD FILEGROUP rpt_CustomerWL_ExtraGMT_21M04
ALTER DATABASE bodb_LicenseeReport ADD FILEGROUP rpt_CustomerWL_ExtraGMT_21M05
ALTER DATABASE bodb_LicenseeReport ADD FILEGROUP rpt_CustomerWL_ExtraGMT_21M06
ALTER DATABASE bodb_LicenseeReport ADD FILEGROUP rpt_CustomerWL_ExtraGMT_21M07
ALTER DATABASE bodb_LicenseeReport ADD FILEGROUP rpt_CustomerWL_ExtraGMT_21M08
ALTER DATABASE bodb_LicenseeReport ADD FILEGROUP rpt_CustomerWL_ExtraGMT_21M09
ALTER DATABASE bodb_LicenseeReport ADD FILEGROUP rpt_CustomerWL_ExtraGMT_21M10
ALTER DATABASE bodb_LicenseeReport ADD FILEGROUP rpt_CustomerWL_ExtraGMT_21M11
ALTER DATABASE bodb_LicenseeReport ADD FILEGROUP rpt_CustomerWL_ExtraGMT_21M12
ALTER DATABASE bodb_LicenseeReport ADD FILEGROUP rpt_CustomerWL_ExtraGMT_22M01
ALTER DATABASE bodb_LicenseeReport ADD FILEGROUP rpt_CustomerWL_ExtraGMT_22M02
ALTER DATABASE bodb_LicenseeReport ADD FILEGROUP rpt_CustomerWL_ExtraGMT_22M03
ALTER DATABASE bodb_LicenseeReport ADD FILEGROUP rpt_CustomerWL_ExtraGMT_22M04
ALTER DATABASE bodb_LicenseeReport ADD FILEGROUP rpt_CustomerWL_ExtraGMT_22M05
ALTER DATABASE bodb_LicenseeReport ADD FILEGROUP rpt_CustomerWL_ExtraGMT_22M06
ALTER DATABASE bodb_LicenseeReport ADD FILEGROUP rpt_CustomerWL_ExtraGMT_22M07
ALTER DATABASE bodb_LicenseeReport ADD FILEGROUP rpt_CustomerWL_ExtraGMT_22M08
ALTER DATABASE bodb_LicenseeReport ADD FILEGROUP rpt_CustomerWL_ExtraGMT_22M09
ALTER DATABASE bodb_LicenseeReport ADD FILEGROUP rpt_CustomerWL_ExtraGMT_22M10
ALTER DATABASE bodb_LicenseeReport ADD FILEGROUP rpt_CustomerWL_ExtraGMT_22M11
ALTER DATABASE bodb_LicenseeReport ADD FILEGROUP rpt_CustomerWL_ExtraGMT_22M12
ALTER DATABASE bodb_LicenseeReport ADD FILEGROUP rpt_CustomerWL_ExtraGMT_MAX

GO

-- add file name -- please change file path before run script below
ALTER DATABASE bodb_LicenseeReport ADD FILE (NAME = rpt_CustomerWL_ExtraGMT_20M04 , FILENAME = 'E:\IBC_DB\bodb_LicenseeReport\rpt_CustomerWL_ExtraGMT\rpt_CustomerWL_ExtraGMT_20M04.ndf', SIZE = 3072 KB, MAXSIZE = UNLIMITED, FILEGROWTH = 1024 KB) TO FILEGROUP [rpt_CustomerWL_ExtraGMT_20M04]
ALTER DATABASE bodb_LicenseeReport ADD FILE (NAME = rpt_CustomerWL_ExtraGMT_20M05 , FILENAME = 'E:\IBC_DB\bodb_LicenseeReport\rpt_CustomerWL_ExtraGMT\rpt_CustomerWL_ExtraGMT_20M05.ndf', SIZE = 3072 KB, MAXSIZE = UNLIMITED, FILEGROWTH = 1024 KB) TO FILEGROUP [rpt_CustomerWL_ExtraGMT_20M05]
ALTER DATABASE bodb_LicenseeReport ADD FILE (NAME = rpt_CustomerWL_ExtraGMT_20M06 , FILENAME = 'E:\IBC_DB\bodb_LicenseeReport\rpt_CustomerWL_ExtraGMT\rpt_CustomerWL_ExtraGMT_20M06.ndf', SIZE = 3072 KB, MAXSIZE = UNLIMITED, FILEGROWTH = 1024 KB) TO FILEGROUP [rpt_CustomerWL_ExtraGMT_20M06]
ALTER DATABASE bodb_LicenseeReport ADD FILE (NAME = rpt_CustomerWL_ExtraGMT_20M07 , FILENAME = 'E:\IBC_DB\bodb_LicenseeReport\rpt_CustomerWL_ExtraGMT\rpt_CustomerWL_ExtraGMT_20M07.ndf', SIZE = 3072 KB, MAXSIZE = UNLIMITED, FILEGROWTH = 1024 KB) TO FILEGROUP [rpt_CustomerWL_ExtraGMT_20M07]
ALTER DATABASE bodb_LicenseeReport ADD FILE (NAME = rpt_CustomerWL_ExtraGMT_20M08 , FILENAME = 'E:\IBC_DB\bodb_LicenseeReport\rpt_CustomerWL_ExtraGMT\rpt_CustomerWL_ExtraGMT_20M08.ndf', SIZE = 3072 KB, MAXSIZE = UNLIMITED, FILEGROWTH = 1024 KB) TO FILEGROUP [rpt_CustomerWL_ExtraGMT_20M08]
ALTER DATABASE bodb_LicenseeReport ADD FILE (NAME = rpt_CustomerWL_ExtraGMT_20M09 , FILENAME = 'E:\IBC_DB\bodb_LicenseeReport\rpt_CustomerWL_ExtraGMT\rpt_CustomerWL_ExtraGMT_20M09.ndf', SIZE = 3072 KB, MAXSIZE = UNLIMITED, FILEGROWTH = 1024 KB) TO FILEGROUP [rpt_CustomerWL_ExtraGMT_20M09]
ALTER DATABASE bodb_LicenseeReport ADD FILE (NAME = rpt_CustomerWL_ExtraGMT_20M10 , FILENAME = 'E:\IBC_DB\bodb_LicenseeReport\rpt_CustomerWL_ExtraGMT\rpt_CustomerWL_ExtraGMT_20M10.ndf', SIZE = 3072 KB, MAXSIZE = UNLIMITED, FILEGROWTH = 1024 KB) TO FILEGROUP [rpt_CustomerWL_ExtraGMT_20M10]
ALTER DATABASE bodb_LicenseeReport ADD FILE (NAME = rpt_CustomerWL_ExtraGMT_20M11 , FILENAME = 'E:\IBC_DB\bodb_LicenseeReport\rpt_CustomerWL_ExtraGMT\rpt_CustomerWL_ExtraGMT_20M11.ndf', SIZE = 3072 KB, MAXSIZE = UNLIMITED, FILEGROWTH = 1024 KB) TO FILEGROUP [rpt_CustomerWL_ExtraGMT_20M11]
ALTER DATABASE bodb_LicenseeReport ADD FILE (NAME = rpt_CustomerWL_ExtraGMT_20M12 , FILENAME = 'E:\IBC_DB\bodb_LicenseeReport\rpt_CustomerWL_ExtraGMT\rpt_CustomerWL_ExtraGMT_20M12.ndf', SIZE = 3072 KB, MAXSIZE = UNLIMITED, FILEGROWTH = 1024 KB) TO FILEGROUP [rpt_CustomerWL_ExtraGMT_20M12]
ALTER DATABASE bodb_LicenseeReport ADD FILE (NAME = rpt_CustomerWL_ExtraGMT_21M01 , FILENAME = 'E:\IBC_DB\bodb_LicenseeReport\rpt_CustomerWL_ExtraGMT\rpt_CustomerWL_ExtraGMT_21M01.ndf', SIZE = 3072 KB, MAXSIZE = UNLIMITED, FILEGROWTH = 1024 KB) TO FILEGROUP [rpt_CustomerWL_ExtraGMT_21M01]
ALTER DATABASE bodb_LicenseeReport ADD FILE (NAME = rpt_CustomerWL_ExtraGMT_21M02 , FILENAME = 'E:\IBC_DB\bodb_LicenseeReport\rpt_CustomerWL_ExtraGMT\rpt_CustomerWL_ExtraGMT_21M02.ndf', SIZE = 3072 KB, MAXSIZE = UNLIMITED, FILEGROWTH = 1024 KB) TO FILEGROUP [rpt_CustomerWL_ExtraGMT_21M02]
ALTER DATABASE bodb_LicenseeReport ADD FILE (NAME = rpt_CustomerWL_ExtraGMT_21M03 , FILENAME = 'E:\IBC_DB\bodb_LicenseeReport\rpt_CustomerWL_ExtraGMT\rpt_CustomerWL_ExtraGMT_21M03.ndf', SIZE = 3072 KB, MAXSIZE = UNLIMITED, FILEGROWTH = 1024 KB) TO FILEGROUP [rpt_CustomerWL_ExtraGMT_21M03]
ALTER DATABASE bodb_LicenseeReport ADD FILE (NAME = rpt_CustomerWL_ExtraGMT_21M04 , FILENAME = 'E:\IBC_DB\bodb_LicenseeReport\rpt_CustomerWL_ExtraGMT\rpt_CustomerWL_ExtraGMT_21M04.ndf', SIZE = 3072 KB, MAXSIZE = UNLIMITED, FILEGROWTH = 1024 KB) TO FILEGROUP [rpt_CustomerWL_ExtraGMT_21M04]
ALTER DATABASE bodb_LicenseeReport ADD FILE (NAME = rpt_CustomerWL_ExtraGMT_21M05 , FILENAME = 'E:\IBC_DB\bodb_LicenseeReport\rpt_CustomerWL_ExtraGMT\rpt_CustomerWL_ExtraGMT_21M05.ndf', SIZE = 3072 KB, MAXSIZE = UNLIMITED, FILEGROWTH = 1024 KB) TO FILEGROUP [rpt_CustomerWL_ExtraGMT_21M05]
ALTER DATABASE bodb_LicenseeReport ADD FILE (NAME = rpt_CustomerWL_ExtraGMT_21M06 , FILENAME = 'E:\IBC_DB\bodb_LicenseeReport\rpt_CustomerWL_ExtraGMT\rpt_CustomerWL_ExtraGMT_21M06.ndf', SIZE = 3072 KB, MAXSIZE = UNLIMITED, FILEGROWTH = 1024 KB) TO FILEGROUP [rpt_CustomerWL_ExtraGMT_21M06]
ALTER DATABASE bodb_LicenseeReport ADD FILE (NAME = rpt_CustomerWL_ExtraGMT_21M07 , FILENAME = 'E:\IBC_DB\bodb_LicenseeReport\rpt_CustomerWL_ExtraGMT\rpt_CustomerWL_ExtraGMT_21M07.ndf', SIZE = 3072 KB, MAXSIZE = UNLIMITED, FILEGROWTH = 1024 KB) TO FILEGROUP [rpt_CustomerWL_ExtraGMT_21M07]
ALTER DATABASE bodb_LicenseeReport ADD FILE (NAME = rpt_CustomerWL_ExtraGMT_21M08 , FILENAME = 'E:\IBC_DB\bodb_LicenseeReport\rpt_CustomerWL_ExtraGMT\rpt_CustomerWL_ExtraGMT_21M08.ndf', SIZE = 3072 KB, MAXSIZE = UNLIMITED, FILEGROWTH = 1024 KB) TO FILEGROUP [rpt_CustomerWL_ExtraGMT_21M08]
ALTER DATABASE bodb_LicenseeReport ADD FILE (NAME = rpt_CustomerWL_ExtraGMT_21M09 , FILENAME = 'E:\IBC_DB\bodb_LicenseeReport\rpt_CustomerWL_ExtraGMT\rpt_CustomerWL_ExtraGMT_21M09.ndf', SIZE = 3072 KB, MAXSIZE = UNLIMITED, FILEGROWTH = 1024 KB) TO FILEGROUP [rpt_CustomerWL_ExtraGMT_21M09]
ALTER DATABASE bodb_LicenseeReport ADD FILE (NAME = rpt_CustomerWL_ExtraGMT_21M10 , FILENAME = 'E:\IBC_DB\bodb_LicenseeReport\rpt_CustomerWL_ExtraGMT\rpt_CustomerWL_ExtraGMT_21M10.ndf', SIZE = 3072 KB, MAXSIZE = UNLIMITED, FILEGROWTH = 1024 KB) TO FILEGROUP [rpt_CustomerWL_ExtraGMT_21M10]
ALTER DATABASE bodb_LicenseeReport ADD FILE (NAME = rpt_CustomerWL_ExtraGMT_21M11 , FILENAME = 'E:\IBC_DB\bodb_LicenseeReport\rpt_CustomerWL_ExtraGMT\rpt_CustomerWL_ExtraGMT_21M11.ndf', SIZE = 3072 KB, MAXSIZE = UNLIMITED, FILEGROWTH = 1024 KB) TO FILEGROUP [rpt_CustomerWL_ExtraGMT_21M11]
ALTER DATABASE bodb_LicenseeReport ADD FILE (NAME = rpt_CustomerWL_ExtraGMT_21M12 , FILENAME = 'E:\IBC_DB\bodb_LicenseeReport\rpt_CustomerWL_ExtraGMT\rpt_CustomerWL_ExtraGMT_21M12.ndf', SIZE = 3072 KB, MAXSIZE = UNLIMITED, FILEGROWTH = 1024 KB) TO FILEGROUP [rpt_CustomerWL_ExtraGMT_21M12]
ALTER DATABASE bodb_LicenseeReport ADD FILE (NAME = rpt_CustomerWL_ExtraGMT_22M01 , FILENAME = 'E:\IBC_DB\bodb_LicenseeReport\rpt_CustomerWL_ExtraGMT\rpt_CustomerWL_ExtraGMT_22M01.ndf', SIZE = 3072 KB, MAXSIZE = UNLIMITED, FILEGROWTH = 1024 KB) TO FILEGROUP [rpt_CustomerWL_ExtraGMT_22M01]
ALTER DATABASE bodb_LicenseeReport ADD FILE (NAME = rpt_CustomerWL_ExtraGMT_22M02 , FILENAME = 'E:\IBC_DB\bodb_LicenseeReport\rpt_CustomerWL_ExtraGMT\rpt_CustomerWL_ExtraGMT_22M02.ndf', SIZE = 3072 KB, MAXSIZE = UNLIMITED, FILEGROWTH = 1024 KB) TO FILEGROUP [rpt_CustomerWL_ExtraGMT_22M02]
ALTER DATABASE bodb_LicenseeReport ADD FILE (NAME = rpt_CustomerWL_ExtraGMT_22M03 , FILENAME = 'E:\IBC_DB\bodb_LicenseeReport\rpt_CustomerWL_ExtraGMT\rpt_CustomerWL_ExtraGMT_22M03.ndf', SIZE = 3072 KB, MAXSIZE = UNLIMITED, FILEGROWTH = 1024 KB) TO FILEGROUP [rpt_CustomerWL_ExtraGMT_22M03]
ALTER DATABASE bodb_LicenseeReport ADD FILE (NAME = rpt_CustomerWL_ExtraGMT_22M04 , FILENAME = 'E:\IBC_DB\bodb_LicenseeReport\rpt_CustomerWL_ExtraGMT\rpt_CustomerWL_ExtraGMT_22M04.ndf', SIZE = 3072 KB, MAXSIZE = UNLIMITED, FILEGROWTH = 1024 KB) TO FILEGROUP [rpt_CustomerWL_ExtraGMT_22M04]
ALTER DATABASE bodb_LicenseeReport ADD FILE (NAME = rpt_CustomerWL_ExtraGMT_22M05 , FILENAME = 'E:\IBC_DB\bodb_LicenseeReport\rpt_CustomerWL_ExtraGMT\rpt_CustomerWL_ExtraGMT_22M05.ndf', SIZE = 3072 KB, MAXSIZE = UNLIMITED, FILEGROWTH = 1024 KB) TO FILEGROUP [rpt_CustomerWL_ExtraGMT_22M05]
ALTER DATABASE bodb_LicenseeReport ADD FILE (NAME = rpt_CustomerWL_ExtraGMT_22M06 , FILENAME = 'E:\IBC_DB\bodb_LicenseeReport\rpt_CustomerWL_ExtraGMT\rpt_CustomerWL_ExtraGMT_22M06.ndf', SIZE = 3072 KB, MAXSIZE = UNLIMITED, FILEGROWTH = 1024 KB) TO FILEGROUP [rpt_CustomerWL_ExtraGMT_22M06]
ALTER DATABASE bodb_LicenseeReport ADD FILE (NAME = rpt_CustomerWL_ExtraGMT_22M07 , FILENAME = 'E:\IBC_DB\bodb_LicenseeReport\rpt_CustomerWL_ExtraGMT\rpt_CustomerWL_ExtraGMT_22M07.ndf', SIZE = 3072 KB, MAXSIZE = UNLIMITED, FILEGROWTH = 1024 KB) TO FILEGROUP [rpt_CustomerWL_ExtraGMT_22M07]
ALTER DATABASE bodb_LicenseeReport ADD FILE (NAME = rpt_CustomerWL_ExtraGMT_22M08 , FILENAME = 'E:\IBC_DB\bodb_LicenseeReport\rpt_CustomerWL_ExtraGMT\rpt_CustomerWL_ExtraGMT_22M08.ndf', SIZE = 3072 KB, MAXSIZE = UNLIMITED, FILEGROWTH = 1024 KB) TO FILEGROUP [rpt_CustomerWL_ExtraGMT_22M08]
ALTER DATABASE bodb_LicenseeReport ADD FILE (NAME = rpt_CustomerWL_ExtraGMT_22M09 , FILENAME = 'E:\IBC_DB\bodb_LicenseeReport\rpt_CustomerWL_ExtraGMT\rpt_CustomerWL_ExtraGMT_22M09.ndf', SIZE = 3072 KB, MAXSIZE = UNLIMITED, FILEGROWTH = 1024 KB) TO FILEGROUP [rpt_CustomerWL_ExtraGMT_22M09]
ALTER DATABASE bodb_LicenseeReport ADD FILE (NAME = rpt_CustomerWL_ExtraGMT_22M10 , FILENAME = 'E:\IBC_DB\bodb_LicenseeReport\rpt_CustomerWL_ExtraGMT\rpt_CustomerWL_ExtraGMT_22M10.ndf', SIZE = 3072 KB, MAXSIZE = UNLIMITED, FILEGROWTH = 1024 KB) TO FILEGROUP [rpt_CustomerWL_ExtraGMT_22M10]
ALTER DATABASE bodb_LicenseeReport ADD FILE (NAME = rpt_CustomerWL_ExtraGMT_22M11 , FILENAME = 'E:\IBC_DB\bodb_LicenseeReport\rpt_CustomerWL_ExtraGMT\rpt_CustomerWL_ExtraGMT_22M11.ndf', SIZE = 3072 KB, MAXSIZE = UNLIMITED, FILEGROWTH = 1024 KB) TO FILEGROUP [rpt_CustomerWL_ExtraGMT_22M11]
ALTER DATABASE bodb_LicenseeReport ADD FILE (NAME = rpt_CustomerWL_ExtraGMT_22M12 , FILENAME = 'E:\IBC_DB\bodb_LicenseeReport\rpt_CustomerWL_ExtraGMT\rpt_CustomerWL_ExtraGMT_22M12.ndf', SIZE = 3072 KB, MAXSIZE = UNLIMITED, FILEGROWTH = 1024 KB) TO FILEGROUP [rpt_CustomerWL_ExtraGMT_22M12]
ALTER DATABASE bodb_LicenseeReport ADD FILE (NAME = rpt_CustomerWL_ExtraGMT_MAX   , FILENAME = 'E:\IBC_DB\bodb_LicenseeReport\rpt_CustomerWL_ExtraGMT\rpt_CustomerWL_ExtraGMT_MAX.ndf', SIZE = 3072 KB, MAXSIZE = UNLIMITED, FILEGROWTH = 1024 KB) TO FILEGROUP   [rpt_CustomerWL_ExtraGMT_MAX]

GO

-- Create partition function
CREATE PARTITION FUNCTION [PF_rpt_CustomerWL_ExtraGMT_Monthly] (DATE) AS 
RANGE LEFT FOR VALUES 
(
    N'2020-04-30',
	N'2020-05-31',
    N'2020-06-30',
    N'2020-07-31',
    N'2020-08-31',
    N'2020-09-30',
    N'2020-10-31',
    N'2020-11-30',
    N'2020-12-31',
    N'2021-01-31',
    N'2021-02-28',
    N'2021-03-31',
    N'2021-04-30',
    N'2021-05-31',
    N'2021-06-30',
    N'2021-07-31',
    N'2021-08-31',
    N'2021-09-30',
    N'2021-10-31',
    N'2021-11-30',
    N'2021-12-31',
    N'2022-01-31',
    N'2022-02-28',
    N'2022-03-31',
    N'2022-04-30',
    N'2022-05-31',
    N'2022-06-30',
    N'2022-07-31',
    N'2022-08-31',
    N'2022-09-30',
    N'2022-10-31',
    N'2022-11-30',
    N'2022-12-31'
)

GO

-- create partition schema
CREATE PARTITION SCHEME [PS_rpt_CustomerWL_ExtraGMT_Monthly] AS PARTITION [PF_rpt_CustomerWL_ExtraGMT_Monthly] TO 
(
    rpt_CustomerWL_ExtraGMT_20M04,
	rpt_CustomerWL_ExtraGMT_20M05,
    rpt_CustomerWL_ExtraGMT_20M06,
    rpt_CustomerWL_ExtraGMT_20M07,
    rpt_CustomerWL_ExtraGMT_20M08,
    rpt_CustomerWL_ExtraGMT_20M09,
    rpt_CustomerWL_ExtraGMT_20M10,
    rpt_CustomerWL_ExtraGMT_20M11,
    rpt_CustomerWL_ExtraGMT_20M12,
    rpt_CustomerWL_ExtraGMT_21M01,
    rpt_CustomerWL_ExtraGMT_21M02,
    rpt_CustomerWL_ExtraGMT_21M03,
    rpt_CustomerWL_ExtraGMT_21M04,
    rpt_CustomerWL_ExtraGMT_21M05,
    rpt_CustomerWL_ExtraGMT_21M06,
    rpt_CustomerWL_ExtraGMT_21M07,
    rpt_CustomerWL_ExtraGMT_21M08,
    rpt_CustomerWL_ExtraGMT_21M09,
    rpt_CustomerWL_ExtraGMT_21M10,
    rpt_CustomerWL_ExtraGMT_21M11,
    rpt_CustomerWL_ExtraGMT_21M12,
    rpt_CustomerWL_ExtraGMT_22M01,
    rpt_CustomerWL_ExtraGMT_22M02,
    rpt_CustomerWL_ExtraGMT_22M03,
    rpt_CustomerWL_ExtraGMT_22M04,
    rpt_CustomerWL_ExtraGMT_22M05,
    rpt_CustomerWL_ExtraGMT_22M06,
    rpt_CustomerWL_ExtraGMT_22M07,
    rpt_CustomerWL_ExtraGMT_22M08,
    rpt_CustomerWL_ExtraGMT_22M09,
    rpt_CustomerWL_ExtraGMT_22M10,
    rpt_CustomerWL_ExtraGMT_22M11,
    rpt_CustomerWL_ExtraGMT_22M12,
    rpt_CustomerWL_ExtraGMT_MAX
)
GO