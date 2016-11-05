DECLARE @name VARCHAR(50) -- database name 
DECLARE @path VARCHAR(256) -- path for backup files 
DECLARE @fileName VARCHAR(256) -- filename for backup 
DECLARE @fileDate VARCHAR(20) -- used for file name

SET @path = 'D:Backup' 

SELECT @fileDate = CONVERT(VARCHAR(20),GETDATE(),112)

DECLARE db_cursor CURSOR FOR 
SELECT name 
FROM master.dbo.sysdatabases 
WHERE name NOT IN ('master','model','msdb','tempdb') 

OPEN db_cursor  
FETCH NEXT FROM db_cursor INTO @name  

WHILE @@FETCH_STATUS = 0  
BEGIN  
       SET @fileName = @path + @name + '_' + @fileDate + '.BAK' 
       BACKUP DATABASE @name TO DISK = @fileName 

       FETCH NEXT FROM db_cursor INTO @name  
END  

CLOSE db_cursor  
DEALLOCATE db_cursor

	

<strong>Backup database to file</strong>
declare @backupFileName varchar(100), @backupDirectory varchar(100),  
@databaseDataFilename varchar(100), @databaseLogFilename varchar(100),  
@databaseDataFile varchar(100), @databaseLogFile varchar(100),  
@databaseName varchar(100), @execSql varchar(1000)  

-- Set the name of the database to backup  
set @databaseName = 'bsnpr'  
-- Set the path fo the backup directory on the sql server pc  
set @backupDirectory = 'D:' -- such as 'c:temp'  

-- Create the backup file name based on the backup directory, the database name and today's date  
set @backupFileName = @backupDirectory + @databaseName + '-' + replace(convert(varchar, getdate(), 110), '-', '.') + '.bak'  

-- Get the data file and its path  
select @databaseDataFile = rtrim([Name]),  
@databaseDataFilename = rtrim([Filename])  
from master.dbo.sysaltfiles as files  
inner join  
master.dbo.sysfilegroups as groups  
on  
files.groupID = groups.groupID  
where DBID = (  
  select dbid  
  from master.dbo.sysdatabases  
  where [Name] = @databaseName  
)  

-- Get the log file and its path  
select @databaseLogFile = rtrim([Name]),  
@databaseLogFilename = rtrim([Filename])  
from master.dbo.sysaltfiles as files  
where DBID = (  
  select dbid  
  from master.dbo.sysdatabases  
  where [Name] = @databaseName  
)  
and  
groupID = 0  

print 'Backing up "' + @databaseName + '" database to "' + @backupFileName + '" with '  
print '  data file "' + @databaseDataFile + '" located at "' + @databaseDataFilename + '"'  
print '  log file "' + @databaseLogFile + '" located at "' + @databaseLogFilename + '"'  

set @execSql = '  
backup database [' + @databaseName + ']  
to disk = ''' + @backupFileName + '''  
with  
  noformat,  
  noinit,  
  name = ''' + @databaseName + ' backup'',  
  norewind,  
  nounload,  
  skip'  

exec(@execSql)
