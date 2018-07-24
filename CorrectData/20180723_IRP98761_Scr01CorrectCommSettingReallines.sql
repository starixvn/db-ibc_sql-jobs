/*
	Created: Johnson
	Date: 2018-07-23
	Task: correct comm setting
	DB: DBCUST/CUSTDB
*/
--set sdiscount = 0.0025, adiscount = 0.0025 for BI8803380 on sporttype = 1, bettype = 5	
UPDATE cs
SET sDiscount = 0.0025,
	adiscount = 0.0025
FROM custsetting cs WITH(UPDLOCK,ROWLOCK)
WHERE custid = 644725
	AND sporttype = 1
	AND bettype = 5
	
--set sdiscount = 0.0025, adiscount = 0.0025, discount = 0.0025 for CI9999066,CI9999068
-- on sporttype = 1, bettype = 5	
UPDATE cs
SET sDiscount = 0.0025,
	adiscount = 0.0025,
	discount = 0.0025
FROM custsetting cs WITH(UPDLOCK,ROWLOCK)
WHERE custid IN (1635880,1635881)
	AND sporttype = 1
	AND bettype = 5	

--set discount = 0 for agent SMOQ0333
--64 rows
 SELECT 	14833304 custid	,	1	sporttype,	9999	bettype,	0.00 discount
INTO #tmp
UNION SELECT 	14833304	,	2	,	10	,	0.00
UNION SELECT 	14833304	,	3	,	10	,	0.00
UNION SELECT 	14833304	,	5	,	10	,	0.00
UNION SELECT 	14833304	,	8	,	10	,	0.00
UNION SELECT 	14833304	,	10	,	10	,	0.00
UNION SELECT 	14833304	,	11	,	10	,	0.00
UNION SELECT 	14833304	,	99	,	10	,	0.00
	
UPDATE cs
SET cs.discount = t.discount
FROM custsetting cs WITH(UPDLOCK,ROWLOCK)
	INNER JOIN #tmp t ON cs.custid = t.custid
						AND cs.sporttype = t.sporttype
						AND cs.bettype = t.bettype

--set sdiscount,adiscount to 0.0025 for BI8803380 on sporttype = 207,bettype = 1004
UPDATE cs
SET SuperDiscount = 0.0025,
	MasterDiscount = 0.0025	
FROM CustDiscount3rd_member cs WITH(UPDLOCK,ROWLOCK)
WHERE custid IN (644725)
	AND sporttype = 207
	AND bettype= 1004
	
--set sdiscount,adiscount,discount to 0.0025 for these customers
--CI9999066,CI9999068 on sporttype = 207, bettype = 1004
UPDATE cs
SET SuperDiscount = 0.0025,
	MasterDiscount = 0.0025,
	AgentDiscount = 0.0025
FROM CustDiscount3rd_member cs WITH(UPDLOCK,ROWLOCK)
WHERE custid IN (1635880,1635881)
	AND sporttype = 207
	AND bettype= 1004
	
	
--UPdate discount = 0.01 for SLAM01 on sporttype = 211 bettype =2401
UPDATE cs
SET Discount = 0.01
FROM CustDiscount3rd_Agent cs WITH(UPDLOCK,ROWLOCK)
WHERE custid = 8159050
	AND sporttype = 211
	AND bettype = 2401						