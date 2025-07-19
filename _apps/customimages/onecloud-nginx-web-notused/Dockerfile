## this image is to run the NGINX under nginx(UID: 101) instead of running as root
FROM aksocdevacr.azurecr.io/nginx-unprivileged:latest

# Copy custom home page into the NGINX container
COPY ./www/ /usr/share/nginx/html/

# Expose port 80 to allow incoming connections
EXPOSE 8080

# Start NGINX when the container starts
CMD ["nginx", "-g", "daemon off;"]
