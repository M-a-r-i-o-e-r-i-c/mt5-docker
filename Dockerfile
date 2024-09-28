# Base image: Ubuntu 20.04
FROM ubuntu:20.04

# Update package list and install dependencies
RUN apt-get update && apt-get install -y \
    wget \
    curl \
    gnupg2 \
    software-properties-common \
    unzip \
    xvfb \
    xfce4 \
    xfce4-goodies \
    tightvncserver \
    wine64 \
    winbind \
    x11vnc \
    net-tools \
    && apt-get clean

# Set environment variables
ENV DISPLAY=:1

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
ngrok tcp 5901 --authtoken=$NGROK_AUTHTOKEN &\n\
wine "C:\\MT5\\terminal.exe" &' > /start.sh && \
    chmod +x /start.sh

# Set environment variable for Ngrok authtoken
ENV NGROK_AUTHTOKEN=2mglReN800R6adU2u5ApNr37mRb_4so9h6qhNmxpYkhbw8XKA

# Set entrypoint to start VNC, Ngrok, and MT5
ENTRYPOINT ["/start.sh"]

# Keep-alive to prevent container from exiting
CMD ["bash", "-c", "while true; do sleep 60; done"]
