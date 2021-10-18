/*<info serverAlias="DBTXN-bodb02,DBTXNIP-IPDB,DBCUST-IPDB" executers="" viewers="" isFunction="1" isNested=""></info>*/
CREATE FUNCTION [dbo].[f_IP_FullForm]
(
	@input VARCHAR(45)
)	
RETURNS TABLE  
AS  
/*
	Created: 20211007@Helen
	Task: IPV6 - [Redmine:160390]
	Database: DBTXN/bodb02,DBTXN-IPDB,DBCUST-IPDB
	
	Revision:
		- 20211007@Helen: Support IPv6 Phase 1 - Support for 3rd party product bet tickets  [Redmine:160390]
		
	Param's Explanation:
*/
RETURN
(
WITH CTE_Split_v6 AS
		(
			SELECT 1 AS Id, CONVERT(INT, 0) AS Index1, 
				CHARINDEX('.', @input) haveV4,
				CASE
					WHEN CHARINDEX(':', @input) > 0 THEN -1
					ELSE 0 END AS V,
			CASE
				WHEN CHARINDEX(':', @input) > 0 THEN CHARINDEX(':', @input)
				ELSE CHARINDEX('.', @input)
				END AS Index2
			UNION ALL

			SELECT Id + 1, Index2 + LEN(':'), 
				CHARINDEX('.', @input) haveV4,
				CASE
					WHEN CHARINDEX(':', @input, Index2 + 1) > 0 THEN -1
					ELSE 0 END AS V,

				CASE
					WHEN CHARINDEX(':', @input, Index2 + 1) > 0 THEN CHARINDEX(':', @input, Index2 + 1)
					ELSE CHARINDEX('.', @input, Index2 + 1)
					END AS Index2
			FROM CTE_Split_v6
			WHERE Index2 > 0
		)
	,IP_Result AS
		(
			SELECT
				*,
				CASE
				WHEN V = -1 OR (haveV4 = 0 AND V = 0) THEN
				CASE LEN(SUBSTRING(@input, Index1, COALESCE(NULLIF(Index2, 0), LEN(@input) + 1) - Index1))
					WHEN 0 THEN ''
					WHEN 1 THEN '000'
					WHEN 2 THEN '00'
					WHEN 3 THEN '0'
					ELSE '' END + SUBSTRING(@input, Index1, COALESCE(NULLIF(Index2, 0), LEN(@input) + 1) - Index1) 
				ELSE
				CASE LEN(dbo.f_IP_StringNumberToBase16(SUBSTRING(@input, Index1, COALESCE(NULLIF(Index2, 0), LEN(@input) + 1) - Index1)))
					WHEN 0 THEN '00'
					WHEN 1 THEN '0'
					ELSE '' END + dbo.f_IP_StringNumberToBase16(SUBSTRING(@input, Index1, COALESCE(NULLIF(Index2, 0), LEN(@input) + 1) - Index1))
					
				END AS IP_segment
				,
				SUBSTRING(@input, Index1, COALESCE(NULLIF(Index2, 0), LEN(@input) + 1) - Index1) AS IPv
			FROM CTE_Split_v6
		)
	,Info AS
		(
			SELECT 
				SUM(CASE WHEN IP_Segment = '' THEN 4 ELSE LEN(IP_Segment) END) SumLen, 
				COUNT(*) totalcnt,
				MAX(haveV4) haveV4,
				MAX( CASE WHEN IP_Segment = '' THEN id ELSE -1 END ) ZeroSeg
			FROM IP_Result
		)

	SELECT ( SELECT '' + 
						CASE 
						WHEN IP_Segment = '' AND id <> info.ZeroSeg THEN '0000'
						WHEN IP_Segment = '' AND id  = info.ZeroSeg THEN REPLACE(SPACE(32 - info.SumLen + 4),' ','0')
						WHEN info.haveV4 > 0 AND info.totalcnt = 4 AND index1 = 0 THEN '00000000000000000000FFFF' + IP_segment
						ELSE IP_Segment END
					FROM IP_Result, Info
					ORDER BY id
					FOR XML PATH(''))
					 AS FullForm

)
GO