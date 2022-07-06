/*<info serverAlias="DBTXN-bodb02,DBACC-bodb02,DBAGE-bodb02,DBBAH-bodb02,DBTP-bodb02,DBBAL-bodb02"></info>*/
CREATE TRIGGER dbo.Trgg_MBUSettings_Tracking_Del
   ON dbo.MBUSettings
   AFTER DELETE
AS 
BEGIN
	SET NOCOUNT ON

	INSERT INTO dbo.MBUSettingsHistory(VName, VValue, CreatedDateTime, ActionType)
	SELECT VName, VValue, SYSDATETIME(), 'D'
	FROM deleted

END
GO
