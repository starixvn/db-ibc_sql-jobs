/*<info serverAlias="DBTXN-bodb02,DBTXNIP-IPDB,DBCUST-IPDB,DBACC-bodb02, DBAFF12BET-Affiliate_12BET" executers="" viewers="" isFunction="1" isNested="1"></info>*/
CREATE FUNCTION [dbo].[f_IP_StringNumberToBase16]
(
	@input VARCHAR(50)
)
RETURNS VARCHAR(50)
/*
	Created: 20211007@Helen
	Task: IPV6 - [Redmine:160390]
	Database: DBTXN/bodb02,DBTXN-IPDB,DBCUST-IPDB,DBACC-bodb02
	
	Revision:
		- 20211007@Helen: Support IPv6 Phase 1 - Support for 3rd party product bet tickets  [Redmine:160390]
		- 20220929@Eddie: Add serverAlias: DBAFF12BET-Affiliate_12BET [RedmineID: #176390]
		
	Param's Explanation:
*/
BEGIN
	DECLARE @result VARCHAR(50)
	DECLARE @HexResult VARCHAR(50)
	SET @HexResult = ''

	WHILE @input <> '0' AND @input <> ''
	BEGIN
		SET @result = dbo.f_IP_DivideBy16(@input)
		SELECT @HexResult = RIGHT(@result, 1) + @HexResult
			 , @input = LEFT(@result, LEN(@result) - 1)
	END

	RETURN @HexResult
END
