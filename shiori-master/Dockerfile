# build stage
FROM golang:1.19-alpine3.16 AS builder
WORKDIR /src
COPY . .
RUN go build -ldflags '-s -w'

# server image

FROM alpine:3.16
COPY --from=builder /src/shiori /usr/bin/
RUN addgroup -g 1000 shiori \
    && adduser -D -h /shiori -g '' -G shiori -u 1000 shiori
USER shiori
WORKDIR /shiori
EXPOSE 8080
ENV SHIORI_DIR /shiori/
ENTRYPOINT ["/usr/bin/shiori"]
CMD ["serve"]
