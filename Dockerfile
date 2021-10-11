FROM debian:buster-slim

ARG myarg

RUN (echo "$myarg"; uname -a) | tee /tmp/uname.txt
