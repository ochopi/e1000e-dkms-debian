# Upgrading the kernel with this driver installed

DKMS keeps your **patched source** safe across kernel upgrades — it lives in
`/usr/src/e1000e-3.8.7/` and is never touched by `apt`. What DKMS does **not**
do automatically is rebuild the **compiled module** for a kernel it has never
seen before. If you install a new kernel and reboot into it without an extra
step, you will hit the original NVM checksum bug again, because the stock
in-kernel `e1000e` driver (without the bypass) loads instead.

This applies to **any** future kernel upgrade, not just a specific version
jump — follow this procedure every time `apt full-upgrade` (or equivalent)
installs a new kernel.

## TL;DR

```bash
# 0. Note the currently running kernel, before upgrading
uname -r

# 1. Upgrade normally
apt update
apt full-upgrade

# 2. Check whether a new kernel was installed (before rebooting)
ls /lib/modules/
# if a newer version appears than the one from step 0, the kernel changed

# 3. If it changed, rebuild the DKMS module for the NEW kernel
#    (use the version string from step 2 — `uname -r` still reports the
#    OLD kernel until you actually reboot into the new one)
apt install -y linux-headers-<new-version>   # or pve-headers-<new-version> on Proxmox
dkms install e1000e/3.8.7 -k <new-version>

dkms status   # confirm "installed" for the new kernel version

# 4. Reboot
reboot
```

## Verifying after reboot

```bash
ip link show <your-interface>     # should exist and be UP
dmesg | grep -i e1000e            # should NOT show "NVM Checksum Is Not Valid"
dkms status                       # should show "installed" for `uname -r`
```

## If it still doesn't work after step 3 — module index out of sync

Sometimes `dkms install` reports success and `dkms status` shows the module
as `installed` for the running kernel, but the driver still doesn't load
correctly. The compiled `.ko` file exists on disk, but the kernel's module
index (`modules.dep` / `modules.alias` under `/lib/modules/<kernel>/`) still
points at the stock in-tree driver instead of the DKMS one.

Fix by rebuilding the index manually:

```bash
depmod -a $(uname -r)
modprobe -r e1000e 2>/dev/null
modprobe -v e1000e
```

The `-v` flag on `modprobe` shows the actual path loaded — confirm it points
to something like:
```bash
.../updates/dkms/e1000e.ko
```

and **not** the generic in-kernel path. If you see the generic path, the
patched module still isn't being used.

> Loading an out-of-tree, unsigned module normally logs a harmless warning:
> `module verification failed: signature and/or required key missing -
> tainting kernel`. This is expected and does not affect functionality
> unless you have Secure Boot enabled (see main README).

## If the interface exists but has no traffic / isn't bridged

This is outside the scope of the driver itself, but worth checking after
any kernel upgrade: some setups bring up the physical NIC and a network
bridge as separate, unsynchronized services at boot. If your interface is
`UP` but not carrying traffic, verify it's actually attached to whatever
bridge or bond you expect:

```bash
bridge link show
ip link show master <your-bridge>
```

If it's missing, re-attach it manually and consider adding a startup check
in your own networking scripts — this is a general Linux networking
consideration, not something this driver package can fix for you.

## Summary

| Situation | Fix |
|---|---|
| New kernel installed, driver reverts to unpatched behavior | Re-run `dkms install e1000e/3.8.7 -k <new-kernel>` |
| `dkms status` shows installed, but bug persists | `depmod -a` + `modprobe -r/modprobe -v` to confirm the right path loads |
| Multiple kernel upgrades without reboot in between | Repeat the DKMS install step for **each** kernel version you plan to boot into |