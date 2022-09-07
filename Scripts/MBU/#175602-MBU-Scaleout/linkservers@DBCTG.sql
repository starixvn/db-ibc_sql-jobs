/*<info serverAlias="DB04ADMIN1-master,DB04ADMIN2-master,DB05-master,DB052-master,DB053-master,DB054-master,DB055-master,DB05BK1-master,DB061-master,DB062-master,DBTP10C-master" executers="" viewers="" isFunction="0" isNested="0"></info>*/
/*
	1- create alias for earch servers first
		- for Central (DBTrans)/DBBAL point to local
		- for others point to Central (DBTrans) 10.1.1.17
	2- change password for sqllink account

	Note that: run on AWS as well
*/

USE [master]
GO

EXEC master.dbo.sp_addlinkedserver @server = N'DBCTG', @srvproduct=N'SQL Server'
EXEC master.dbo.sp_addlinkedsrvlogin @rmtsrvname=N'DBCTG',@useself=N'False',@locallogin=NULL,@rmtuser=N'sqllink',@rmtpassword='########'
GO

EXEC master.dbo.sp_serveroption @server=N'DBCTG', @optname=N'collation compatible', @optvalue=N'false'
GO

EXEC master.dbo.sp_serveroption @server=N'DBCTG', @optname=N'data access', @optvalue=N'true'
GO

EXEC master.dbo.sp_serveroption @server=N'DBCTG', @optname=N'dist', @optvalue=N'false'
GO

EXEC master.dbo.sp_serveroption @server=N'DBCTG', @optname=N'pub', @optvalue=N'false'
GO

EXEC master.dbo.sp_serveroption @server=N'DBCTG', @optname=N'rpc', @optvalue=N'true'
GO

EXEC master.dbo.sp_serveroption @server=N'DBCTG', @optname=N'rpc out', @optvalue=N'true'
GO

EXEC master.dbo.sp_serveroption @server=N'DBCTG', @optname=N'sub', @optvalue=N'false'
GO

EXEC master.dbo.sp_serveroption @server=N'DBCTG', @optname=N'connect timeout', @optvalue=N'0'
GO

EXEC master.dbo.sp_serveroption @server=N'DBCTG', @optname=N'collation name', @optvalue=null
GO

EXEC master.dbo.sp_serveroption @server=N'DBCTG', @optname=N'lazy schema validation', @optvalue=N'false'
GO

EXEC master.dbo.sp_serveroption @server=N'DBCTG', @optname=N'query timeout', @optvalue=N'0'
GO

EXEC master.dbo.sp_serveroption @server=N'DBCTG', @optname=N'use remote collation', @optvalue=N'true'
GO

EXEC master.dbo.sp_serveroption @server=N'DBCTG', @optname=N'remote proc transaction promotion', @optvalue=N'false'
GO


