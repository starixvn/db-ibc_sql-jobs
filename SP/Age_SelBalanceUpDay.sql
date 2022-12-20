/*<info serverAlias="DBTXN-bodb02,DBACC-bodb02,DBAGE-bodb02,DBBAH-bodb02,DBTP-bodb02,DBBAL-bodb02" executers="bodbAdminNet,bodbExtAccNet,bodbDownlineNet,bodbDownlineNetView" viewers="" isFunction="0" isNested="1"></info>*/
ALTER PROCEDURE  [dbo].[Age_SelBalanceUpDay]	
AS	
/*
Created: 
Task : Get move bet day, balanceup day
DB: DBTXN-bodb02,DBACC-bodb02,DBAGE-bodb02,DBBAH-bodb02,DBTP-bodb02,DBBAL-bodb02
Original:

Revisions:
    - 20090311@Daniel: grant permission to [bodbAdminNet] 
    - 20090324@Thien: modify to retrieve balanceUpDay by bettype 100 and matchID 0
	- 20090730@Viet: Hardcode CustID for better performance
	- 20101224@Johnson: Apply new arrange of bettype
	- 20110713@Henry: Change to get @MoveBetsDay from match14 
	- 20210323@Patrick: Change get movebet date source [Redmine: #149927]
	- 20210816@Sophia: add DBBAL [Redmine: #154300]
	- 20211111@Sol: Split Transfer out of bettrans/Support IPv6 - and remove SP at DBBOF [RedmineID: #164301]
	- 20221216@Patrick: Balance-Up support transfer 247 [RedmineID: #173554]

Param's Explanation:
*/

SET NOCOUNT ON
BEGIN
	DECLARE @BalanceUpDay SMALLDATETIME, @MoveBetsDay SMALLDATETIME
	
	EXEC dbo.NAP_Admin_GetMovebetDate @MovebetDate = @MoveBetsDay OUTPUT
	EXEC dbo.NAP_Admin_GetBalanceUpDate @BalanceUpDate = @BalanceUpDay OUTPUT

	SELECT @BalanceUpDay AS BalanceUpDay, @MoveBetsDay AS MoveBetsDay
END

GO
