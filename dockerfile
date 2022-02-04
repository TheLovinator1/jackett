FROM archlinux

# Jackett version
ARG pkgver="0.20.470"

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
# Also create folder that we will use later.
# https://linux.die.net/man/8/useradd
# https://linux.die.net/man/8/groupadd
RUN groupadd --gid 1000 --system jackett && \
useradd --system --uid 1000 --gid 1000 jackett && \
install -d -o jackett -g jackett -m 775 /var/lib/jackett /usr/lib/jackett/ /tmp/jackett

# Update the system and install depends
RUN pacman -Syu --noconfirm && pacman -S curl openssl-1.0 --noconfirm

# Download and extract everything to /tmp/jackett, it will be removed after installation
WORKDIR /tmp/jackett

# Download and extract the package
ADD "https://github.com/Jackett/Jackett/releases/download/v${pkgver}/Jackett.Binaries.LinuxAMDx64.tar.gz" "/tmp/jackett/Jackett.Binaries.LinuxAMDx64-${pkgver}.tar.gz"
RUN tar -xf "Jackett.Binaries.LinuxAMDx64-${pkgver}.tar.gz" -C /tmp/jackett && \
rm "Jackett.Binaries.LinuxAMDx64-${pkgver}.tar.gz" && \
install -d -m 755 "/usr/lib/jackett/" && \
cp -dpr --no-preserve=ownership "Jackett/." "/usr/lib/jackett/" && \
chmod +x "/usr/lib/jackett/jackett" && \
rm -rf "/tmp/jackett" && \
chown -R jackett:jackett /var/lib/jackett /usr/lib/jackett/

# Where Jackett will store its data
WORKDIR /var/lib/jackett
VOLUME /var/lib/jackett

# Web UI
EXPOSE 9117/tcp

# Don't run as root
USER jackett

# This folder will be used to store your config files. Oterwise, it will use your /home folder.
ENV XDG_CONFIG_HOME=/var/lib/jackett

# Launch Jackett and disable updates
CMD ["/usr/lib/jackett/jackett", "--NoRestart", "--NoUpdates", "--DataFolder", "/var/lib/jackett"]
