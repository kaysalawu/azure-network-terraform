FROM alpine:3.19.0
RUN apk add --no-cache unbound
EXPOSE 53/tcp 53/udp
CMD ["unbound", "-d"]
