/*<info serverAlias="DBRMS-bodb_RMS"></info>*/
/*	
	Created: 20231228@Cherry
	DB: DBRMS-bodb_RMS
	Task: New table rmSumByEventBettype
	RedmineID: #197684 - Report by Bettype

	Step 1: Create new file group and partition
*/

USE bodb_RMS
GO

-- add file group
ALTER DATABASE bodb_RMS ADD FILEGROUP rmSumByEventBettype_24M01
ALTER DATABASE bodb_RMS ADD FILEGROUP rmSumByEventBettype_24M02
ALTER DATABASE bodb_RMS ADD FILEGROUP rmSumByEventBettype_24M03
ALTER DATABASE bodb_RMS ADD FILEGROUP rmSumByEventBettype_24M04
ALTER DATABASE bodb_RMS ADD FILEGROUP rmSumByEventBettype_24M05
ALTER DATABASE bodb_RMS ADD FILEGROUP rmSumByEventBettype_24M06
ALTER DATABASE bodb_RMS ADD FILEGROUP rmSumByEventBettype_24M07
ALTER DATABASE bodb_RMS ADD FILEGROUP rmSumByEventBettype_24M08
ALTER DATABASE bodb_RMS ADD FILEGROUP rmSumByEventBettype_24M09
ALTER DATABASE bodb_RMS ADD FILEGROUP rmSumByEventBettype_24M10
ALTER DATABASE bodb_RMS ADD FILEGROUP rmSumByEventBettype_24M11
ALTER DATABASE bodb_RMS ADD FILEGROUP rmSumByEventBettype_24M12
ALTER DATABASE bodb_RMS ADD FILEGROUP rmSumByEventBettype_25M01
ALTER DATABASE bodb_RMS ADD FILEGROUP rmSumByEventBettype_25M02
ALTER DATABASE bodb_RMS ADD FILEGROUP rmSumByEventBettype_25M03
ALTER DATABASE bodb_RMS ADD FILEGROUP rmSumByEventBettype_25M04
ALTER DATABASE bodb_RMS ADD FILEGROUP rmSumByEventBettype_25M05
ALTER DATABASE bodb_RMS ADD FILEGROUP rmSumByEventBettype_25M06
ALTER DATABASE bodb_RMS ADD FILEGROUP rmSumByEventBettype_25M07
ALTER DATABASE bodb_RMS ADD FILEGROUP rmSumByEventBettype_25M08
ALTER DATABASE bodb_RMS ADD FILEGROUP rmSumByEventBettype_25M09
ALTER DATABASE bodb_RMS ADD FILEGROUP rmSumByEventBettype_25M10
ALTER DATABASE bodb_RMS ADD FILEGROUP rmSumByEventBettype_25M11
ALTER DATABASE bodb_RMS ADD FILEGROUP rmSumByEventBettype_25M12
ALTER DATABASE bodb_RMS ADD FILEGROUP rmSumByEventBettype_26M01
ALTER DATABASE bodb_RMS ADD FILEGROUP rmSumByEventBettype_26M02
ALTER DATABASE bodb_RMS ADD FILEGROUP rmSumByEventBettype_26M03
ALTER DATABASE bodb_RMS ADD FILEGROUP rmSumByEventBettype_26M04
ALTER DATABASE bodb_RMS ADD FILEGROUP rmSumByEventBettype_26M05
ALTER DATABASE bodb_RMS ADD FILEGROUP rmSumByEventBettype_26M06
ALTER DATABASE bodb_RMS ADD FILEGROUP rmSumByEventBettype_26M07
ALTER DATABASE bodb_RMS ADD FILEGROUP rmSumByEventBettype_26M08
ALTER DATABASE bodb_RMS ADD FILEGROUP rmSumByEventBettype_26M09
ALTER DATABASE bodb_RMS ADD FILEGROUP rmSumByEventBettype_26M10
ALTER DATABASE bodb_RMS ADD FILEGROUP rmSumByEventBettype_26M11
ALTER DATABASE bodb_RMS ADD FILEGROUP rmSumByEventBettype_26M12
ALTER DATABASE bodb_RMS ADD FILEGROUP rmSumByEventBettype_MAX
GO

-- add file name -- please change file path before run script below
ALTER DATABASE bodb_RMS ADD FILE (NAME = rmSumByEventBettype_24M01, FILENAME = 'E:\IBC_DB\bodb_RMS\rmSumByEventBettype\rmSumByEventBettype_24M01.ndf', SIZE = 3072 KB, MAXSIZE = UNLIMITED, FILEGROWTH = 1024 KB) TO FILEGROUP [rmSumByEventBettype_24M01]
ALTER DATABASE bodb_RMS ADD FILE (NAME = rmSumByEventBettype_24M02, FILENAME = 'E:\IBC_DB\bodb_RMS\rmSumByEventBettype\rmSumByEventBettype_24M02.ndf', SIZE = 3072 KB, MAXSIZE = UNLIMITED, FILEGROWTH = 1024 KB) TO FILEGROUP [rmSumByEventBettype_24M02]
ALTER DATABASE bodb_RMS ADD FILE (NAME = rmSumByEventBettype_24M03, FILENAME = 'E:\IBC_DB\bodb_RMS\rmSumByEventBettype\rmSumByEventBettype_24M03.ndf', SIZE = 3072 KB, MAXSIZE = UNLIMITED, FILEGROWTH = 1024 KB) TO FILEGROUP [rmSumByEventBettype_24M03]
ALTER DATABASE bodb_RMS ADD FILE (NAME = rmSumByEventBettype_24M04, FILENAME = 'E:\IBC_DB\bodb_RMS\rmSumByEventBettype\rmSumByEventBettype_24M04.ndf', SIZE = 3072 KB, MAXSIZE = UNLIMITED, FILEGROWTH = 1024 KB) TO FILEGROUP [rmSumByEventBettype_24M04]
ALTER DATABASE bodb_RMS ADD FILE (NAME = rmSumByEventBettype_24M05, FILENAME = 'E:\IBC_DB\bodb_RMS\rmSumByEventBettype\rmSumByEventBettype_24M05.ndf', SIZE = 3072 KB, MAXSIZE = UNLIMITED, FILEGROWTH = 1024 KB) TO FILEGROUP [rmSumByEventBettype_24M05]
ALTER DATABASE bodb_RMS ADD FILE (NAME = rmSumByEventBettype_24M06, FILENAME = 'E:\IBC_DB\bodb_RMS\rmSumByEventBettype\rmSumByEventBettype_24M06.ndf', SIZE = 3072 KB, MAXSIZE = UNLIMITED, FILEGROWTH = 1024 KB) TO FILEGROUP [rmSumByEventBettype_24M06]
ALTER DATABASE bodb_RMS ADD FILE (NAME = rmSumByEventBettype_24M07, FILENAME = 'E:\IBC_DB\bodb_RMS\rmSumByEventBettype\rmSumByEventBettype_24M07.ndf', SIZE = 3072 KB, MAXSIZE = UNLIMITED, FILEGROWTH = 1024 KB) TO FILEGROUP [rmSumByEventBettype_24M07]
ALTER DATABASE bodb_RMS ADD FILE (NAME = rmSumByEventBettype_24M08, FILENAME = 'E:\IBC_DB\bodb_RMS\rmSumByEventBettype\rmSumByEventBettype_24M08.ndf', SIZE = 3072 KB, MAXSIZE = UNLIMITED, FILEGROWTH = 1024 KB) TO FILEGROUP [rmSumByEventBettype_24M08]
ALTER DATABASE bodb_RMS ADD FILE (NAME = rmSumByEventBettype_24M09, FILENAME = 'E:\IBC_DB\bodb_RMS\rmSumByEventBettype\rmSumByEventBettype_24M09.ndf', SIZE = 3072 KB, MAXSIZE = UNLIMITED, FILEGROWTH = 1024 KB) TO FILEGROUP [rmSumByEventBettype_24M09]
ALTER DATABASE bodb_RMS ADD FILE (NAME = rmSumByEventBettype_24M10, FILENAME = 'E:\IBC_DB\bodb_RMS\rmSumByEventBettype\rmSumByEventBettype_24M10.ndf', SIZE = 3072 KB, MAXSIZE = UNLIMITED, FILEGROWTH = 1024 KB) TO FILEGROUP [rmSumByEventBettype_24M10]
ALTER DATABASE bodb_RMS ADD FILE (NAME = rmSumByEventBettype_24M11, FILENAME = 'E:\IBC_DB\bodb_RMS\rmSumByEventBettype\rmSumByEventBettype_24M11.ndf', SIZE = 3072 KB, MAXSIZE = UNLIMITED, FILEGROWTH = 1024 KB) TO FILEGROUP [rmSumByEventBettype_24M11]
ALTER DATABASE bodb_RMS ADD FILE (NAME = rmSumByEventBettype_24M12, FILENAME = 'E:\IBC_DB\bodb_RMS\rmSumByEventBettype\rmSumByEventBettype_24M12.ndf', SIZE = 3072 KB, MAXSIZE = UNLIMITED, FILEGROWTH = 1024 KB) TO FILEGROUP [rmSumByEventBettype_24M12]
ALTER DATABASE bodb_RMS ADD FILE (NAME = rmSumByEventBettype_25M01, FILENAME = 'E:\IBC_DB\bodb_RMS\rmSumByEventBettype\rmSumByEventBettype_25M01.ndf', SIZE = 3072 KB, MAXSIZE = UNLIMITED, FILEGROWTH = 1024 KB) TO FILEGROUP [rmSumByEventBettype_25M01]
ALTER DATABASE bodb_RMS ADD FILE (NAME = rmSumByEventBettype_25M02, FILENAME = 'E:\IBC_DB\bodb_RMS\rmSumByEventBettype\rmSumByEventBettype_25M02.ndf', SIZE = 3072 KB, MAXSIZE = UNLIMITED, FILEGROWTH = 1024 KB) TO FILEGROUP [rmSumByEventBettype_25M02]
ALTER DATABASE bodb_RMS ADD FILE (NAME = rmSumByEventBettype_25M03, FILENAME = 'E:\IBC_DB\bodb_RMS\rmSumByEventBettype\rmSumByEventBettype_25M03.ndf', SIZE = 3072 KB, MAXSIZE = UNLIMITED, FILEGROWTH = 1024 KB) TO FILEGROUP [rmSumByEventBettype_25M03]
ALTER DATABASE bodb_RMS ADD FILE (NAME = rmSumByEventBettype_25M04, FILENAME = 'E:\IBC_DB\bodb_RMS\rmSumByEventBettype\rmSumByEventBettype_25M04.ndf', SIZE = 3072 KB, MAXSIZE = UNLIMITED, FILEGROWTH = 1024 KB) TO FILEGROUP [rmSumByEventBettype_25M04]
ALTER DATABASE bodb_RMS ADD FILE (NAME = rmSumByEventBettype_25M05, FILENAME = 'E:\IBC_DB\bodb_RMS\rmSumByEventBettype\rmSumByEventBettype_25M05.ndf', SIZE = 3072 KB, MAXSIZE = UNLIMITED, FILEGROWTH = 1024 KB) TO FILEGROUP [rmSumByEventBettype_25M05]
ALTER DATABASE bodb_RMS ADD FILE (NAME = rmSumByEventBettype_25M06, FILENAME = 'E:\IBC_DB\bodb_RMS\rmSumByEventBettype\rmSumByEventBettype_25M06.ndf', SIZE = 3072 KB, MAXSIZE = UNLIMITED, FILEGROWTH = 1024 KB) TO FILEGROUP [rmSumByEventBettype_25M06]
ALTER DATABASE bodb_RMS ADD FILE (NAME = rmSumByEventBettype_25M07, FILENAME = 'E:\IBC_DB\bodb_RMS\rmSumByEventBettype\rmSumByEventBettype_25M07.ndf', SIZE = 3072 KB, MAXSIZE = UNLIMITED, FILEGROWTH = 1024 KB) TO FILEGROUP [rmSumByEventBettype_25M07]
ALTER DATABASE bodb_RMS ADD FILE (NAME = rmSumByEventBettype_25M08, FILENAME = 'E:\IBC_DB\bodb_RMS\rmSumByEventBettype\rmSumByEventBettype_25M08.ndf', SIZE = 3072 KB, MAXSIZE = UNLIMITED, FILEGROWTH = 1024 KB) TO FILEGROUP [rmSumByEventBettype_25M08]
ALTER DATABASE bodb_RMS ADD FILE (NAME = rmSumByEventBettype_25M09, FILENAME = 'E:\IBC_DB\bodb_RMS\rmSumByEventBettype\rmSumByEventBettype_25M09.ndf', SIZE = 3072 KB, MAXSIZE = UNLIMITED, FILEGROWTH = 1024 KB) TO FILEGROUP [rmSumByEventBettype_25M09]
ALTER DATABASE bodb_RMS ADD FILE (NAME = rmSumByEventBettype_25M10, FILENAME = 'E:\IBC_DB\bodb_RMS\rmSumByEventBettype\rmSumByEventBettype_25M10.ndf', SIZE = 3072 KB, MAXSIZE = UNLIMITED, FILEGROWTH = 1024 KB) TO FILEGROUP [rmSumByEventBettype_25M10]
ALTER DATABASE bodb_RMS ADD FILE (NAME = rmSumByEventBettype_25M11, FILENAME = 'E:\IBC_DB\bodb_RMS\rmSumByEventBettype\rmSumByEventBettype_25M11.ndf', SIZE = 3072 KB, MAXSIZE = UNLIMITED, FILEGROWTH = 1024 KB) TO FILEGROUP [rmSumByEventBettype_25M11]
ALTER DATABASE bodb_RMS ADD FILE (NAME = rmSumByEventBettype_25M12, FILENAME = 'E:\IBC_DB\bodb_RMS\rmSumByEventBettype\rmSumByEventBettype_25M12.ndf', SIZE = 3072 KB, MAXSIZE = UNLIMITED, FILEGROWTH = 1024 KB) TO FILEGROUP [rmSumByEventBettype_25M12]
ALTER DATABASE bodb_RMS ADD FILE (NAME = rmSumByEventBettype_26M01, FILENAME = 'E:\IBC_DB\bodb_RMS\rmSumByEventBettype\rmSumByEventBettype_26M01.ndf', SIZE = 3072 KB, MAXSIZE = UNLIMITED, FILEGROWTH = 1024 KB) TO FILEGROUP [rmSumByEventBettype_26M01]
ALTER DATABASE bodb_RMS ADD FILE (NAME = rmSumByEventBettype_26M02, FILENAME = 'E:\IBC_DB\bodb_RMS\rmSumByEventBettype\rmSumByEventBettype_26M02.ndf', SIZE = 3072 KB, MAXSIZE = UNLIMITED, FILEGROWTH = 1024 KB) TO FILEGROUP [rmSumByEventBettype_26M02]
ALTER DATABASE bodb_RMS ADD FILE (NAME = rmSumByEventBettype_26M03, FILENAME = 'E:\IBC_DB\bodb_RMS\rmSumByEventBettype\rmSumByEventBettype_26M03.ndf', SIZE = 3072 KB, MAXSIZE = UNLIMITED, FILEGROWTH = 1024 KB) TO FILEGROUP [rmSumByEventBettype_26M03]
ALTER DATABASE bodb_RMS ADD FILE (NAME = rmSumByEventBettype_26M04, FILENAME = 'E:\IBC_DB\bodb_RMS\rmSumByEventBettype\rmSumByEventBettype_26M04.ndf', SIZE = 3072 KB, MAXSIZE = UNLIMITED, FILEGROWTH = 1024 KB) TO FILEGROUP [rmSumByEventBettype_26M04]
ALTER DATABASE bodb_RMS ADD FILE (NAME = rmSumByEventBettype_26M05, FILENAME = 'E:\IBC_DB\bodb_RMS\rmSumByEventBettype\rmSumByEventBettype_26M05.ndf', SIZE = 3072 KB, MAXSIZE = UNLIMITED, FILEGROWTH = 1024 KB) TO FILEGROUP [rmSumByEventBettype_26M05]
ALTER DATABASE bodb_RMS ADD FILE (NAME = rmSumByEventBettype_26M06, FILENAME = 'E:\IBC_DB\bodb_RMS\rmSumByEventBettype\rmSumByEventBettype_26M06.ndf', SIZE = 3072 KB, MAXSIZE = UNLIMITED, FILEGROWTH = 1024 KB) TO FILEGROUP [rmSumByEventBettype_26M06]
ALTER DATABASE bodb_RMS ADD FILE (NAME = rmSumByEventBettype_26M07, FILENAME = 'E:\IBC_DB\bodb_RMS\rmSumByEventBettype\rmSumByEventBettype_26M07.ndf', SIZE = 3072 KB, MAXSIZE = UNLIMITED, FILEGROWTH = 1024 KB) TO FILEGROUP [rmSumByEventBettype_26M07]
ALTER DATABASE bodb_RMS ADD FILE (NAME = rmSumByEventBettype_26M08, FILENAME = 'E:\IBC_DB\bodb_RMS\rmSumByEventBettype\rmSumByEventBettype_26M08.ndf', SIZE = 3072 KB, MAXSIZE = UNLIMITED, FILEGROWTH = 1024 KB) TO FILEGROUP [rmSumByEventBettype_26M08]
ALTER DATABASE bodb_RMS ADD FILE (NAME = rmSumByEventBettype_26M09, FILENAME = 'E:\IBC_DB\bodb_RMS\rmSumByEventBettype\rmSumByEventBettype_26M09.ndf', SIZE = 3072 KB, MAXSIZE = UNLIMITED, FILEGROWTH = 1024 KB) TO FILEGROUP [rmSumByEventBettype_26M09]
ALTER DATABASE bodb_RMS ADD FILE (NAME = rmSumByEventBettype_26M10, FILENAME = 'E:\IBC_DB\bodb_RMS\rmSumByEventBettype\rmSumByEventBettype_26M10.ndf', SIZE = 3072 KB, MAXSIZE = UNLIMITED, FILEGROWTH = 1024 KB) TO FILEGROUP [rmSumByEventBettype_26M10]
ALTER DATABASE bodb_RMS ADD FILE (NAME = rmSumByEventBettype_26M11, FILENAME = 'E:\IBC_DB\bodb_RMS\rmSumByEventBettype\rmSumByEventBettype_26M11.ndf', SIZE = 3072 KB, MAXSIZE = UNLIMITED, FILEGROWTH = 1024 KB) TO FILEGROUP [rmSumByEventBettype_26M11]
ALTER DATABASE bodb_RMS ADD FILE (NAME = rmSumByEventBettype_26M12, FILENAME = 'E:\IBC_DB\bodb_RMS\rmSumByEventBettype\rmSumByEventBettype_26M12.ndf', SIZE = 3072 KB, MAXSIZE = UNLIMITED, FILEGROWTH = 1024 KB) TO FILEGROUP [rmSumByEventBettype_26M12]
ALTER DATABASE bodb_RMS ADD FILE (NAME = rmSumByEventBettype_MAX, FILENAME = 'E:\IBC_DB\bodb_RMS\rmSumByEventBettype\rmSumByEventBettype_MAX.ndf', SIZE = 3072 KB, MAXSIZE = UNLIMITED, FILEGROWTH = 1024 KB) TO FILEGROUP   [rmSumByEventBettype_MAX]
GO

-- Create partition function
CREATE PARTITION FUNCTION [PF_rmSumByEventBettype_Monthly] (DATE) AS 
RANGE LEFT FOR VALUES 
(
	N'2024-01-31',
	N'2024-02-29',
    N'2024-03-31',
    N'2024-04-30',
    N'2024-05-31',
    N'2024-06-30',
    N'2024-07-31',
    N'2024-08-31',
    N'2024-09-30',
    N'2024-10-31',
    N'2024-11-30',
    N'2024-12-31',
    N'2025-01-31',
    N'2025-02-28',
    N'2025-03-31',
    N'2025-04-30',
    N'2025-05-31',
    N'2025-06-30',
    N'2025-07-31',
    N'2025-08-31',
    N'2025-09-30',
    N'2025-10-31',
    N'2025-11-30',
    N'2025-12-31',
    N'2026-01-31',
    N'2026-02-28',
    N'2026-03-31',
    N'2026-04-30',
    N'2026-05-31',
    N'2026-06-30',
    N'2026-07-31',
    N'2026-08-31',
    N'2026-09-30',
    N'2026-10-31',
    N'2026-11-30',
    N'2026-12-31'
)
GO

-- create partition schema
CREATE PARTITION SCHEME [PS_rmSumByEventBettype_Monthly] AS PARTITION [PF_rmSumByEventBettype_Monthly] TO 
(
    rmSumByEventBettype_24M01,
    rmSumByEventBettype_24M02,
    rmSumByEventBettype_24M03,
    rmSumByEventBettype_24M04,
    rmSumByEventBettype_24M05,
    rmSumByEventBettype_24M06,
    rmSumByEventBettype_24M07,
    rmSumByEventBettype_24M08,
    rmSumByEventBettype_24M09,
    rmSumByEventBettype_24M10,
    rmSumByEventBettype_24M11,
    rmSumByEventBettype_24M12,
    rmSumByEventBettype_25M01,
    rmSumByEventBettype_25M02,
    rmSumByEventBettype_25M03,
    rmSumByEventBettype_25M04,
    rmSumByEventBettype_25M05,
    rmSumByEventBettype_25M06,
    rmSumByEventBettype_25M07,
    rmSumByEventBettype_25M08,
    rmSumByEventBettype_25M09,
    rmSumByEventBettype_25M10,
    rmSumByEventBettype_25M11,
    rmSumByEventBettype_25M12,
    rmSumByEventBettype_26M01,
    rmSumByEventBettype_26M02,
    rmSumByEventBettype_26M03,
    rmSumByEventBettype_26M04,
    rmSumByEventBettype_26M05,
    rmSumByEventBettype_26M06,
    rmSumByEventBettype_26M07,
    rmSumByEventBettype_26M08,
    rmSumByEventBettype_26M09,
    rmSumByEventBettype_26M10,
    rmSumByEventBettype_26M11,
    rmSumByEventBettype_26M12,
    rmSumByEventBettype_MAX
)
GO