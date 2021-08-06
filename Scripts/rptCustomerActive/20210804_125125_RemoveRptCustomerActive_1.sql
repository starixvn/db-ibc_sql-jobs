/*<info serverAlias="DBLIC-bodb_LicenseeReport"></info>*/
/*	
	Created: 20210804@Sophia
	DB: DBLIC-bodb_LicenseeReport
	RedmineID: Remove RptCustomerActive [redmine:125125]
 
*/
 


USE bodb02
GO
 

DROP PROC Lrf_Rpt_ActiveMember
DROP PROC Lrf_Rpt_ActiveMember_xtest
DROP PROC Lrf_Rpt_ActiveMember_xpre

USE bodb_LicenseeReport
GO

DROP TABLE rptCustomerActive