/*<info serverAlias="DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G"></info>*/
/*
	Created: 20201111@Percy
	DB:
		DBAFFN88-Affiliate_N88
		DBAFFN8B-Affiliate_N8B
		DBAFFN8G-Affiliate_N8G
	Task: Add setting for Member Info - Updated Time

	USE Affiliate_N88
	USE Affiliate_N8B
	USE Affiliate_N8G
*/

INSERT INTO dbo.SystemSettings (SName, SValue)
VALUES ('MemberInfoLastUpdatedTime', '2020-11-11')