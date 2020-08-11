/*<info serverAlias="DB042-bodb02" executers="" viewers="" isFunction="1" isNested="0"></info>*/
CREATE FUNCTION  [dbo].[f_age_settled_ticket_exclued_bettype]() 
RETURNS TABLE
AS
 /*
	Created	: 20180627@Patrick
	Task	: Sync settled ticket
	DB		: DB042.bodb02
	Revisions: 
		- 20180906@Sophia: Add Poker Games [Redmine : #93050]
		- 20180924@Sophia: add more bettype of Macau Games by remove hardcode bettype and use SportBettypeMatrix [Redmind: #100793]
		- 20191127@Patrick: Setup sync status ticket on DB052 -> DB054 - [Redmine: #124482]
		- 20200811@Sophia: Add PG Sooft and old products [Redmine: #137767]
*/

RETURN (
	SELECT DISTINCT Bettype 
	FROM SportBettypeMatrix WITH (NOLOCK) 
	WHERE PRODUCTID IN (6,8,11,12,15,17,21,22,23,24,28,32,33)
	)
GO
