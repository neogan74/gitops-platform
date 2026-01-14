.PHONY: build push run test clean

# Configuration
IMAGE_NAME ?= localhost:5001/demo-app-go
VERSION ?= v1.0.0
TAG ?= $(VERSION)

build:
	@echo "Building Docker image $(IMAGE_NAME):$(TAG)..."
	docker build -t $(IMAGE_NAME):$(TAG) .
	docker tag $(IMAGE_NAME):$(TAG) $(IMAGE_NAME):latest

push: build
	@echo "Pushing Docker image $(IMAGE_NAME):$(TAG)..."
	docker push $(IMAGE_NAME):$(TAG)
	docker push $(IMAGE_NAME):latest

run:
	@echo "Running application locally..."
	cd src && go run .

test:
	@echo "Running tests..."
	cd src && go test -v ./...

clean:
	@echo "Cleaning up..."
	docker rmi $(IMAGE_NAME):$(TAG) $(IMAGE_NAME):latest 2>/dev/null || true

# Build and push specific version
release:
	@if [ -z "$(VERSION)" ]; then echo "VERSION is required"; exit 1; fi
	@echo "Building and pushing version $(VERSION)..."
	$(MAKE) build VERSION=$(VERSION)
	$(MAKE) push VERSION=$(VERSION)

# Quick rebuild and push (for development)
dev: build push
	@echo "Development image ready: $(IMAGE_NAME):$(TAG)"
