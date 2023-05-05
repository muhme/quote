# chrome.Dockerfile - instructions to build Docker image for the chrome container for testing the web application zitat-service.de
#
# Headless Chrome for system tests in German language, because the tests were written when there was only German.
#
# inspired from https://stackoverflow.com/questions/28405902/how-to-set-the-locale-inside-a-debian-ubuntu-docker-container
#
FROM selenium/standalone-chrome
RUN sudo apt-get update -qq && \
    sudo apt-get upgrade -y && \
    sudo apt-get install -y locales && \
    sudo sed -i '/de_DE.UTF-8/s/^# //g' /etc/locale.gen && \
    sudo locale-gen de_DE.UTF-8
# set de locale
ENV LANG de_DE.UTF-8  
ENV LANGUAGE de_DE:de  
ENV LC_ALL de_DE.UTF-8 
