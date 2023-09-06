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

## DNS and firewall rules
Shamelessly stolen from [Matthew Hodgkins](https://hodgkins.io/securing-home-assitant-with-cloudflare)
- Setup CloudFlare (free)
  - Setup domain to point to your home IP. Make sure you pick "proxy" here!
  - Create SSL/TLS certificate in CloudFlare and save the private key in /opt/homeassistant/config/privkey.key and certificate in /opt/homeassistant/config/origin.pem.
  - Setup CloudFlare firewall (WAF) to only allow your country through to the chosen domain.
- Setup NAT port forwarding from WAN port 8443 -> IP of your host running the pods, port 8443.
- Setup your firewall to only allow access from CloudFlares IP addresses.


## TODO
- Setup log aggregation & visualization
- Configure & setup 2FA SSH

## Prerequisites
- Podman
- Podman compose


```
sudo dnf update && 
sudo dnf -y upgrade &&
loginctl enable-linger &&
sudo mkdir /opt &&
sudo chown $(id -u) /opt &&
sudo dnf -y install podman podman-compose cockpit-podman &&
wget https://raw.githubusercontent.com/jlor/portal/main/docker-compose.yaml -P /opt/ &&
wget https://raw.githubusercontent.com/jlor/portal/main/update.sh -P /opt/ &&
sudo semanage fcontext -a -t container_file_t '/opt(/.*)?' &&
mkdir /opt/{duplicati,homeassistant,media,mqtt,zigbee2mqtt,nzbget,radarr,sonarr} &&
sudo restorecon -Rv /opt &&
cd /opt &&
sudo firewall-cmd --add-port=9090/tcp --add-port=8433/tcp --add-port=8200/tcp &&
sudo firewall-cmd --add-port=8080/tcp --add-port=8081/tcp --add-port=8082/tcp &&
sudo firewall-cmd --add-port=1883 --add-port=9001 &&
sudo firewall-cmd --runtime-to-permanent &&
podman-compose up -d &&
systemctl enable --user podman-restart.service
```

### Troubleshooting
In case portainer isn't working correctly, verify your users ID. If it is not `1000`, correct the ID in the `docker-compose.yaml` file for the portainer service.


### Mounts
```
/opt
├── portainer
├── duplicati
├── homeassistant
├── mqtt
├── nzbget
├── radarr
├── sonarr
└── media (mounted from single NAS volume)
    ├── tmp (temporary downloaded files)
    │   ├── completed
    │   │   ├── movies
    │   │   └── tv
    │   └── incomplete (in progress downloads)
    ├── movies
    └── tv
```

It is important that the media mount is a single volume, containing both the download folder and the target folder for media. This way hardlinks can be used which make moving unpacked content instant.

Keep in mind the entire media folder should be made available to nzbget to make use of hardlinks. See more on [TRaSH's hardlink tutorial](https://trash-guides.info/Hardlinks/How-to-setup-for/Docker/) or the [tutorial at Servarr](https://wiki.servarr.com/docker-guide).

## Auto updating
If you want to enable auto updating of the OS and containers, add `/opt/update.sh` to roots crontab:
```
sudo crontab -u root -l; echo "0 5 * * 6 /opt/update.sh >> /opt/update.log" | sudo crontab -u root -
```
This will run the `update.sh` script every Saturday at 5am giving you plenty of time to read changelogs from Home Assistant that are published on the first Wednesday of each month.

## Containers

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
Setup password for MQTT:
```
podman-compose exec mqtt mosquitto_passwd -b /mosquitto/config/passwd <user> <password>
```

Delete user: 
```
podman-compose exec mqtt mosquitto_passwd -D /mosquitto/config/passwd <user>
```

### NZB stack

#### SabNZBd
Open SabNZBd UI on port `:8080`, for me that is [http://10.0.0.4:8080](http://10.0.0.4:8080). Follow on screen instructions.

NB: Need to use IP to get around the [hostname block of SabNZBd](https://sabnzbd.org/wiki/extra/hostname-check.html).

Depending on how you have setup your NFS mounts, you may need to manually create the complete and incomplete folders and set _very_ wide permissions:
```
mkdir /opt/media/tmp/{complete,incomplete}
sudo chmod 777 /opt/media/tmp/{complete,incomplete}
```

Remember to setup your folders so:
```
Temporary Download Folder: /data/tmp/incomplete
Completed Download Folder: /data/tmp/completed
```

And set relative folders for the `movies` and `tv` categories.

#### Radarr
Add the root folder for `/data/movies` under media management.

Add SabNZBd as download client under `Settings -> Download Clients`. Find the API key from SabNZBd under General in SabNZBd UI.

#### Sonarr
Add the root folder for `/data/tv` under media management.

Add SabNZBd as download client under `Settings -> Download Clients`. Find the API key from SabNZBd under General in SabNZBd UI.

## Improvements
- Look into Fedora CoreOS or SilverBlue.

- Alternatively move everything to a kubernetes cluster + helm charts.
  - Will move to https://github.com/x00-sh/k8s-prod

- Work with SELinux rather than disable it for the required paths.

  - `sudo chcon -Rt svirt_sandbox_file_t /opt /run/user/$(id -u)/podman/podman.sock` might not be needed.
