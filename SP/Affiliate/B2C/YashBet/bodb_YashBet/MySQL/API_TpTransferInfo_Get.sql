/*<info serverAlias="DBYASHBET-bodb_YashBet" isFunction="0" isNested="1"></info>*/
USE Siebog;

DROP PROCEDURE IF EXISTS `API_TpTransferInfo_Get`;

DELIMITER //

CREATE DEFINER=`affiliate_api`@`%` PROCEDURE `API_TpTransferInfo_Get`(
  IN Id INT,
  IN batchCount INT
/*
    Created: 20240115@Sally
    DB: YashBet DB/Siebog
    Task: Get TpTransferInfo data
    
	Revisions:
		- 20240115@Sally: Initialize SP

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