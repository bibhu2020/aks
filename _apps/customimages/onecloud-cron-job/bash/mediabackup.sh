#!/bin/bash

################################################################

export PATH=/bin:/usr/bin:/usr/local/bin
TODAY=`date +"%m-%d-%Y"`
TIME_NOW=`date +"%H%M%S"`
################################################################
################## Update below values  ########################

MEDIA_FILE_FOLDER=$1
BACKUP_PATH=$2
APP_NAME=$3
RETAIN_DAYS=$4   ## Number of days to keep local backup copy

#################################################################

if [ ! -d ${BACKUP_PATH}/media-${TODAY} ]
then
     mkdir '${BACKUP_PATH}/media-${TODAY}'
else
     echo "Directory exists"
fi

tar -czvf ${BACKUP_PATH}media-${TODAY}/${APP_NAME}.tar.gz -C $MEDIA_FILE_FOLDER .


if [ $? -eq 0 ]; then
  echo "${TODAY}-${TIME_NOW}: ${APP_NAME} media backup successfully completed" >> ${BACKUP_PATH}/mediabackup.log
else
  echo "${TODAY}-${TIME_NOW}: ${APP_NAME} >> Error found during backup" >> ${BACKUP_PATH}/mediabackup.log
  exit 1
fi


##### Remove backups older than {BACKUP_RETAIN_DAYS} days  #####

DBDELDATE=`date +"media-%m-%d-%Y" --date="${RETAIN_DAYS} days ago"`

if [ ! -z ${BACKUP_PATH} ]; then
      cd ${BACKUP_PATH}
      if [ ! -z ${DBDELDATE} ] && [ -d ${DBDELDATE} ]; then
            rm -rf ${DBDELDATE}
      fi
fi

### End of script ####
