USE Siebog;

DROP PROCEDURE IF EXISTS `API_TpTransferInfo_Get`;

DELIMITER //

CREATE DEFINER=`aff_user`@`%` PROCEDURE `API_TpTransferInfo_Get`(
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

GRANT EXECUTE ON PROCEDURE `API_TpTransferInfo_Get` TO 'affiliate_api'@'%';