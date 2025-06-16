# Aesir

![Build](https://github.com/OnyxJeff/ha-aesir-1/actions/workflows/build.yml/badge.svg)
![Maintained](https://img.shields.io/badge/maintained-yes-blue)

**Aesir** is my homelab's command center—an Intel NUC running **Proxmox**, managing my container infrastructure via **Portainer**. It powers essential services like:

- `*-darr stack` (Sonarr, Radarr, etc.)
- `netboot.xyz` for PXE booting
- `nginx-proxy-manager` for reverse proxy and SSL management

---

## 📁 Repo Structure

```text
aesir-1/
├── .github/workflows/    # CI for YAML validation
├── docker/               # YAML-based -darr stack and other applications
├── scripts/              # Shared/reusable automation logic
└── README.md             # You're reading it!
```

---

## 🚀 Deployment

After installing Proxmox on this node this should be installed into a Linux VM or Ubuntu LXC container.

To deploy a stack:

```bash
cd docker/"stack-name"
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