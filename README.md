# Linux Server Manager for Android

![Android](https://img.shields.io/badge/Platform-Android-3DDC84?logo=android&logoColor=white)
![Linux](https://img.shields.io/badge/Userspace-GNU%2FLinux-FCC624?logo=linux&logoColor=black)
![No Root](https://img.shields.io/badge/Privilege-No%20Root%20Required-success)
![Shell](https://img.shields.io/badge/Shell-Bash-4EAA25?logo=gnu-bash&logoColor=white)

---

## 🚀 Overview

**Linux Server Manager for Android** is a modular, mobile-optimized management suite that installs, configures, and manages Linux distributions inside **Termux** using **proot-distro**, completely rootless.

Transform any Android phone or tablet into:
- 🌐 **Self-hosted Server**: Run web servers, databases, and APIs
- 💻 **Development Machine**: Full development stack with Python, Node.js, C/C++, Rust, Go
- 🖥️ **Desktop Environment**: Lightweight LXDE desktop via VNC
- 🔒 **Secure Remote Access**: SSH server and VNC with port management
- 📱 **Mobile-First Experience**: Clean, responsive TUI designed for small touchscreens

👉 **Prefer manual installation?**  
Check out the **[Manual Installation Guide](docs/MANUAL-INSTALL.md)**.

---

## ✨ Key Features

### 📱 Mobile-Optimized TUI
- Responsive status bar showing active distro, IP address, battery, storage, and RAM
- Big, touch-friendly numbered menus
- Graceful color fallback for non-color terminals
- Designed specifically for portrait mode and on-screen keyboards

### 🏗️ Modular Architecture
- Clean library structure under `lib/` for easy extension
- Independent modules for system detection, networking, distro management, VNC, SSH, backups, and packages

### 🐧 Distribution Management
- One-click install of Debian, Ubuntu, Alpine, Arch, Fedora, and more via `proot-distro`
- User management with automated passwordless `sudo` configuration
- Clean uninstallation (single distro or full wipe)

### 🖥️ Remote Display & Access
- Automated LXDE desktop + TightVNC configuration
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
   git clone https://github.com/uzairmukadam/linux-on-android.git
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
├── linux-on-android.sh    # Main interactive entry point
├── lib/                   # Modular libraries
│   ├── colors.sh          # Terminal styling and color detection
│   ├── system.sh          # System info (CPU, RAM, battery, storage)
│   ├── network.sh         # Network interfaces and IP detection
│   ├── distro.sh          # proot-distro management
│   ├── users.sh           # User and sudo provisioning
│   ├── ssh.sh             # OpenSSH server manager
│   ├── vnc.sh             # LXDE / TightVNC manager
│   ├── ui.sh              # Mobile-first headers and status bars
│   ├── diagnostics.sh     # Health check and environment audit
│   ├── backup.sh          # Rootfs backup and restore
│   └── packages.sh        # Quick package stack installers
├── docs/
│   └── MANUAL-INSTALL.md  # Step-by-step manual setup guide
└── LICENSE                # MIT License
```

---

## 🧩 What the Script Does

### 1. Installs your chosen Linux distro  
Supports any distro available through `proot-distro`.

### 2. Creates a non‑root user  
Passwordless login, safe sudo access.

### 3. Optional LXDE desktop setup  
If selected, the script installs:

- LXDE  
- TightVNCServer  
- A working `xstartup`  
- A VNC password  
- Automatic lock‑file cleanup  
- A test VNC session to initialize configs  

### 4. Saves configuration  
Each installed distro gets a config file in:

```
$PREFIX/etc/linux-on-android/<distro>.conf
```

### 5. Provides clean uninstall options  
Remove one distro or all of them.

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

