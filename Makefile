.PHONY: build build-control-plane build-worker init validate clean

IMAGE_VERSION ?= 0.0.0

build: build-control-plane build-worker

build-control-plane: init
	packer build -var "image_version=$(IMAGE_VERSION)" control-plane.pkr.hcl

build-worker: init
	packer build -var "image_version=$(IMAGE_VERSION)" worker.pkr.hcl

init:
	packer init control-plane.pkr.hcl
	packer init worker.pkr.hcl

validate: init
	packer validate control-plane.pkr.hcl
	packer validate worker.pkr.hcl

clean:
	rm -rf build/
