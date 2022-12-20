/*<info serverAlias="DBTXN-bodb02,DBACC-bodb02,DBAGE-bodb02,DBBAH-bodb02,DBTP-bodb02,DBBAL-bodb02"></info>*/
ALTER TRIGGER dbo.Trgg_MBUSettings_Tracking_Ins
   ON dbo.MBUSettings
   AFTER INSERT
AS 
BEGIN
	SET NOCOUNT ON

	INSERT INTO dbo.MBUSettingsHistory(VName, VValue, CreatedDateTime, ActionType)
	SELECT VName, VValue, SYSDATETIME(), 'I'
	FROM inserted

END
GO
