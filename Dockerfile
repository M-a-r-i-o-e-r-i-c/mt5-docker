# Base image: Ubuntu 20.04
FROM ubuntu:20.04

# Set timezone environment variable
ENV DEBIAN_FRONTEND=noninteractive

# Update package list
RUN apt-get update

# Install packages in smaller groups
RUN apt-get install -y tzdata wget curl gnupg2 software-properties-common
RUN apt-get install -y unzip xvfb
RUN apt-get install -y xfce4 xfce4-goodies
RUN apt-get install -y tightvncserver
RUN apt-get install -y wine64 winbind
RUN apt-get install -y x11vnc net-tools

# Clean up
RUN apt-get clean

# Set timezone
RUN ln -fs /usr/share/zoneinfo/America/New_York /etc/localtime && dpkg-reconfigure -f noninteractive tzdata

# Set environment variables
ENV DISPLAY=:1
ENV NGROK_AUTHTOKEN=2mglReN800R6adU2u5ApNr37mRb_4so9h6qhNmxpYkhbw8XKA

# Download and install Metatrader 5 (MT5)
RUN wget https://download.mql5.com/cdn/web/metaquotes.software.corp/mt5/mt5setup.exe -O mt5setup.exe && \
    wine mt5setup.exe /S /D=C:\\MT5 && \
    rm mt5setup.exe

# Install Ngrok
RUN wget https://bin.equinox.io/c/4VmDzA7iaHb/ngrok-stable-linux-amd64.zip && \
    unzip ngrok-stable-linux-amd64.zip && \
    mv ngrok /usr/local/bin/ && \
    rm ngrok-stable-linux-amd64.zip

# Set up VNC
RUN mkdir -p ~/.vnc && \
    echo "vncpassword" | vncpasswd -f > ~/.vnc/passwd && \
    chmod 600 ~/.vnc/passwd

# Expose VNC and Ngrok tunnel ports
EXPOSE 5901 4040

# Create entrypoint script to start VNC and Ngrok
RUN echo '#!/bin/bash\n\
vncserver :1 -geometry 1280x800 -depth 24 &&\n\
ngrok tcp 5901 --authtoken=${NGROK_AUTHTOKEN} &\n\
wine "C:\\MT5\\terminal.exe" &' > /start.sh && \
    chmod +x /start.sh

# Set entrypoint to start VNC, Ngrok, and MT5
ENTRYPOINT ["/start.sh"]

# Keep-alive to prevent container from exiting
CMD ["bash", "-c", "while true; do sleep 60; done"]