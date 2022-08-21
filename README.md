# Docker setup

## System sizing
CPU cores: 4

Memory: 16Gb

Disk size: 150Gb

OS: Fedora Server 36

Network: VMNet being routed/controlled by OPNSense

Running on a virtual host under ESXi.

## TODO
- Configure & setup containers
- Configure & setup 2FA SSH
- Configure firewall rules

## Prerequisites
- Podman
- Podman compose

[Enable podman socket for root context](https://github.com/portainer/portainer/issues/2991):
`systemctl --user enable --now podman.socket`

```
sudo dnf update && 
sudo dnf -y upgrade &&
sudo chown $(id -u) /opt &&
sudo dnf -y install podman podman-compose git &&
systemctl --user enable --now podman.socket &&
cd /opt && git clone git@github.com:jlor/portal.git
```


### Mounts
/opt
  - portainer
  - duplicati
  - homeassistant
  - mqtt
  - nzbget
  - radarr
  - sonarr
  - media (mounted from single NAS volume)
    - tmp (keeping temporary downloaded files)
    - tv
    - movies

It is important that the media mount is a single volume, containing both the download folder and the target folder for media. This way hardlinks can be used which make moving unpacked content instant.

Keep in mind the entire media folder should be made available to nzbget to make use of hardlinks. See more on [TRaSH's hardlink tutorial](https://trash-guides.info/Hardlinks/How-to-setup-for/Docker/) or the [tutorial at Servarr](https://wiki.servarr.com/docker-guide).

## Containers

### Portainer

### Duplicati

### Home Assistant

#### MQTT

### NZB stack

#### NzbGet

#### Radarr

#### Sonarr

## Improvements
Look into Fedora CoreOS or SilverBlue.

Alternatively move everything to a kubernetes cluster + helm charts.