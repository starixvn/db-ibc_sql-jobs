/*
	Created By: Helen
	Created Date: 20151027
	Description: Scripts to maintain PT Group
	DB: DBCUST/CUSTDB

*/	

--Step 1: Pick up the top agents that have most inefficient GROUP PT settings before re-grouping process

EXEC DBA_CustSetting_DetectGroupedPTSetting @Threshold_cnt = 100
/*
Note: if only pick up agents under particular line, we can pass param @srecommend when executing sp

for example:
EXEC DBA_CustSetting_DetectGroupedPTSetting @srecommend = 2, @Threshold_cnt = 100
*/

--Step 2: Choose agents in the first step and run this command to start re-grouping process

EXEC DBA_CustSetting_GroupedPTSettingMaintenance @agentid = 1262, @Threshold = 20