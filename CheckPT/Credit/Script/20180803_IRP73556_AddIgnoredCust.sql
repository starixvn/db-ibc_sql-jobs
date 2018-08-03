/*
	Created: 20180802@Elodie
	Task: Add ISPO into IgnoredCust
	DB: DBCHECK.CheckResultDB  
*/

USE CheckResultDB
GO

INSERT INTO dbo.IgnoredCust
        ( CustID ,
          RoleID ,
          RuleID ,
          Sporttype ,
          Bettype ,
          AllLine ,
          ModifiedDate ,
          Remark
        )
VALUES  ( 11237 , -- CustID - int
          2 , -- RoleID - tinyint
          0 , -- RuleID - smallint
          0 , -- Sporttype - smallint
          0 , -- Bettype - smallint
          0 , -- AllLine - bit
          GETDATE() , -- ModifiedDate - smalldatetime
          'Internal Account'  -- Remark - varchar(500)
        )

INSERT INTO dbo.IgnoredCust
        ( CustID ,
          RoleID ,
          RuleID ,
          Sporttype ,
          Bettype ,
          AllLine ,
          ModifiedDate ,
          Remark
        )
VALUES  ( 10063686 , -- CustID - int
          4 , -- RoleID - tinyint
          0 , -- RuleID - smallint
          0 , -- Sporttype - smallint
          0 , -- Bettype - smallint
          0 , -- AllLine - bit
          GETDATE() , -- ModifiedDate - smalldatetime
          'Internal Account'  -- Remark - varchar(500)
        )

INSERT INTO dbo.IgnoredCust
        ( CustID ,
          RoleID ,
          RuleID ,
          Sporttype ,
          Bettype ,
          AllLine ,
          ModifiedDate ,
          Remark
        )
VALUES  ( 14737513 , -- CustID - int
          2 , -- RoleID - tinyint
          0 , -- RuleID - smallint
          0 , -- Sporttype - smallint
          0 , -- Bettype - smallint
          0 , -- AllLine - bit
          GETDATE() , -- ModifiedDate - smalldatetime
          'Internal Account'  -- Remark - varchar(500)
        )

INSERT INTO dbo.IgnoredCust
        ( CustID ,
          RoleID ,
          RuleID ,
          Sporttype ,
          Bettype ,
          AllLine ,
          ModifiedDate ,
          Remark
        )
VALUES  ( 27471636 , -- CustID - int
          1 , -- RoleID - tinyint
          0 , -- RuleID - smallint
          0 , -- Sporttype - smallint
          0 , -- Bettype - smallint
          0 , -- AllLine - bit
          GETDATE() , -- ModifiedDate - smalldatetime
          'Inactive'  -- Remark - varchar(500)
        )

		