#!/bin/bash

dnf update && dnf -y upgrade && dnf clean all

cd /opt/
podman-compose pull
podman-compose up -d
podman image prune -af
podman volume prune -f