/*<info serverAlias="DBLIC-bodb_licensee,DBBAL-bodb_licensee" selecters="bodbAdminNet" viewers="" isFunction="1" isNested="0"></info>*/
USE [bodb_licensee]
GO

ALTER FUNCTION [dbo].[LA_f_GetChargeInfoWithTrialTime] (@PartyIDs VARCHAR(1000)
	, @FromDate DATETIME
	, @ToDate DATETIME
	, @ProductCodes VARCHAR(1000)
	, @System VARCHAR(10) = 'OA'
	, @ExcludeTest BIT)
RETURNS @tbChargeInfo TABLE (ChargeId INT
	, PartyId INT
	, LicenseeId INT
	, IsDeposit INT
	, AffectedDate SMALLDATETIME
	, ProductId INT
	, DI_Rate MONEY
	, OW_Rate MONEY
	, PNR_Rate MONEY
	, FromDate SMALLDATETIME
	, ToDate SMALLDATETIME
	, ChargeType TINYINT
	)
AS
/*  Created: 20150618@Patrick
    Task : Get charge information for trial time but have charge rate for summary data to bettrans only
    DB: DBLIC/bodb_Licensee  
    Param's Explanation:
	Revisions:
		- 20171227@Sophia: output column ChargeType [Redmine: #82408]
		- 20180508@Harper: Change PayToSupplier term of Exchange product [RedmineID: #94281]
		- 20181003@Percy: Add chargeType = 12 for GoldDeluxe Tip [RedmineID: #70177]
		- 20210816@Sophia: add DBBAL [Redmine: #154300]

    select * FROM dbo.LA_f_GetChargeInfoWithTrialTime ('14','2016-06-01','2016-06-30','GD','OA', 0)
*/

BEGIN     
    INSERT INTO @tbChargeInfo (ChargeID , PartyID, LicenseeID, isDeposit, AffectedDate, ProductID, DI_Rate, OW_Rate, PNR_Rate, Fromdate, Todate, ChargeType)
	SELECT DISTINCT DI.ChargeID 
		, p.PartyID
		, CASE 
		 	WHEN ISNULL(pd.IsDeposit, 0) = 1
		 		THEN p.OldRefID
		 	ELSE lb.LabelID
		 	END AS LicenseeID
		, pd.IsDeposit
		, @FromDate AS AffectedDate
		, DI.ProductID
		, CASE WHEN DI.Rate = 0 THEN ISNULL(OW.Rate,0) ELSE DI.Rate END AS DI_Rate	
		, 0	 AS OW_Rate  -- not use now
		, 0	 AS PNR_Rate -- not use now
		, CASE 
		 	WHEN @FromDate <= DI.FromDate 
		 		THEN DI.FromDate
		 	ELSE @FromDate
		 	END
		, CASE 
			WHEN @ToDate >= DI.ToDate 
				THEN DI.ToDate
			ELSE @ToDate
			END
		, DI.ChargeType 
	FROM dbo.OAS_Party p WITH (NOLOCK)	
		INNER JOIN dbo.OAS_ChargeInfo DI WITH (NOLOCK) ON DI.FromParty = p.PartyID	AND DI.ChargeType IN (1, 12) AND p.PartyType = 1
		LEFT JOIN dbo.OAS_ChargeInfo OW WITH (NOLOCK) ON DI.ParentChargeID = OW.ChargeID
		LEFT JOIN dbo.OAS_PartyDetail pd WITH (NOLOCK) ON pd.PartyID = p.PartyID
		LEFT JOIN dbo.labels lb(NOLOCK) ON p.OldRefID = lb.LicenseeID
	WHERE p.PartyID IN (SELECT VAL FROM strSplit(@PartyIDs, ','))		
		AND DI.FromDate IS NULL
		AND DI.ProductID IN (SELECT CASE WHEN s.val = 'SB' THEN 0 ELSE p3.Productid	END
								FROM bodb02.dbo.strSplit(@ProductCodes, ',') s
								LEFT JOIN dbo.Product3rd p3 WITH (NOLOCK) ON s.val = p3.ProductPrefix
							)
		AND NOT EXISTS (SELECT 1 FROM dbo.OAS_Party t WITH (NOLOCK) WHERE DI.FromParty NOT IN (25, 30) AND DI.ToParty = t.PartyID AND t.PartyType = 3 AND (t.OldRefID IS NULL OR t.OldRefID IN (2, 3, 5, 6)))
	ORDER BY p.PartyID, Di.ProductID

	RETURN
END
GO