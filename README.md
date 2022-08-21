# Docker setup

This document is inspired by [Home Automation Guy](https://www.homeautomationguy.io/), [TRasH guides](https://trash-guides.info) and [Servarr](https://wiki.servarr.com).

Main difference is this guide is built on Fedora and Podman, rather than Ubuntu and Docker. 

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

## Prerequisites
- Podman
- Podman compose


```
sudo dnf update && 
sudo dnf -y upgrade &&
sudo chown $(id -u) /opt &&
sudo dnf -y install podman podman-compose &&
systemctl --user enable --now podman.socket &&
wget https://raw.githubusercontent.com/jlor/portal/main/docker-compose.yaml -P /opt/ &&
wget https://raw.githubusercontent.com/jlor/portal/main/update.sh -P /opt/ &&
mkdir /opt/{duplicati,homeassistant,media,mqtt,nzbget,portainer,radarr,sonarr} &&
cd /opt &&
sudo firewall-cmd --add-port=9000/tcp --add-port=8123/tcp --add-port=8200/tcp &&
sudo firewall-cmd --runtime-to-permanent &&
podman-compose up -d
```

### Troubleshooting
In case portainer isn't working correctly, verify your users ID. If it is not `1000`, correct the ID in the `docker-compose.yaml` file for the portainer service.


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
Open portainer on port `:9000`, for me that is [http://portal.tm234.lan:9000](http://portal.tm234.lan:9000). Setup a password and configure it to use a "docker" socket.


### Duplicati
Open Duplicati on port `:8200`, for me that is [http://portal.tm234.lan:8200](http://portal.tm234.lan:8200). Setup a backup for your /source directory with a filter excluding `/media/*` to avoid backing up your media.

I have set my backup to occur at 2AM every day and push it to a system outside my home.


### Home Assistant
Open Home Assistant UI on port `:8123`, for me that is [http://portal.tm234.lan:8123](http://portal.tm234.lan:8123). Create an account.

Install [HACS](https://hacs.xyz/docs/setup/download):
```
cd /opt/homeassistant
wget -O - https://get.hacs.xyz | bash -
```

Restart HomeAssistant from UI -> Settings -> System -> Top right "Restart".

Once restarted, go to Settings -> Integrations -> Add Integration -> Search for `HACS` and add it. Follow on screen directions.

#### MQTT

### NZB stack

#### NzbGet

#### Radarr

#### Sonarr

## Improvements
Look into Fedora CoreOS or SilverBlue.

Alternatively move everything to a kubernetes cluster + helm charts.