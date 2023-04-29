# Install
```bash
git clone --recursive -j8 https://github.com/zunoffon/bbb_lvgl.git && cd bbb_lvgl
```
`docker` is required to setup build environment

# Build
- Setup build environment
```bash
make builder
```
- Build all
```bash
make
```

# Deploy
- Create sd card partition table
```bash
# erase the partition table
sudo dd if=/dev/zero of=/dev/sdg bs=512 count=1 conv=notrunc
# boot partition
printf "o\nn\np\n1\n\n+100M\na\n1\nt\nc\nw\n" | sudo fdisk /dev/sdg
# rfs partition
printf "n\np\n2\n\n+28G\nw\nq\n" | sudo fdisk /dev/sdg
sudo mkfs.ext4 /dev/sdg2
# partitions something like
$ lsblk -fm /dev/sdg
NAME   FSTYPE LABEL UUID                                 FSAVAIL FSUSE% MOUNTPOINT  SIZE OWNER GROUP MODE
sdg                                                                                29,7G root  disk  brw-rw----
├─sdg1 vfat   BOOT  257B-EED1                                                       100M root  disk  brw-rw----
└─sdg2 ext4         3740dea0-9bb5-4244-93f5-7b92a8a7a625                             28G root  disk  brw-rw----
```
- Sync build artefacts
```bash
sudo mkdir -p /mnt/{boot,rootfs}

sudo mount /dev/sdg1 /mnt/boot/
sudo cp conf/uboot.env /mnt/boot/
sudo cp src/u-boot/MLO /mnt/boot/
sudo cp src/u-boot/u-boot.img /mnt/boot/
sudo cp src/linux/arch/arm/boot/dts/am335x-boneblack.dtb /mnt/boot/
sudo cp src/linux/arch/arm/boot/zImage /mnt/boot/
sudo sync
sudo umount /dev/sdg1

sudo mount /dev/sdg2 /mnt/rootfs/
sudo tar -xvf ospack_v2022-armhf-fixedfunction_v2022.4.tar.gz -C /mnt/rootfs/
sudo cp src/lvgl_demo/demo /mnt/rootfs/root/
echo "PermitRootLogin yes" | sudo tee -a /mnt/rootfs/etc/ssh/sshd_config
sudo sync
sudo umount /dev/sdg2
```
- Insert SD card, hold the Boot Button (S2) on the top right (near the SD card slot) and, while holding this button, insert the USB/power lead to connect the power.

# Demo
```bash
$ scp src/lvgl_demo/demo user@192.168.2.2:/home/user/
$ ssh user@192.168.2.2
$ sudo -i
# ./demo
./demo: error while loading shared libraries: libinput.so.10: cannot open shared object file: No such file or directory
# apt update && apt install libinput10
```
 
# Target trouble shooting
## Login
```bash
Apertis v2022 apertis ttyS0
apertis login: user
Password: user
$ whoami
user
$ sudo -i
# whoami
root
```
## Device stucking at u-boot
- Enter boot command
```bash
setenv loadkernel fatload mmc 0:1 ${loadaddr} zImage
setenv loaddtb fatload mmc 0:1 ${fdtaddr} am335x-boneblack.dtb
setenv bootargs console=${console} ${optargs} root=/dev/mmcblk0p2 rw rootfstype=ext4 video=HDMI-A-1:800x480@60
setenv bootcmd "run loadkernel; run loaddtb; bootz ${loadaddr} - ${fdtaddr}"
saveenv
```
## Disable blinking while running graphic app (Linux framebuffer)
```bash
echo 0 > /sys/class/graphics/fbcon/cursor_blink
```
## ssh
- Target
```bash
# ifconfig eth0 192.168.2.2/24
# ifconfig
eth0: flags=-28605<UP,BROADCAST,RUNNING,MULTICAST,DYNAMIC>  mtu 1500
        inet 192.168.2.2  netmask 255.255.255.255  broadcast 192.168.2.255
        inet6 fe80::6a3:16ff:feb5:1912  prefixlen 64  scopeid 0x20<link>
        ether 04:a3:16:b5:19:12  txqueuelen 1000  (Ethernet)
        RX packets 152  bytes 17300 (16.8 KiB)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 166  bytes 36230 (35.3 KiB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0
```
- Host
```bash
$ ifconfig
enx00e04c334361: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet 192.168.2.1  netmask 255.255.255.0  broadcast 192.168.2.255
        inet6 fe80::2e0:4cff:fe33:4361  prefixlen 64  scopeid 0x20<link>
        ether 00:e0:4c:33:43:61  txqueuelen 1000  (Ethernet)
        RX packets 17  bytes 7142 (7.1 KB)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 45  bytes 6785 (6.7 KB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0
$ ssh user@192.168.2.2
user@192.168.2.2's password:
```
## Share internet access
- Host
```bash
$ git clone https://github.com/tinyproxy/tinyproxy.git && cd tinyproxy
$ ./autogen.sh && ./configure && make
$ cat <<EOF > tinyproxy.conf
Port 8080
Listen 0.0.0.0
Timeout 600
Allow 192.168.2.1/24
EOF
$ src/tinyproxy -d -c tinyproxy.conf
```
- Target
```bash
# export http_proxy=http://192.168.2.1:8080
# busybox date -s "2023-04-30 10:34:00"
```
