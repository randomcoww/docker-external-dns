# This is mostly copied from https://github.com/kubernetes-sigs/external-dns/blob/master/Dockerfile
#
# Image is normally available at registry.opensource.zalan.do/teapot/external-dns:latest
# but is slow and occasionally down from my location
#
FROM golang:1.13-alpine as builder

WORKDIR /sigs.k8s.io
ENV VERSION v0.5.17

RUN set -x \
  \
  && apk add --no-cache \
    git \
    make \
    g++ \
  \
  && git clone -b $VERSION \
    https://github.com/kubernetes-sigs/external-dns.git \
  && cd external-dns \
  && go mod vendor \
  && make build

FROM alpine:edge

COPY --from=builder /sigs.k8s.io/external-dns/build/external-dns /bin/

RUN set -x \
  \
  && apk add --no-cache \
    ca-certificates \
  && update-ca-certificates

# Run as UID for nobody since k8s pod securityContext runAsNonRoot can't resolve the user ID:
# https://github.com/kubernetes/kubernetes/issues/40958
USER 65534

ENTRYPOINT ["/bin/external-dns"]