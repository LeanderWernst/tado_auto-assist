#!/bin/bash

# Get the current directory of the script
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Function to install PyTado module
install_pytado() {
    echo "Cloning PyTado-Fork (wmalgadey) from GitHub..."
    
    # Clone PyTado repository into a temporary directory
    TMP_DIR=$(mktemp -d)
    git clone https://github.com/wmalgadey/PyTado.git "$TMP_DIR"

    # Navigate to the cloned repository
    cd "$TMP_DIR" || exit

    # Install PyTado using the appropriate method depending on user privileges
    if [ "$EUID" -eq 0 ]; then
        echo "Installing PyTado globally for root..."
        python3 setup.py install
    else
        echo "Installing PyTado for the current user..."
        python3 setup.py install --user
    fi

    # Clean up temporary directory
    rm -rf "$TMP_DIR"
    echo "PyTado installation complete."
}

# Generate the systemd service file dynamically
echo "[Unit]
Description=Tado Auto-Assist Service
After=network.target

[Service]
WorkingDirectory=/home/lndr/Automation/tado_aa
ExecStart=/usr/bin/python3 \"$DIR/tado_aa.py\"
Restart=always
User=$(logname)
Group=$(logname)
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=tado_aa

[Install]
WantedBy=multi-user.target" | sudo tee /etc/systemd/system/tado_aa.service > /dev/null

# Ensure proper permissions for the service file
sudo chmod 644 /etc/systemd/system/tado_aa.service

# Reload systemd to recognize the service
sudo systemctl daemon-reload

# Enable the service to start on boot
sudo systemctl enable tado_aa.service

# Start the service
if sudo systemctl start tado_aa.service; then
    echo "Service started successfully!"
else
    echo "Failed to start the service."
    exit 1
fi

# Call the function to install PyTado
install_pytado

echo "Installation complete!"
