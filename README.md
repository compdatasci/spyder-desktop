# Docker Image for Spyder
This Docker image provides the Ubuntu 16.04 environment with X Windows with Spyder and Jupyter Notebook. The X Windows will display in your web browser in full-screen mode. You can use this Docker image on 64-bit Linux, Mac or Windows. It allows you to use the same programming environment regardless which OS you are running on your laptop or desktop.

[![Build Status](https://travis-ci.org/compdatasci/spyder-desktop.svg?branch=master)](https://travis-ci.org/compdatasci/spyder-desktop) [![](https://images.microbadger.com/badges/image/compdatasci/spyder-desktop.svg)](https://microbadger.com/images/compdatasci/spyder-desktop)

## Preparation
Before you start, you need to first install Python and Docker on your computer by following the steps below.

### Installing Python
If you use Linux or Mac, Python is most likely already installed on your computer, so you can skip this step.

If you use Windows, you need to install Python if you have not yet done so. The easiest way is to install `Miniconda`, which you can download at https://repo.continuum.io/miniconda/Miniconda3-latest-Windows-x86_64.exe. You can use the default options during installation.

### Installing Docker
Download the Docker Community Edition for free at https://www.docker.com/community-edition#/download and then run the installer. Note that you need administrator's privilege to install Docker. After installation, make sure you launch Docker before proceeding to the next step.

**Notes for Windows Users**
1. Docker only supports 64-bit Windows 10 Pro or higher. If you have Windows 8 or Windows 10 Home, you need to upgrade your Windows operating system before installing Docker. Stony Brook students can get Windows 10 Education free of charge at https://stonybrook.onthehub.com. Note that the older [Docker Toolbox](https://www.docker.com/products/docker-toolbox) supports older versions of Windows, but it should not be used.
2. After installing Docker, you may need to restart your computer to enable virtualization.
3. When you use Docker for the first time, you must change its settings to make the C drive shared. To do this, right-click the Docker icon in the system tray, and then click on `Settings...`. Go to `Shared Drives` tab and check the C drive.

**Notes for Linux Users**
* After you install Docker, make sure you add yourself to the Docker group by running the command:
```
sudo adduser $USER docker
```
Then, log out and log back in before you can use Docker.
## Tips and Tricks
1. By default, Docker uses two CPU cores and 2GB of memory on Mac and Windows. If you want to run large jobs, go to the `Advanced` tab in `Settings` (or `Preferences` for Mac) and increase the amount of memory dedicated to Docker.
2. When using the Docker image, the files under `$HOME/.config`, `$HOME/.ssh`, , $HOME/project`,  `$HOME/shared` and any other
directory that you might have mounted explicitly are persistent. Any change to files in other directories will be lost when you stop the Docker image. `$HOME/.config` contains the configuration files of the desktop environment. `$HOME/shared` maps to the working directory on the host where you started the docker image.
3. The `$HOME/.ssh` directory in the Docker image maps to the `.ssh` directory on your host computer. This is particularly convenient for you to use your ssh-keys for authentications with git repositories on github.com or bitbucket.org. To use your ssh-keys, run the `ssh-add` in a terminal to add your keys to the ssh-agent.
4. You can copy and paste between the host and the Docker image through the `Clipboard` box in the left toolbar, which is synced automatically with the clipboard of the Docker image. To copy from the Docker image to the host, first, select the text in the Docker image, and then go to the `Clipboard` box to copy. To copy from host to the Docker image, first, paste the text into the `Clipboard` box, and then paste the text in the Docker image.
