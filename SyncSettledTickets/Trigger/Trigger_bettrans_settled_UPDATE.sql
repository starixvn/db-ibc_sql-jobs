/*<info serverAlias="DBAGE-bodb02" executers="" viewers="" isFunction="0"></info>*/
ALTER TRIGGER [dbo].[bettrans_Settled_UPDATE] ON [dbo].[bettrans]
   AFTER UPDATE
AS 
/*
	Created: 20180622@Patrick
	Task: Get setttled ticket
	DB: DBAGE.bodb02
	
	- Revisions:
*/
BEGIN
	SET NOCOUNT ON

	INSERT INTO dbo.BetSettled_Transition(TransId)
	SELECT TransId 
	FROM inserted
	WHERE bettype < 19999 AND statusID NOT IN (0,1,101)
END


GO