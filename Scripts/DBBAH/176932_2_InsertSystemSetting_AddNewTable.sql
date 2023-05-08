/*<info serverAlias="DBBAH-bodb02" executers="" viewers="" isFunction="0"></info>*/  

/*
	Created: 20220130@Louisa
    DB: DBBAH/bodb02
   
    Revisions:
		- 20220130@Louisa: Phase 2 - use Web Service to pull ticket from DBSIG to DB05/DB05BK1 [Redmine:#176932]

*/

USE bodb02
GO

---- insert flag to on/off service
BEGIN
	SET NOCOUNT ON


	----init configuration with Enable UAT and disable PROD, LastRow inserted UAT = lastrow insert PROD

	DECLARE @LastRow_PROD_Site1 VARCHAR(200)
			,@LastRow_PROD_Site2 VARCHAR(200)

	SELECT @LastRow_PROD_Site1 = VValue FROM dbo.SystemSettings WITH(NOLOCK) WHERE VName = 'BT_SiteDB01_Sync'
	SELECT @LastRow_PROD_Site2 = VValue FROM dbo.SystemSettings WITH(NOLOCK) WHERE VName = 'BT_SiteDB02_Sync'
	
	INSERT INTO bodb02.dbo.SystemSettings ( VName, VValue )
	VALUES ( @LastRow_PROD_Site1, '0' )
		 , ( @LastRow_PROD_Site2, '0' )
		 , ('BT_SiteDB01_InsStatus_UAT', '2' )
		 , ('BT_SiteDB02_InsStatus_UAT', '2' )
		 , ('BT_SiteDB01_ServiceStatus_UAT', '1' )
		 , ('BT_SiteDB02_ServiceStatus_UAT', '1' )

		 , ('BT_SiteDB01_InsStatus', '2' )
		 , ('BT_SiteDB02_InsStatus', '2' )

		 , ('BT_SiteDB01_ServiceStatus', '0' )
		 , ('BT_SiteDB02_ServiceStatus', '0' )
	

END
GO

----create table to test UAT
BEGIN
	IF NOT EXISTS (SELECT TOP 1 1 FROM bodb02.sys.objects WHERE name = 'BalanceTrigger_UAT')
	BEGIN
		CREATE TABLE BalanceTrigger_UAT
		(
			RowID			bigint			NOT NULL
			,custid			int				NOT NULL
			,transid		bigint			NOT NULL
			,bettype		smallint		NOT NULL
			,actual_stake	money			NOT NULL
			,winlost		money			NOT NULL
			,playercomm		money			NOT NULL
			,BalanceChanged	money			NOT NULL
			,NewBalance		money			NULL
			,ActionDate		datetime		NOT NULL
			,ActionID		tinyint			NULL
			,Action			varchar(200)	NOT NULL
			,BTBalance		money			NULL
			,StatusId		tinyint			NULL
			,MatchId		int				NULL
			,SettlementType	tinyint			NULL
			,awinlost		money			NULL
			,mwinlost		money			NULL
			,swinlost		money			NULL
			,comm			money			NULL
			,acomm			money			NULL
			,scomm			money			NULL
			,modds			smallmoney		NULL
			,SiteDBGroupId	smallint
			CONSTRAINT [PK_BalanceTrigger_UAT] PRIMARY KEY CLUSTERED 
			( SiteDBGroupId,RowID ASC) 
			WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [BALANCE]
		) ON [BALANCE]
	END

END
GO
 