/*<info serverAlias="DB042-bodb02" executers="" viewers="" isFunction="1" isNested="0"></info>*/
ALTER FUNCTION  [dbo].[f_age_settled_ticket_exclued_bettype]() 
RETURNS TABLE
AS
 /*
	Created	: 20180627@Patrick
	Task	: Sync settled ticket
	DB		: DB042.bodb02
	Revisions: 
		- 20180906@Sophia: Add Poker Games [Redmine : #93050]
		- 20180924@Sophia: add more bettype of Macau Games by remove hardcode bettype and use SportBettypeMatrix [Redmind: #100793]
		- 20180924@Sophia: revise code, exclude SB only [Redmind: #100793]
*/

RETURN (
	SELECT DISTINCT Bettype 
	FROM SportBettypeMatrix WITH (NOLOCK) 
	WHERE PRODUCTID NOT IN (1)
)
GO
