USE Siebog;

DROP PROCEDURE IF EXISTS `N88_Get_DepositInfo`;

DELIMITER //

CREATE DEFINER=`aff_user`@`%` PROCEDURE `N88_Get_DepositInfo`(
  IN Id INT,
  IN batchCount INT
  /*
    Created: 20200714@Percy
    DB: Slave DB/Siebog
    Task: Get DepositInfo data
    
    Revisions:
      - 20200714@Percy: Initialize SP

  */
)
BEGIN
  SELECT DepositId,TransId,DepositType,CustId,UserName,CurrencyId,SiteId,DepositInfo,Amount,ActualDeposit,CreateTime,TPCreateTime,CallbackTime,FirstDeposit,ThirdId,RefId,DepositTime,Memo,PostScript,Comment,Status
    FROM `DepositInfo`
    WHERE DepositId > Id
    LIMIT batchCount;
END

//
DELIMITER ;

GRANT EXECUTE ON PROCEDURE `N88_Get_DepositInfo` TO 'affiliate_api'@'%';