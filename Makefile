modules   := events invite mods welcome
runtime   := nodejs10.x
stages    := build plan
terraform := latest
build     := $(shell git describe --tags --always)
packages  := $(foreach module,$(modules),$(module)/package.zip)
lockfiles := $(foreach module,$(modules),$(module)/package-lock.json)
shells    := $(foreach stage,$(stages),shell@$(stage))

.PHONY: all apply clean clobber $(stages) $(shells)

all: $(lockfiles) $(packages)

.docker:
	mkdir -p $@

.docker/$(build)@plan: .docker/$(build)@build
.docker/$(build)@%: | .docker
	docker build \
	--build-arg AWS_ACCESS_KEY_ID \
	--build-arg AWS_DEFAULT_REGION \
	--build-arg AWS_SECRET_ACCESS_KEY \
	--build-arg RUNTIME=$(runtime) \
	--build-arg TERRAFORM=$(terraform) \
	--build-arg TF_VAR_release=$(build) \
	--iidfile $@ \
	--tag boston-dsa/socialismbot:$(build)-$* \
	--target $* .

apply: .docker/$(build)@plan
	docker run --rm \
	--env AWS_ACCESS_KEY_ID \
	--env AWS_DEFAULT_REGION \
	--env AWS_SECRET_ACCESS_KEY \
	$(shell cat $<)

clean:
	-docker image rm $(shell awk {print} .docker/*)
	-rm -rf .docker

clobber: clean
	-rm -rf $(packages)

$(lockfiles) $(packages): .docker/$(build)@build
	docker run --rm \
	$(shell cat $<) \
	cat $@ > $@

$(stages): %: .docker/$(build)@%

$(shells): shell@%: .docker/$(build)@%
	docker run --rm -it \
	--entrypoint /bin/sh \
	$(shell cat $<)
