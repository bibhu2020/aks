FROM aksocstgacr.azurecr.io/mysql:8.3
LABEL description="Custom Mysql Docker Image Built to Run SQL backup cronjobs"

# Add Environment Variables
ENV MYSQL_HOST ""
ENV MYSQL_PORT 3306
ENV MYSQL_USER ""
ENV MYSQL_PSWD ""
ENV MYSQL_DBNM ""
ENV BACKUP_PATH ""

COPY ./mysqlbackup.sh /var/scripts/

# # Set appropriate permissions for directories
# RUN chown -R mysql:mysql /var/scripts/

# # Switch to the non-root user
# USER mysql
