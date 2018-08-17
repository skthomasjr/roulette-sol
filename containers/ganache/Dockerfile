FROM node:latest

MAINTAINER Scott K. Thomas, Jr. <sthomas@idis.com>

ARG GANACHE_HOST
ARG GANACHE_PORT
ARG GANACHE_CHAIN_ID

RUN npm i -g ganache-cli

CMD ganache-cli -h $GANACHE_HOST -p $GANACHE_PORT -i $GANACHE_CHAIN_ID
