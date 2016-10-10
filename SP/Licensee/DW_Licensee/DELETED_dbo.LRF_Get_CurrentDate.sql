SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[LRF_Get_CurrentDate]
AS
/*
    Created: 20111012@Don
    Task: Get current date
    DB: DB052.bodb_Licensee

    Revisions:
        
    Param's Explanation:

*/
SELECT CURRENT_TIMESTAMP AS CurrentDate



GO
GRANT EXECUTE ON [dbo].[LRF_Get_CurrentDate] TO [bodbLicenseeNet]
GO
GRANT VIEW DEFINITION ON [dbo].[LRF_Get_CurrentDate] TO [VNTeam]