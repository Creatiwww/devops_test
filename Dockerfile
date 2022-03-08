##
## Build
##
FROM golang:1.16-buster AS build

WORKDIR /app

COPY go.mod ./
COPY go.sum ./
RUN go mod download

COPY *.go ./

RUN go build -o /devops_test

##
## Deploy
##
FROM gcr.io/distroless/base-debian10

WORKDIR /

COPY --from=build /devops_test /devops_test

EXPOSE 8080
EXPOSE 9000

USER nonroot:nonroot

ENTRYPOINT ["/devops_test"]
