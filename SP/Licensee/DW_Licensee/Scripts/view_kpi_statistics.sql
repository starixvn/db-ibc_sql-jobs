USE [bodb_licensee]
GO
/****** Object:  View [dbo].[view_kpi_statistics]    Script Date: 10/30/2012 09:51:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER VIEW [dbo].[view_kpi_statistics]
AS
/*
    Created: 20120816@Don
    Task: Get list of KPI statistics
    DB: DB052.bodb_Licensee

    Revisions:
		-20121030@Jim: fix bug data not correct for  SportRevenueTicketsLoss value
*/
-- Transfer
select convert(int,1) StatID, 0 IsCurrency union all
select convert(int,2), 1 union all
select convert(int,3), 0 union all
select convert(int,4), 0 union all

-- Account
select convert(int,5), 0 union all
select convert(int,6), 0 union all

-- Betting
select convert(int,7), 0 union all
select convert(int,9), 1 union all
select convert(int,10), 1 union all
select convert(int,11), 1 union all
select convert(int,14), 0 union all
select convert(int,15), 1 union ALL-- 20121030@Jim edit
select convert(int,16), 0 union all
select convert(int,17), 0 union all
select convert(int,19), 1 union all
select convert(int,22), 0 union all
select convert(int,23), 1

