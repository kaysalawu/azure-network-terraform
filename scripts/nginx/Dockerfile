FROM nginx:latest

RUN mkdir -p /etc/ssl/app
COPY nginx.conf /etc/nginx/nginx.conf
COPY cert.pem /etc/ssl/app/cert.pem
COPY key.pem /etc/ssl/app/key.pem

EXPOSE 8080

CMD ["nginx", "-g", "daemon off;"]
