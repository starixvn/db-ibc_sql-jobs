USE Siebog;
DROP PROCEDURE IF EXISTS `Affiliate_TransferToPlayer`;
DELIMITER //
CREATE DEFINER=`affiliate_api`@`%` PROCEDURE `Affiliate_TransferToPlayer`(
	IN SiteId INT,
    IN RefTransId VARCHAR(45),
	IN FromCustId INT,
    IN FromAmount DECIMAL(20, 4),
    IN ToCustId INT,
    IN ToAmount DECIMAL(20, 4),
    IN MaxTransferAmount DECIMAL(20, 4),
    OUT ErrCode INT
    /*
		Created: 20211010@Percy
		DB: Siebog
		Task: Get Cust Balance data
		
		Revisions:
		  - 20211010@Percy: Initialize SP
	*/
)
Affiliate_TransferToPlayer:BEGIN
	
    DECLARE Cust_Status INT;
    DECLARE TransType INT;
    DECLARE TransDesc VARCHAR(100);
    DECLARE FromUserName VARCHAR(30);
    DECLARE ToUserName VARCHAR(30);
    DECLARE AfterAmount DECIMAL(18, 4);
    DECLARE TransferedAmount DECIMAL(18, 4);
    DECLARE FromDate DATETIME;
    DECLARE ToDate DATETIME;
    
    SET FromDate = CAST(CURRENT_TIMESTAMP AS DATE);
    SET ToDate = DATE_ADD(CURRENT_TIMESTAMP, INTERVAL 1 DAY);
    SET TransType = 15; -- Affiliate transfer to Player
    SET TransDesc = 'Affiliate transfer to Player';
    
    -- Validation FromCustId
    SELECT Status, UserName INTO Cust_Status, FromUserName FROM Customer WHERE CustId = FromCustId;
    
    IF Cust_Status IS NULL THEN
		SET ErrCode = 101; -- This Payment Account does not exists
        LEAVE Affiliate_TransferToPlayer;
	ELSEIF Cust_Status <> 1 THEN -- running = 1
		SET ErrCode = 103; -- This Payment Account is not active
        LEAVE Affiliate_TransferToPlayer;
	END IF;
    
    -- Validation ToCustId
    SET Cust_Status = NULL;
    SELECT Status, UserName INTO Cust_Status, ToUserName FROM Customer WHERE CustId = ToCustId;
    
    IF Cust_Status IS NULL THEN
		SET ErrCode = 102; -- This Player does not exists
        LEAVE Affiliate_TransferToPlayer;
	ELSEIF Cust_Status <> 1 THEN -- running = 1
		SET ErrCode = 104; -- This Player is not active
        LEAVE Affiliate_TransferToPlayer;
	END IF;
    
    -- Check enough balance
    IF NOT EXISTS (
		SELECT 1
        FROM CustWallet c
        WHERE c.CustId = FromCustId
        HAVING SUM(c.Balance) >= FromAmount
    ) THEN
		SET ErrCode = 105; -- Amount must not exceed Transfer Limit.
        LEAVE Affiliate_TransferToPlayer;
	END IF;
    
    -- Check Transfer Limit
    IF MaxTransferAmount < 100000000000 THEN -- 100000000000: Unlimited, no need check
		SELECT SUM(fa.ChangeAmount) INTO TransferedAmount
		FROM FinancialLog fa
			INNER JOIN FinancialLog fc ON fa.RefTransId = fc.RefTransId AND fa.Type = fc.Type
		WHERE fa.CustId = FromCustId AND fc.CustId = ToCustId
			AND fa.CreateTime >= FromDate AND fa.CreateTime < ToDate;
    END IF;
    
    IF FromAmount > MaxTransferAmount - IFNULL(TransferedAmount, 0) THEN
		SET ErrCode = 105; -- Amount must not exceed Transfer Limit.
        LEAVE Affiliate_TransferToPlayer;
    END IF;

    -- FromCustId: Affiliate
    SET FromAmount = -FromAmount;
	CALL Affiliate_Wallet_Set(FromCustId, FromUserName, SiteId, FromAmount, TransType, TransDesc, RefTransId, AfterAmount);
   
	-- ToCustId: Player
    CALL Affiliate_Wallet_Set(ToCustId, ToUserName, SiteId, ToAmount, TransType, TransDesc, RefTransId, AfterAmount);
END
//
DELIMITER ;
GRANT EXECUTE ON PROCEDURE `Affiliate_TransferToPlayer` TO 'affiliate_api'@'%';
