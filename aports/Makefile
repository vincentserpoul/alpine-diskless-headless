.PHONY: build run cleanup
PWD=$(shell pwd)

build:
	docker buildx build --platform linux/arm64 -t alpine-aports-mkimage --load ./

run: cleanup
	docker run --platform linux/arm64 --name aam --rm -v "$(PWD)/build:/build" -it alpine-aports-mkimage

cleanup:
	rm -rf ./build