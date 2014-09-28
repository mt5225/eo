osql -S localhost -U $1 -P $2 -r -h-1 -s "," -Q "set nocount on
declare @name sysname,
	@SQL  nvarchar(600)

if exists (select [id] from tempdb..sysobjects where [id] = OBJECT_ID ('tempdb..#tmpTable'))
	drop table #tmpTable
	
CREATE TABLE #tmpTable (
	[DATABASENAME] sysname NOT NULL ,
	[USER_NAME] sysname NOT NULL,
	[ROLE_NAME] sysname NOT NULL)

declare c1 cursor for 
	select name from master.dbo.sysdatabases
			
open c1
fetch c1 into @name
while @@fetch_status >= 0
begin
	select @SQL = 
		'insert into #tmpTable
		 select N'''+ @name + ''', a.name, c.name
		from ' + QuoteName(@name) + '.dbo.sysusers a 
		join ' + QuoteName(@name) + '.dbo.sysmembers b on b.memberuid = a.uid
		join ' + QuoteName(@name) + '.dbo.sysusers c on c.uid = b.groupuid
		where a.name != ''dbo'''

		/* 	Insert row for each database */
		execute (@SQL)
	fetch c1 into @name
end
close c1
deallocate c1
	
select * from #tmpTable

" -w 700 

