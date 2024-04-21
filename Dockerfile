FROM docker.io/zmkfirmware/zmk-build-arm:stable

RUN apt-get update && apt-get install -y \
    jq \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY config/west.yml config/west.yml

# West Init
RUN west init -l config
# West Update
RUN west update
# West Zephyr export
RUN west zephyr-export

COPY bin/build.sh ./

CMD ["./build.sh"]
