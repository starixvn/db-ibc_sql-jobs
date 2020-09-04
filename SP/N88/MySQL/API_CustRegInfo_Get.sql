USE Siebog;

DROP PROCEDURE IF EXISTS `API_CustRegInfo_Get`;

DELIMITER //

CREATE DEFINER=`affiliate_api`@`%` PROCEDURE `API_CustRegInfo_Get`(
  IN fromDate DATETIME
  /*
    Created: 20200818@Percy
    DB: Slave DB/Siebog
    Task: Get CustRegInfo data
    
    Revisions:
      - 20200818@Percy: Initialize SP

  */
)
BEGIN
	SET @fromDate = UNIX_TIMESTAMP(fromDate);
		
	SELECT 
		cg.CustId, 
        cg.SiteId, 
        cg.SignupUrl,
        DATE_FORMAT(CONVERT_TZ(c.RegTime, @@session.time_zone, '+00:00'), '%Y-%m-%dT%TZ') AS RegTime
	FROM
		`Customer` c
			INNER JOIN
		`CustRegInfo` cg ON c.CustId = cg.CustId
	WHERE
		c.RegTime >= @fromDate;
END

//
DELIMITER ;

GRANT EXECUTE ON PROCEDURE `API_CustRegInfo_Get` TO 'affiliate_api'@'%';