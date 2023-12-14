FROM golang:1.17.9-alpine as build

WORKDIR /go/src

COPY go.mod .
COPY go.sum .
RUN go mod download

COPY . .

RUN CGO_ENABLED=0 go build -o /opt/image-previewer/previewer ./cmd/previewer/main.go

FROM alpine:3.15

ENV HTTP_PORT "8000"

COPY --from=build /opt/image-previewer/previewer /opt/image-previewer/previewer

ENTRYPOINT ["/opt/image-previewer/previewer"]