#!/data/data/com.termux/files/usr/bin/bash

# --- Configuration & Colors ---
MSF_PATH="$PREFIX/opt/metasploit-framework"
G_VER="1.19.1"
R_VER="3.4.0"
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}[*] Starting Metasploit Installation for Termux (Ruby 3.4 Patch)...${NC}"

# 1. Update and Install Dependencies
echo -e "${YELLOW}[1/6] Updating packages and installing dependencies...${NC}"
apt update -y && apt upgrade -y
apt install -y git python autoconf bison clang coreutils curl findutils apr apr-util postgresql openssl readline libffi libgmp libpcap libsqlite libgrpc libtool libxml2 libxslt ncurses make ncurses-utils termux-tools termux-elf-cleaner pkg-config ruby libiconv binutils zlib libyaml

# 2. Apply Nokogiri Security & Build Fixes
echo -e "${YELLOW}[2/6] Applying Nokogiri/Gumbo patches...${NC}"
bundle config set build.nokogiri --use-system-libraries
bundle config set force_ruby_platform true

# Manually create the header symlink for Gumbo
echo -e "${BLUE}[*] Linking Gumbo headers...${NC}"
mkdir -p $PREFIX/include
ln -sf $PREFIX/lib/ruby/gems/$R_VER/gems/nokogiri-$G_VER/ext/nokogiri/ports/aarch64-linux-android/libgumbo/1.0.0-nokogiri/include/nokogiri_gumbo.h $PREFIX/include/nokogiri_gumbo.h

# Install Nokogiri manually with specific CFLAGS to ignore deprecated warnings
echo -e "${BLUE}[*] Compiling Nokogiri (this may take a minute)...${NC}"
gem install nokogiri -v $G_VER --platform=ruby -- \
  --use-system-libraries \
  --with-xml2-include=$PREFIX/include/libxml2 \
  --with-xml2-lib=$PREFIX/lib \
  --with-cflags="-Wno-deprecated-declarations -Wno-implicit-function-declaration"

# 3. Clone Metasploit Framework
echo -e "${YELLOW}[3/6] Cloning Metasploit Framework into /opt...${NC}"
mkdir -p $PREFIX/opt/
if [ ! -d "$MSF_PATH" ]; then
    git clone https://github.com/rapid7/metasploit-framework.git "$MSF_PATH"
else
    echo -e "${BLUE}[*] Directory exists, pulling latest updates...${NC}"
    cd "$MSF_PATH" && git pull
fi

# 4. Install Gems via Bundler
echo -e "${YELLOW}[4/6] Installing Ruby gems (Bundler)...${NC}"
cd "$MSF_PATH"
# Using -j1 to prevent Android's Phantom Process Killer from stopping the build
bundle install -j1

# 5. Setup Binary Symlinks
echo -e "${YELLOW}[5/6] Creating system-wide symlinks...${NC}"
ln -sf "$MSF_PATH/msfconsole" "$PREFIX/bin/msfconsole"
ln -sf "$MSF_PATH/msfvenom" "$PREFIX/bin/msfvenom"
chmod +x "$PREFIX/bin/msfconsole" "$PREFIX/bin/msfvenom"

# 6. Create msfdb Helper & Database Config
echo -e "${YELLOW}[6/6] Configuring PostgreSQL and msfdb helper...${NC}"

cat << 'EOF' > $PREFIX/bin/msfdb
#!/data/data/com.termux/files/usr/bin/bash
PG_DATA="$PREFIX/var/lib/postgresql"
GREEN='\033[0;32m'
NC='\033[0m'

case "$1" in
    start)
        if [ ! -d "$PG_DATA" ]; then
            echo -e "${GREEN}[*] Initializing Database...${NC}"
            mkdir -p "$PG_DATA"
            initdb "$PG_DATA"
            pg_ctl -D "$PG_DATA" start
            sleep 2
            createuser -s postgres
            createdb msf
            echo -e "${GREEN}[*] DB Initialized and Started.${NC}"
        else
            pg_ctl -D "$PG_DATA" start
        fi
        ;;
    stop)
        pg_ctl -D "$PG_DATA" stop
        ;;
    status)
        pg_ctl -D "$PG_DATA" status
        ;;
    *)
        echo "Usage: msfdb {start|stop|status}"
        exit 1
        ;;
esac
EOF

chmod +x $PREFIX/bin/msfdb

# Create database.yml
mkdir -p ~/.msf4
cat << 'EOF' > ~/.msf4/database.yml
production: &default
  adapter: postgresql
  database: msf
  username: postgres
  password: 
  host: localhost
  port: 5432
  pool: 75
  timeout: 5

development:
  <<: *default
EOF

echo -e "${GREEN}[+] INSTALLATION COMPLETE!${NC}"
echo -e "${BLUE}[*] Run 'msfdb start' then 'msfconsole' to begin.${NC}"
