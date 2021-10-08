/*<info serverAlias="DBTXN-bodb02,DBTXNIP-IPDB" executers="" viewers="" isFunction="1" isNested="1"></info>*/
CREATE FUNCTION [dbo].[f_IP_DecToHex]
(
	@input tinyint
)
RETURNS char(1)
/*
	Created: 20211007@Helen
	Task: IPV6 - [Redmine:160390]
	Database: DBTXN/bodb02,DBTXN-IPDB
	
	Revision:
		- 20211007@Helen: Support IPv6 Phase 1 - Support for 3rd party product bet tickets  [Redmine:160390]
		
	Param's Explanation:
*/
BEGIN
	RETURN CASE @input
		WHEN 15 THEN 'F'
		WHEN 14 THEN 'E'
		WHEN 13 THEN 'D'
		WHEN 12 THEN 'C'
		WHEN 11 THEN 'B'
		WHEN 10 THEN 'A'
		ELSE CONVERT(char(1), @input)
		END
END
GO