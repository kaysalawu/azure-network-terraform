#cloud-config

package_update: true
package_upgrade: true

packages:
  - docker.io
  - docker-compose

write_files:
  - path: /etc/docker-compose-nginx.yml
    content: |
      version: '3'
      services:
        nginx:
          image: nginx
          ports:
            - "80:80"
            - "8080:80"
            - "8000:80"
            - "9000:80"

runcmd:
  - docker-compose -f /etc/docker-compose-nginx.yml up -d
