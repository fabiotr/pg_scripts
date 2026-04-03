
#!/bin/sh

file_dest=/tmp/so.md

echo "# SO report for $HOSTNAME"                                     > $file_dest
echo ""                                                             >> $file_dest

echo "## CPU"                                                       >> $file_dest
echo '```text'                                                      >> $file_dest
lscpu | grep 'Architecture'                                         >> $file_dest
lscpu | grep 'Byte Order'                                           >> $file_dest
lscpu | grep 'Vendor ID'                                            >> $file_dest
lscpu | grep 'Model name'                                           >> $file_dest
lscpu | grep 'CPU MHz'                                              >> $file_dest
lscpu | grep 'BogoMIPS'                                             >> $file_dest
lscpu | grep 'L1d'                                                  >> $file_dest
lscpu | grep 'L1i'                                                  >> $file_dest
lscpu | grep 'L2'                                                   >> $file_dest
lscpu | grep 'L3'                                                   >> $file_dest
lscpu | grep 'Thread(s) per core'                                   >> $file_dest
lscpu | grep 'Core(s) per socket'                                   >> $file_dest
lscpu | grep 'Socket(s)'                                            >> $file_dest
lscpu | grep 'CPU(s):' | grep -v NUMA                               >> $file_dest
echo '```'                                                          >> $file_dest
echo ""                                                             >> $file_dest

echo "## Network"                                                   >> $file_dest
echo '```text'                                                      >> $file_dest
#/sbin/ifconfig | grep inet | grep -v '127.0.0.1' | grep -v '::1'   >> $file_dest
#ip a | grep inet | grep -v '127.0.0.1' | grep -v '::1/128'         >> $file_dest
printf "%-12s | %-8s | %-18s | %-28s\n" "Interface" "State" "IPv4/Mask" "IPv6/Mask"            >> $file_dest
echo "-------------+----------+--------------------+-----------------------------------------" >> $file_dest
for interface in /sys/class/net/*; do
  ifname=$(basename "$interface")
  if [ "$ifname" != "lo" ]; then
    state=$(cat "$interface/operstate" 2>/dev/null || echo "unknown")
    ipv4=$(ip -4 addr show "$ifname" | grep -oP '(?<=inet\s)\d+(\.\d+){3}/\d+' | head -n 1)
    ipv4=${ipv4:-"N/A"}
    ipv6=$(ip -6 addr show "$ifname" | grep -oP '(?<=inet6\s)[a-f0-9:]+/\d+' | grep -v '^fe80' | head -n 1)
    ipv6=${ipv6:-"N/A"}
    printf "%-12s | %-8s | %-18s | %-28s\n" "$ifname" "$state" "$ipv4" "$ipv6"                 >> $file_dest
  fi
done
echo '```'                                                          >> $file_dest
echo ""                                                             >> $file_dest

echo "## Memory"                                                    >> $file_dest
echo '```text'                                                      >> $file_dest
free -h                                                             >> $file_dest
echo '```'                                                          >> $file_dest
echo ""                                                             >> $file_dest

echo "## Huge Pages"                                                >> $file_dest
echo "### THP defrag"                                               >> $file_dest
echo '```text'                                                      >> $file_dest
cat /sys/kernel/mm/transparent_hugepage/defrag                      >> $file_dest
echo '```'                                                          >> $file_dest
echo ""                                                             >> $file_dest

echo "### THP enabled"                                             >> $file_dest
echo '```text'                                                      >> $file_dest
cat /sys/kernel/mm/transparent_hugepage/enabled                     >> $file_dest
echo '```'                                                          >> $file_dest
echo ""                                                             >> $file_dest

echo "### VmPeak"                                                   >> $file_dest
echo '```text'                                                      >> $file_dest
if [ -e /proc/"$(pgrep -o postgres)"/status ]; then
  grep ^VmPeak /proc/"$(pgrep -o postgres)"/status                  >> $file_dest
else
  echo "No PostgreSQL active now"                                   >> $file_dest
fi
echo '```'                                                          >> $file_dest
echo ""                                                             >> $file_dest

echo "### Pages:"                                                   >> $file_dest
echo '```text'                                                      >> $file_dest
cat /proc/meminfo | grep -i 'HugePages'                             >> $file_dest
echo '```'                                                          >> $file_dest
echo ""                                                             >> $file_dest

echo "## Discs"                                                     >> $file_dest
echo "### fstab"                                                    >> $file_dest
echo '```text'                                                      >> $file_dest
cat /etc/fstab | grep -v '#'                                        >> $file_dest
echo '```'                                                          >> $file_dest
echo ""                                                             >> $file_dest

echo "### Partitions"                                               >> $file_dest
echo '```text'                                                      >> $file_dest
df -hT | grep -v '/run' | grep -v '/sys' | grep -v 'devtmpfs'       >> $file_dest
echo '```'                                                          >> $file_dest
echo ""                                                             >> $file_dest

echo "## Linux"                                                     >> $file_dest
echo "### Distro"                                                   >> $file_dest
echo '```text'                                                      >> $file_dest
hostnamectl | grep "Operating System"                               >> $file_dest
hostnamectl | grep "Kernel"                                         >> $file_dest
hostnamectl | grep "Virtualization"                                 >> $file_dest
hostnamectl | grep "Hardware Vendor"                                >> $file_dest
hostnamectl | grep "Hardware Model"                                 >> $file_dest
echo '```'                                                          >> $file_dest
echo ""                                                             >> $file_dest

echo "### sysctl.conf"                                              >> $file_dest
echo '```bash'                                                          >> $file_dest
grep -vhE '^(#|;|[[:space:]]*$)' /etc/sysctl.conf                   >> $file_dest
echo '```'                                                          >> $file_dest
echo ""                                                             >> $file_dest

echo "### sysctl.d"                                                 >> $file_dest
echo '```bash'                                                      >> $file_dest
ls /etc/sysctl.d | grep .conf | while read FILE
do 
  grep -vHE '^(#|;|[[:space:]]*$)' /etc/sysctl.d/$FILE              >> $file_dest             
done
echo '```'                                                          >> $file_dest
echo ""                                                             >> $file_dest

echo "### limits.conf"                                              >> $file_dest
echo '```bash'                                                          >> $file_dest
grep -vhE '^(#|;|[[:space:]]*$)' /etc/security/limits.conf          >> $file_dest
echo '```'                                                          >> $file_dest
echo ""                                                             >> $file_dest

echo "### limits.d:"                                                >> $file_dest
echo '```bash'                                                      >> $file_dest
ls /etc/security/limits.d | grep .conf | while read FILE
do 
  grep -vHE '^(#|;|[[:space:]]*$)' /etc/security/limits.d/$FILE     >> $file_dest             
done
echo '```'                                                          >> $file_dest
echo ""                                                             >> $file_dest

echo "### Grub Huge Pages parameters"                               >> $file_dest
echo '```bash'                                                          >> $file_dest
grub_config=$(grep "^[^#]*GRUB_CMDLINE_LINUX" /etc/default/grub | sed 's/.*"\(.*\)".*/\1/')
if [ -n "$grub_config" ]; then
  echo "$grub_config" | tr ' ' '\n' | grep -E "hugepages|transparent_hugepage" >> $file_dest
fi
echo '```'                                                          >> $file_dest
echo ""                                                             >> $file_dest

echo "### Scheduler"                                                >> $file_dest
echo '```text'                                                      >> $file_dest
echo "Device      | Scheduler"                                      >> $file_dest
echo "------------+----------"                                      >> $file_dest
for disk_path in /sys/block/*/queue/scheduler; do
  dev_name=$(basename "$(dirname "$(dirname "$disk_path")")")
  if [[ ! $dev_name =~ ^loop ]]; then
    current_scheduler=$(cat "$disk_path")
    printf "%-11s | %s\n" "$dev_name" "$current_scheduler"          >> $file_dest
  fi
done
echo '```'                                                          >> $file_dest
echo ""                                                             >> $file_dest

echo "### Crontab ($USER)"                                          >> $file_dest
echo '```bash'                                                      >> $file_dest
crontab -l | grep -vE '^(#|;|PATH|SHELL|MAIL|[[:space:]]*$)'        >> $file_dest
echo '```'                                                          >> $file_dest
echo ""                                                             >> $file_dest

echo "### Crontab (/etc/crontab)"                                   >> $file_dest
echo '```bash'                                                      >> $file_dest
cat /etc/crontab | grep -vE '^(#|;|PATH|SHELL|MAIL|[[:space:]]*$)'  >> $file_dest
echo '```'                                                          >> $file_dest
echo ""                                                             >> $file_dest

echo "### Crontab (/etc/cron.d)"                                    >> $file_dest
echo '```bash'                                                      >> $file_dest
cat /etc/cron.d/* | grep -vE '^(#|;|PATH|SHELL|MAIL|[[:space:]]*$)' >> $file_dest
echo '```'                                                          >> $file_dest


echo "### PostgreSQL related packages"                              >> $file_dest
# Red Hat like Linux
if [ -f /etc/redhat-release ]; then
  echo '```text'                                                    >> $file_dest
  rpm -qa | grep postgres                                           >> $file_dest
  rpm -qa | grep pgbackrest                                         >> $file_dest
  rpm -qa | grep pgbadger                                           >> $file_dest
  rpm -qa | grep pg_                                                >> $file_dest
  echo '```'                                                        >> $file_dest
fi

# Debian like Linux
if [ -f /etc/debian_version ]; then
  echo '```text'                                                    >> $file_dest
  dpkg -l | grep postgres                                           >> $file_dest
  dpkg -l | grep pgbackrest                                         >> $file_dest
  dpkg -l | grep pgbadger                                           >> $file_dest
  dpkg -l | grep pg-activity                                        >> $file_dest
  echo '```'                                                        >> $file_dest
fi
echo ""                                                             >> $file_dest

echo "### Locale"                                                   >> $file_dest
echo '```text'                                                      >> $file_dest
localectl | grep 'System Locale'                                    >> $file_dest
echo '```'                                                          >> $file_dest
echo ""                                                             >> $file_dest

echo "### Timezone"                                                 >> $file_dest
echo '```text'                                                      >> $file_dest
echo `timedatectl | grep 'Time zone'`                               >> $file_dest
timedatectl | grep 'System clock synchronized'                      >> $file_dest
echo '```'                                                          >> $file_dest
echo ""                                                             >> $file_dest

echo "### Environment Variables"                                    >> $file_dest
echo '```bash'                                                      >> $file_dest
env | grep USER                                                     >> $file_dest
env | grep HOME                                                     >> $file_dest
env | grep ^PATH                                                    >> $file_dest
env | grep ^PG | grep -v PGPASSWORD                                 >> $file_dest
if [ -n "$PGPASSWORD" ]; then echo 'PGPASSWORD=*****';fi            >> $file_dest
echo '```'                                                          >> $file_dest
echo ""                                                             >> $file_dest

echo "### .pgpass"                                                  >> $file_dest
echo '```bash'                                                      >> $file_dest
if [ -n "$PGPASSFILE" ]; then
  if [ -f "$PGPASSFILE" ]; then
    echo "Enviroment file: $PGPASSFILE"                             >> $file_dest
    cut -d ':' -f 1,2,3,4 $PGPASSFILE | while read LINE
          do echo "$LINE:*****"                                     >> $file_dest
        done
  fi
fi
if [ -f "$HOME/.pgpass" ]; then
  cut -d ':' -f 1,2,3,4 $HOME/.pgpass | while read LINE
    do echo "$LINE:*****"                                           >> $file_dest
  done
fi
echo '```'                                                          >> $file_dest
echo ""                                                             >> $file_dest

echo "### .pg_service.conf"                                         >> $file_dest
echo '```bash'                                                      >> $file_dest
if [ -n "$PGSERVICEFILE" ]; then
  if [ -f "$PGSERVICEFILE" ]; then
    echo "Enviroment file: $PGSERVICEFILE"                          >> $file_dest
        cat $PGSERVICEFILE | grep -v '#'                            >> $file_dest
  fi
fi
if [ -f "$HOME/.pg_service.conf" ]; then
  cat $HOME/.pg_service.conf | grep -v '#'                          >> $file_dest
fi
echo '```'                                                          >> $file_dest
echo ""                                                             >> $file_dest

echo "### .psqlrc"                                                  >> $file_dest
echo '```sql'                                                          >> $file_dest
if [ -f "$HOME/.psqlrc" ]; then
  cat $HOME/.psqlrc | grep -v '\-\-'                                >> $file_dest
fi
echo '```'                                                          >> $file_dest
echo ""                                                             >> $file_dest

echo "END"                                                          >> $file_dest

cat $file_dest
