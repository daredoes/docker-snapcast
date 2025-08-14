DOCKER_IMAGE=snapcast
DOCKER_REPO=daredoes
TAG_NAME=$(shell date +%Y.%m.%d.%H.%M.%S)
PLATFORMS=linux/amd64,linux/arm64
TAG_NAME_TO_RUN=2025.08.13.15.56.42

host-run:
	docker run -d --network host \
    -p 1780:1780 \
    -p 1705:1705 \
    -p 1704:1704 \
    -p 5000:5000 \
    -p 7000:7000 \
    -v /Users/dare/Git/docker-snapcast/myconfig:/config \
    -v /tmp/navidrome:/tmp/navidrome \
    $(DOCKER_REPO)/$(DOCKER_IMAGE):$(TAG_NAME_TO_RUN)
run:
	docker run -d \
    -p 1780:1780 \
    -p 1705:1705 \
    -p 1704:1704 \
    -p 5000:5000 \
    -p 7000:7000 \
    --privileged \
    -v /Users/dare/Git/docker-snapcast/myconfig:/config \
    --mount type=bind,source=/tmp/navififo,target=/tmp/navififo \
    $(DOCKER_REPO)/$(DOCKER_IMAGE):$(TAG_NAME_TO_RUN)

build:
	docker buildx build --platform=$(PLATFORMS) -t $(DOCKER_REPO)/$(DOCKER_IMAGE):$(TAG_NAME) . --build-arg SHAIRPORT_SYNC_BRANCH=development --build-arg NQPTP_BRANCH=development --build-arg SNAPCAST_BRANCH=master
slim:
	slim build --target $(DOCKER_REPO)/$(DOCKER_IMAGE) --tag $(DOCKER_REPO)/$(DOCKER_IMAGE):$(TAG_NAME) --include-path /config --include-path /usr/share/snapserver/snapweb
push:
	make build && docker push $(DOCKER_REPO)/$(DOCKER_IMAGE):$(TAG_NAME)
push-premade:
	docker push $(DOCKER_REPO)/$(DOCKER_IMAGE):$(TAG_NAME_TO_RUN)

.PHONY: build push 
