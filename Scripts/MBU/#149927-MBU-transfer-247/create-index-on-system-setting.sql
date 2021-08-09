/*<info serverAlias="DBAGE-bodb02,DBACC-bodb02,DBTP-bodb02,DBBOF-bodb02" executers="" viewers="" isFunction="0" isNested="0"></info>*/

CREATE NONCLUSTERED INDEX [IX_VName] ON [dbo].[SystemSettings]
(
	[VName] ASC
) ON [DATA]
GO
