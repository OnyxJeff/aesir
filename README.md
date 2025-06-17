# Aesir

![Build Status](https://github.com/OnyxJeff/aesir/actions/workflows/build.yml/badge.svg)
![Maintenance](https://img.shields.io/maintenance/yes/2025.svg)
![License](https://img.shields.io/badge/license-MIT-green.svg)
![GitHub release](https://img.shields.io/github/v/release/OnyxJeff/aesir)
![Issues](https://img.shields.io/github/issues/OnyxJeff/aesir)

**Aesir** is my homelab's command center—an Intel NUC running **Proxmox**, managing my container infrastructure via **Portainer**. It powers essential services like:

- `*-darr stack` (Sonarr, Radarr, etc.)
- `netboot.xyz` for PXE booting
- `nginx-proxy-manager` for reverse proxy and SSL management

---

## 📁 Repo Structure

```text
aesir/
├── .github/workflows/ # CI for Compose/YAML validation
├── docker/ # All Docker Compose stacks
│ ├── portainer/
│ │ ├── containers/
│ │ │ ├── gitea/
│ │ │ ├── media-stack/
│ │ │ ├── netboot-xyz/
│ │ └─└── nginxrp/
│ └── dockprom/
├── scripts/ # Utility scripts and backups
└── README.md # System overview and service notes
```

---

## 🚀 Deployment

After installing Proxmox on this node this should be installed into a Linux VM or Ubuntu LXC container.

To deploy a stack:

```bash
cd aesir/docker/portainer/containers/"stack-name"
docker-compose up -d
```

---

## 🧰 Services

| Stack               | Description                                |
| :---                | :---:                                      |
| darr-stack          | Media automation with Sonarr, Radarr, etc. |
| nginx-proxy-manager |	Reverse proxy with SSL & GUI               |
| netbootxyz          | PXE boot server                            |

---

## 💾 Backup
To backup container volumes:

```bash
bash scripts/backup.sh
```
This will tarball volumes for media apps, proxy configs, and Portainer data.

---

📬 Maintained By
Jeff M. • [@OnyxJeff](https://github.com/onyxjeff)