# Faxkup MS SqlServer Edition

## Cosa è
Faxkup è uno script per il backup di database. 
Nato per esigenze interne, di backup per database Oracle su sistemi linux, 
ora è sbarcato anche nel fantastitico mondo MS SqlServer su sistemi Windows.

## Come funziona
Il gioco è abbastanza facile, si connette all'istanza MS SqlServer, recupera la lista di database ed effettua il backup di tutti i db presenti nel server, escludendo quelli di sistema: 
  - master
  - tempdb
  - model
  - msdb

Una volta fatto il backup li comprime con 7zip e li archivia in un bucket S3 su AWS.
Il flusso del backup è il seguente:
- Recupera la lista dei database del server con sqlcmd e li salva su un file db.list
- Recupera il nome di un database dal file db.list
- Effettua il backup con sqlcmd
- Comprime il file .bak appena generato
- Elimina il file .bak
- Presegue con il database successivo, seguendo gli stessi passi.
- Finiti i database da processare, comprime tutti i file .7z in un unico archivio .7z
- Copia l'archivio su un bucket S3 di AWS
- Invia una notifica usando il servizio SNS di AWS con il log in allegato

__Al momento non è ancora prevista una logica per escludere o per includere determinati database.__

## Installazione
Per installare questo scritp basta copiare la struttura e i file di questo repository in una cartella del server. 
Consiglio caldamente di posizionarli in una unità che abbia abbastanza spazio, 

## Configurazione
La confgurazione è abbastanza semplice, sarà sufficiente editare il file **faxkup.bat** ed andare a modificare i valori dei seguenti parametri
- **AWS_ACCESS_KEY_ID=_<aws_access_key_id>_**
- **AWS_SECRET_ACCESS_KEY=_<aws_secret_access_key>_**
- **AWS_CONFIG_FILE=C:\Users\Administrator\.aws\config**
- **aws_region=eu-west-1**
- **aws_bucket_url=s3://_<bucketname>_**
- **aws_sns_arn=_<aws_sns_arn>_**
- **home=Z:\faxkup_sqlserver**
- **computer_name=_<COMPUTERNAME>_**

Aggiungere faxkup.bat alle _**"operazioni pianificate"**_ di Windows e il gioco è fatto.

## TO DO
Ci sono ancora parecchie cosette da implementare:
- Inclusion/exclusion list
- prebackup e postbackup task
- Gestione degli errori (ossibilmente seria)
- Verifica dei pre requisiti (aws cli, 7zip...)
- Varie ed eventuali

License
----

Apache License 2.0
