## Ajustes de SO
## Savepoint
## 2024-03-27


# sysctl.conf (ajustes padrões)
## https://www.postgresql.org/docs/current/kernel-resources.html

# Método antigo
# /etc/sysctl.conf
# sysctl -p

# Método novo
# /etc/sysctl.d/90_postgresql.conf
# sysctl -p /etc/sysctl.d/90_postgresql.conf

vm.dirty_ratio=10
vm.dirty_background_ratio=5
vm.overcommit_memory=2
vm.overcommit_ratio=95
vm.swappiness=1

net.ipv4.tcp_tw_reuse=1
net.core.somaxconn=65535
net.ipv4.tcp_fin_timeout=5


# sysctl.conf (ajustes em ambientes muito grandes)
# só ajustar se encontrar erros no log do PostgreSQL

Out of Memory: Killed process 12345 (postgres).

# Ajustar shmmax e shmall
FATAL:  could not create shared memory segment: Invalid argument
DETAIL:  Failed system call was shmget(key=5440001, size=4011376640, 03600).

# Ajustar semáforos
FATAL:  could not create semaphores: No space left on device
DETAIL:  Failed system call was semget(5440126, 17, 03600).

# Até a versão 9.2 o ajuste do shmmax e shmall era obrigatório, depois só é necessário em ambientes muito grandes.
# shmmax = 1/2 da RAM of shmmax
# Script para calcular os valores de acordo com o servidor
page_size=`getconf PAGE_SIZE`
phys_pages=`getconf _PHYS_PAGES`
shmall=`expr $phys_pages / 2`
shmmax=`expr $shmall \* $page_size`
echo kernel.shmmax = $shmmax
echo kernel.shmall = $shmall

# EX (servidor com 32GB RAM):
kernel.shmmax = 17179869184
kernel.shmall = 4194304

kernel.sem = 250 512000 100 2048
fs.file-max = 312139770
fs.aio-max-nr = 1048576
net.core.somaxconn = 256

# Limits (ajustes em ambientes muito grandes)
# só ajustar se encontrar erros no log do PostgreSQL

# Método antigo:
# /etc/security/limits.conf
# Método novo: 
# /etc/security/limits.d/30-postgresql.conf

postgres soft nofile 65535
postgres hard nofile 65535

## Se o SELinux estiver ativo...
restorecon -Fvv /etc/security/limits.d/30-postgresql.conf

ext4 noatime

### Huge pages (para servidores com muita memória - >=64GB )
# O número de páginas deve ser o valor do shared_buffers + 10%, dividido pelo tamanho da página.
# O valor do hugepages deve ser = (shared_buffers(em MB) * 1,1)/ 2. 
# Ex: shared_buffers = 16GB
# hugepages = (16 * 1024 *1,1) / 2 = 9011
# editar /etc/default/grub 
...
...
GRUB_CMDLINE_LINUX="... hugepages=9011 hugepagesz=2M transparent_hugepage=never"
...
...

# Atualizar o grub com o comando (mais confiável que ajustar o vm.nr_hugepages no sysctl.conf)
# No Debian:
update-grub

# No Red Hat
grub2-mkconfig -o /boot/grub2/grub.cfg
# ou
grub2-mkconfig -o /boot/efi/EFI/redhat/grub.cfg

### init.d script
### /etc/rc.local
if test -f /sys/kernel/mm/transparent_hugepage/enabled; then
    echo never > /sys/kernel/mm/transparent_hugepage/enabled
fi
if test -f /sys/kernel/mm/transparent_hugepage/defrag; then
    echo never > /sys/kernel/mm/transparent_hugepage/defrag
fi

### Não esquecer de fazer um reboot no servidor e só depois ajustar o parâmetro huge_pages do postgresql.conf para ON

# Verificar hugepages:
cat /proc/meminfo | grep Huge

# No postgresql.conf ajustar o parâmetro "huge_pages". O default é 'try', mudar para 'on';
ALTER SYSTEM SET huge_pages TO on;

# Subir o PostgreSQL
# Verificar novamente o hugepages:
cat /proc/meminfo | grep Huge


### Particionamento
# - Manter pelo menos uma partição separada para dos dados
# Outras opções:
# - Uma partição para os logs (mudar o log_directory no postgresql.conf)
# - Uma partição para os logs de transação (fazer um link simbólico para $PGDATA/pg_wal)
# - Uma partição para o temp_files (mudar o temp_tablespaces no postgresql.conf)
# - Uma partição para cada novo tablespaces (útil para separar dados em discos rápidos e discos lentos)


### File systems
# XFS ~ EXT4 > ZFS >> BTRFS
# https://www.enterprisedb.com/blog/postgres-vs-file-systems-performance-comparison

# /etc/fstab
# - Sempre montar o dispositivo utlizando o UUID (ls -lh /dev/disk/by-uuid/)
# - Opções de montagem 
#   - noatime (seguro)
#   - nobarrier (somente em storages/controladoras com write cache e bateria)
# ex:
UUID=0bcbad84-23f8-485b-9d66-513bb480a5cb /data ext4 noatime,nobarrier,errors=remount-ro, 0 1

# Read-Ahead Tuning

# Verificar parâmetro atual
blockdev --getra /dev/sda1
blockdev --report

# Ajustar valor: 4096 ~ 16384
# /etc/rc.local

blockdev --setra 4096 /dev/sda1
