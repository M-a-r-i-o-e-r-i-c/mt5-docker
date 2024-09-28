# Use a minimal Ubuntu base
FROM ubuntu:22.04

# Avoid prompts from apt
ENV DEBIAN_FRONTEND=noninteractive

# Update and install dependencies in one step to reduce layers
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    wget \
    xvfb \
    x11vnc \
    xfce4 \
    xfce4-terminal \
    dbus-x11 \
    psmisc \
    npm \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install LocalTunnel globally
RUN npm install -g localtunnel

# Set up wine prefix
ENV WINEPREFIX=/root/.wine
ENV WINEARCH=win64

# Download MT5
RUN wget https://download.mql5.com/cdn/web/metaquotes.software.corp/mt5/mt5setup.exe

# Set up VNC
RUN mkdir ~/.vnc && \
    echo "123456" > ~/.vnc/passwd && \
    chmod 600 ~/.vnc/passwd

# Set display for Xvfb
ENV DISPLAY=:99

# Expose VNC port (5900)
EXPOSE 5900

# Start script
RUN echo '#!/bin/bash\n\
# Function to check if a process is running\n\
is_running() {\n\
    pgrep -x "$1" >/dev/null\n\
}\n\
\n\
# Kill existing processes if they are running\n\
killall Xvfb xfce4-session x11vnc 2>/dev/null\n\
\n\
# Remove any existing lock files\n\
rm -f /tmp/.X99-lock\n\
\n\
echo "Starting Xvfb..."\n\
Xvfb :99 -screen 0 1024x768x16 &\n\
sleep 2\n\
\n\
echo "Starting Xfce4..."\n\
if ! is_running "xfce4-session"; then\n\
    DISPLAY=:99 startxfce4 &\n\
    sleep 2\n\
fi\n\
\n\
echo "Starting x11vnc..."\n\
if ! is_running "x11vnc"; then\n\
    x11vnc -forever -usepw -display :99 &\n\
fi\n\
\n\
echo "Attempting to install MT5..."\n\
if [ -f mt5setup.exe ]; then\n\
    wine mt5setup.exe /auto\n\
    echo "MT5 installation attempt complete"\n\
else\n\
    echo "MT5 setup file not found"\n\
fi\n\
\n\
echo "Starting MT5..."\n\
if [ -f "$WINEPREFIX/drive_c/Program Files/MetaTrader 5/terminal64.exe" ]; then\n\
    wine "$WINEPREFIX/drive_c/Program Files/MetaTrader 5/terminal64.exe" &\n\
else\n\
    echo "MT5 executable not found"\n\
fi\n\
\n\
# Start LocalTunnel without subdomain\n\
lt --port 5900 &\n\
\n\
# Keep the container running\n\
tail -f /dev/null\n\
' > /start.sh && chmod +x /start.sh

# Set the entry point
ENTRYPOINT ["/start.sh"]
