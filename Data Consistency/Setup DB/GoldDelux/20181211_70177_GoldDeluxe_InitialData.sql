/*
	Created: 20181212@Helen
	Task: Setup schedule for GoldDeluxe [Redmine:70177]
	DB: DBTP/bodb_Consistency
*/
USE [bodb_Consistency]
GO

DELETE [dbo].[DBA_TASKS] WHERE TaskId >= 12
DELETE [dbo].[DBA_Rules] WHERE RuleId >= 12

GO

SET IDENTITY_INSERT [dbo].[DBA_Rules] ON 
INSERT [dbo].[DBA_Rules] ([RuleId], [Name], [Description], [SeverityLevel]) VALUES (12, N'Check oddsspread value for GoldDeluxe', N'oddsspread >= 0 AND WHEN statusid in (101,102,103,111) THEN oddsspread = 0
WHEN statusid in (112,113) THEN oddsspread <= stake', N'High')
SET IDENTITY_INSERT [dbo].[DBA_Rules] OFF

GO
-------------- TASKS ------------------------------------------------

SET IDENTITY_INSERT [dbo].[DBA_Tasks] ON 
GO
INSERT [dbo].[DBA_Tasks] ([TaskId], [RuleId], [command]) VALUES (12, 1, N'EXEC dbo.DBA_Consistency_DiscountChecking @ProductId = 255, @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT, @SampleData = @SampleData OUTPUT ')
GO
INSERT [dbo].[DBA_Tasks] ([TaskId], [RuleId], [command]) VALUES (13, 2, N'EXEC dbo.DBA_Consistency_PTChecking @ProductId = 255, @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT, @SampleData = @SampleData OUTPUT ')
GO
INSERT [dbo].[DBA_Tasks] ([TaskId], [RuleId], [command]) VALUES (14, 3, N'EXEC dbo.DBA_Consistency_StakeChecking @ProductId = 255, @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT, @SampleData = @SampleData OUTPUT ')
GO
INSERT [dbo].[DBA_Tasks] ([TaskId], [RuleId], [command]) VALUES (15, 5, N'EXEC dbo.DBA_Consistency_StatusChecking @ProductId = 255, @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT, @SampleData = @SampleData OUTPUT ')
GO
INSERT [dbo].[DBA_Tasks] ([TaskId], [RuleId], [command]) VALUES (16, 12, N'EXEC dbo.DBA_Consistency_SpecificRulesChecking @ProductId = 255, @Rule = ''oddsspread'', @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT, @SampleData = @SampleData OUTPUT ')
GO
SET IDENTITY_INSERT [dbo].[DBA_Tasks] OFF
GO


