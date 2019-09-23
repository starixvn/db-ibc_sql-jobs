/*<info serverAlias="DBTXN-bodb02" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Task_Control_TicketVoiding_RoutineTasks]
(
	@ExecutedType TINYINT = 1
)
AS
/*
	Created: 20190906@Lukas
	Task: routine task after void/recover tickets in bet14 - control the flow of task execution
	DB: DBTXN.bodb02

	Revisions:
		- 20190906@Lukas: Initialize SP [RedmineID: #115377]
*/
BEGIN
	-- check if have failed or uncompleted running steps
	IF EXISTS (SELECT TOP 1 1 FROM TicketVoiding_RoutineTasks WITH(NOLOCK) WHERE Status IN (1,3) )
	BEGIN
		RAISERROR ('uncompleted steps found, please help check!',16,1)
		RETURN
	END
	---most of time will have nothing to do
	IF NOT EXISTS (SELECT TOP 1 1 FROM TicketVoiding_RoutineTasks WITH(NOLOCK) WHERE Status = 0 )
	BEGIN
		RETURN
	END

	DECLARE @stepNo TINYINT,	
			@RequestID INT,
			@ExecuteType TINYINT,
			@AffectedList VARCHAR(MAX),
			@errmsg VARCHAR(1000) = '',
			@result TINYINT = 0

	IF @ExecutedType = 1
	BEGIN
		WHILE NOT EXISTS (SELECT TOP 1 1 FROM TicketVoiding_RoutineTasks WITH(NOLOCK) WHERE Status IN (1,3) AND ExecuteType = 1 )
		BEGIN
			--- pick step which type = 1 to execute
			SELECT TOP(1) @stepNo = StepNo, @AffectedList = AffectedList, @ExecuteType = ExecuteType, @RequestID = RequestID	
			FROM TicketVoiding_RoutineTasks t WITH(NOLOCK)
			WHERE ExecuteType = 1 
				AND Status = 0
			ORDER BY RequestID, StepNo
			IF @@ROWCOUNT = 0
				BREAK; 
			
			--- prepare for runing
			UPDATE TicketVoiding_RoutineTasks
			SET Status = 1,
				ExecutedDate = GETDATE()
			WHERE RequestID = @RequestID AND StepNo = @stepNo
				AND status = 0
			IF @@ROWCOUNT > 0
			BEGIN
				SELECT @result = 2, @errmsg = '' --- default is successfully
				BEGIN TRY
					EXECUTE Task_ReadyToGo_TicketVoiding_RoutineTasks @stepNo = @stepNo, @AffectedList = @AffectedList, @ExecuteType = @ExecuteType
				END TRY
				BEGIN CATCH
					SELECT @errmsg = ERROR_MESSAGE(), @result = 3
				END CATCH
			END
			--- set this stepno is done with success 
			UPDATE TicketVoiding_RoutineTasks
			SET Status = @result,
				remark = @errmsg,
				Duration = DATEDIFF(SECOND,ExecutedDate,GETDATE())
			WHERE RequestID = @RequestID AND StepNo = @stepNo
				--AND status = 1 
			-----lukas: temprarily stop to test & debug at local, will remove when it's done.
			--break
		END
	END
	IF @ExecutedType = 2
	BEGIN
		---- check the allowed time to execute
		IF NOT EXISTS (SELECT TOP 1 1 FROM TicketVoiding_RoutineTasks WITH(NOLOCK) WHERE Status = 0 AND ExecuteType = 2 AND CreatedDate < CONVERT(VARCHAR, GETDATE(), 23) )
			RETURN

		SELECT @stepNo = 0
		-- if no instantly waiting tasks & no uncompleted daily tasks then it's ready to go
		WHILE NOT EXISTS (SELECT TOP 1 1 FROM TicketVoiding_RoutineTasks WITH(NOLOCK) WHERE Status = 0 AND ExecuteType = 1 ) --- type = 1 get higher priority
			AND NOT EXISTS (SELECT TOP 1 1 FROM TicketVoiding_RoutineTasks WITH(NOLOCK) WHERE Status IN (1,3) AND ExecuteType = 2 )
		BEGIN
			--- run by group together
			SELECT TOP(1) @stepNo = StepNo, @ExecuteType = ExecuteType 	
			FROM TicketVoiding_RoutineTasks t WITH(NOLOCK)
			WHERE ExecuteType = 2 
				AND Status = 0
				AND CreatedDate < CONVERT(VARCHAR, GETDATE(), 23)
			GROUP BY StepNo,ExecuteType
			ORDER BY StepNo
			IF @@ROWCOUNT = 0
				BREAK;

			--- prepare for runing
			UPDATE TicketVoiding_RoutineTasks
			SET Status = 1,
				ExecutedDate = GETDATE()
			WHERE ExecuteType = 2 AND StepNo = @stepNo
				AND CreatedDate < CONVERT(VARCHAR, GETDATE(), 23)
				AND status = 0
			IF @@ROWCOUNT > 0
			BEGIN
				SELECT @result = 2, @errmsg = '' --- default is successfully
				BEGIN TRY
					EXECUTE Task_ReadyToGo_TicketVoiding_RoutineTasks @stepNo = @stepNo, @ExecuteType = @ExecuteType
				END TRY
				BEGIN CATCH
					SELECT @errmsg = ERROR_MESSAGE(), @result = 3
				END CATCH
			END

			--- set this stepno is done with success 
			UPDATE TicketVoiding_RoutineTasks
			SET Status = @result,
				remark = @errmsg,
				Duration = DATEDIFF(SECOND,ExecutedDate,GETDATE())
			WHERE ExecuteType = 2 AND StepNo = @stepNo
				AND CreatedDate < CONVERT(VARCHAR, GETDATE(), 23)
				AND status = 1
		END
	END
END
GO