# Check if 'silicon' is installed, and install it if not.
# Works on Windows 11. Tries Scoop, Chocolatey, then cargo (Rust).

function Is-CommandAvailable {
    param([string]$cmd)
    $null -ne (Get-Command $cmd -ErrorAction SilentlyContinue)
}

Write-Host "Checking if 'silicon' is installed..."
if (Is-CommandAvailable "silicon") {
    Write-Host "'silicon' is already installed."
    exit 0
}

Write-Host "'silicon' not found. Attempting to install..."

# Try Scoop
if (Is-CommandAvailable "scoop") {
    Write-Host "Scoop detected. Installing 'silicon' via Scoop..."
    scoop install silicon
    if (Is-CommandAvailable "silicon") {
        Write-Host "'silicon' installed successfully via Scoop."
        exit 0
    } else {
        Write-Host "Failed to install 'silicon' via Scoop."
    }
}

# Try Chocolatey
if (Is-CommandAvailable "choco") {
    Write-Host "Chocolatey detected. Installing 'silicon' via Chocolatey..."
    choco install silicon -y
    if (Is-CommandAvailable "silicon") {
        Write-Host "'silicon' installed successfully via Chocolatey."
        exit 0
    } else {
        Write-Host "Failed to install 'silicon' via Chocolatey."
    }
}

# Try cargo (Rust)
if (Is-CommandAvailable "cargo") {
    Write-Host "Cargo detected. Installing 'silicon' via cargo..."
    cargo install silicon
    # Add cargo bin to PATH for current session if needed
    $cargoBin = "$env:USERPROFILE\.cargo\bin"
    if (-not ($env:PATH -split ";" | Where-Object { $_ -eq $cargoBin })) {
        $env:PATH += ";$cargoBin"
    }
    if (Is-CommandAvailable "silicon") {
        Write-Host "'silicon' installed successfully via cargo."
        exit 0
    } else {
        Write-Host "Failed to install 'silicon' via cargo."
    }
}

Write-Host "Could not install 'silicon'."
Write-Host "Please install Scoop (https://scoop.sh), Chocolatey (https://chocolatey.org), or Rust (https://rustup.rs) and try again."
exit 1
