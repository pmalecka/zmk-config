FROM docker.io/zmkfirmware/zmk-build-arm:stable

RUN apt-get update && apt-get install -y \
    jq \
    python3-dev \
    python3-pip \
    python3-setuptools \
    python3-wheel \
    && PIP_BREAK_SYSTEM_PACKAGES=1 pip3 install remarshal \
    && apt-get clean \
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
