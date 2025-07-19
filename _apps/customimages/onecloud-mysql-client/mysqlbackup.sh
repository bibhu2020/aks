#!/bin/bash

################################################################

export PATH=/bin:/usr/bin:/usr/local/bin
TODAY=`date +"%m-%d-%Y"`
TIME_NOW=`date +"%H%M%S"`
################################################################
################## Update below values  ########################

DB_BACKUP_PATH=$6 #'/mnt/cloudblogs'
MYSQL_HOST=$1 #'cloudblogs-ms-pre-prod-db.mysql.database.azure.com'
MYSQL_PORT=$2 #'3306'
MYSQL_USER=$3 #'cloudblogspreprodadmin'
MYSQL_PASSWORD=$4 #'1N8zx3L14tU'
DATABASE_NAME=$5 #'cloudblogsmspreprod'
BACKUP_RETAIN_DAYS=22   ## Number of days to keep local backup copy

#################################################################

if [ ! -d ${DB_BACKUP_PATH}/${TODAY} ]
then
     mkdir ${DB_BACKUP_PATH}/${TODAY}
else
     echo "Directory exists"
fi
echo "Backup started for database - ${DATABASE_NAME}" >> ${DB_BACKUP_PATH}/dbbackup.log

mysqldump --column-statistics=0 --set-gtid-purged=OFF --single-transaction \
   -h ${MYSQL_HOST} \
   -P ${MYSQL_PORT} \
   -u ${MYSQL_USER} \
   -p${MYSQL_PASSWORD} \
   ${DATABASE_NAME} | gzip > ${DB_BACKUP_PATH}/${TODAY}/${DATABASE_NAME}-${TODAY}-${TIME_NOW}.sql.gz

if [ $? -eq 0 ]; then
  echo "${TODAY}-${TIME_NOW}: ${DATABASE_NAME}@${MYSQL_HOST} database backup successfully completed" >> ${DB_BACKUP_PATH}/dbbackup.log
else
  echo "${TODAY}-${TIME_NOW}: ${DATABASE_NAME}@${MYSQL_HOST} >> Error found during backup" >> ${DB_BACKUP_PATH}/dbbackup.log
  exit 1
fi


##### Remove backups older than {BACKUP_RETAIN_DAYS} days  #####

DBDELDATE=`date +"%m-%d-%Y" --date="${BACKUP_RETAIN_DAYS} days ago"`

if [ ! -z ${DB_BACKUP_PATH} ]; then
      cd ${DB_BACKUP_PATH}
      if [ ! -z ${DBDELDATE} ] && [ -d ${DBDELDATE} ]; then
            rm -rf ${DBDELDATE}
      fi
fi

### End of script ####
