FROM archlinux:base-devel

RUN pacman -Syu --noconfirm --needed \
    base-devel \
    bash \
    coreutils \
    devtools \
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
  && rm -f /var/cache/pacman/pkg/*.pkg.tar.*

COPY docker/entrypoint.sh /usr/local/bin/gdops-container-entrypoint

WORKDIR /workspace
ENTRYPOINT ["/usr/local/bin/gdops-container-entrypoint"]
CMD ["./bin/gdops", "--help"]
