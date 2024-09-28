# Use a minimal Ubuntu base
FROM ubuntu:22.04

# Avoid prompts from apt
ENV DEBIAN_FRONTEND=noninteractive

# Update and install minimal dependencies in separate steps
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates && rm -rf /var/lib/apt/lists/*
RUN apt-get update && apt-get install -y --no-install-recommends wget && rm -rf /var/lib/apt/lists/*
RUN apt-get update && apt-get install -y --no-install-recommends xvfb && rm -rf /var/lib/apt/lists/*
RUN apt-get update && apt-get install -y --no-install-recommends x11vnc && rm -rf /var/lib/apt/lists/*
RUN apt-get update && apt-get install -y --no-install-recommends xfce4 xfce4-terminal && rm -rf /var/lib/apt/lists/*
RUN apt-get update && apt-get install -y --no-install-recommends wine64 && rm -rf /var/lib/apt/lists/*

# Set up wine prefix
ENV WINEPREFIX=/root/.wine
ENV WINEARCH=win64

# Download MT5 (but don't install yet)
RUN wget https://download.mql5.com/cdn/web/metaquotes.software.corp/mt5/mt5setup.exe

# Set up VNC
RUN mkdir ~/.vnc \
    && echo "123456" | vncpasswd -f > ~/.vnc/passwd \
    && chmod 600 ~/.vnc/passwd

# Set display for Xvfb
ENV DISPLAY=:99

# Expose VNC port
EXPOSE 5900

# Start script
RUN echo '#!/bin/bash\n\
echo "Starting Xvfb..."\n\
Xvfb :99 -screen 0 1024x768x16 &\n\
sleep 2\n\
echo "Starting Xfce4..."\n\
DISPLAY=:99 startxfce4 &\n\
sleep 2\n\
echo "Starting x11vnc..."\n\
x11vnc -forever -usepw -display :99 &\n\
echo "Attempting to install MT5..."\n\
wine mt5setup.exe /auto\n\
echo "MT5 installation attempt complete"\n\
echo "Starting MT5..."\n\
wine ~/.wine/drive_c/Program\ Files/MetaTrader\ 5/terminal64.exe\n\
' > /start.sh && chmod +x /start.sh

# Set the entry point
ENTRYPOINT ["/start.sh"]

# Keep-alive to prevent container from exiting
CMD ["bash", "-c", "while true; do sleep 60; done"]