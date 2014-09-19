

sudo apt-get -y install xscreensaver xscreensaver-gl

sudo rm /usr/bin/xscreensaver-getimage-file
sudo ln -s $HOME/xscreensaver_by_pics/deploy_data/xscreensaver-getimage-file /usr/bin/xscreensaver-getimage-file

cp .xscreensaver $HOME/
cp xscreensaver.desktop $HOME/.config/autostart/xscreensaver.desktop
cp xscreensaver_service.desktop $HOME/.config/autostart/xscreensaver_service.desktop
cp xscreensaver_test.desktop $HOME/.config/autostart/xscreensaver_test.desktop

sudo cpan
install JSON
install Data::GUID
Sys::HostAddr 
