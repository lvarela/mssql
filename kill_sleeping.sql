DECLARE @v_spid INT
DECLARE c_Users CURSOR
   FAST_FORWARD FOR
   SELECT SPID
   FROM master..sysprocesses (NOLOCK)
   WHERE spid>50 
   AND status='sleeping' 
   AND DATEDIFF(mi,last_batch,GETDATE())>=30
   AND spid<>@@spid

   OPEN c_Users
FETCH NEXT FROM c_Users INTO @v_spid
WHILE (@@FETCH_STATUS=0)
BEGIN
  PRINT 'KILLing '+CONVERT(VARCHAR,@v_spid)+'...'
  EXEC('KILL '+@v_spid)
  FETCH NEXT FROM c_Users INTO @v_spid
END  

   CLOSE c_Users
DEALLOCATE c_Users
