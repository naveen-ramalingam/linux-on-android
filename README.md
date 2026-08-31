# Linux Server Manager for Android

![Android](https://img.shields.io/badge/Platform-Android-3DDC84?logo=android&logoColor=white)
![Linux](https://img.shields.io/badge/Userspace-GNU%2FLinux-FCC624?logo=linux&logoColor=black)
![No Root](https://img.shields.io/badge/Privilege-Rootless%20%2B%20Root%20Supported-success)
![Shell](https://img.shields.io/badge/Shell-Bash-4EAA25?logo=gnu-bash&logoColor=white)

---

## 🚀 Overview

**Linux Server Manager for Android** is a modular, mobile-optimized management suite that installs, configures, and manages Linux distributions inside **Termux** using **proot-distro** (Rootless) and **Native Chroot** (Rooted).

Transform any Android phone or tablet into:
- 🌐 **Self-hosted Server**: Run web servers, databases, and APIs
- ⚡ **Rooted Bare-Metal Chroot**: 100% native kernel execution without PRoot overhead for rooted users (KernelSU, Magisk, APatch)
- 💻 **Development Machine**: Full development stack with Python, Node.js, C/C++, Rust, Go
- 🖥️ **Desktop Environment**: Lightweight LXDE desktop via VNC
- 🔒 **Secure Remote Access**: SSH server and VNC with port management
- 📱 **Mobile-First Experience**: Clean, responsive TUI designed for small touchscreens

👉 **Prefer manual installation?**  
Check out the **[Manual Installation Guide](docs/MANUAL-INSTALL.md)**.

---

## ✨ Key Features

### ⚡ Root Hub & Native Chroot (For Rooted Devices)
- **Bare-Metal Chroot Shell**: 100% native Linux kernel speed (zero ptrace/PRoot emulation overhead)
- **Hardware & Kernel Diagnostics**: Detects KernelSU, Magisk, APatch, `/dev/net/tun` (VPN/WireGuard), `/dev/kvm` (Hardware Virtualization), and Adreno/Mali GPU nodes (`/dev/kgsl-3d0`)
- **SELinux Switcher**: Toggle between Permissive and Enforcing modes
- **Privileged Port Forwarding**: Redirect standard ports (`80` -> `8080`, `443` -> `8443`, `22` -> `2222`) using root `iptables`
- **Device Swap / RAM Booster**: Allocate and activate Linux swap files to prevent OOM kills during heavy builds

### 📱 Mobile-Optimized TUI
- Responsive status bar showing active distro, root status, IP address, battery, storage, and RAM
- Big, touch-friendly numbered menus with universal quick back/exit shortcuts (`0`, `b`, `q`)
- Graceful color fallback for non-color terminals
- Designed specifically for portrait mode and on-screen keyboards

### 🏗️ Modular Architecture
- Clean library structure under `lib/` for easy extension
- Independent modules for system detection, networking, distro management, VNC, SSH, backups, and packages

### 🐧 Distribution Management
- One-click install of Debian, Ubuntu, Alpine, Arch, Fedora, and more via `proot-distro`
- User management with automated passwordless `sudo` configuration
- Clean uninstallation (single distro or full wipe)

### 🌐 Network & Remote Access Hub
- **Auto-Detect IP Address**: Instant lookup of local Wi-Fi, hotspot, cellular, and VPN/Tailscale/WireGuard IPs
- **SSH & VNC Direct Connection Strings**: Formats ready-to-use commands (`ssh user@<IP> -p 2222`) and VNC addresses (`<IP>:5901`) with configured passwords
- **SSH Client Mode**: Connect directly to remote servers, Raspberry Pis, or PCs by entering their IP from within the manager
- **Real-Time Status Bar**: Your device's active IP address is always visible on the top status bar

### 🖥️ Remote Display & Access
- Automated LXDE desktop + TightVNC configuration with instant connection card
- Auto-cleanup of stale VNC locks (`X1-lock`)
- SSH server management (start, stop, status monitoring)
- Network IP detection for easy LAN connections

### 💾 Backup & Restore
- Full rootfs backup to `.tar.gz` with configuration preservation
- Simple one-command restore

### 🔧 System Diagnostics
- Environment checks (Termux prefix, proot-distro version, architecture)
- Resource monitoring (storage, battery, memory)
- Network interface and port inspection

---

## 📦 Requirements

- Android **8.0+**
- **Termux** ([F-Droid](https://f-droid.org/packages/com.termux/) recommended)
- **4–6 GB** free storage
- Active network connection
- Optional: VNC viewer ([bVNC](https://f-droid.org/packages/com.iiordanov.freebVNC/) or RealVNC)

---

## 🛠 Quick Start

1. Install **Termux** from F-Droid:  
   https://f-droid.org/packages/com.termux/

2. Update Termux and install Git:

   ```bash
   apt update && apt upgrade -y
   apt install git -y
   ```

3. Clone the repository:

   ```bash
   git clone https://github.com/naveen-ramalingam/linux-on-android.git
   cd linux-on-android
   ```

4. Make the script executable:

   ```bash
   chmod +x linux-on-android.sh
   ```

5. Run the manager:

   ```bash
   ./linux-on-android.sh
   ```

---

## 📂 Project Structure

```
Linux-on-Android/
├── linux-on-android.sh    # Main interactive entry point & CLI router
├── lib/                   # Modular libraries (16 modules)
│   ├── colors.sh          # Terminal styling, color detection & themes
│   ├── config.sh          # Centralized configuration (~/.linux-on-android.conf)
│   ├── system.sh          # System detection (CPU, RAM, battery, storage)
│   ├── network.sh         # Network interfaces, LAN detection & port scanner
│   ├── distro.sh          # proot-distro lifecycle management & profiles
│   ├── users.sh           # Non-root user creation & sudo provisioning
│   ├── ssh.sh             # OpenSSH server manager & key setup
│   ├── vnc.sh             # LXDE / XFCE / TightVNC display manager
│   ├── services.sh        # Service supervisor (PID/Port tracking without systemd)
│   ├── recommendations.sh # Hardware-based distro & desktop recommendations
│   ├── wizard.sh          # 6-step interactive first-run & custom install wizards
│   ├── logs.sh            # Structured logging engine, log rotation & viewer
│   ├── ui.sh              # Responsive TUI (cards, progress bars, spinners)
│   ├── diagnostics.sh     # System doctor & environment audit
│   ├── backup.sh          # Compressed rootfs backup & restore
│   └── packages.sh        # Curated stack installers (Web, Python, Docker/Podman)
├── docs/
│   └── MANUAL-INSTALL.md  # Step-by-step manual setup guide
└── LICENSE                # MIT License
```

---

## ⚡ CLI Arguments & Automation

In addition to the interactive TUI menu, `linux-on-android.sh` can be executed directly with CLI flags for automation and quick checks:

| Flag | Description |
|---|---|
| `--status` | Show active system & distro status overview |
| `--auto-install` | Auto-detect hardware specs and run recommended installation |
| `--wizard` | Launch the guided 6-step setup wizard |
| `--recommend` | Inspect device hardware and show distro/desktop sizing recommendations |
| `--services` | Open the unified service supervisor (SSH, VNC, Desktop) |
| `--logs` | Open the structured log viewer & statistics |
| `--doctor` | Run comprehensive system diagnostics and environment health check |
| `--start-vnc [distro]` | Start VNC server for the default or specified distro |
| `--stop-vnc [distro]` | Stop running VNC server and clean stale locks |
| `--start-ssh [distro]` | Start OpenSSH daemon in distro userspace |
| `--stop-ssh [distro]` | Stop running OpenSSH server |
| `--help` / `-h` | Display command-line usage reference |

---

## 🧩 What the Script Does

### 1. Hardware-Aware Recommendations
Analyzes available RAM, CPU architecture, and free disk space to classify devices into **Low**, **Mid**, or **High** spec tiers, offering tailored distro recommendations (e.g. Alpine for low-spec, Ubuntu/Debian for high-spec).

### 2. Guided 6-Step Setup Wizard
Interactive walkthrough to choose:
1. Target Distribution
2. Non-root Username & Secure Password
3. Desktop Environment (LXDE, XFCE, or Headless Server)
4. Remote Access Services (SSH, VNC)
5. Custom Port Configuration
6. Pre-installed Development Stacks

### 3. Service Supervision (Without systemd)
Because PRoot runs rootless in Android userspace without `systemd` or `init`, traditional service managers fail. Our `lib/services.sh` provides direct PID tracking, port monitoring, automated lockfile cleanup (`/tmp/.X1-lock`), and clean background process lifecycle management.

### 4. Structured Logging & Auditing
All installation steps, service transitions, errors, and diagnostics are recorded with timestamps to `~/.linux-on-android.log` with automatic log rotation and an interactive log viewer.

### 5. Installs your chosen Linux distro
Supports Debian, Ubuntu, Alpine, Arch, Fedora, and Void through `proot-distro`.

### 6. Creates a non‑root user
Passwordless or secure authenticated login with safe sudo access.

### 7. Saves configuration & Profiles
Stores global settings in `~/.linux-on-android.conf` and per-distro profiles in:

```
$PREFIX/etc/linux-on-android/<distro>.conf
```

### 8. Provides clean uninstall options
Remove one distro or all of them with full cleanup.

---

## 🖥 Using Your Linux Environment

### Login to your distro:

```bash
proot-distro login <distro> --
```

### Switch to your user:

```bash
su - <username>
```

---

## 🖼 Using VNC (if GUI installed)

### Start VNC:

```bash
vncserver -geometry 1920x1080 :1
```

### Stop VNC:

```bash
vncserver -kill :1
```

### Connect from Android VNC viewer:

```
localhost:5901
```

Password: `1234` (default)

---

## 🔌 How to Cleanly Shut Down Everything

### 1. Stop the VNC desktop  
```bash
vncserver -kill :1
```

### 2. Exit the user session  
```bash
exit
```

### 3. Exit the distro  
```bash
exit
```

### 4. Kill leftover proot processes (optional)  
From Termux:

```bash
pkill -9 -f proot
```

### 5. Close Termux  
```bash
exit
```

Then swipe Termux away from recent apps.

---

## 🗑 Uninstalling

### Remove a single distro:

```bash
./linux-on-android.sh
```

Choose: **Uninstall a specific distro**

### Remove all distros:

Choose: **Uninstall ALL distros**

You can also optionally remove `proot-distro`.

---

## 🐧 Supported Distributions

Any distro supported by `proot-distro`, including:

- Debian  
- Ubuntu  
- Arch Linux  
- Fedora  
- Alpine  
- Void Linux  

---

## ⚠ Known Limitations

- No GPU acceleration (Android does not expose GPU to proot)  
- No systemd  
- VNC performance depends on device hardware  
- Some desktop apps may require additional packages  

---

## ❓ FAQ

### **Q: Why are so many packages missing in my Linux-on-Android install?**
Most `proot-distro` rootfs images are **intentionally minimal**. They include only the bare essentials needed to boot a userspace environment. This keeps downloads small, reduces storage usage, and speeds up installation — but it also means many common tools are not included by default.

It’s normal for the following to be missing:

- Editors (`nano`, `vim`, `micro`)

- Build tools (`make`, `gcc`, `cmake`, `pkg-config`)

- Networking utilities (`curl`, `wget`, `net-tools`)

- Compression tools (`zip`, `unzip`, `tar`, `xz-utils`)

- GUI components (if you didn’t install a desktop environment)

You can install any of these manually using your distro’s package manager.

### **Q: How do I install missing packages?**
Use your distro’s package manager:

- Debian/Ubuntu: `sudo apt install <package>`

- Arch Linux: `sudo pacman -S <package>`

- Alpine: `sudo apk add <package>`

- Fedora: `sudo dnf install <package>`

- Void Linux: `sudo xbps-install <package>`

### **Q: Why does my distro say “Unable to locate package <package>”?**
This usually means one of the following:

- Your rootfs image is extremely minimal

- Your package lists are outdated

- Optional repositories (like “community”, “extra”, “contrib”, or “nonfree”) are disabled

- The package isn’t available for your architecture (ARM vs ARM64 vs x86_64)

Updating your package lists or enabling additional repositories typically fixes this.

### **Q: Where can I learn more about my distro’s package system?**
Here are official resources for each major distro supported by proot-distro:

- Debian/Ubuntu: https://wiki.debian.org/Apt

- Arch Linux: https://wiki.archlinux.org/title/Pacman

- Alpine: https://wiki.alpinelinux.org/wiki/Alpine_Linux_package_management

- Fedora: https://docs.fedoraproject.org/en-US/quick-docs/dnf/

- Void Linux: https://docs.voidlinux.org/xbps/index.html

These pages explain how to enable extra repositories, install missing tools, and troubleshoot package issues.

### **Q: Does this give me real hardware access (GPU, kernel modules, etc.)?**  
No. proot runs in userspace and cannot access kernel‑level hardware like GPU, DRM, or kernel modules.

### **Q: Why can’t I use systemd?**  
proot does not support PID 1 or kernel‑level init systems. Use supervisord or run services manually.

### **Q: Why do I need `su - <username>` instead of `su <username>`?**  
`su -` loads a full login environment (PATH, HOME, DBus, configs).  
`su` does not, and it breaks desktops and VNC.

### **Q: Why does VNC show “No session for pid XXXX”?**  
This usually means an LXDE component failed to attach to the session.  
Check:

```
~/.cache/lxsession/LXDE/run.log
```

### **Q: Can I install XFCE, KDE, or GNOME?**  
Yes, but they are heavy and may perform poorly on older devices. LXDE is recommended.

### **Q: Can I run Docker or LXC?**  
No, they require kernel features unavailable in proot.

### **Q: Can I use this on a non‑ARM device?**  
Yes. proot-distro supports ARM, ARM64, and x86_64 depending on Termux architecture.

---

## 🛠 Troubleshooting

### **VNC won’t start / port already in use**
Run:

```bash
rm -f /tmp/.X1-lock /tmp/.X11-unix/X1
```

Then:

```bash
vncserver :1
```

### **LXDE shows “Cannot start pid XXXX”**
Check:

```
~/.cache/lxsession/LXDE/run.log
```

### **Desktop is slow**
Try:

- Lower resolution: `vncserver -geometry 1280x720 :1`
- Disable compositing in LXDE
- Use a lighter distro (Alpine, Debian minimal)

### **proot-distro command not found**
Install it:

```bash
apt install proot-distro -y
```

---

## 🤝 Contributing

Contributions, ideas, and improvements are welcome!  
Feel free to:

- Open an issue  
- Submit a pull request  
- Suggest features  
- Share creative use‑cases  

---

## ❤️ Closing Thoughts

This project is built for people who love repurposing old hardware, reducing e‑waste, and exploring what’s possible with minimal resources.  
If you have ideas, improvements, or want to contribute, feel free to reach out or open an issue.

