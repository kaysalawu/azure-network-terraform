FROM alpine:3.19.0
RUN apk add --no-cache dnsmasq
EXPOSE 53/tcp 53/udp
CMD ["dnsmasq", "-k", "--log-facility=-"]
