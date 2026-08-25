WSL (specifically WSL 2) stores its Linux distribution data inside a Virtual Hard Disk (`.vhdx`) file. By default, this file is saved on your system drive:

* **Default Location:** `C:\Users\<YourUsername>\AppData\Local\Packages\` (inside the distribution's package folder).

---

**Moving WSL to Another Drive**

You can move your WSL distribution (e.g., Ubuntu, Debian) to another drive using the export and import features of the `wsl` command-line tool.

**1. Export the Existing Distribution**

1. Open PowerShell or Command Prompt as Administrator.
2. List your installed distributions to get the exact name:
```bash
wsl -l -v

```


3. Shut down WSL completely:
```bash
wsl --shutdown

```


4. Export the distribution to a single tar file on your target drive (e.g., `D:\` drive):
```bash
wsl --export <DistroName> D:\wsl-backup.tar

```


*(Replace `<DistroName>` with your actual distro name, e.g., `Ubuntu`)*.

**2. Unregister the Old Distribution**
Remove the original instance from your `C:` drive (this frees up the space immediately):

```bash
wsl --unregister <DistroName>

```

**3. Import to the New Location**

1. Create a folder on your target drive where you want the new disk file to live (e.g., `D:\WSL\Ubuntu`).
2. Import the distribution into the new folder:
```bash
wsl --import <DistroName> D:\WSL\Ubuntu D:\wsl-backup.tar --version 2

```



**4. Reset the Default User**
By default, importing resets the distribution user to `root`. Set your primary username back as default:

```bash
<DistroName> config --default-user <YourLinuxUsername>

```

*(For example: `ubuntu config --default-user malik`)*.

Once verified, you can delete the temporary backup file `D:\wsl-backup.tar`.