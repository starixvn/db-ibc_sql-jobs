/*<info serverAlias="DBAGE-bodb02" executers="" viewers="" isFunction="0"></info>*/
ALTER TRIGGER [dbo].[bettrans_Settled_UPDATE] ON [dbo].[bettrans]
   AFTER UPDATE
AS 
/*
	Created: 20180622@Patrick
	Task: Get setttled ticket
	DB: DBAGE.bodb02
	
	- Revisions:
		-20210816@Helen: Apply Uncalculate Flow on DB054 for Both Single & Parlay Tickets [Redmine: #157381]
*/
BEGIN
	SET NOCOUNT ON

	INSERT INTO dbo.BetSettled_Transition(TransId,statusID,winlostdate)
	SELECT i.TransId
		, CASE WHEN i.matchid = 29 AND i.statusID = 0 THEN 0 ELSE NULL END AS statusID
		, CASE WHEN i.matchid = 29 AND i.winlostdate <> d.winlostdate THEN i.winlostdate ELSE NULL END AS winlostdate
	FROM inserted i
		inner join deleted d ON i.transid = d.transid 
	WHERE i.bettype < 19999 AND (i.statusID NOT IN (0,1,101) OR (i.statusID = 0 and d.statusID NOT IN (0,1,101) and i.matchid = 29))
	
END

GO