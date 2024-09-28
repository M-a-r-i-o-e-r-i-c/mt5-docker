# Use a minimal Ubuntu base
FROM ubuntu:22.04

# Avoid prompts from apt
ENV DEBIAN_FRONTEND=noninteractive

# Update and install minimal dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    wget \
    xvfb \
    x11vnc \
    xfce4 \
    xfce4-terminal \
    firefox-esr \
    wine64 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Set up wine prefix
ENV WINEPREFIX=/root/.wine
ENV WINEARCH=win64

# Download and install MT5
RUN wget https://download.mql5.com/cdn/web/metaquotes.software.corp/mt5/mt5setup.exe \
    && xvfb-run wine mt5setup.exe /auto \
    && rm mt5setup.exe

# Set up VNC
RUN mkdir ~/.vnc \
    && x11vnc -storepasswd 1234 ~/.vnc/passwd

# Set display for Xvfb
ENV DISPLAY=:99

# Expose VNC port
EXPOSE 5900

# Start script
RUN echo '#!/bin/bash\n\
Xvfb :99 -screen 0 1024x768x16 &\n\
sleep 2\n\
DISPLAY=:99 startxfce4 &\n\
x11vnc -forever -usepw -display :99 &\n\
wine ~/.wine/drive_c/Program\ Files/MetaTrader\ 5/terminal64.exe\n\
' > /start.sh && chmod +x /start.sh

# Set the entry point
ENTRYPOINT ["/start.sh"]

# Keep-alive to prevent container from exiting
CMD ["bash", "-c", "while true; do sleep 60; done"]