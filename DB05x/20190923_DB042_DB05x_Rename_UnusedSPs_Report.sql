/*
	Created: 20190923@Percy
	DB: DBSUM.bodb_Summary
	Task: Un-used SPs of Report - Rename SPs
*/


-- DB042.bodb02
sp_rename 'CS_Rpt_Outstanding_Headline', 'DEL_CS_Rpt_Outstanding_Headline'
go

-- DB05x.bodb02
sp_rename 'CS_Rpt_Winloss_Headline', 'DEL_CS_Rpt_Winloss_Headline'
go