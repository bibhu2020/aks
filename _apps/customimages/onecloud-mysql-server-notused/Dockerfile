FROM aksocstgacr.azurecr.io/mysql:8.3
LABEL description="Custom Mysql Docker Image Built to under non-root user."

# Set appropriate permissions for directories
RUN chown -R mysql:mysql /var/lib/mysql /var/run/mysqld

# Copy custom configuration file if needed
# COPY custom-config-file.cnf /etc/mysql/conf.d/

# Switch to the non-root user
USER mysql

# Start MySQL server
CMD ["mysqld"]

## Needs to be tested properly. not working at the moment


