CREATE PROCEDURE sp_who3

as

set nocount on

declare
@retcode int, @loginame sysname
declare
@sidlow varbinary(85),@sidhigh varbinary(85) ,@sid1 varbinary(85) ,@spidlow int ,@spidhigh int

declare
@charMaxLenLoginName varchar(6),@charMaxLenDBName varchar(6),@charMaxLenCPUTime varchar(10),@charMaxLenDiskIO varchar(10),
@charMaxLenHostName varchar(10),@charMaxLenProgramName varchar(10),@charMaxLenLastBatch varchar(10),@charMaxLenCommand varchar(10)
--------
select @retcode = 0 -- 0=good ,1=bad.
--------------------------------------------------------------

if (object_id('tempdb..#tb1_sysprocesses') is not null)
drop table #tb1_sysprocesses

-------------------- Capture consistent sysprocesses. -------------------

SELECT
spid,status,sid,hostname,program_name,cmd,cpu,physical_io,blocked,dbid,
convert(sysname, rtrim(loginame)) as loginname,spid as 'spid_sort',
substring( convert(varchar,last_batch,111) ,6 ,5 ) + ' ' + substring( convert(varchar,last_batch,113) ,13 ,8 ) as 'last_batch_char',last_batch
INTO #tb1_sysprocesses
from master.dbo.sysprocesses (nolock)

--------Screen out any rows
DELETE #tb1_sysprocesses
where lower(status) = 'sleeping'
and upper(cmd) IN (
'AWAITING COMMAND'
,'MIRROR HANDLER'
,'LAZY WRITER'
,'CHECKPOINT SLEEP'
,'RA MANAGER'
,'TASK MANAGER'
)

and blocked = 0 or spid <= 50
---set the column widths
UPDATE #tb1_sysprocesses set last_batch = DATEADD(year,-10,GETDATE())
where last_batch IS NULL or last_batch = '01/01/1901 00:00:00' or last_batch < '01/01/1950'
update #tb1_sysprocesses set status = substring(status,1,10), program_name = substring(program_name,1,20)
ALTER TABLE #tb1_sysprocesses
ALTER COLUMN status varchar(10)
ALTER TABLE #tb1_sysprocesses
ALTER COLUMN program_name varchar(20)
--------Prepare to dynamically optimize column widths.
SELECT
@charMaxLenLoginName = convert( varchar ,isnull( max( datalength(loginname)) ,5)),
@charMaxLenDBName = convert( varchar ,isnull( max( datalength( rtrim(convert(varchar(128),db_name(dbid))))) ,6)),
@charMaxLenCPUTime = convert( varchar,isnull( max( datalength( rtrim(convert(varchar(128),cpu)))) ,7)),
@charMaxLenDiskIO = convert( varchar,isnull( max( datalength( rtrim(convert(varchar(128),physical_io)))) ,6)),
@charMaxLenCommand = convert( varchar,isnull( max( datalength( rtrim(convert(varchar(128),cmd)))) ,7)),
@charMaxLenHostName = convert( varchar,isnull( max( datalength( rtrim(convert(varchar(128),hostname)))) ,8)),
@charMaxLenProgramName = convert( varchar,isnull( max( datalength( rtrim(convert(varchar(128),program_name)))) ,11)),
@charMaxLenLastBatch = convert( varchar,isnull( max( datalength( rtrim(convert(varchar(128),last_batch_char)))) ,9))
from
#tb1_sysprocesses
where
spid >= 0 and spid <= 32767

 

--------Output the report.


EXECUTE(
'SET nocount off
SELECT SPID = convert(char(5),spid)
,HostName =
CASE hostname
When Null Then '' .''
When '' '' Then '' .''
Else substring(hostname,1,' + @charMaxLenHostName + ')
END
,BlkBy =
CASE isnull(convert(char(5),blocked),''0'')
When ''0'' Then '' .''
Else isnull(convert(char(5),blocked),''0'')
END
,ActiveSeconds = DATEDIFF(ss,last_batch,getdate())
,DBName = substring(case when dbid = 0 then null when dbid <> 0 then db_name(dbid) end,1,' + @charMaxLenDBName + ')
,Command = substring(cmd,1,' + @charMaxLenCommand + ')
,Status =
CASE lower(status)
When ''sleeping'' Then lower(status)
Else upper(status)
END
,BatchStart = CONVERT(varchar(8),last_batch,14)
,Now = CONVERT(varchar(8),getdate(),14)
,LBDate = substring(last_batch_char,1,5)
,ProgramName = substring(program_name,1,' + @charMaxLenProgramName + ')
,Login = substring(loginname,1,' + @charMaxLenLoginName + ')
,CPUTime = substring(convert(varchar,cpu),1,' + @charMaxLenCPUTime + ')
,DiskIO = substring(convert(varchar,physical_io),1,' + @charMaxLenDiskIO + ')
from
#tb1_sysprocesses --Usually DB qualification is needed in exec().
order by CAST(SPID as int)
-- (Seems always auto sorted.) order by SPID
SET nocount on')

drop table #tb1_sysprocesses
--return @retcode
GO
