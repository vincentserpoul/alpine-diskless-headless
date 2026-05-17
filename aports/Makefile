.PHONY: build run cleanup
PWD=$(shell pwd)

build:
	docker buildx build --platform linux/arm64 -t alpine-aports-mkimage --load ./

run:
	docker run --platform linux/arm64 --name aam --rm -it \
		-v "$(PWD)/build:/build" \
		-v "$(PWD)/mkimg.adh.sh:/src/aports/scripts/mkimg.adh.sh" \
		alpine-aports-mkimage

cleanup:
	rm -rf ./build