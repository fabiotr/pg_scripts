# Linux adjusts recommendations for PostgreSQL

## sysctl (default recommendations)
- PostgreSQL reference: https://www.postgresql.org/docs/current/kernel-resources.html

### How to change sysctl
- Old way
  - Edit `/etc/sysctl.conf`
  - Run `sysctl -p`

- New way
  - Edit `/etc/sysctl.d/90_postgresql.conf`
  - Run `sysctl -p /etc/sysctl.d/90_postgresql.conf`

### Recommendations
```
vm.dirty_ratio=10
vm.dirty_background_ratio=5
vm.overcommit_memory=2
vm.overcommit_ratio=95
vm.swappiness=1

net.ipv4.tcp_tw_reuse=1
net.core.somaxconn=65535
net.ipv4.tcp_fin_timeout=5
```

## sysctl (very large databases recommendations)
**Change if you find these errors on PostgreSQL or Linux logs**

- Out of memory killer
```
Out of Memory: Killed process 12345 (postgres).
```
  - **Action**: lower PostgreSQL `shared_buffers` and/or `work_mem`

- Semaphores error
```
FATAL:  could not create semaphores: No space left on device
DETAIL:  Failed system call was semget(5440126, 17, 03600).
```
  - **Action**: Raise semaphores on sysctl
  - Typical number:
```
kernel.sem = 250 512000 100 2048
```

- Shared memory error
```
FATAL:  could not create shared memory segment: Invalid argument
DETAIL:  Failed system call was shmget(key=5440001, size=4011376640, 03600).
```
  - **Action**: Raise shmmax and shmall on sysctl
  - Until PostgreSQL 9.2 you need to change always shmmax and shmall. 
  - How calculate shmmax and shmall:
```shell
# Script to calculate shmmax and shmall values
page_size=`getconf PAGE_SIZE`
# shmmax = 1/2  of available RAM
phys_pages=`getconf _PHYS_PAGES`
shmall=`expr $phys_pages / 2`
shmmax=`expr $shmall \* $page_size`
echo kernel.shmmax = $shmmax
echo kernel.shmall = $shmall
```
  - Example on 32GB RAM server:
```
kernel.shmmax = 17179869184
kernel.shmall = 4194304
```

- Too many open files error
```
ERROR:  could not open shared memory segment "/PostgreSQL.1477116630": Too many open files in system
```
  - **Action**: Raise `fs.file-max`
  - Typical number:
```
fs.file-max = 312139770
```

- aio error
```
io_setup() failed: Resource temporarily unavailable
failed to create aio context: Resource temporarily unavailable
```
  - **Action**: Raise `fs.aio-max-nr`
  - Typical number:
```
fs.aio-max-nr = 1048576
```

- Network errors
  * TCP handshake latency 
  * Connection Refused errors when PostgreSQL `max_connections` not reached

  - **Action**: Raise `net.core.somaxconn`
  - Typical number:
```
net.core.somaxconn = 256
```

## limits (Recommendations for very large databases)
**Change if you find this errors on PostgreSQL logs**

```
ERROR: could not open file "base/16384/12456": Too many open files;
```
### How to change limits
- Old way: edit `/etc/security/limits.conf`
- New way: edit `/etc/security/limits.d/30-postgresql.conf`

- If SE Linux is active, you may need to run this too:
```shell
restorecon -Fvv /etc/security/limits.d/30-postgresql.conf
```
  - Typical values
```
postgres soft nofile 65535
postgres hard nofile 65535
```


## Huge pages (only for servers with RAM >= 32GB)
- The huge memory size must be at least PostgreSQL + 10% at a dedicated server.
- To get the number of Huge Pages size: (shared_buffers * 1,1) / huge page size
- The default Huge page size (for each huge page) is 2MB
- Example
  - Server with 64GB of RAM and 16GB of PostgreSQL shared_buffers
  (16GB * 1,1) / 2MB = 9011

### How change Huge pages (do not trust sysctl config for Huge pages):
- Edit `/etc/default/grub `
```
...
...
GRUB_CMDLINE_LINUX="... hugepages=9011 hugepagesz=2M transparent_hugepage=never"
...
...
```

- Compile changes to grub boot loader:
```
# On Debian:
update-grub

# On Red Hat
grub2-mkconfig -o /boot/grub2/grub.cfg
# or
grub2-mkconfig -o /boot/efi/EFI/redhat/grub.cfg
```
- Reboot server
- Check if Huge pages is OK
```
cat /proc/meminfo | grep Huge
```
- Change PostgreSQL `huge_pages`
  - **Caution**: Remember to change PostgreSQL `huge_pages` parameter to `on` only after reboot server and check if Huge pages is available at Linux
```sql
ALTER SYSTEM SET huge_pages TO on;
```

- Start PostgreSQL and check Huge Pages again
```
systemctl start postgresql
cat /proc/meminfo | grep Huge
```

## Disk partitioning
- Use at least one partition or disk separated only to database (PGDATA)
- Other partitions or disks that may be useful
  - PostgreSQL logs (change the `log_directory` parameter on PostgreSQL too)
  - Write Ahead Log or WAL (make a symbolic link to  $PGDATA/pg_wal too)
  - Temp files (change `temp_tablespaces` parameter on PostgreSQL too)
  - New tablespaces (created with `CREATE TABLESPACE` Postgresql command)


## File systems
- XFS ~ EXT4 > ZFS >> BTRFS
- Reference: https://www.enterprisedb.com/blog/postgres-vs-file-systems-performance-comparison

### How to edit mounting points and options
- Edit `/etc/fstab`
- Always use UUID reference for devices (use `ls -lh /dev/disk/by-uuid/`)
- Mounting points options:
  - noatime (safe)
  - nobarrier (only on storages with write cache batteries)
- Example:
```
UUID=0bcbad84-23f8-485b-9d66-513bb480a5cb /data ext4 noatime,nobarrier,errors=remount-ro, 0 1
```
### Read-Ahead Tuning
- Verify actual value on device
```
blockdev --getra /dev/sda1
blockdev --report
```
- Adjust to new value (from 4096 to 16384)
- Edit `/etc/rc.local`
- Typical value:
```
blockdev --setra 4096 /dev/sda1
```
