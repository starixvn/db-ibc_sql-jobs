/*<info serverAlias="DBTXN-bodb02,DBTXNIP-IPDB,DBCUST-IPDB,DBACC-bodb02, DBAFF12BET-Affiliate_12BET" executers="" viewers="" isFunction="1" isNested="1"></info>*/
CREATE FUNCTION [dbo].[f_IP_DivideBy16]
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
	DECLARE @maxLen INT
	DECLARE @ipos INT
	DECLARE @result VARCHAR(50)
	DECLARE @CurrentValue TINYINT
	SET @maxLen = LEN(@input)
	SET @ipos   = 1
	SET @result = ''
	SET @CurrentValue = CONVERT(TINYINT, LEFT(@input,1))

	WHILE @ipos <= @maxLen
	BEGIN
		If @CurrentValue >= 16
			SELECT @result = @result + CONVERT(CHAR(1), @CurrentValue/16 ) -- divide result
				 , @CurrentValue = @CurrentValue % 16 -- left over
		Else 
		BEGIN
			SET @ipos = @ipos + 1

			IF @ipos > @maxLen -- finished compute, convert leftover to HEX and append to result
				SET @result = @result + dbo.f_IP_DecToHex(@CurrentValue)
			Else
			BEGIN -- get next value, add for next round calculation
				SET @CurrentValue = (@CurrentValue * 10) + CONVERT(TINYINT, SUBSTRING(@input, @ipos, 1))
				IF @CurrentValue < 16 AND @result <> '' SET @result = @result + '0'
			END
		END
	END

	RETURN @result
END

GO