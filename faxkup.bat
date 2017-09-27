@echo off
setlocal enabledelayedexpansion
set AWS_ACCESS_KEY_ID=<aws_access_key_id>
set AWS_SECRET_ACCESS_KEY=<aws_secret_access_key>
set AWS_CONFIG_FILE=C:\Users\Administrator\.aws\config
set aws_region=eu-west-1
set aws_bucket_url=s3://<bucketname>
set aws_sns_arn=<aws_sns_arn>
set data=%Date:~6,4%-%Date:~3,2%-%Date:~0,2%
set home=Z:\faxkup_sqlserver
set backup_dir=%home%\backup
set stage_dir=%home%\stage
set zip_bin=%home%\bin\7z.exe
set computer_name=<COMPUTERNAME>
echo ########################################################################## >%home%\faxkup.log 2>&1
echo Start Backup of <COMPUTERNAME> MS SqlServer instance >>%home%\faxkup.log 2>&1
echo %data% >>%home%\faxkup.log 2>&1
echo --------------------------------------------------- >>%home%\faxkup.log 2>&1
rem recupero la lista dei database presenti nell'istanza e la salvo su file
echo Get DB list from %computer_name% MS SqlServer instance >>%home%\faxkup.log 2>&1
sqlcmd -E -S %computer_name% -W -u -h -1 -Q "SET NOCOUNT ON;SELECT NAME FROM sys.sysdatabases" -o %home%\db.list >>%home%\faxkup.log 2>&1
rem parso la lista di database
echo parsing db list file %home%\db.list >>%home%\faxkup.log 2>&1
for /f "tokens=*" %%a in ('type %home%\db.list') do (
set line=%%a
if "%%a"=="master" (
	echo Ignoring master DB >>%home%\faxkup.log 2>&1
) else if "%%a"=="tempdb" (
	echo Ignoring tempdb db >>%home%\faxkup.log 2>&1
) else if "%%a"=="model" (
	echo Ignoring model db >>%home%\faxkup.log 2>&1
) else if "%%a"=="msdb" (
	echo Ignoring msdb db >>%home%\faxkup.log 2>&1
) else (
	rem eseguo il backup di ogni singolo database
	echo Backing up %%a db >>%home%\faxkup.log 2>&1
	sqlcmd -E -S %computer_name% -Q "BACKUP DATABASE %%a TO DISK='%backup_dir%\%%a.bak'" >>%home%\faxkup.log 2>&1
	rem e lo comprimo con 7zip, ci vuole tempo, ma ne vale la pena, da 10GB a 600MB mi pare una buona cosa
	echo 7Zipping and deleting %%a.bak file >>%home%\faxkup.log 2>&1
	%zip_bin% a -sdel %backup_dir%\%%a.7z %backup_dir%\%%a.bak >>%home%\faxkup.log 2>&1
	)
)
rem un 7zip per ghermirli tutti e nel buio incatenarli
echo 7Zipping and deleting all .7z archive into %data%-backup.7z Z:\backup\*.7z >>%home%\faxkup.log 2>&1
%zip_bin% a -sdel %stage_dir%\%data%-backup.7z %backup_dir%\*.7z >>%home%\faxkup.log 2>&1
rem copio il backup su S3
echo Copy %data%-backup.7z Z:\backup\*.7z into  >>%home%\faxkup.log 2>&1
aws --region %aws_region% s3 cp %stage_dir%\%data%-backup.7z %aws_bucket_url% >>%home%\faxkup.log 2>&1
del /f /q %stage_dir%\%data%-backup.7z >>%home%\faxkup.log 2>&1
echo Sending SNS notification  >>%home%\faxkup.log 2>&1
echo Done >>%home%\faxkup.log 2>&1
echo ########################################################################## >>%home%\faxkup.log 2>&1
aws sns publish --topic-arn "%aws_sns_arn%" --message file://%home%\faxkup.log
