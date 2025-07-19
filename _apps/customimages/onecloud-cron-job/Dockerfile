# Use an official Python runtime as a parent image
FROM aksocstgacr.azurecr.io/onecloud-base:v1

# Set the working directory in the container
WORKDIR /home/onecloud

# Install any needed Python packages specified in requirements.txt
COPY ./python/requirements.txt .
RUN pip install --trusted-host pypi.python.org -r requirements.txt

# Install any needed Node.js packages specified in package.json
COPY ./nodejs/package.json .
RUN npm install

# Copy the current directory contents into the container at /app
COPY ./* .

# No CMD or ENTRYPOINT specified; container designed for flexible command execution
