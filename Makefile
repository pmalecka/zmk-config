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

.PHONY: build clean_firmware clean_image clean

# Catch-all target to ignore unknown arguments
%:
	@:

# Process arguments as BUILD_* variables
ARGS := $(filter-out build,$(MAKECMDGOALS))
$(foreach arg,$(ARGS),$(eval BUILD_$(shell echo $(arg) | tr a-z A-Z)=true))

build:
	$(shell bin/get_version.sh >> /dev/null)
	$(DOCKER) build --tag zmk --file Dockerfile .
	$(DOCKER) run --rm -it --name zmk \
		-v $(PWD)/firmware:/app/firmware$(SELINUX1) \
		-v $(PWD)/config:/app/config:ro$(SELINUX2) \
		-v $(PWD)/build.yaml:/app/build.yaml:ro$(SELINUX2) \
		-e TIMESTAMP=$(TIMESTAMP) \
		-e COMMIT=$(COMMIT) \
		$(foreach v,$(filter BUILD_%,$(.VARIABLES)),-e $(v)=true) \
		zmk
	# git checkout config/version.dtsi

clean_firmware:
	rm -f firmware/*.uf2

clean_image:
	$(DOCKER) image rm zmk docker.io/zmkfirmware/zmk-build-arm:stable

clean: clean_image
