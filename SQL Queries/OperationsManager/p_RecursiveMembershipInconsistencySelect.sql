	--Create the detection sproc: 
	USE [OperationsManager] 
	GO 
	/****** Object:  StoredProcedure [dbo].[p_RecursiveMembershipInconsistencySelect]    Script Date: 8/30/2017 6:35:07 PM ******/ 
	SET ANSI_NULLS ON 
	GO 
	SET QUOTED_IDENTIFIER ON 
	GO 
	CREATE PROCEDURE [dbo].[p_RecursiveMembershipInconsistencySelect] 
	AS 
	BEGIN 
	    DECLARE @LastErr int; 
	    DECLARE @RowCount int; 
	    DECLARE @Depth int; 
	    DECLARE @RelationshipTypeId uniqueidentifier = dbo.fn_ManagedTypeId_SystemContainment(); 
	    CREATE TABLE #RecursiveMembershipTemp ( 
	        [ContainerEntityId] uniqueidentifier NOT NULL, 
	        [ContainedEntityId] uniqueidentifier NOT NULL, 
	        [Depth] [int] NOT NULL 
	    ); 
	    SET @LastErr = @@ERROR; 
	    IF @LastErr <> 0 
	        GOTO Err; 
	    CREATE TABLE #RecursiveMembership ( 
	        [ContainerEntityId] uniqueidentifier NOT NULL, 
	        [ContainedEntityId] uniqueidentifier NOT NULL, 
	        [Depth] [int] NOT NULL, 
	        [PathCount] [int] NOT NULL 
	    ); 
	    SET @LastErr = @@ERROR; 
	    IF @LastErr <> 0 
	        GOTO Err; 
	    BEGIN TRANSACTION; 
	    -- ddp lock 
	    UPDATE [dbo].[DiscoverySource] 
	    SET [TimeGeneratedOfLastSnapshot] = [TimeGeneratedOfLastSnapshot] 
	    WHERE [DiscoverySourceId] = '85AB926D-6E0F-4B36-A951-77CCD4399681'; 
	    SET @LastErr = @@ERROR; 
	    IF @LastErr <> 0 
	        GOTO Err; 
	    SET @Depth = 0; 
	    INSERT INTO #RecursiveMembershipTemp 
	        ([ContainerEntityId], [ContainedEntityId], [Depth]) 
	    SELECT  
	        [BaseManagedEntityId], [BaseManagedEntityId], @Depth 
	    FROM dbo.[BaseManagedEntity] 
	    WHERE IsDeleted = 0; 
	    SELECT @LastErr = @@ERROR, @RowCount = @@ROWCOUNT; 
	    IF @LastErr <> 0 
	        GOTO Err; 
	    WHILE (@RowCount > 0)     
	    BEGIN        
	        INSERT INTO #RecursiveMembershipTemp 
	           ([ContainerEntityId], [ContainedEntityId], [Depth]) 
	        SELECT  
	            RR.[ContainerEntityId], R.[TargetEntityId], @Depth + 1 
	        -- Filtering by RelationshipTypes that derive from 'Containment' 
	        FROM  dbo.[RelationshipType] AS RT 
	        INNER JOIN dbo.fn_DerivedRelationshipTypes(@RelationshipTypeId) DRT 
	            ON DRT.[DerivedRelationshipTypeId] = RT.[RelationshipTypeId] 
	        INNER JOIN dbo.[Relationship] AS R 
	            ON RT.[RelationshipTypeId] = R.[RelationshipTypeId] 
	            AND R.[IsDeleted] = 0 
	        INNER JOIN #RecursiveMembershipTemp AS RR 
	            ON RR.[ContainedEntityId] = R.[SourceEntityId] 
	            AND RR.Depth = @Depth; 
	        SELECT @LastErr = @@ERROR, @RowCount = @@ROWCOUNT; 
	       IF @LastErr <> 0 
	            GOTO Err; 
	        SET @Depth = @Depth + 1; 
	    END 
	    INSERT INTO #RecursiveMembership 
	            ([ContainerEntityId], [ContainedEntityId], [Depth], [PathCount]) 
	    SELECT  
	        [ContainerEntityId], [ContainedEntityId], MIN(Depth), COUNT(1) 
	    FROM #RecursiveMembershipTemp 
	    GROUP BY [ContainerEntityId], [ContainedEntityId]; 
	    SET @LastErr = @@ERROR; 
	    IF @LastErr <> 0 
	        GOTO Err; 
	    -- Incorrect entries in RecursiveMembership 
	    SELECT R.[ContainerEntityId], R.[ContainedEntityId], R.[Depth], R.[PathCount], R.[LastModified] 
	    FROM dbo.[RecursiveMembership] R 
	    LEFT OUTER JOIN #RecursiveMembership TMP 
	        ON R.[ContainedEntityId] = TMP.[ContainedEntityId] 
	        AND R.[ContainerEntityId] = TMP.[ContainerEntityId] 
	        AND R.[PathCount] = TMP.[PathCount] 
	    WHERE TMP.[ContainedEntityId] IS NULL; 
	    -- Missing RecursiveMembership entries. 
	    SELECT S.[DisplayName] AS ContainerName, T.[DisplayName] AS ContainedName, R.[ContainerEntityId], R.[ContainedEntityId] 
	    FROM #RecursiveMembership R 
	    INNER JOIN BaseManagedEntity S 
	        on S.BaseManagedEntityId = R.ContainerEntityId 
	    INNER JOIN BaseManagedEntity T 
	        on T.BaseManagedEntityId = R.ContainedEntityId 
	    LEFT OUTER JOIN dbo.[RecursiveMembership] TMP 
	        ON R.ContainedEntityId = TMP.ContainedEntityId 
	        AND R.ContainerEntityId = TMP.ContainerEntityId 
	        AND R.PathCount = TMP.PathCount 
	    WHERE TMP.ContainedEntityId IS NULL; 
	    COMMIT TRANSACTION; 
	    DROP TABLE #RecursiveMembershipTemp; 
	    DROP TABLE #RecursiveMembership; 
	    RETURN 0; 
	Err: 
	    ROLLBACK TRANSACTION; 
	    RETURN 1; 
	END 
	GO 
