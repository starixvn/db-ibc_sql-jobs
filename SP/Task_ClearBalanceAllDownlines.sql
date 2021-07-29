/*<info serverAlias="DBTXN-bodb02" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Task_ClearBalanceAllDownlines]
(
	@isConfirmed BIT
)
AS
/*
	Created:
	DB: DBTXN/bodb02
	Task: Clear balance for downlines of agent
	
	Revisions: 
	- 20140925@Johnson: Add option clear balance for all members under agent and remove column isActive
	- 20150617@Daniel: Separating custDB to new server DBCUST [Redmine:#36216]		
	- 20150701@Kathy: Correct condition to break WHILE loop [Redmine:#36216]
	- 20160810@Lukas: Add finished time for each SMA customer		
	- 20200525@Sophia: Prioritize clear active account first [Redmine: #134653]
	- 20200730@Sophia: prevent duplicated transfer [Redmine: #137141]
	- 20200730@Sophia: Check UM Transfer Function [Redmine: #136992]
	- 20201007@Sophia: Hot fix - account keep waiting [Redmine: #143099]
	- 20210729@Sol: Hot fix - change table which is used in order by - [Redmine: #159245]
*/
BEGIN

	DECLARE @CustID int, @Username varchar(50), @TransferType INT
	DECLARE @Today datetime, @finishedtime datetime
	DECLARE @ErrCode int, @ErrMsg NVARCHAR(MAX), @msg VARCHAR(1000) 
	DECLARE @OLD_lasttransfer datetime
	DECLARE @CustIdList  VARCHAR(MAX), @ID INT, @t INT
	CREATE TABLE #Cust (ID INT IDENTITY (1,1), Custid INT, Status VARCHAR(20) ,TransferType TINYINT, LastTransfer DATETIME, IsTransferring BIT)

	SET @today = CURRENT_TIMESTAMP
	
	-- prepare for running
		EXEC DBCUST.custDB.dbo.Task_UpdClearBalanceList @mode = 0

	-- Get customer list
		INSERT INTO #Cust (Custid, Status, TransferType, LastTransfer, IsTransferring)
		SELECT a.custid, a.Status, a.TransferType, a.LastTransfer, a.IsTransferring 
		FROM DBCUST.custdb.dbo.Acc_ClearBalanceList a WITH(NOLOCK)
			INNER JOIN DBCUST.custdb.dbo.CustProductStatus c WITH(NOLOCK)
				ON c.CustID = a.CustID
		WHERE a.[Status] = 'waiting'
		ORDER BY c.SuspendInfo, c.CloseInfo
		
		------------------------------------------------------------------------
		--- top 20 custID which will be locked at other transfer function
		SET @t = 20 --- top 20 custID which will be locked at other transfer function
		
		SELECT TOP (@t) @CustIdList = COALESCE(@CustIdList + ',', '') +  convert(varchar(12),Custid)  
		FROM #Cust
		ORDER BY ID		
		
		---- mark flag IsTransferring = 1 for list 20 customers, other func transfer can not execute
		EXEC DBCUST.custDB.dbo.Task_UpdClearBalanceList @mode = 2, @CustIdList = @CustIdList, @IsTransferring = 1
		
		UPDATE 	#Cust 
		SET  	IsTransferring = 1
		WHERE 	Custid IN (Select Val from [f_SplitString](@CustIDList, ',')) 

		WAITFOR DELAY '00:00:05' 
		-----------------------------------------------------------------------------------

	WHILE (1 = 1)
	BEGIN
		IF (dbo.f_IsContinueClearBalance() = 0) BREAK -- control from outside (old Code)		

		SELECT TOP 1
		  @ID = ID,
		  @CustID = a.custid,
		  @TransferType = a.TransferType		
		  ,@OLD_lasttransfer = a.LastTransfer  
		FROM #Cust a
		WHERE a.[Status] = 'waiting'
			  AND a.IsTransferring = 1
		ORDER BY a.ID			

		--IF(@CustID IS NULL) BREAK -- no more to transfer
		IF @@ROWCOUNT = 0 BREAK -- no more to transfer
		
		EXEC DBCUST.custDB.dbo.Task_UpdClearBalanceList 
		  @custid = @custid,
		  @Status = 'running',
		  @LastTransfer = @today,
		  @msg = ''
		  
		UPDATE  #Cust
		SET 	Status = 'running',
				LastTransfer = @today
		WHERE   Custid = @CustID	
  					
		SELECT @Username = username 
		FROM custdb.dbo.custInfo WITH(NOLOCK)
		WHERE custid = @CustID
			AND roleid IN (2,3,4)
			
		IF @@ROWCOUNT = 0
		BEGIN
		
		    EXEC DBCUST.custDB.dbo.Task_UpdClearBalanceList 
			 @custid = @custid,
			 @Status = 'failed',
			 @msg = 'InValid CustID!!!',
			 @IsTransferring = 0
			 
			UPDATE  #Cust
			SET 	Status = 'failed',
					IsTransferring = 0
			WHERE   Custid = @CustID			
			
		END
		ELSE
		BEGIN
		
			SELECT @ErrCode = 0, @ErrMsg = ''
			
			IF @TransferType = 1-- Clear All balance of members
			BEGIN
				EXEC Acc_BettransInsTransferAllMembers @AgentName =@Username
					,@UserID = 862400 -- starix2
					,@IsJob = 1
					,@ErrMsg = @ErrMsg OUTPUT 
					,@ErrCode = @ErrCode OUTPUT
				
				SET @finishedtime = GETDATE()
				
				IF @ErrCode <> 0
				BEGIN
					SET @msg = LEFT(@ErrMsg, 1000)						
					EXEC DBCUST.custDB.dbo.Task_UpdClearBalanceList 
						@custid = @custid,
						@Status = 'failed',
						@LastTransfer = @finishedtime,
						@msg = @msg, -- just in case more than 1000 characters	
						@IsTransferring = 0
						
					UPDATE  #Cust
					SET 	Status = 'failed',
							LastTransfer = @finishedtime,
							IsTransferring = 0
					WHERE   Custid = @CustID				
					
				END
				ELSE  --- successful
				BEGIN				
					EXEC DBCUST.custDB.dbo.Task_UpdClearBalanceList 				   
						@custid = @custid,
						@Status = 'completed',
						@LastTransfer = @finishedtime,
						@IsTransferring = 0					
						
					UPDATE  #Cust
					SET 	Status = 'completed',
							LastTransfer = @finishedtime,
							IsTransferring = 0
					WHERE   Custid = @CustID
				END	
					
			END
			ELSE IF @TransferType = 2
			BEGIN
				EXEC [dbo].[Acc_ClearBalanceAllDownlines] @AgentName =@Username
					,@UserID = 862400 -- starix2
					,@IsJob = 1
					,@ErrMsg = @ErrMsg OUTPUT 
					,@ErrCode = @ErrCode OUTPUT
					
				SET @finishedtime = GETDATE()
				IF @ErrCode = 1 -- server is busy, rollback lasttransfer value, wait 5 seconds and continue
				BEGIN
				
					EXEC DBCUST.custDB.dbo.Task_UpdClearBalanceList 
						@custid = @custid,
						@Status = 'waiting',
						@LastTransfer = @OLD_lasttransfer		
						
					UPDATE  #Cust
					SET 	Status = 'waiting',
							LastTransfer = @OLD_lasttransfer						
					WHERE   Custid = @CustID
					
					WAITFOR DELAY '00:00:05'
					CONTINUE
				END
				ELSE IF @ErrCode <> 0
				BEGIN
					SET @msg = LEFT(@ErrMsg, 1000)				
					
					EXEC DBCUST.custDB.dbo.Task_UpdClearBalanceList 
						@custid = @custid,
						@Status = 'failed',
						@LastTransfer = @finishedtime,
						@msg = @msg, -- just in case more than 1000 characters
						@IsTransferring = 0

					UPDATE  #Cust
					SET 	Status = 'failed',
							LastTransfer = @finishedtime,
							IsTransferring = 0
					WHERE   Custid = @CustID				    						
					
				END
				ELSE  --- successful
				BEGIN				 
					
					EXEC DBCUST.custDB.dbo.Task_UpdClearBalanceList 
						@custid = @custid,
						@Status = 'completed',
						@LastTransfer = @finishedtime,
						@IsTransferring = 0

					UPDATE  #Cust
					SET 	Status = 'completed',
							LastTransfer = @finishedtime,
							IsTransferring = 0
					WHERE   Custid = @CustID
						
				END
			END
		END
		------ Mark flag IsTransferring = 1 for the next CustID
		
			SELECT 	@CustID = CustID
			FROM 	#Cust 
			WHERE 	ID = @ID + @t
			
			IF @@ROWCOUNT <> 0
			BEGIN 		
				EXEC DBCUST.custDB.dbo.Task_UpdClearBalanceList 
					@mode = 1,
					@custid = @custid,  --- 21
					@Status = 'waiting',
					@IsTransferring = 1
					
				UPDATE  #Cust
				SET 	IsTransferring = 1
				WHERE   Custid = @CustID
			END		
		
	END
END