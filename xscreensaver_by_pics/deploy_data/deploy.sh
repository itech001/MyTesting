#!/bin/sh

SUDO=
if [ $USER != root ]; then
 SUDO=sudo
fi

echo the current user is $USER, sudo is $SUDO

cd -  # $HOME

wget  https://github.com/itech001/MyTesting/archive/master.zip
unzip master.zip
ln -s MyTesting-master/xscreensaver_by_pics xscreensaver_by_pics

$SUDO apt-get -y install xscreensaver xscreensaver-gl
$SUDO rm /usr/bin/xscreensaver-getimage-file
$SUDO ln -s $HOME/xscreensaver_by_pics/deploy_data/xscreensaver-getimage-file /usr/bin/xscreensaver-getimage-file

cd $HOME/xscreensaver_by_pics/deploy_data
cp .xscreensaver $HOME/
cp xscreensaver.desktop $HOME/.config/autostart/xscreensaver.desktop
cp xscreensaver_service.desktop $HOME/.config/autostart/xscreensaver_service.desktop
cp xscreensaver_mytest.desktop $HOME/.config/autostart/xscreensaver_mytest.desktop

$SUDO cpan -fi JSON Data::GUID Sys::HostAddr 
