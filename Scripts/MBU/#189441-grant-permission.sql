/*<info serverAlias="DBTXN-bodb_CustomerLog" executers="" viewers="" isNested="0"></info>*/
--grant permssion to send message

GRANT RECEIVE ON [dbo].[Queue_UserLog] TO [bodbAdminNet] AS [dbo]
GO