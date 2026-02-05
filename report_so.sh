echo "so.txt"                                                        > /tmp/so.txt
echo ""                                                             >> /tmp/so.txt
echo "## CPU:"                                                      >> /tmp/so.txt
lscpu | grep 'Architecture'					    >> /tmp/so.txt
lscpu | grep 'Thread(s) per core'				    >> /tmp/so.txt
lscpu | grep 'Core(s) per socket'				    >> /tmp/so.txt
lscpu | grep 'Socket(s)'					    >> /tmp/so.txt
lscpu | grep 'Vendor ID'					    >> /tmp/so.txt
lscpu | grep 'Model name'                                           >> /tmp/so.txt
lscpu | grep 'CPU MHz'						    >> /tmp/so.txt
lscpu | grep 'CPU(s):' | grep -v NUMA                               >> /tmp/so.txt
echo ""                                                             >> /tmp/so.txt
echo "## Rede:"                                                     >> /tmp/so.txt
#/sbin/ifconfig | grep inet | grep -v '127.0.0.1' | grep -v '::1'    >> /tmp/so.txt
ip a | grep inet | grep -v '127.0.0.1'				    >> /tmp/so.txt
echo ""                                                             >> /tmp/so.txt
echo "## Memória:"                                                  >> /tmp/so.txt
free -g                                                             >> /tmp/so.txt
echo ""								    >> /tmp/so.txt
echo "### Huge Pages"	                                            >> /tmp/so.txt
echo "#### VmPeak"                                                  >> /tmp/so.txt
grep ^VmPeak /proc/"$(pgrep -o postgres)"/status                    >> /tmp/so.txt
echo "#### defrag:"                                                 >> /tmp/so.txt
cat /sys/kernel/mm/transparent_hugepage/defrag                      >> /tmp/so.txt
echo "#### enabled:"                                                >> /tmp/so.txt
cat /sys/kernel/mm/transparent_hugepage/enabled                     >> /tmp/so.txt
echo "#### Pages:"                                                  >> /tmp/so.txt
cat /proc/meminfo | grep -i 'HugePages'                             >> /tmp/so.txt
echo ""                                                             >> /tmp/so.txt
echo "## Discos"				 	 	    >> /tmp/so.txt
echo "### fstab"						    >> /tmp/so.txt
cat /etc/fstab | grep -v '#'                                        >> /tmp/so.txt
echo ""								    >> /tmp/so.txt
echo "### Partitions"						    >> /tmp/so.txt
df -hT | grep -v '/run' | grep -v '/sys' | grep -v 'devtmpfs'       >> /tmp/so.txt
echo ""     							    >> /tmp/so.txt
echo "## Linux"							    >> /tmp/so.txt
echo "### Kernel"						    >> /tmp/so.txt
uname -a							    >> /tmp/so.txt
echo ""								    >> /tmp/so.txt
echo "### Distro:"                                                  >> /tmp/so.txt
hostnamectl                                                         >> /tmp/so.txt
echo "### sysctl.conf:"                                             >> /tmp/so.txt
cat /etc/sysctl.conf | grep -v '#'                                  >> /tmp/so.txt
cat /etc/sysctl.d/*.conf | grep -v '#'				    >> /tmp/so.txt
echo ""                                                             >> /tmp/so.txt
echo "### Scheduler:"                                               >> /tmp/so.txt
cat /sys/block/sda/queue/scheduler                                  >> /tmp/so.txt
echo ""                                                             >> /tmp/so.txt
echo "### Crontab:"                                                 >> /tmp/so.txt
crontab -l | grep -v '#'                                            >> /tmp/so.txt
cat /etc/crontab | grep -v '#'					    >> /tmp/so.txt
cat /etc/cron.d/* | grep -v '#'					    >> /tmp/so.txt
cat /tmp/so.txt
