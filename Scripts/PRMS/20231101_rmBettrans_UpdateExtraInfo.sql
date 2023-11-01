/*<info serverAlias="DBRMS-bodb_RMS"></info>*/
/*	
	Created: 20231101@Cherry
	DB: DBRMS-bodb_RMS
	Task: Parlay Generator
	RedmineID: 195498

*/

USE bodb_RMS
GO

UPDATE rb
SET rb.ExtraInfo = b.ExtraInfo
FROM bodb_RMS.dbo.rmBettrans rb WITH(ROWLOCK,UPDLOCK)
	INNER JOIN bodb02.dbo.bettrans b WITH(NOLOCK) ON rb.transid = b.transid 
WHERE b.bettype = 29 AND b.betteam = N'1' AND b.currency <> 20 
	AND TRY_CAST(TRY_CAST(b.ExtraInfo AS XML).value('(/p1/@bact)[1]', 'VARCHAR(50)') AS INT) = 5
	AND rb.ExtraInfo IS NULL

GO

-- 248 rows