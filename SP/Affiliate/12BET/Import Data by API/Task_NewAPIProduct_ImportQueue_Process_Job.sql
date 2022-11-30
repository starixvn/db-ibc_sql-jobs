/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Task_NewAPIProduct_ImportQueue_Process_Job]
AS

/*
	Created: 20221118@Malcolm
	DB: DBAFF12BET.Affiliate_12BET
	Task: Import Data Job - Parse Json data from Queue

	Revisions:
		- 20221118@Malcolm: Initialize SP [RedmineID: #180311]

*/

BEGIN
	SET NOCOUNT ON

	DECLARE @Products TABLE (Id INT IDENTITY(1,1), ProductId INT, TpType INT, SubItem VARCHAR(200))
	
	INSERT INTO @Products (ProductId, TpType, SubItem)
	SELECT ProductId, TpType, SubItem FROM dbo.APIProductMappingSettings WITH (NOLOCK) 

	DECLARE @ErrCode INT, @ErrMsg NVARCHAR(4000)
	DECLARE @ErrTable TABLE (ProductId INT, ErrMsg NVARCHAR(4000))

	DECLARE @Id INT = 1, @ProductId INT = NULL, @TpType INT = NULL, @SubItem VARCHAR(200) = NULL
	SELECT  @ProductId = ProductId, @TpType = TpType, @SubItem = SubItem FROM @Products WHERE Id = @Id

	WHILE @ProductId IS NOT NULL
	BEGIN
		-- Parse data
		SELECT @ErrCode = 0, @ErrMsg = ''
		
		BEGIN TRY
			EXEC dbo.Task_NewAPIProduct_ImportQueue_Process @TpType = @TpType, @SubItem = @SubItem, @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT

			IF @ErrCode <> 0
				INSERT INTO @ErrTable (ProductId, ErrMsg)
				VALUES (@ProductId, @ErrMsg)
		END TRY
		BEGIN CATCH
			INSERT INTO @ErrTable (ProductId, ErrMsg)
			VALUES (@ProductId, ERROR_MESSAGE())
		END CATCH

		SELECT @Id = @Id + 1
		SELECT @ProductId = NULL, @TpType = NULL, @SubItem = NULL
		SELECT @ProductId = ProductId, @TpType = TpType, @SubItem = SubItem FROM @Products WHERE Id = @Id
	END

	-- Send mail if have error
	DECLARE @Subject VARCHAR(1000) = '', @recipients VARCHAR(1000), @Msg NVARCHAR(MAX) = ''

	IF EXISTS (SELECT 1 FROM @ErrTable)
	BEGIN
		SELECT @Subject = 'SQL Server Job System: ''Affiliate_12BET: Generate Queue Data'' failed on ' + @@SERVERNAME

		SELECT @recipients = 'dba_local@starixvn.com'
		
		IF @@SERVERNAME IN ('DB052', 'DB053')
			SELECT @recipients = 'sophia.nguyen@starixvn.com;pontus@starixvn.com'

		SELECT @Msg = '<H3>List of products have wrong data</H3>'
						+ '<table border="1"> '
						+ '<tr><th>No.</th><th>Product</th><th>Error Message</th></tr>'
						+ CAST((SELECT	td = ROW_NUMBER() OVER(ORDER BY (SELECT NULL)), '',
										td = p.ProductName, '',
										td = e.ErrMsg, ''
								FROM @ErrTable e
									INNER JOIN dbo.Products p WITH (NOLOCK) ON e.ProductId = p.ProductID
								FOR XML PATH('tr'), TYPE 
								) AS NVARCHAR(MAX)) + N'</table>'
			
		EXEC msdb.dbo.sp_send_dbmail
			@recipients		= @recipients,
			@subject		= @subject,
			@body			= @Msg,
			@body_format	= 'HTML'
	END
END
GO