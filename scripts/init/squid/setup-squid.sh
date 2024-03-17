#!/bin/bash

mkdir -p /var/log/squid
touch /var/log/squid/access.log
touch /var/log/squid/cache.log
touch /var/log/squid/store.log
chown proxy:proxy /var/log/squid/*
chmod a+x /var/log/squid/*
