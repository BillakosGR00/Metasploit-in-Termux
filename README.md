# Metasploit Framework Installer for Termux (Ruby 3.4+ Optimized)

Setting up the Metasploit Framework (MSF) on Android via Termux often fails due to compilation errors in native extensions like **Nokogiri** and **Gumbo**. This script automates the entire installation process, applies critical compatibility patches, and sets up a dedicated database management helper.

## 🚀 Key Features

* **Ruby 3.4 Compatibility:** Tailored to work with modern Ruby versions and updated dependencies.
* **Nokogiri & Gumbo Patches:** Includes manual header symlinking and specific `CFLAGS` to bypass deprecated/implicit function declaration errors during compilation.
* **Automated DB Setup:** Automatically configures PostgreSQL, creates the necessary database users, and generates the `database.yml` file.
* **`msfdb` Helper Script:** Adds a custom system-wide command to easily `start`, `stop`, and check the `status` of your Metasploit database.
* **Android-Optimized Build:** Uses single-threaded Bundler execution (`-j1`) to prevent the Android "Phantom Process Killer" from terminating the installation.

---

## 🛠️ Installation

1.  **Open Termux** and ensure your packages are up to date:
    ```bash
    pkg update && pkg upgrade -y
    ```

2.  **Clone this repository:**
    ```bash
    git clone https://github.com/BillakosGR00/Metasploit-in-Termux.git
    cd Metasploit-in-Termux
    ```

3.  **Run the installer:**
    ```bash
    chmod +x msfinstall.sh
    ./msfinstall.sh
    ```

---

## 💡 Usage

### 1. Initialize/Start the Database
Before launching Metasploit, you need to ensure the PostgreSQL database is running. We've included a helper script for this:
```bash
msfdb start
