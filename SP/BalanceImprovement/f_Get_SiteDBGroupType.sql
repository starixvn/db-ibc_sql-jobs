/*<info serverAlias="DBTXN-bodb02" executers="" viewers="" isNested="0"></info>*/
USE [bodb02]
GO
/****** Object:  UserDefinedFunction [dbo].[f_Get_SiteDBGroupID]    Script Date: 7/7/2023 6:08:42 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER FUNCTION [dbo].[f_Get_SiteDBGroupType]()
RETURNS SMALLINT
AS
/*
	Created: 20230707@Brice
	DB: DBTXN.bodb02
	Task: 158293 - Scale out site 3
		1: deposit site
		2: credit site

	Revisions:
		- 20230707@Brice: Create [RedmineID: #191003]
*/
BEGIN
  RETURN 
  CASE dbo.[f_Get_SiteDBGroupID]()
     WHEN 0 then 2
     WHEN 1 then 1
	 WHEN 2 then 1
	 when 3 then 2
  ELSE 1023 END 
END
