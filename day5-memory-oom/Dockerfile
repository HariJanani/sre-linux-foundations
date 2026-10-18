FROM ubuntu:22.04
RUN apt-get update && apt-get install -y gcc
COPY oom-simulation.c /app/oom-simulation.c
WORKDIR /app
RUN gcc -o oom-simulation oom-simulation.c
CMD ["./oom-simulation"]
