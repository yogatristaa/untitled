FROM golang:1.16-alpine

WORKDIR /app

COPY main.go .

RUN go build -o demo-service main.go

EXPOSE 8080

CMD ["./demo-service"]
