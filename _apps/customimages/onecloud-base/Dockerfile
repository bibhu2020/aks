# Use an official Python runtime as a parent image
FROM aksocpocacr.azurecr.io/python:3.9-slim

# Install Node.js (assuming version 20 setup script is available) and MySQL client
RUN apt-get update && \
    apt-get install -y curl gnupg && \
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y nodejs && \
    apt-get install -y default-mysql-client && \
    apt install net-tools traceroute dnsutils nmap iputils-ping -y && \
    apt-get install gzip -y  && \
    npm install -g serve   && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Create a group and user with specified GID and UID, here we use UID 1001 and GID 1001 as an example
RUN groupadd -g 11000 onecloud && \
    useradd -m -u 22000 -g onecloud onecloud

# Switch to the created user
USER onecloud

# Set the user's home directory as the working directory
WORKDIR /home/onecloud

# Change ownership of the /app and /home/onecloud directories to the new user
RUN chown -R onecloud:onecloud /home/onecloud

# No CMD or ENTRYPOINT specified; container designed for flexible command execution
