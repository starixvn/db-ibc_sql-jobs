/*<info serverAlias="DBTXN-bodb02,DBTXNIP-IPDB,DBEXT-bodb02,DBAGE-bodb02,DBACC-bodb02" selecters="bodbDownlineNet,bodbDownlineNetView,bodbAdminNet,bodbLicenseeNet" viewers="" isFunction="1" isNested=""></info>*/
CREATE FUNCTION [dbo].[f_IP_Decompress]  
(  
	@input VARCHAR(16)  
)  
RETURNS TABLE          
AS  
/*
	Created: 20211007@Helen
	Task: IPV6 - [Redmine:160390]
	Database: DBTXN/bodb02,DBTXN-IPDB,DBEXT-bodb02,DBAGE-bodb02,DBACC-bodb02
	
	Revision:
		- 20211007@Helen: Support IPv6 Phase 1 - Support for 3rd party product bet tickets  [Redmine:160390]
		
	Param's Explanation:
*/
RETURN    
(    
SELECT CASE DATALENGTH(@input) WHEN 4 THEN CONVERT(varchar(45), CONVERT(tinyint, CONVERT(binary(1), SUBSTRING(@input,1,1)))) + '.' +  
         CONVERT(varchar(45), CONVERT(tinyint, CONVERT(binary(1), SUBSTRING(@input,2,1)))) + '.' +  
         CONVERT(varchar(45), CONVERT(tinyint, CONVERT(binary(1), SUBSTRING(@input,3,1)))) + '.' +  
         CONVERT(varchar(45), CONVERT(tinyint, CONVERT(binary(1), SUBSTRING(@input,4,1))))    
      WHEN 16 THEN LOWER(  
         SUBSTRING(CONVERT(varchar(32), CONVERT(binary(16), @input), 2), 1,4) + ':' +  
         SUBSTRING(CONVERT(varchar(32), CONVERT(binary(16), @input), 2), 5,4) + ':' +  
         SUBSTRING(CONVERT(varchar(32), CONVERT(binary(16), @input), 2), 9,4) + ':' +  
         SUBSTRING(CONVERT(varchar(32), CONVERT(binary(16), @input), 2),13,4) + ':' +  
         SUBSTRING(CONVERT(varchar(32), CONVERT(binary(16), @input), 2),17,4) + ':' +  
         SUBSTRING(CONVERT(varchar(32), CONVERT(binary(16), @input), 2),21,4) + ':' +  
         SUBSTRING(CONVERT(varchar(32), CONVERT(binary(16), @input), 2),25,4) + ':' +  
         SUBSTRING(CONVERT(varchar(32), CONVERT(binary(16), @input), 2),29,4)  
         ) 
	ELSE @input END as [IP]   
)   
GO