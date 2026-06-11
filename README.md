**Delayed File Detection — SQL Automation Report**

**Overview**

A SQL-based automation report that identifies expected daily files which have not been received within an acceptable time window. The report runs against a live file receipt log and flags delays for operational follow-up which was replacing a manual checking process that was previously done by hand.

This script is actively used in production at a business solutions firm in Johannesburg.

**Business Problem**

Operations teams rely on daily files arriving from various sources on schedule. When a file is delayed, downstream processes stall, but without an automated check, the only way to catch a delay was to manually look through logs.

This script automates that process end to end.

**How It Works**

The logic runs in five steps using SQL temp tables:
- Step 1 - Loads the list of expected files and their patterns from a configuration table
- Step 2 - Extracts recently received files from the file intake log
- Step 3 - Matches received files to expected patterns using LIKE on filename and folder path
- Step 4 - Deduplicates to keep only the most recent receipt per expected file
- Step 5 - Flags files not received within 2 days (with weekend gap handling)

**Weekend Gap Handling**

A key business logic consideration: files are not expected over weekends. Without accounting for this, any Friday file would incorrectly show as delayed every Monday morning.
The script handles this by excluding files from the delay flag if:

The last received date was a Friday, and
the current day is Sunday or Monday

**AND NOT** (
    DATEPART(WEEKDAY, mf.Last_File_Received) = 6   
  AND DATEPART(WEEKDAY, GETDATE()) IN (1, 2) 
)

**Output**
The final result set returns one row per delayed file, including:

- CellID - identifier for the file source
- Last_File_Received - when it was last seen
- Folder - source folder path
- FileNamePattern - the expected filename pattern
- ExpectedDailyId - configuration reference
- Indicator - business classification
- Author - responsible owner

**Tech Stack**
- SQL Server (SQL)
- Temp tables (#) for staged processing
- LIKE pattern matching for flexible filename detection
- DATEPART / DATEADD for date logic


**Skills Demonstrated**
- Translating a manual operational process into an automated SQL report
- Multi-step temp table logic for staged data transformation
- Business-aware date handling (weekend exclusions)
- Pattern matching across dynamic file names and folder paths
- Writing production-ready, commented SQL


Built and maintained by **Modiehi Mphuthi**
