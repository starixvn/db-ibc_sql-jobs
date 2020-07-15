USE Siebog;

DROP PROCEDURE IF EXISTS `N88_Get_TpTransferInfo`;

DELIMITER //

CREATE DEFINER=`aff_user`@`%` PROCEDURE `N88_Get_TpTransferInfo`(
  IN Id INT,
  IN batchCount INT
  /*
    Created: 20200714@Percy
    DB: Slave DB/Siebog
    Task: Get TpTransferInfo data
    
    Revisions:
      - 20200714@Percy: Initialize SP

  */
)
BEGIN
  SELECT TransferId,TransId,TpId,CustId,UserName,SiteId,Direction,Amount,Memo,Status,CreateTime,ThirdId
    FROM `TpTransferInfo`
    WHERE TransferId > Id
    LIMIT batchCount;
END

//
DELIMITER ;

GRANT EXECUTE ON PROCEDURE `N88_Get_TpTransferInfo` TO 'affiliate_api'@'%';