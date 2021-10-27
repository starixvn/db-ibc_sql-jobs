/*<info serverAlias="DBTXN-bodb02,DBTXNIP-IPDB,DBACC-bodb02" executers="" viewers="" isFunction="1" isNested=""></info>*/
CREATE FUNCTION [dbo].[f_IP_Compress]        
(        
	@input VARCHAR(45)        
)        
RETURNS TABLE        
AS  
/*
	Created: 20211007@Helen
	Task: IPV6 - [Redmine:160390]
	Database: DBTXN/bodb02,DBTXNIP-IPDB,DBACC-bodb02
	
	Revision:
		- 20211007@Helen: Support IPv6 Phase 1 - Support for 3rd party product bet tickets  [Redmine:160390]
		
	Param's Explanation:
*/
RETURN  
(  
SELECT CASE WHEN LEFT(FullForm,24) = '00000000000000000000FFFF' THEN CONVERT(varchar(16), CONVERT(binary(4), RIGHT(FullForm,8),2)) -- IPv4 was send in IPv6 format, return as IPv4   
  ELSE CONVERT(VARCHAR(16), CONVERT(binary(16), FullForm, 2)) END AS [IP] -- regular IPv6   
FROM dbo.f_IP_FullForm(@input)   
)  
GO