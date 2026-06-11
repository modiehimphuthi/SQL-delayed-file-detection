-- ============================================================
-- Script:   Delayed File Detection Report
-- Author:   Modiehi Mphuthi
-- Purpose:  Identifies expected daily files that have not been
--           received within the acceptable window, flagging
--           them for follow-up. Accounts for weekend gaps to
--           avoid false positives on Mondays.
-- ============================================================


-- ============================================================
-- STEP 1: Load expected file patterns from configuration table
-- ============================================================
SELECT
    LTRIM(RTRIM(REPLACE(FileName, '*', '%'))) AS FileNamePattern,
    CellID,
    Folder,
    AllocatedTable,
    Indicator,
    Author,
    ExpectedDailyId
INTO #ExpectedPatterns
FROM Expected_File_Config
WHERE ActiveStatus = 'Active'
  AND ExpectedDailyId IS NOT NULL
  AND ExpectedDailyId <> 0;


-- ============================================================
-- STEP 2: Extract recently received files from the intake path
-- ============================================================
SELECT
    ReceivedAt,
    RIGHT(SourcePath, CHARINDEX('\', REVERSE(SourcePath)) - 1) AS FileName,
    SourcePath
INTO #ReceivedFiles
FROM File_Receipt_Log
WHERE SourcePath LIKE '%\Input\%'
  AND ReceivedAt > DATEADD(DAY, -90, GETDATE());


-- ============================================================
-- STEP 3: Match received files to expected patterns
--         Uses LIKE matching on filename and folder path
-- ============================================================
SELECT
    a.CellID,
    a.Folder,
    a.FileNamePattern,
    b.FileName,
    b.ReceivedAt,
    a.ExpectedDailyId,
    a.Indicator,
    a.Author
INTO #MatchedFilesRaw
FROM #ExpectedPatterns a
LEFT JOIN #ReceivedFiles b
    ON RTRIM(b.FileName) LIKE RTRIM(a.FileNamePattern)
    AND b.SourcePath LIKE '%' + a.Folder + '%';


-- ============================================================
-- STEP 4: Deduplicate — keep only the most recent receipt
--         per expected file
-- ============================================================
SELECT
    CellID,
    Folder,
    FileNamePattern,
    MAX(ReceivedAt) AS Last_File_Received,
    ExpectedDailyId,
    Indicator,
    Author
INTO #MatchedFiles
FROM #MatchedFilesRaw
GROUP BY CellID, Folder, FileNamePattern, ExpectedDailyId, Indicator, Author;


-- ============================================================
-- STEP 5: Flag delayed files
--
-- A file is considered delayed if:
--   - It was last received more than 2 days ago
--
-- Exception — weekend gap handling:
--   - If the last file arrived on a Friday and today is
--     Sunday or Monday, it is NOT flagged as delayed.
--     This prevents false positives caused by the weekend.
-- ============================================================
SELECT
    mf.CellID,
    mf.Last_File_Received,
    mf.Folder,
    mf.FileNamePattern,
    mf.ExpectedDailyId,
    mf.Indicator,
    mf.Author
FROM #MatchedFiles mf
WHERE
    mf.Last_File_Received < DATEADD(DAY, -2, CAST(GETDATE() AS DATE))
    AND NOT (
        DATEPART(WEEKDAY, mf.Last_File_Received) = 6      -- last received on Friday
        AND DATEPART(WEEKDAY, GETDATE()) IN (1, 2)         -- and today is Sunday or Monday
    )
ORDER BY CellID ASC;


-- ============================================================
-- Cleanup (run manually if needed)
-- ============================================================
-- DROP TABLE #ExpectedPatterns;
-- DROP TABLE #ReceivedFiles;
-- DROP TABLE #MatchedFilesRaw;
-- DROP TABLE #MatchedFiles;
