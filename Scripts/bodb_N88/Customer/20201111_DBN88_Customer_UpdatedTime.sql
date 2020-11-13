/*<info serverAlias="DBN88-bodb_N88"></info>*/
USE bodb_N88
GO

ALTER TABLE dbo.Customer
	ADD UpdatedTime DATETIME CONSTRAINT DF_Customer_UpdatedTime DEFAULT (GETDATE())
GO

CREATE NONCLUSTERED INDEX IX_SiteId ON dbo.Customer (SiteId, RegTime)
	INCLUDE (UpdatedTime, IsTest, ActStatus, Status, FirstDepositDate, FirstDepositAmount)
GO