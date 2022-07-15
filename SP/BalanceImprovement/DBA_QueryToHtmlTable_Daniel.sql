/*<info serverAlias="DBTXN-bodb02" executers="" viewers="" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[DBA_QueryToHtmlTable_Daniel] 
(
  @query nvarchar(MAX), --A query to turn into HTML format. It should not include an ORDER BY clause.
  @orderBy nvarchar(MAX) = NULL, --An optional ORDER BY clause. It should contain the words 'ORDER BY'.
  @html nvarchar(MAX) = NULL OUTPUT --The HTML output of the procedure.
)
AS
/*
	Task: Get HTML string for formatted table from result set of a query
	Created: 20150604@Daniel
	Original: 
	Location: DBTXN.bodb02

	Revision: 
		- 20220712@Daniel: Avoid SELECT ... INTO #TempTable

*/

BEGIN   
  SET NOCOUNT ON;

  IF @orderBy IS NULL BEGIN
    SET @orderBy = ''  
  END

  SET @orderBy = REPLACE(@orderBy, '''', '''''');
  SET @query = REPLACE(@query, '''', '''''');

  DECLARE @realQuery nvarchar(MAX) = '
    DECLARE @headerRow nvarchar(MAX);
    DECLARE @cols nvarchar(MAX);    

    SELECT @cols = COALESCE(@cols + '', '''''''', '', '''') + ''['' + name + ''] AS ''''td''''''
	FROM sys.dm_exec_describe_first_result_set(''' + @query + ''', NULL, NULL);

    SET @cols = ''SET @html = CAST(( SELECT '' + @cols + '' FROM (' + @query + ') AA ' + @orderBy + ' FOR XML PATH(''''tr''''), ELEMENTS XSINIL) AS nvarchar(max))''    

    EXEC sys.sp_executesql @cols, N''@html nvarchar(MAX) OUTPUT'', @html=@html OUTPUT

    SELECT @headerRow = COALESCE(@headerRow + '''', '''') + ''<th>'' + name + ''</th>'' 
    FROM sys.dm_exec_describe_first_result_set(''' + @query + ''', NULL, NULL);

    SET @headerRow = ''<tr>'' + @headerRow + ''</tr>'';

    SET @html = ''<table border="1">'' + @headerRow + @html + ''</table>'';    
    ';

  EXEC sys.sp_executesql @realQuery, N'@html nvarchar(MAX) OUTPUT', @html=@html OUTPUT
END