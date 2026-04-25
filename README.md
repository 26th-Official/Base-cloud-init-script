# Base-cloud-init-script

A secure, production-ready cloud-init configuration for hardening new Ubuntu servers from first boot.

---

## What It Does

This script automates the initial setup and security hardening of a fresh Ubuntu server. It is intended to be passed as **User Data** when provisioning a cloud instance (AWS, DigitalOcean, Hetzner, etc.).

### Security Features

| Feature | Details |
|---|---|
| **Fail2Ban** | Blocks brute-force SSH login attempts. Bans IPs after 3 failed retries within 10 minutes for 1 hour. |
| **Unattended Upgrades** | Automatically installs security patches so the server stays up to date without manual intervention. |
| **Tailscale VPN + SSH** | Provides encrypted, authenticated remote access via Tailscale. `tailscale up --ssh` replaces traditional SSH key management with Tailscale's identity-based access controls. |
| **haveged** | Ensures sufficient entropy is always available, which is critical for cryptographic operations (key generation, TLS, etc.) on virtual machines that typically have low hardware entropy. |
| **UTC timezone + time sync** | Keeps system time accurate via `systemd-timesyncd`, which is essential for log correlation, certificate validation, and audit trails. |

### Installed Tools

- **Node.js** (latest LTS via NodeSource)
- **Git** (latest stable via `git-core/ppa`)
- **Docker** (CE + CLI + containerd + Buildx + Compose plugin, official Docker repository)

---

## Usage

### 1. Replace the Tailscale Auth Key

Before deploying, open `cloudinit.yml` and replace the placeholder auth key with your real one:

```yaml
- tailscale up --authkey=YOUR_AUTH_KEY --ssh
```

Generate an auth key at: <https://login.tailscale.com/admin/settings/keys>

> **Tip:** Use a **pre-authorized, ephemeral** key for automated provisioning so the node is automatically removed from your network when it is shut down.

### 2. Deploy

Paste the contents of `cloudinit.yml` into the **User Data** field of your cloud provider's instance-creation wizard, or supply it via the CLI.

**AWS CLI example:**

```bash
aws ec2 run-instances \
  --image-id ami-xxxxxxxxxxxxxxxxx \
  --instance-type t3.micro \
  --user-data file://cloudinit.yml \
  ...
```

**DigitalOcean CLI example:**

```bash
doctl compute droplet create my-server \
  --image ubuntu-24-04-x64 \
  --size s-1vcpu-1gb \
  --user-data-file cloudinit.yml \
  ...
```

### 3. Verify After Boot

Once the instance is running, SSH in via Tailscale and confirm services are healthy:

```bash
# Fail2Ban running
sudo systemctl status fail2ban

# Unattended upgrades configured
cat /etc/apt/apt.conf.d/20auto-upgrades

# Docker accessible without sudo
docker ps

# Tailscale connected
tailscale status
```

---

## Security Notes

- **Do not commit real auth keys** to version control. Use CI/CD secrets or a secrets manager to inject the key at deploy time.
- The `ubuntu` user is added to the `docker` group. Be aware that membership in this group is equivalent to root access on the host — restrict it accordingly.
- Review and tighten the Fail2Ban jail settings (`/etc/fail2ban/jail.local`) to match your threat model (e.g., lower `maxretry`, increase `bantime`).
- Consider disabling password-based SSH authentication (`PasswordAuthentication no` in `/etc/ssh/sshd_config`) and relying solely on Tailscale SSH or key-based auth.
