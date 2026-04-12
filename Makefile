.PHONY: build build-control-plane build-worker init validate clean

IMAGE_VERSION ?= 0.0.0
SKIP_SIGNING ?= true
PCR_SIGNING_KEY ?=

PACKER_VARS = -var "image_version=$(IMAGE_VERSION)" \
  -var "skip_signing=$(SKIP_SIGNING)" \
  -var "pcr_signing_key=$(PCR_SIGNING_KEY)"

build: build-control-plane build-worker

build-control-plane: init
	packer build $(PACKER_VARS) control-plane.pkr.hcl

build-worker: init
	packer build $(PACKER_VARS) worker.pkr.hcl

init:
	packer init control-plane.pkr.hcl
	packer init worker.pkr.hcl

validate: init
	packer validate control-plane.pkr.hcl
	packer validate worker.pkr.hcl

clean:
	rm -rf build/
