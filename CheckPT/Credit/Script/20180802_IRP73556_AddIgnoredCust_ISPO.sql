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
VALUES  ( 1533014 , -- CustID - int
          4 , -- RoleID - tinyint
          0 , -- RuleID - smallint
          0 , -- Sporttype - smallint
          0 , -- Bettype - smallint
          1 , -- AllLine - bit
          GETDATE() , -- ModifiedDate - smalldatetime
          'Inactive'  -- Remark - varchar(500)
        )

		