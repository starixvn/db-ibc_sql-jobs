CREATE VIEW [dbo].[view_status_list]
AS
/*
    Created: 20110621@Don
    Task: Get list of status
    DB: DB052.bodb_Licensee

    Revisions:

*/

/*SELECT 
    CASE
        WHEN (s.status = 'HALF WON') THEN 114
        WHEN (s.status = 'HALF LOSE') THEN 115
        WHEN b.status IS NOT NULL THEN b.StatusID
        ELSE -1
    END AS StatusID, 
	s.status AS StatusName,
	s.statusid AS DwStatusID
FROM
    DBDW2.bodb_Account.dbo.tbl_Status s WITH(NOLOCK) -- for production
    LEFT JOIN (
        SELECT DISTINCT TOP(30) statusid,[status]
        FROM bodb02.dbo.bettrans (NOLOCK) ) b ON s.status = b.status*/



SELECT -1 AS StatusID, 'Cancelled' AS StatusName, 16 AS DwStatusID
UNION 
SELECT -1 , 'Rejected' , 17 
UNION
SELECT 0 , 'running' , 5 
UNION 
SELECT 1 , 'waiting' , 7 
UNION
SELECT 101 , 'Reject' , 9 
UNION 
SELECT 102 , 'Void' , 10 
UNION
SELECT 103 , 'REFUND' , 14 
UNION 
SELECT 111 , 'DRAW' , 3 
UNION
SELECT 112 , 'WON' , 8 
UNION 
SELECT 113 , 'LOSE' , 4 
UNION
SELECT 114 , 'HALF WON' , 13 
UNION 
SELECT 115 , 'HALF LOSE' , 12 
UNION
SELECT 121 , 'done' , 18 
UNION 
SELECT 131 , 'Completed' , 19 
UNION
SELECT 132 , 'Approved' , 15 
UNION 
SELECT 141 , 'BALANCE' , 20 
UNION 
SELECT 142 , 'SUM' , 6 

