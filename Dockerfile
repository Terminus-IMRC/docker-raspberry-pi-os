FROM --platform=$TARGETPLATFORM scratch
ARG TARGETPLATFORM
ARG TARGETARCH
ADD root-$TARGETARCH.tar /
CMD ["bash"]
