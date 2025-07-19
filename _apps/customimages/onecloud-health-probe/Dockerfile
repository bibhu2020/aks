FROM aksocpocacr.azurecr.io/onecloud-base:v2

# Set the working directory
WORKDIR /app

# Give ownership of the working directory to the user and group
RUN chown -R onecloud:onecloud /app

# Change to the non-root user
USER onecloud

COPY package*.json ./
RUN npm install

COPY . .

EXPOSE 8080
CMD [ "node", "server.js" ]
