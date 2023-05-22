/*<info serverAlias="DBARC-bodb_Archive" executers="" isFunction="0" isNested="0"></info>*/
USE bodb_archive
GO
EXEC sp_rename 'RMS_ARC_rmSumwinloss_OLD_Ins', 'DEL_RMS_ARC_rmSumwinloss_OLD_Ins'
GO