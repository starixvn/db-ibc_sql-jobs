CREATE VIEW [dbo].[view_site_servergroup]
AS
/*
    Created: 20111124@Don
    Task: Get list of site and server group
    DB: DB052.bodb_Licensee

    Revisions:

*/

----- Deposit sites -----
-- OneNet
SELECT convert(int,3) SiteID, 'mansion88' SiteName, convert(int,202) ServerGrp
UNION
SELECT convert(int,7), 'dela', convert(int,206)
UNION
SELECT convert(int,9), 'mayfair', convert(int,208)
UNION
SELECT convert(int,10), 'zzun88', convert(int,209)

-- GWI
UNION
SELECT convert(int,1), '12bet', convert(int,200)
UNION
SELECT convert(int,2), 'asiabet88', convert(int,201)
UNION
SELECT convert(int,4), 'alog', convert(int,203)
UNION
SELECT convert(int,6), 'tlc', convert(int,205)
UNION
SELECT convert(int,14), 'bodog', convert(int,212)

-- Cozni
UNION
SELECT convert(int,12), 'haifa', convert(int,211)


/*
----- Credit sites -----
-- Group 1 (FDL)
UNION
SELECT convert(int,1001), 'best-odds', convert(int,101)
UNION
SELECT convert(int,1013), 'xyzbet', convert(int,107)
UNION
SELECT convert(int,1016), '611111', convert(int,115)
--UNION
--SELECT 1025, '222227', 109120
--UNION
--SELECT 1029, 'spotico', 130
UNION
SELECT convert(int,1035), 'koribc', convert(int,121)

-- Group 2
UNION
SELECT convert(int,1003), '789', convert(int,104)

-- Group 3
--UNION
--SELECT 1023, '222223', 109000
UNION
SELECT convert(int,1021), '733333', convert(int,119)

-- Group 4
--UNION
--SELECT 1024, '222225', 109110
UNION
SELECT convert(int,1020), '722222', convert(int,118)

-- Group 5
UNION
SELECT convert(int,1022), '755555', convert(int,120)

-- Group 6
UNION
SELECT convert(int,1011), 'indo', convert(int,1011)
*/



GO
GRANT SELECT ON [dbo].[view_site_servergroup] TO [vnteam]
GO
GRANT VIEW DEFINITION ON [dbo].[view_site_servergroup] TO [vnteam]