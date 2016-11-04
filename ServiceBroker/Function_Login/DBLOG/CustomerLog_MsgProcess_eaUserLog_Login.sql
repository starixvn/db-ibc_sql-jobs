CREATE PROCEDURE sb.CustomerLog_MsgProcess_eaUserLog_Login
(
	@XmlMessage XML
)

/*
	Created By: Helen
	Created Date: 20161027
	Task: Apply Service Broker for login function
	DB:DBLOG/bodb_CustomerLog
	-- For testing
	DECLARE @XmlData XML = '<root>
							<row LogID="76" UserID="0" RoleID="0" SubAccID="0" ServerID="0" IP="10.19.10.112" LogDate="2012-04-16T09:32:18.123" ActionID="1310" Doing="Account:12BETRMB01 - Login Result:Failed (User_Not_Found)" DomainName="10.18.200.201" BrowserName="Firefox 3.6" Platform="Windows NT" CountryCode="-" Duration="423" />
							<row LogID="398" UserID="0" RoleID="0" SubAccID="0" ServerID="0" IP="10.19.10.114" LogDate="2012-04-16T11:09:20.753" ActionID="1310" Doing="Account:hi - Login Result:Failed (User_Not_Found)" DomainName="10.18.200.201" BrowserName="Firefox 11.0" Platform="Windows NT" CountryCode="-" Duration="0" />
							</root>';

*/
AS
BEGIN
 
	DECLARE @_hdoc INT
	
	SELECT @XmlMessage as message
	
	EXECUTE sys.sp_xml_preparedocument @_hdoc OUTPUT, @XmlMessage

	INSERT INTO [dbo].[eaUserLog_Login]([UserID],[IP],[LogDate],[ActionID],[TrackingValue],[DomainName],[BrowserName],[Platform],[CountryCode],[Duration], [CreatedDate])    
    SELECT  [UserID],[IP],[LogDate],[ActionID],[TrackingValue],[DomainName],[BrowserName],[Platform],[CountryCode],[Duration], GETDATE() AS [CreatedDate]      
    FROM OPENXML(@_hdoc,'/root/row', 1)   
		WITH (UserID		INT '@UserID',
			IP			VARCHAR(50) '@IP',
			LogDate		DATETIME '@LogDate',
			ActionID	INT '@ActionID',
			TrackingValue NVARCHAR(300) '@TrackingValue',
			DomainName VARCHAR(256) '@DomainName',
			BrowserName VARCHAR(256) '@BrowserName',
			Platform VARCHAR(256) '@Platform',
			CountryCode VARCHAR(50) '@CountryCode',
			Duration INT '@Duration'
			)
			
	EXECUTE	sys.sp_xml_removedocument @_hdoc;


END	
GO

