#!/bin/sh
echo "# Report SO"                                                   > /tmp/so.md
echo ""                                                             >> /tmp/so.md

echo "## CPU:"                                                      >> /tmp/so.md
echo '```'                                                          >> /tmp/so.md
lscpu | grep 'Architecture'                                         >> /tmp/so.md
lscpu | grep 'Byte Order'                                           >> /tmp/so.md
lscpu | grep 'Vendor ID'                                            >> /tmp/so.md
lscpu | grep 'Model name'                                           >> /tmp/so.md
lscpu | grep 'CPU MHz'                                              >> /tmp/so.md
lscpu | grep 'BogoMIPS'                                             >> /tmp/so.md
lscpu | grep 'L1d'                                                  >> /tmp/so.md
lscpu | grep 'L1i'                                                  >> /tmp/so.md
lscpu | grep 'L2'                                                   >> /tmp/so.md
lscpu | grep 'L3'                                                   >> /tmp/so.md
lscpu | grep 'Thread(s) per core'                                   >> /tmp/so.md
lscpu | grep 'Core(s) per socket'                                   >> /tmp/so.md
lscpu | grep 'Socket(s)'                                            >> /tmp/so.md
lscpu | grep 'CPU(s):' | grep -v NUMA                               >> /tmp/so.md
echo '```'                                                          >> /tmp/so.md
echo ""                                                             >> /tmp/so.md

echo "## Network:"                                                  >> /tmp/so.md
echo '```'                                                          >> /tmp/so.md
#/sbin/ifconfig | grep inet | grep -v '127.0.0.1' | grep -v '::1'   >> /tmp/so.md
ip a | grep inet | grep -v '127.0.0.1'                              >> /tmp/so.md
echo '```'                                                          >> /tmp/so.md
echo ""                                                             >> /tmp/so.md

echo "## Memory:"                                                   >> /tmp/so.md
echo '```'                                                          >> /tmp/so.md
free -h                                                             >> /tmp/so.md
echo '```'                                                          >> /tmp/so.md
echo ""                                                             >> /tmp/so.md

echo "## Huge Pages"                                                >> /tmp/so.md
echo "### THP defrag:"                                              >> /tmp/so.md
echo '```'                                                          >> /tmp/so.md
cat /sys/kernel/mm/transparent_hugepage/defrag                      >> /tmp/so.md
echo '```'                                                          >> /tmp/so.md
echo ""                                                             >> /tmp/so.md

echo "### THP enabled:"                                             >> /tmp/so.md
echo '```'                                                          >> /tmp/so.md
cat /sys/kernel/mm/transparent_hugepage/enabled                     >> /tmp/so.md
echo '```'                                                          >> /tmp/so.md
echo ""                                                             >> /tmp/so.md

echo "### VmPeak"                                                   >> /tmp/so.md
echo '```'                                                          >> /tmp/so.md
grep ^VmPeak /proc/"$(pgrep -o postgres)"/status                    >> /tmp/so.md
echo '```'                                                          >> /tmp/so.md
echo ""                                                             >> /tmp/so.md

echo "### Pages:"                                                   >> /tmp/so.md
echo '```'                                                          >> /tmp/so.md
cat /proc/meminfo | grep -i 'HugePages'                             >> /tmp/so.md
echo '```'                                                          >> /tmp/so.md
echo ""                                                             >> /tmp/so.md

echo "## Discs"                                                     >> /tmp/so.md
echo "### fstab"                                                    >> /tmp/so.md
echo '```'                                                          >> /tmp/so.md
cat /etc/fstab | grep -v '#'                                        >> /tmp/so.md
echo '```'                                                          >> /tmp/so.md
echo ""                                                             >> /tmp/so.md

echo "### Partitions"                                               >> /tmp/so.md
echo '```'                                                          >> /tmp/so.md
df -hT | grep -v '/run' | grep -v '/sys' | grep -v 'devtmpfs'       >> /tmp/so.md
echo '```'                                                          >> /tmp/so.md
echo ""                                                             >> /tmp/so.md

echo "## Linux"                                                     >> /tmp/so.md
echo "### Kernel"                                                   >> /tmp/so.md
echo '```'                                                          >> /tmp/so.md
uname -a                                                            >> /tmp/so.md
echo '```'                                                          >> /tmp/so.md
echo ""                                                             >> /tmp/so.md

echo "### Distro:"                                                  >> /tmp/so.md
echo '```'                                                          >> /tmp/so.md
hostnamectl                                                         >> /tmp/so.md
echo '```'                                                          >> /tmp/so.md
echo ""                                                             >> /tmp/so.md

echo "### sysctl.conf:"                                             >> /tmp/so.md
echo '```'                                                          >> /tmp/so.md
cat /etc/sysctl.conf | grep -v '#'                                  >> /tmp/so.md
echo '```'                                                          >> /tmp/so.md
echo ""                                                             >> /tmp/so.md

echo "### sysctl.d:"                                                >> /tmp/so.md
echo '```'                                                          >> /tmp/so.md
cat /etc/sysctl.d/*.conf | grep -v '#'                              >> /tmp/so.md
echo '```'                                                          >> /tmp/so.md
echo ""                                                             >> /tmp/so.md

echo "### Scheduler:"                                               >> /tmp/so.md
echo '```'                                                          >> /tmp/so.md
for d in /sys/block/*; do
  [ -f "$d/queue/scheduler" ] || continue
  echo "$(basename "$d"): $d/queue/scheduler"                       >> /tmp/so.md
done
echo '```'                                                          >> /tmp/so.md
echo ""                                                             >> /tmp/so.md

echo "### Crontab ($USER):"                                         >> /tmp/so.md
echo '```'                                                          >> /tmp/so.md
crontab -l | grep -v '#'                                            >> /tmp/so.md
echo '```'                                                          >> /tmp/so.md
echo ""                                                             >> /tmp/so.md

echo "### Crontab (/etc/crontab):"                                  >> /tmp/so.md
echo '```'                                                          >> /tmp/so.md
cat /etc/crontab | grep -v '#'                                      >> /tmp/so.md
echo '```'                                                          >> /tmp/so.md
echo ""                                                             >> /tmp/so.md

echo "### Crontab (/etc/cron.d):"                                   >> /tmp/so.md
echo '```'                                                          >> /tmp/so.md
cat /etc/cron.d/* | grep -v '#'                                     >> /tmp/so.md
echo '```'                                                          >> /tmp/so.md

cat /tmp/so.md
