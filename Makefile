BIN="./bin/previewer"
DOCKER_IMG="previewer:develop"
INTGRTEST_PROJECT=previever_intgrtest

build:
	go build -v -o $(BIN) cmd/previewer/main.go

run: build
	$(BIN)

install-linter:
	(which golangci-lint > /dev/null) || curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s -- -b $(shell go env GOPATH)/bin v1.45.2

lint: install-linter
	golangci-lint run ./...

lint-fix:
	golangci-lint run ./... --fix

build-img:
	docker build \
		-t $(DOCKER_IMG) \
		-f build/Dockerfile .

up-test: build-img
	docker-compose \
		--env-file=./deployments/.env \
		-f ./deployments/docker-compose.yaml \
		up --remove-orphans --force-recreate

test:
	go test -race ./internal/...

mock:
	rm -rf internal/resizer/mocks
	rm -rf internal/client/mocks
	rm -rf internal/cache/filesystem/mocks
	rm -rf internal/cache/lru/mocks
	rm -rf internal/app/mocks
	rm -rf internal/logger/mocks
	mockery --dir=internal/resizer/. --all --output=internal/resizer/mocks --packageprefix=mock
	mockery --dir=internal/client/. --name=Client --output=internal/client/mocks --packageprefix=mock
	mockery --dir=internal/cache/filesystem/. --all --output=internal/cache/filesystem/mocks --packageprefix=mock
	mockery --dir=internal/cache/lru/. --name=Cache --output=internal/cache/lru/mocks --packageprefix=mock
	mockery --dir=internal/app/. --all --output=internal/app/mocks --packageprefix=mock
	mockery --dir=internal/logger/. --all --output=internal/logger/mocks --packageprefix=mock

intgrtest:
	set -e ;\
	test_result=0 ;\
	COMPOSE_PROJECT_NAME=$(INTGRTEST_PROJECT) \
		docker-compose \
		-f ./deployments/docker-compose.test.yaml \
		up --build --remove-orphans --abort-on-container-exit --exit-code-from intgrtest || test_result=$$? ;\
	exit $$test_result ;

intgrtest-clean:
	COMPOSE_PROJECT_NAME=$(INTGRTEST_PROJECT) \
		docker-compose \
		-f ./deployments/docker-compose.test.yaml \
		down --rmi local --volumes --remove-orphans --timeout 60;

nginx:
	COMPOSE_PROJECT_NAME=$(INTGRTEST_PROJECT) \
		docker-compose \
		-f ./deployments/docker-compose.test.yaml \
		run  --service-ports nginx;

.PHONY: build run install-linter lint lint-fix build-img test mock intgrtest intgrtest-clean