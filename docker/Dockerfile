FROM archlinux:base-devel

RUN pacman -Syu --noconfirm --needed \
    base-devel \
    bash \
    coreutils \
    diffutils \
    findutils \
    git \
    grep \
    namcap \
    openssh \
    pacman-contrib \
    sed \
    shellcheck \
    sudo \
    tar \
    zstd \
  && pacman -Scc --noconfirm

COPY docker/entrypoint.sh /usr/local/bin/gdops-container-entrypoint

WORKDIR /workspace
ENTRYPOINT ["/usr/local/bin/gdops-container-entrypoint"]
CMD ["./bin/gdops", "--help"]
