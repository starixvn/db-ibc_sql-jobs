/*
	Created: 20181212@Helen
	Task: GD & Allbet - Add rules to check data consistency to exclude void tickets (GD) and detect VIP Baccarat ticket (credit) [Redmine:111567]
	DB: DBTP/bodb_Consistency
*/
USE [bodb_Consistency]
GO

SET IDENTITY_INSERT [dbo].[DBA_Rules] ON 

INSERT [dbo].[DBA_Rules] ([RuleId], [Name], [Description], [SeverityLevel]) VALUES (18, N'Check 2402 - Vip baccarat', N'bettype 2402 Vip baccarat just for deposit only', N'High')

SET IDENTITY_INSERT [dbo].[DBA_Rules] OFF

GO
-------------- TASKS ------------------------------------------------

SET IDENTITY_INSERT [dbo].[DBA_Tasks] ON 
GO
INSERT [dbo].[DBA_Tasks] ([TaskId], [RuleId], [command]) VALUES (33, 1, N'EXEC dbo.DBA_Consistency_DiscountChecking @ProductId = 211, @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT, @SampleData = @SampleData OUTPUT ')
GO
INSERT [dbo].[DBA_Tasks] ([TaskId], [RuleId], [command]) VALUES (34, 2, N'EXEC dbo.DBA_Consistency_PTChecking @ProductId = 211, @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT, @SampleData = @SampleData OUTPUT ')
GO
INSERT [dbo].[DBA_Tasks] ([TaskId], [RuleId], [command]) VALUES (35, 3, N'EXEC dbo.DBA_Consistency_StakeChecking @ProductId = 211, @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT, @SampleData = @SampleData OUTPUT ')
GO
INSERT [dbo].[DBA_Tasks] ([TaskId], [RuleId], [command]) VALUES (36, 4, N'EXEC dbo.DBA_Consistency_IPChecking @ProductId = 211, @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT, @SampleData = @SampleData OUTPUT ')
GO
INSERT [dbo].[DBA_Tasks] ([TaskId], [RuleId], [command]) VALUES (37, 5, N'EXEC dbo.DBA_Consistency_StatusChecking @ProductId = 211, @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT, @SampleData = @SampleData OUTPUT ')
GO
INSERT [dbo].[DBA_Tasks] ([TaskId], [RuleId], [command]) VALUES (38, 18, N'EXEC dbo.DBA_Consistency_SpecificRulesChecking @ProductId = 211, @Rule = ''VipBaccarat_2402'', @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT, @SampleData = @SampleData OUTPUT ')

SET IDENTITY_INSERT [dbo].[DBA_Tasks] OFF
GO


