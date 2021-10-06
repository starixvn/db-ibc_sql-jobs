USE Siebog;

DROP PROCEDURE IF EXISTS `N88_Get_TpBetRecord`;

DELIMITER //

CREATE DEFINER=`affiliate_api`@`%` PROCEDURE `N88_Get_TpBetRecord`(
  IN fromDate DATETIME,
  IN toDate DATETIME,
  IN pageIndex INT,
  IN pageSize INT

  /*
    Created: 20200220@Percy
    DB: Slave DB/Siebog
    Task: Get data from TpBetRecord table
    
    Revisions:
		- 20200220@Percy: Initialize SP
		- 20210929@Percy: Add paging
        
	Param's Explanation
		fromDate, toDate: every 30 mins
		pageSize: max is 2000
  */
)

BEGIN
	DECLARE _offSet INT;
    
    SET pageSize = IF(pageSize > 2000, 2000, pageSize); -- maximum is 2000
    SET _offSet = pageIndex * pageSize;
    
    IF CAST(fromDate AS DATE) >= CAST(TIMESTAMPADD(DAY, -14, CURRENT_DATE) AS DATE) THEN
		SELECT TpId,TransId,GameType,CustId,UserName,CurrencyId,SiteId,TpUserName,TransTime,SettledTime,
			Stake,WinlostAmount,SettlementType,TicketStatus,OriginalState,TicketKey,CreateTime,ValidBet,BonusId,
			Revenue,ProgressiveBet,ProgressiveWin
		FROM `TpBetRecord` t WHERE t.SettledTime BETWEEN fromDate AND toDate
		LIMIT _offSet, pageSize;
	ELSE
		SELECT TpId,TransId,GameType,CustId,UserName,CurrencyId,SiteId,TpUserName,TransTime,SettledTime,
			Stake,WinlostAmount,SettlementType,TicketStatus,OriginalState,TicketKey,CreateTime,ValidBet,BonusId,
			Revenue,ProgressiveBet,ProgressiveWin
		FROM `TpBetRecord14` t WHERE t.SettledTime BETWEEN fromDate AND toDate
		LIMIT _offSet, pageSize;
	END IF;
END

//
DELIMITER ;

GRANT EXECUTE ON PROCEDURE `Affiliate_Wallet_Set` TO 'affiliate_api'@'%';