DROP PROCEDURE IF EXISTS Affiliate_Wallet_Set;
DELIMITER $$
CREATE  PROCEDURE `Affiliate_Wallet_Set`(
    IN CustId INT,
    IN UserName VARCHAR(30) CHARACTER SET ASCII,
    IN SiteId INT,
    IN Amount DECIMAL(18, 2),
    IN TYPE SMALLINT,
    IN Memo VARCHAR(200),
    IN RefTransId VARCHAR(45),
    OUT AfterAmount DECIMAL(18, 4))
BEGIN
    

    SET AfterAmount = Amount;

    SELECT
        Amount + CustWallet.Balance
    INTO AfterAmount FROM
        CustWallet
    WHERE
        CustWallet.CustId = CustId
    FOR UPDATE;

    IF AfterAmount >= 0 AND CustId > 0 THEN
        SET @Direction = 2;

        IF Amount > 0 THEN
            SET @Direction = 1;
        END IF;

        SELECT NOW() INTO @Time;

        INSERT INTO FinancialLog (CustId,UserName,SiteId,`Type`,Direction,ChangeAmount,BeforeAmount,AfterAmount,Memo,RefTransId, CreateTime) VALUES
        (CustId, UserName, SiteId,`Type`, @Direction, ABS(Amount), AfterAmount - Amount, AfterAmount, Memo, RefTransId, @Time);

        UPDATE Customer AS C SET C.LastFinancialTime = @Time WHERE C.CustId = CustId;

        INSERT INTO CustWallet(CustId, SiteId, Balance) VALUE(CustId, SiteId, AfterAmount)
        ON DUPLICATE KEY
        UPDATE CustWallet.Balance = AfterAmount;
    END IF;
END $$ 
DELIMITER ; 

GRANT EXECUTE ON PROCEDURE `API_AdjustmentInfo_Get` TO 'affiliate_api'@'%';