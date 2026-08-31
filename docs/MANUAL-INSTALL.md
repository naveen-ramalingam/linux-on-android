# Linux on Android — Manual Installation Guide

![Android](https://img.shields.io/badge/Platform-Android-3DDC84?logo=android&logoColor=white)
![Linux](https://img.shields.io/badge/Userspace-GNU%2FLinux-FCC624?logo=linux&logoColor=black)
![No Root](https://img.shields.io/badge/Privilege-No%20Root%20Required-success)

---

## 📌 Overview

This guide walks you through the **manual installation** of Linux distributions on Android using **Termux** and **proot-distro**, without relying on the automation script.

It is ideal for users who:

- Prefer full control  
- Want to understand the underlying workflow  
- Enjoy customizing their environment  
- Want transparency over every step  

These instructions mirror the workflow used to build the automated installer.

If you prefer a one‑click, fully automated setup, use the main script in the project's **[README](../README.md)** instead.

---

## 📦 Requirements

- Android **8.0+**
- **Termux** (recommended from F‑Droid)
- Internet connection
- 4–6 GB free storage
- Optional: VNC viewer (RealVNC, bVNC, etc.)

---

# 🧰 1. Install Termux & Update Packages

Install Termux from F‑Droid, then run:

```bash
apt update && apt upgrade -y
apt install git -y
```

Clone the repository if you want to reference the automation script (optional):

```bash
git clone https://github.com/uzairmukadam/linux-on-android.git
```

---

# 📥 2. Install `proot-distro`

Install:

```bash
apt install proot-distro -y
```

List available Linux distributions:

```bash
proot-distro list
```

---

# 🐧 3. Install a Linux Distribution

Example: install Debian

```bash
proot-distro install debian
```

You may replace `debian` with:

- `ubuntu`
- `archlinux`
- `alpine`
- `fedora`
- or any other supported distro

---

# 🔑 4. Enter the Linux Environment

Use the login syntax:

```bash
proot-distro login debian --
```

This ensures a proper login shell and correct environment variables.

---

# 👤 5. Install Essential Packages & Create a User

Many rootfs images are minimal, so install essentials:

```bash
apt update && apt upgrade -y
apt install -y sudo adduser passwd apt-utils dialog tzdata
```

Create a non‑root user:

```bash
adduser username
```

Give sudo access:

```bash
echo "username ALL=(ALL:ALL) ALL" >> /etc/sudoers
```

Switch to the new user:

```bash
su - username
```

> **Note:**  
> Always use `su - username` (with a hyphen).  
> This loads the user’s full login environment and prevents issues with VNC, LXDE, and DBus.

---

# 🖥️ 6. (Optional) Install LXDE Desktop + VNC

Still inside the distro:

### Install LXDE and TightVNC:

```bash
apt install -y lxde lxterminal tightvncserver
```

### Initialize VNC:

```bash
vncserver :1
vncserver -kill :1
```

### Create the `xstartup` file:

```bash
mkdir -p ~/.vnc
nano ~/.vnc/xstartup
```

Paste:

```
#!/bin/bash
xrdb $HOME/.Xresources
exec startlxde &
```

Make it executable:

```bash
chmod +x ~/.vnc/xstartup
```

---

# 🖧 7. Start the Desktop Environment

Start VNC:

```bash
vncserver -geometry 1920x1080 :1
```

Connect using any VNC viewer to:

```
localhost:5901
```

Stop VNC:

```bash
vncserver -kill :1
```

---

# 🧹 8. Uninstall a Linux Distribution

List installed distros:

```bash
proot-distro list
```

Remove one:

```bash
proot-distro remove debian
```

---

# 🗑️ 9. (Optional) Remove `proot-distro`

```bash
apt remove proot-distro -y
```

---

# 🧠 Tips for Manual Users

- **Debian** is the most stable for proot environments  
- **Alpine** is extremely lightweight but requires more manual setup  
- Use **lower VNC resolutions** for better performance  
- Avoid heavy desktops like **GNOME/KDE**  
- Install **code-server** for a VS Code‑like experience  
- Use `su - username` instead of `su username` to avoid session issues  

---

# 🛠 Troubleshooting

### **VNC won’t start / port already in use**
Remove stale lock files:

```bash
rm -f /tmp/.X1-lock /tmp/.X11-unix/X1
```

Then restart:

```bash
vncserver :1
```

---

### **LXDE shows “Cannot start pid XXXX” or “No session for pid XXXX”**
Check LXDE logs:

```bash
less ~/.cache/lxsession/LXDE/run.log
```

Common fixes:

```bash
sudo apt install --reinstall pcmanfm lxpanel openbox gvfs-daemons -y
```

---

### **Desktop is slow**
Try:

- Lower resolution: `vncserver -geometry 1280x720 :1`
- Disable compositing in LXDE
- Use a lighter distro (Alpine, Debian minimal)

---

### **proot-distro command not found**
Install it:

```bash
apt install proot-distro -y
```

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

# 🗒️ Summary of Manual Steps

1. Install Termux  
2. Install `proot-distro`  
3. Install a Linux distro  
4. Enter the distro  
5. Install essential packages  
6. Create a user  
7. (Optional) Install LXDE + VNC  
8. Start VNC and connect  
9. Uninstall when done  

This guide gives you full control over every part of the setup.

---

## 📬 Contributions

If you discover improvements or want to expand this guide, feel free to open an issue or submit a pull request.

