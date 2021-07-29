#!/bin/bash

# create custom bootable iso for CentOS 7 with kickstart


if [ $# -lt 2 ]
then
    echo "Usage1: $0 path-iso path-kickstart"
    exit 1
else
    if [ ! -f $1 ]
    then
        echo "File $1 does not exist!"
        exit 0
    elif [ ! -f $2 ]
    then
        echo "File $2 does not exist!"
        exit 0
    else
        INNAME="$1"
        echo "Source file - $INNAME"
        KSFILE="$2"
        echo "Kickstart file - $KSFILE"
    fi
fi

# necessary package install
yum install syslinux genisoimage createrepo -y

# original ISO file of CentOS 7
ISO_ORIGINAL=$INNAME

# out file name
OUTNAME=$(basename "$INNAME" | cut -d. -f1)"-Kickstart".iso

# working directory
WORK=$PWD/WORK

# Delete possible previous results
rm -rf $WORK

# create a new working directory
echo "Create working directory - $WORK"
mkdir $WORK

# dir to mount original ISO - SRC
SRC=$WORK/SRC

# dir for customised ISO
DST=$WORK/DST

# Dir for mount EFI image
EFI=$WORK/EFI

# mount ISO to SRC dir
echo "Create $SRC"
mkdir $SRC
echo "Mount original $ISO_ORIGINAL to $SRC"
mount -o loop $ISO_ORIGINAL $SRC

# create dir for  ISO customisation
echo "Create dir $DST for customisation"
mkdir $DST

# copy orginal files to destination dir
# use dot after SRC dir (SRC/.) to help copy hidden files also
cp -v -r $SRC/. $DST/

echo "Umount original ISO $SRC"
umount $SRC

# create dir for EFI image
echo "Create dir for EFIBOOT image - $EFI"
mkdir $EFI

# change rights for rw
echo "Make EFIBOOT RW"
chmod 644 $DST/images/efiboot.img

echo "Mount EFIBOOT image to $EFI"
mount -o loop $DST/images/efiboot.img $EFI/

# add boot menu grab.cfg for UEFI mode
cp -v $(dirname $0)/cfg/efi-boot-grub.cfg $EFI/EFI/BOOT/grub.cfg

# unmount image
echo "Unmount $EFI"
umount $EFI/

# back RO rights
echo "Make EFIBOOT RO"
chmod 444 $DST/images/efiboot.img

# add boot menu grab.cfg for UEFI mode
# It is the second place where boot menu is exists for EFI.
# /images/efiboot.img/{grub.cfg} has the working menu
# /EFI/BOOT/grub.cfg just present (this case has to be discovered)
cp -v $(dirname $0)/cfg/efi-boot-grub.cfg $DST/EFI/BOOT/grub.cfg

# add boot menu with kickstart option to /isolinux (BIOS)
cp -v $(dirname $0)/cfg/isolinux.cfg $DST/isolinux/isolinux.cfg

# put kickstart file custom-ks.cfg to isolinux/ks.cfg
cp -v $KSFILE $DST/isolinux/ks.cfg

# create dir for custom scripts
#mkdir -p $DST/extras/ansible/
#cp -v -r $(dirname $0)/../ansible/. $DST/extras/ansible/

# copy custom rc.local
#cp -v -r $(dirname $0)/cfg/rc.local $DST/extras/

# copy extra RPM to Packages
#echo "Copy custom RPM to $DST/Packages"
#PACKAGES="$(dirname $0)/packages.txt"
#while IFS='' read -r pname || [[ -n "$pname" ]]; do
#    cp -v $(dirname $0)/Packages/$pname $DST/Packages/
#done < "$PACKAGES"

# update RPM repository index
echo "Update repository index"
(
    cd $DST/;
    rm -rf repodata/*minimal-x86_64-comps.xml;
    chmod u+w repodata/*;
    gunzip repodata/*minimal-x86_64-comps.xml.gz;
    createrepo -g repodata/*minimal-x86_64-comps.xml . --update;
)

# create output directory
OUTPUT=$WORK/OUTPUT
mkdir $OUTPUT

(
    echo "$PWD - Create custom ISO";
    cd $DST;
    genisoimage \
        -V "CentOS 7 x86_64" \
        -A "CentOS 7 x86_64" \
        -o $OUTPUT/$OUTNAME \
        -joliet-long \
        -b isolinux/isolinux.bin \
        -c isolinux/boot.cat \
        -no-emul-boot \
        -boot-load-size 4 \
        -boot-info-table \
        -eltorito-alt-boot -e images/efiboot.img \
        -no-emul-boot \
        -R -J -v -T \
        $DST \
        > $WORK/out.log 2>&1
)

echo "Isohybrid - make custom iso bootable"
sudo isohybrid --uefi $OUTPUT/$OUTNAME
