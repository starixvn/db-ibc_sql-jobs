/*
    Created: 20110622@Don
    Task: Create linked server from DB052 to DBDW2
    DB: DB052

    Revisions:

*/



/****** Object:  LinkedServer [DBDW2]    Script Date: 06/22/2011 15:27:16 ******/
EXEC master.dbo.sp_addlinkedserver @server = N'DBDW2', @srvproduct=N'', @provider=N'SQLNCLI', @datasrc=N'10.18.200.40', @location=NULL, @provstr=NULL, @catalog=NULL


 /* For security reasons the linked server remote logins password is changed with ######## */
/*EXEC master.dbo.sp_addlinkedsrvlogin @rmtsrvname=N'DBDW2',@useself=N'True',@locallogin=N'bodbLicenseeNet',@rmtuser=NULL,@rmtpassword=NULL
EXEC master.dbo.sp_addlinkedsrvlogin @rmtsrvname=N'DBDW2',@useself=N'True',@locallogin=N'vnteam',@rmtuser=NULL,@rmtpassword=NULL*/

GO
EXEC master.dbo.sp_serveroption @server=N'DBDW2', @optname=N'collation compatible', @optvalue=N'false'
GO
EXEC master.dbo.sp_serveroption @server=N'DBDW2', @optname=N'data access', @optvalue=N'true'
GO
EXEC master.dbo.sp_serveroption @server=N'DBDW2', @optname=N'dist', @optvalue=N'false'
GO
EXEC master.dbo.sp_serveroption @server=N'DBDW2', @optname=N'pub', @optvalue=N'false'
GO
EXEC master.dbo.sp_serveroption @server=N'DBDW2', @optname=N'rpc', @optvalue=N'true'
GO
EXEC master.dbo.sp_serveroption @server=N'DBDW2', @optname=N'rpc out', @optvalue=N'true'
GO
EXEC master.dbo.sp_serveroption @server=N'DBDW2', @optname=N'sub', @optvalue=N'false'
GO
EXEC master.dbo.sp_serveroption @server=N'DBDW2', @optname=N'connect timeout', @optvalue=N'0'
GO
EXEC master.dbo.sp_serveroption @server=N'DBDW2', @optname=N'collation name', @optvalue=null
GO
EXEC master.dbo.sp_serveroption @server=N'DBDW2', @optname=N'lazy schema validation', @optvalue=N'false'
GO
EXEC master.dbo.sp_serveroption @server=N'DBDW2', @optname=N'query timeout', @optvalue=N'0'
GO
EXEC master.dbo.sp_serveroption @server=N'DBDW2', @optname=N'use remote collation', @optvalue=N'true'



/*
select S.server_id, S.name, S.provider,S.data_source,S.provider_string, L.uses_self_credential
 
from

 sys.servers as S, sys.linked_logins as L 

where

 S.server_id=L.server_id and S.name=N'DBDW2'
*/
