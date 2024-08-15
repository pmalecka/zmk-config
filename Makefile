DOCKER := $(shell { command -v podman || command -v docker; })
TIMESTAMP := $(shell date +"%Y%m%d-%H%M%S-%Z")
COMMIT := $(shell git rev-parse --short HEAD 2>/dev/null)
ifeq ($(shell uname),Darwin)
SELINUX1 :=
SELINUX2 :=
else
SELINUX1 := :z
SELINUX2 := ,z
endif

.PHONY: all left clean_firmware clean_image clean

all:
	$(shell bin/get_version.sh >> /dev/null)
	$(DOCKER) build --tag zmk --file Dockerfile .
	$(DOCKER) run --rm -it --name zmk \
		-v $(PWD)/firmware:/app/firmware$(SELINUX1) \
		-v $(PWD)/config:/app/config:ro$(SELINUX2) \
		-v $(PWD)/build.json:/app/build.json:ro$(SELINUX2) \
		-e TIMESTAMP=$(TIMESTAMP) \
		-e COMMIT=$(COMMIT) \
		-e BUILD_LEFT=true \
		-e BUILD_RIGHT=true \
		-e BUILD_SETTINGS_RESET=true \
		zmk
	# git checkout config/version.dtsi

left:
	$(shell bin/get_version.sh >> /dev/null)
	$(DOCKER) build --tag zmk --file Dockerfile .
	$(DOCKER) run --rm -it --name zmk \
		-v $(PWD)/firmware:/app/firmware$(SELINUX1) \
		-v $(PWD)/config:/app/config:ro$(SELINUX2) \
		-v $(PWD)/build.json:/app/build.json:ro$(SELINUX2) \
		-e TIMESTAMP=$(TIMESTAMP) \
		-e COMMIT=$(COMMIT) \
		-e BUILD_LEFT=true \
		-e BUILD_RIGHT=false \
		-e BUILD_SETTINGS_RESET=false \
		zmk
	# git checkout config/version.dtsi

settings_reset:
	$(shell bin/get_version.sh >> /dev/null)
	$(DOCKER) build --tag zmk --file Dockerfile .
	$(DOCKER) run --rm -it --name zmk \
		-v $(PWD)/firmware:/app/firmware$(SELINUX1) \
		-v $(PWD)/config:/app/config:ro$(SELINUX2) \
		-v $(PWD)/build.json:/app/build.json:ro$(SELINUX2) \
		-e TIMESTAMP=$(TIMESTAMP) \
		-e COMMIT=$(COMMIT) \
		-e BUILD_LEFT=false \
		-e BUILD_RIGHT=false \
		-e BUILD_SETTINGS_RESET=true \
		zmk
	# git checkout config/version.dtsi

clean_firmware:
	rm -f firmware/*.uf2

clean_image:
	$(DOCKER) image rm zmk docker.io/zmkfirmware/zmk-build-arm:stable

clean: clean_firmware clean_image
