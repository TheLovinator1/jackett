FROM ubuntu:devel

# https://github.com/opencontainers/image-spec/blob/main/annotations.md#pre-defined-annotation-keys
LABEL org.opencontainers.image.authors="Joakim Hellsén <tlovinator@gmail.com>" \
org.opencontainers.image.url="https://github.com/TheLovinator1/jackett" \
org.opencontainers.image.documentation="https://github.com/TheLovinator1/jackett" \
org.opencontainers.image.source="https://github.com/TheLovinator1/jackett" \
org.opencontainers.image.vendor="Joakim Hellsén" \
org.opencontainers.image.license="GPL-3.0+" \
org.opencontainers.image.title="Jackett" \
org.opencontainers.image.description="More trackers for Sonarr, Radarr, Lidarr and other arrs."

# Jackett version
ARG pkgver=v0.20.811

# Update the system and install depends
# https://packages.ubuntu.com/search?suite=jammy&arch=amd64&searchon=names&keywords=libicu
# TODO: #8 Automate libicu version with LoviBot?
RUN apt-get update && apt-get install -y curl libicu70

# Download and extract everything to /tmp/jackett, it will be removed after installation
WORKDIR /tmp/jackett

# Download and extract the package
ADD "https://github.com/Jackett/Jackett/releases/download/${pkgver}/Jackett.Binaries.LinuxAMDx64.tar.gz" "/tmp/jackett/Jackett.Binaries.LinuxAMDx64-${pkgver}.tar.gz"
RUN tar -xf "Jackett.Binaries.LinuxAMDx64-${pkgver}.tar.gz" -C /tmp/jackett && \
rm "Jackett.Binaries.LinuxAMDx64-${pkgver}.tar.gz" && \
useradd --system --home /var/lib/jackett --shell /bin/nologin lovinator && \
install -d -o lovinator -g lovinator -m 755 /var/lib/jackett /usr/lib/jackett && \
cp -dpr --no-preserve=ownership "Jackett/." "/usr/lib/jackett/" && \
chmod +x "/usr/lib/jackett/jackett" && \
rm -rf "/tmp/jackett" && \
chown -R lovinator:lovinator /var/lib/jackett /usr/lib/jackett/

# Where Jackett will store its data
WORKDIR /var/lib/jackett
VOLUME /var/lib/jackett

# Web UI
EXPOSE 9117/tcp

# Don't run as root
USER lovinator

# This folder will be used to store your config files. Oterwise, it will use your /home folder.
ENV XDG_CONFIG_HOME=/var/lib/jackett

# Launch Jackett and disable updates
CMD ["/usr/lib/jackett/jackett", "--NoRestart", "--NoUpdates", "--DataFolder", "/var/lib/jackett"]
