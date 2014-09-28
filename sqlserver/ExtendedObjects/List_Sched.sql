set nocount on
go
use msdb
go
set rowcount 0
declare @job_id	varchar(200),
	@sched_id varchar(200),
	@freq_type	int,
	@Freq_Interval	int,
	@freq_subday_type	int,
	@freq_subday_interval	int,
	@freq_relative_interval	int,
	@freq_recurrence_factor	int,
	@active_start_date	int,
	@schedule_word varchar(1000),
	@schedule_day varchar(200),
	@conv_start_time char(6),
	@conv_end_time char(6)

create table #joblistings
	(job_id		varchar(200),
	sched_id	varchar(200),
	job_name	sysname,
--	sched_name	sysname null,
	Status		int,
	Scheduled	int null,
	schedule_word 	varchar(1000) null,
	freq_type	int null,
	freq_interval	int null,
	freq_subday_type	int null,
	freq_subday_interval	int null,
	freq_relative_interval	int null,
	freq_recurrence_factor	int null,
	active_start_date	int null,
	active_end_date		int null,
	active_start_time	int null,
	active_end_time		int null,
	date_created	datetime  null)

insert into #joblistings (job_id,
			sched_id	,
			job_name	,
--			sched_name	,
			status		,
			Scheduled	,
			schedule_word 	,
			freq_type,
			freq_interval,
			freq_subday_type,
			freq_subday_interval,
			freq_relative_interval,
			freq_recurrence_factor,
			active_start_date,
			active_end_date,
			active_start_time,
			active_end_time,
			date_created) 
select 	j.job_id,
	c.schedule_id,
	j.name	,
--	c.name ,
	j.enabled,
	c.enabled,
	null,
	c.freq_type,
	c.freq_interval,
	c.freq_subday_type,
	c.freq_subday_interval,
	c.freq_relative_interval,
	c.freq_recurrence_factor,
	c.active_start_date,
	c.active_end_date,
	c.active_start_time,
	c.active_end_time,
	j.date_created
from sysjobs j, 
	sysjobschedules c
where j.job_id*=c.job_id

while 1=1
begin
	set rowcount 0
	set @schedule_word = ''
	if (select count(*) from #joblistings where scheduled=1 and schedule_word is null) = 0
		break
	else
	begin
		set rowcount 1
		select 	@job_id=job_id,
			@sched_id=sched_id,
			@freq_type=freq_type,
			@Freq_Interval=freq_interval,
			@freq_subday_type=freq_subday_type,
			@freq_subday_interval=freq_subday_interval,
			@freq_relative_interval=freq_relative_interval,
			@freq_recurrence_factor=freq_recurrence_factor,
			@active_start_date = active_start_date,
			@conv_start_time = case 
				when len(active_start_time) < 6 then replicate('0',6-(len(active_start_time))) + cast(active_start_time as varchar(5))
				else cast(active_start_time as varchar(6))
				end,
			@conv_end_time= case 
				when len(active_end_time) < 6 then replicate('0',6-(len(active_end_time))) + cast(active_end_time as varchar(5))
				else cast(active_end_time as varchar(6))
				end
  		from #joblistings 
		where schedule_word is null
			and scheduled=1

		if exists(select @freq_type where @freq_type in (1,64))
		begin
			select @schedule_word =	case @freq_type 
						when 1  then 'Occurs Once, On '+cast(@active_start_date as varchar(8))+', At '+@conv_start_time
						when 64 then 'Occurs When SQL Server Agent Starts'
				end
		end
		else
		begin
			if @freq_type=4
			begin
			select @schedule_word = 'Occurs Every '+cast(@freq_interval as varchar(10))+' Day(s)'
			end

			if @freq_type=8
			begin
			select @schedule_word = 'Occurs Every '+cast(@freq_recurrence_factor as varchar(3))+' Week(s)'
			select @schedule_day=''
			if (SELECT (convert(int,(@freq_interval/1)) % 2)) = 1
				select @schedule_day = @schedule_day+'Sun'
			if (SELECT (convert(int,(@freq_interval/2)) % 2)) = 1
				select @schedule_day = @schedule_day+'Mon'
			if (SELECT (convert(int,(@freq_interval/4)) % 2)) = 1
				select @schedule_day = @schedule_day+'Tue'
			if (SELECT (convert(int,(@freq_interval/8)) % 2)) = 1
				select @schedule_day = @schedule_day+'Wed'
			if (SELECT (convert(int,(@freq_interval/16)) % 2)) = 1
				select @schedule_day = @schedule_day+'Thu'
			if (SELECT (convert(int,(@freq_interval/32)) % 2)) = 1
				select @schedule_day = @schedule_day+'Fri'
			if (SELECT (convert(int,(@freq_interval/64)) % 2)) = 1
				select @schedule_day = @schedule_day+'Sat'
			
			select @schedule_word = @schedule_word+', On '+@schedule_day
			end

			if @freq_type=16
			begin
			select @schedule_word = 'Occurs Every '+cast(@freq_recurrence_factor as varchar(3))+' Month(s) on Day '+cast(@freq_interval as varchar(3))+' of that Month'
			end

			if @freq_type=32
			begin
			select @schedule_word = case @freq_relative_interval
						when 1 then 'First'
						when 2 then 'Second'
						when 4 then 'Third'
						when 8 then 'Fourth'
						when 16 then 'Last'
					end
			select @schedule_word = 
				case @freq_interval
					when 1 then 'Occurs Every '+@schedule_word+' Sunday of the Month'
					when 2 then 'Occurs Every '+@schedule_word+' Monday of the Month'
					when 3 then 'Occurs Every '+@schedule_word+' Tueday of the Month'
					when 4 then 'Occurs Every '+@schedule_word+' Wednesday of the Month'
					when 5 then 'Occurs Every '+@schedule_word+' Thursday of the Month'
					when 6 then 'Occurs Every '+@schedule_word+' Friday of the Month'
					when 7 then 'Occurs Every '+@schedule_word+' Saturday of the Month'
					when 8 then 'Occurs Every '+@schedule_word+' Day of the Month'
					when 9 then 'Occurs Every '+@schedule_word+' Weekday of the Month'
					when 10 then 'Occurs Every '+@schedule_word+' Weekend Day of the Month'
				end
			end

		select @schedule_word = 
			case @freq_subday_type
				when 1 then @schedule_word+', At '+@conv_start_time
				when 2 then @schedule_word+', every '+cast(@freq_subday_interval as varchar(3))+' Second(s) Between '+@conv_start_time+' and '+@conv_end_time
				when 4 then @schedule_word+', every '+cast(@freq_subday_interval as varchar(3))+' Minute(s) Between '+@conv_start_time+' and '+@conv_end_time
				when 8 then @schedule_word+', every '+cast(@freq_subday_interval as varchar(3))+' Hour(s) Between '+@conv_start_time+' and '+@conv_end_time
			end
		end
	end
	update #joblistings
	set schedule_word=@schedule_word
	where job_id=@job_id
		and sched_id=@sched_Id
	set rowcount 0
end
select job_name	,
--	sched_name	,
	Status	= case Status
			when 1 then 'Enabled'
			when 0 then 'Disabled'
			else ' '
		end,
	Scheduled= case scheduled	
			when 1 then 'Yes'
			when 0 then 'No'
			else ' '
		end,
	schedule_word as 'Frequency'	,
	active_start_date,
	active_end_date,
	date_created
from #joblistings 
where scheduled=1
order by job_name

drop table #joblistings





