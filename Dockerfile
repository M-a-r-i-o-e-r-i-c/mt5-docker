# Use Ubuntu 22.04 as the base image
FROM ubuntu:22.04

# Avoid prompts from apt
ENV DEBIAN_FRONTEND=noninteractive

# Set up environment variables
ENV DISPLAY=:99
ENV WINEPREFIX=/root/.wine
ENV WINEARCH=win64

# Update and install dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    wget \
    xvfb \
    x11vnc \
    xfce4 \
    xfce4-terminal \
    dbus-x11 \
    psmisc \
    wine64 \
    winetricks \
    curl \
    gpg \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install ZeroTier
RUN curl -s https://install.zerotier.com | bash

# Download MT5
RUN wget https://download.mql5.com/cdn/web/metaquotes.software.corp/mt5/mt5setup.exe -O /root/mt5setup.exe

# Set up VNC
RUN mkdir ~/.vnc && \
    x11vnc -storepasswd 123456 ~/.vnc/passwd

# Expose VNC port
EXPOSE 5900

# Create start script
RUN echo '#!/bin/bash\n\
\n\
# Start ZeroTier\n\
zerotier-one -d\n\
\n\
# Join ZeroTier network (replace NETWORK_ID with your ZeroTier network ID)\n\
zerotier-cli join 56374ac9a4e613b1\n\
\n\
# Function to check if a process is running\n\
is_running() {\n\
    pgrep -x "$1" >/dev/null\n\
}\n\
\n\
# Remove any existing lock files\n\
rm -f /tmp/.X99-lock\n\
\n\
# Start Xvfb\n\
Xvfb :99 -screen 0 1024x768x16 &\n\
sleep 2\n\
\n\
# Start Xfce4\n\
if ! is_running "xfce4-session"; then\n\
    startxfce4 &\n\
    sleep 2\n\
fi\n\
\n\
# Start x11vnc\n\
if ! is_running "x11vnc"; then\n\
    x11vnc -forever -usepw -display :99 &\n\
fi\n\
\n\
# Install MT5 if not already installed\n\
if [ ! -f "$WINEPREFIX/drive_c/Program Files/MetaTrader 5/terminal64.exe" ]; then\n\
    echo "Installing MT5..."\n\
    wine /root/mt5setup.exe /auto\n\
    echo "MT5 installation complete"\n\
fi\n\
\n\
# Start MT5\n\
if [ -f "$WINEPREFIX/drive_c/Program Files/MetaTrader 5/terminal64.exe" ]; then\n\
    wine "$WINEPREFIX/drive_c/Program Files/MetaTrader 5/terminal64.exe" &\n\
else\n\
    echo "MT5 executable not found"\n\
fi\n\
\n\
# Keep the container running\n\
tail -f /dev/null\n\
' > /start.sh && chmod +x /start.sh

# Set the entry point
ENTRYPOINT ["/start.sh"]