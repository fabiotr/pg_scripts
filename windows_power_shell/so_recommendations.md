# Windows adjustments recommendations for PostgreSQL


## Memory management (equivalent to `sysctl` vm.* settings)
- PostgreSQL reference: https://www.postgresql.org/docs/current/kernel-resources.html

### Paging file (closest equivalent to `vm.swappiness` / `vm.overcommit_*`)
- Windows has no per-process overcommit control; the practical lever is the paging file size/location.
- Old way: System Properties → Advanced → Performance Settings → Advanced → Virtual Memory → Change
- New way (PowerShell, run elevated):
```powershell
$cs = Get-WmiObject Win32_ComputerSystem
$cs.AutomaticManagedPagefile = $false
$cs.Put()

$pf = Get-WmiObject Win32_PageFileSetting
$pf.InitialSize = 16384
$pf.MaximumSize = 16384
$pf.Put()
```
**Recommendation**: 
- On a dedicated DB server with plenty of RAM, set a fixed-size page file rather than "System managed" — same intent as `vm.swappiness=1` on Linux (avoid the OS proactively paging out PostgreSQL memory).
- Size: Set both the initial size and maximum size to the same value—typically 1.5 to 2 times your physical RAM (for example, if you have 16 GB of RAM, set the page file to 24,576 MB or 32,768 MB).
- Location: Place the page file on your fastest dedicated drive (preferably a fast NVMe or SSD), separate from where heavy database logs or tables reside if possible.

### TCP/IP tuning (equivalent to `net.ipv4.tcp_*` / `net.core.somaxconn`)
- Registry path: `HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters`
- Ephemeral port range + faster TIME_WAIT reuse (equivalent to `tcp_tw_reuse` / `tcp_fin_timeout`):
```powershell
netsh int ipv4 set dynamicport tcp start=10000 num=55536
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" `
  -Name "TcpTimedWaitDelay" -Value 30 -Type DWord
```
- There is no direct `somaxconn` knob on Windows — the closest levers are the dynamic port range above and PostgreSQL's own `max_connections`; Windows Sockets manages the listen backlog internally.

## Errors on very large databases (Windows mapping)
**Check these if you see errors in the PostgreSQL log or Windows Event Viewer**

- **Out of memory**
```
FATAL:  could not create shared memory segment
```
  or Event Viewer shows non-paged pool depletion.
  - **Action**: lower PostgreSQL `shared_buffers`/`work_mem`.

- **Shared memory error**
```
FATAL:  could not create shared memory segment: ...
```
  - Windows shared memory is backed by the paging file, not `shmmax`/`shmall`. If this happens: check paging file size/free space and lower `shared_buffers`.

- **Too many open files**
  - Windows equivalent is usually a `FATAL: out of file descriptors` message in the log, or handle-count warnings in Event Viewer.
  - **Action**: there's no OS-level limit to raise (Windows has no `ulimit`/`fs.file-max`) — the lever is PostgreSQL's own `max_files_per_process` in `postgresql.conf`.

- **Network errors / connection refused**
  - **Action**: apply the TCP/IP tuning above and check PostgreSQL `max_connections`.

## Large Pages (Windows equivalent of Huge Pages, RAM ≥ 32GB)
- PostgreSQL's `huge_pages` setting maps to Windows "large-page support," which requires the
  **Lock Pages in Memory** privilege for the account running the PostgreSQL service.

### How to enable
1. `gpedit.msc` → Computer Configuration → Windows Settings → Security Settings →
   Local Policies → User Rights Assignment → **Lock pages in memory** → add the PostgreSQL
   service account.
2. Restart the PostgreSQL service.
3. In PostgreSQL, prefer `try` over `on` on Windows so it falls back gracefully if the
   privilege isn't granted:
```sql
ALTER SYSTEM SET huge_pages TO try;
```
4. Check the PostgreSQL startup log to confirm large pages were actually used.

## Disk partitioning
- Same principle as Linux — use a dedicated volume/drive letter for PGDATA.
- Suggested separate volumes:
  - PostgreSQL logs (`log_directory`)
  - WAL — Windows doesn't support the same symlink trick as Linux; use `initdb --waldir <path>`
    at cluster creation time to place `pg_wal` on its own volume from the start.
  - Temp files (`temp_tablespaces`)
  - Extra tablespaces: `CREATE TABLESPACE ts1 LOCATION 'D:\pgdata\ts1';`

## File systems
- Recommended: **NTFS** with the default 4KB allocation unit size. ReFS is not
  officially recommended for PostgreSQL data directories.
- Disable Windows Search indexing on the PGDATA volume (Drive Properties → General →
  uncheck "Allow files on this drive to have contents indexed").
- Disable NTFS last-access-time tracking (equivalent to Linux `noatime`):
```powershell
fsutil behavior set disablelastaccess 1
```
- Add the PGDATA and WAL folders to your **antivirus exclusion list** — real-time
  scanning of live database/WAL files is a very common Windows-specific source of latency
  with no Linux equivalent.
- Reference: https://www.enterprisedb.com/blog/postgres-vs-file-systems-performance-comparison

### Storage / read-ahead
- There's no per-volume `blockdev --setra` equivalent on Windows. Closest levers:
  - Device Manager → Disk drives → Policies → enable write caching only if the storage has
    battery/flash-backed cache.
  - On virtualized/cloud disks (Hyper-V, Azure, AWS), read-ahead/cache behavior is usually
    configured at the storage layer (e.g., disk cache setting in the hypervisor/cloud console),
    not inside Windows itself.

