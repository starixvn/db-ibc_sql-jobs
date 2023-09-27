USE Siebog;

DROP PROCEDURE IF EXISTS `API_LogAdminAdjustWallet_Get`;

DELIMITER //

CREATE DEFINER=`affiliate_api`@`%` PROCEDURE `API_LogAdminAdjustWallet_Get`(
  IN Id INT,
  IN batchCount INT
  /*
    Created: 20211118@Percy
    DB: Siebog
    Task: Get LogAdminAdjustWallet data
    
    Revisions:
      - 20211118@Percy: Initialize SP
      - 20230911@Sally: Enhance get data LogAdminAdjustWallet [RedmineID: #186979]

  */
)
BEGIN
	SET batchCount = IF(batchCount > 2000, 2000, batchCount);
    
	SELECT l.TransferId
		,l.TransId
        ,l.ThirdId
        ,l.TpId
        ,l.CustID
        ,l.UserName
        ,l.SiteId
        ,l.Direction
        ,l.Amount
        ,l.Memo
        ,l.Status
        ,l.CreateTime
        ,l.Operator
        ,l.Remarks
        ,c.CurrencyId
	FROM LogAdminAdjustWallet l
		INNER JOIN Customer c ON l.CustId = c.CustId
	WHERE l.TransferId BETWEEN Id + 1 AND Id + batchCount;
END

//
DELIMITER ;

GRANT EXECUTE ON PROCEDURE `API_LogAdminAdjustWallet_Get` TO 'affiliate_api'@'%';