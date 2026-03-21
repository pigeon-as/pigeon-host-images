.PHONY: build build-control-plane build-worker init validate clean

build: build-control-plane build-worker

build-control-plane: init
	packer build control-plane.pkr.hcl

build-worker: init
	packer build worker.pkr.hcl

init:
	packer init control-plane.pkr.hcl
	packer init worker.pkr.hcl

validate: init
	packer validate control-plane.pkr.hcl
	packer validate worker.pkr.hcl

clean:
	rm -rf output/
