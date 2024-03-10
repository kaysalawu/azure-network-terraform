#cloud-config

# Update and upgrade the system
package_update: true
package_upgrade: true

# Install Docker and Docker Compose
packages:
  - docker.io
  - docker-compose

# Enable and start Docker service
runcmd:
  - systemctl enable docker
  - systemctl start docker

# Create a directory for the Docker Compose files
runcmd:
  - mkdir /app
  - cd /app

# Create a Docker Compose YAML file
write_files:
  - path: /app/docker-compose.yml
    content: |
      version: '3'
      services:
        juice-shop:
          image: bkimminich/juice-shop
          ports:
            - "3000:3000"

# Use Docker Compose to start the Juice Shop container
runcmd:
  - docker-compose -f /app/docker-compose.yml up -d
