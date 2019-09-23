USE CheckResultDB
GO
/*  
	Created: 20180404@Winnie
	Task: Check PT
	DB: DBCHECK/CheckResultDB  
*/ 
DELETE FROM Rule_Credit WHERE RuleId BETWEEN 43 AND 70

INSERT INTO Rule_Credit(RuleId,RuleName,ModifiedDate)
SELECT 44,'S4 <> M3',GETDATE()

INSERT INTO Rule_Credit(RuleId,RuleName,ModifiedDate)
SELECT 45,'M3 <> A2',GETDATE()

INSERT INTO Rule_Credit(RuleId,RuleName,ModifiedDate)
SELECT 46,'A1 <>A2',GETDATE()

INSERT INTO Rule_Credit(RuleId,RuleName,ModifiedDate)
SELECT 48,'A1 <>0.85 OR M1<>0 OR S1<>0 (sportsbook) AND A1 <>0.88 OR M1<>0 OR S1<>0 (NG)',GETDATE()

INSERT INTO Rule_Credit(RuleId,RuleName,ModifiedDate)
SELECT 49,'A1 <>0.85 OR M1<>0 OR S1<>0 (Allbet Athena) AND A1 <>0.88 OR M1<>0 OR S1<>0 (VS,VS2)',GETDATE()

INSERT INTO Rule_Credit(RuleId,RuleName,ModifiedDate)
SELECT 50,'a1<>0.9 OR M1<>0 OR S1<>0 (Keno, Lotery, Fishing World Athena, PP Athena)',GETDATE()

INSERT INTO Rule_Credit(RuleId,RuleName,ModifiedDate)
SELECT 51,'a1<>0.92  OR M1<>0 OR S1<>0 (Allbet API, Fishing World API, PP API)',GETDATE()

INSERT INTO Rule_Credit(RuleId,RuleName,ModifiedDate)
SELECT 52,'a1 <> 0.93 OR M1<>0 OR S1<>0 (Macaugame)',GETDATE()

INSERT INTO Rule_Credit(RuleId,RuleName,ModifiedDate)
SELECT 53,'S1 <> 0 OR M1 <> 0 OR A1 <> 0  (BA member )',GETDATE()

INSERT INTO Rule_Credit(RuleId,RuleName,ModifiedDate)
SELECT 54,'Missing PT group for Agent',GETDATE()

INSERT INTO Rule_Credit(RuleId,RuleName,ModifiedDate)
SELECT 55,'Missing PT setting SMA',GETDATE()

INSERT INTO Rule_Credit(RuleId,RuleName,ModifiedDate)
SELECT 56,'Missing member setting mode (Dep_CustSettingMode)',GETDATE()

INSERT INTO Rule_Credit(RuleId,RuleName,ModifiedDate)
SELECT 57,'HousePT <> 1 (Cashout product ) (TradeComm table)',GETDATE()

INSERT INTO Rule_Credit(RuleId,RuleName,ModifiedDate)
SELECT 59,'Missing PT row (cashout)',GETDATE()

INSERT INTO Rule_Credit(RuleId,RuleName,ModifiedDate)
SELECT 60,'Dep_CustSettingMode.IsGroupedPT <> 1',GETDATE()

INSERT INTO Rule_Credit(RuleId,RuleName,ModifiedDate)
SELECT 61,'S2 <> 0 OR M2 <> 0 OR A2 <> 0 (Dep_CustPTGroupSetting_Member)',GETDATE()

INSERT INTO Rule_Credit(RuleId,RuleName,ModifiedDate)
SELECT 62,'Dep_CustSettingMode.IsGroupedPT <> 0',GETDATE()

INSERT INTO Rule_Credit(RuleId,RuleName,ModifiedDate)
SELECT 63,'Don''t have enough data of offer products in Dep_CustPTSetting_Member',GETDATE()

INSERT INTO Rule_Credit(RuleId,RuleName,ModifiedDate)
SELECT 64,'S1 <> S2 OR M1 <> M2 OR A1 <> A2 (Dep_CustPTSetting_Member, Dep_CustPTSetting_Agent)',GETDATE()

INSERT INTO Rule_Credit(RuleId,RuleName,ModifiedDate)
SELECT 65,'Dep_CustSettingMode.IsGroupedPT <> 0',GETDATE()

INSERT INTO Rule_Credit(RuleId,RuleName,ModifiedDate)
SELECT 66,'Don''t have enough data of offer products in Dep_CustPTSetting_Member',GETDATE()

INSERT INTO Rule_Credit(RuleId,RuleName,ModifiedDate)
SELECT 67,'S2 <> 0 OR M2 <> 0 OR A2 <> 0 (Dep_CustPTSetting_Member)',GETDATE()

INSERT INTO Rule_Credit(RuleId,RuleName,ModifiedDate)
SELECT 68,'S1 <> S2 OR M1 <> M2 OR A1 <> A2 (Dep_CustPTSetting_Member, Dep_CustPTSetting_Agent)',GETDATE()

INSERT INTO Rule_Credit(RuleId,RuleName,ModifiedDate)
SELECT 69,'Dep_CustSettingMode.IsGroupedPT <> 1',GETDATE()

INSERT INTO Rule_Credit(RuleId,RuleName,ModifiedDate)
SELECT 70,'"A2 <> 85 (Dep_CustPTGroupSetting_Member) For HAIFA: A2 <> 90.5"',GETDATE()