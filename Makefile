MODULES   := events invite mods welcome
REPO      := boston-dsa/socialismbot
RUNTIME   := nodejs12.x
STAGES    := lock zip plan
TERRAFORM := latest
LOCKFILES := $(foreach MODULE,$(MODULES),$(MODULE)/package-lock.json)
PACKAGES  := $(foreach MODULE,$(MODULES),dist/$(MODULE).zip)
VERSION   := $(shell git describe --tags --always)

.PHONY: default apply clean clobber $(STAGES) $(MODULES)

default: $(LOCKFILES) $(PACKAGES)

.docker dist:
	mkdir -p $@

.docker/zip: .docker/lock
.docker/plan: .docker/zip
.docker/%: | .docker
	docker build \
	--build-arg AWS_ACCESS_KEY_ID \
	--build-arg AWS_DEFAULT_REGION \
	--build-arg AWS_SECRET_ACCESS_KEY \
	--build-arg RUNTIME=$(RUNTIME) \
	--build-arg TERRAFORM=$(TERRAFORM) \
	--build-arg TF_VAR_VERSION=$(VERSION) \
	--iidfile $@ \
	--tag $(REPO):$* \
	--target $* \
	.

.env:
	cp $@.example $@

apply: .docker/plan
	docker run --rm \
	--env AWS_ACCESS_KEY_ID \
	--env AWS_DEFAULT_REGION \
	--env AWS_SECRET_ACCESS_KEY \
	$$(cat $<)

clean:
	rm -rf .docker

clobber: clean
	docker image ls $(REPO) --quiet | uniq | xargs docker image rm --force
	rm -rf dist

$(LOCKFILES): .docker/lock
	docker run --rm --entrypoint cat $$(cat $<) $@ > $@

$(PACKAGES): .docker/zip | dist
	docker run --rm --entrypoint cat $$(cat $<) $@ > $@

$(STAGES): %: .docker/%
