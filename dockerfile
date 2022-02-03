FROM archlinux

ARG pkgver="0.20.470"
ARG source_x86_64="https://github.com/Jackett/Jackett/releases/download/v${pkgver}/Jackett.Binaries.LinuxAMDx64.tar.gz"

# Add mirrors for Sweden. You can add your own mirrors to the mirrorlist file. Should probably use reflector.
ADD mirrorlist /etc/pacman.d/mirrorlist

# NOTE: For Security Reasons, archlinux image strips the pacman lsign key.
# This is because the same key would be spread to all containers of the same
# image, allowing for malicious actors to inject packages (via, for example,
# a man-in-the-middle).
RUN gpg --refresh-keys && pacman-key --init && pacman-key --populate archlinux

# Set locale. Needed for some programs.
# https://wiki.archlinux.org/title/locale
RUN echo "en_US.UTF-8 UTF-8" >"/etc/locale.gen" && locale-gen && echo "LANG=en_US.UTF-8" >"/etc/locale.conf"

# Create a new user with id 1000 and name "jackett".
# https://linux.die.net/man/8/useradd
# https://linux.die.net/man/8/groupadd
RUN groupadd --gid 1000 --system jackett && \
useradd --system --uid 1000 --gid 1000 jackett && \
install -d -o jackett -g jackett -m 775 /var/lib/jackett /usr/lib/jackett/ /tmp/jackett

# Update the system and install depends
RUN pacman -Syu --noconfirm && pacman -S curl openssl-1.0 wget --noconfirm

WORKDIR /tmp/jackett

RUN wget "${source_x86_64}" -O "Jackett.Binaries.LinuxAMDx64-${pkgver}.tar.gz"
RUN tar -xf "Jackett.Binaries.LinuxAMDx64-${pkgver}.tar.gz" -C /tmp/jackett && \
rm "Jackett.Binaries.LinuxAMDx64-${pkgver}.tar.gz" && \
install -d -m 755 "/usr/lib/jackett/" && \
cp -dpr --no-preserve=ownership "Jackett/." "/usr/lib/jackett/" && \
chmod +x "/usr/lib/jackett/jackett" && \
rm -rf "/tmp/jackett" && \
chown -R jackett:jackett /var/lib/jackett /usr/lib/jackett/

WORKDIR /var/lib/jackett
VOLUME /var/lib/jackett

EXPOSE 9117

USER jackett

# This folder will be used to store your config files. Oterwise, it will use your /home folder.
ENV XDG_CONFIG_HOME=/var/lib/jackett

CMD ["/usr/lib/jackett/jackett", "--NoRestart", "--NoUpdates", "--DataFolder", "/var/lib/jackett"]
