#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Function to print colored messages
print_message() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

print_header() {
    echo ""
    print_message "$BLUE" "=========================================="
    print_message "$BLUE" "$1"
    print_message "$BLUE" "=========================================="
}

print_success() {
    print_message "$GREEN" "✓ $1"
}

print_error() {
    print_message "$RED" "✗ $1"
}

print_warning() {
    print_message "$YELLOW" "⚠ $1"
}

print_info() {
    print_message "$BLUE" "ℹ $1"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check prerequisites
check_prerequisites() {
    print_header "Checking Prerequisites"

    if ! command_exists docker; then
        print_error "Docker is not installed. Please install Docker Desktop first."
        exit 1
    fi
    print_success "Docker is installed"

    if ! command_exists docker-compose; then
        print_error "Docker Compose is not installed. Please install Docker Compose first."
        exit 1
    fi
    print_success "Docker Compose is installed"
}

# Setup environment file
setup_env() {
    print_header "Setting Up Environment File"

    if [ -f "${SCRIPT_DIR}/.env" ]; then
        print_warning ".env file already exists. Skipping..."
        read -p "Do you want to overwrite it? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            return
        fi
    fi

    cp "${SCRIPT_DIR}/.env.example" "${SCRIPT_DIR}/.env"
    print_success "Created .env file from .env.example"
    print_info "You can customize the .env file to change versions, ports, and other settings"
}

# Load environment variables
load_env() {
    if [ -f "${SCRIPT_DIR}/.env" ]; then
        export $(cat "${SCRIPT_DIR}/.env" | grep -v '^#' | xargs)
        print_success "Loaded environment variables"
    fi
}

# Build and start Docker containers
start_containers() {
    print_header "Building and Starting Docker Containers"

    cd "${SCRIPT_DIR}"

    print_info "Building Docker images (this may take a few minutes)..."
    docker-compose build

    print_info "Starting containers..."
    docker-compose up -d

    print_success "Containers started successfully"
}

# Wait for services to be ready
wait_for_services() {
    print_header "Waiting for Services to be Ready"

    print_info "Waiting for database to be ready..."
    sleep 10

    local max_attempts=30
    local attempt=1

    while [ $attempt -le $max_attempts ]; do
        if docker-compose exec -T db mysqladmin ping -h localhost -u root -p"${MYSQL_ROOT_PASSWORD:-rootpassword}" >/dev/null 2>&1; then
            print_success "Database is ready"
            break
        fi

        if [ $attempt -eq $max_attempts ]; then
            print_error "Database failed to start"
            exit 1
        fi

        print_info "Waiting for database... (attempt $attempt/$max_attempts)"
        sleep 2
        ((attempt++))
    done

    print_info "Waiting for WordPress to be ready..."
    sleep 5
    print_success "WordPress is ready"
}

# Install WordPress
install_wordpress() {
    print_header "Installing WordPress"

    # Check if WordPress is already installed
    if docker-compose exec -T wordpress wp core is-installed --allow-root 2>/dev/null; then
        print_warning "WordPress is already installed. Skipping installation..."
        return
    fi

    local site_url="${WP_SITE_URL:-http://localhost:8000}"
    local site_title="${WP_SITE_TITLE:-WooCommerce Dev Site}"
    local admin_user="${WP_ADMIN_USER:-admin}"
    local admin_password="${WP_ADMIN_PASSWORD:-admin123}"
    local admin_email="${WP_ADMIN_EMAIL:-admin@example.local}"

    print_info "Installing WordPress..."
    docker-compose exec -T wordpress wp core install \
        --url="${site_url}" \
        --title="${site_title}" \
        --admin_user="${admin_user}" \
        --admin_password="${admin_password}" \
        --admin_email="${admin_email}" \
        --skip-email \
        --allow-root

    print_success "WordPress installed successfully"
    print_info "Admin URL: ${site_url}/wp-admin"
    print_info "Username: ${admin_user}"
    print_info "Password: ${admin_password}"
}

# Install and activate plugins
install_plugins() {
    print_header "Installing and Activating Plugins"

    local wc_version="${WOOCOMMERCE_VERSION:-8.5.2}"

    # Install WooCommerce
    print_info "Installing WooCommerce ${wc_version}..."
    docker-compose exec -T wordpress wp plugin install "woocommerce" --version="${wc_version}" --activate --allow-root
    print_success "WooCommerce installed and activated"

    # Run WooCommerce setup
    print_info "Configuring WooCommerce..."
    docker-compose exec -T wordpress wp option update woocommerce_store_address "123 Test Street" --allow-root
    docker-compose exec -T wordpress wp option update woocommerce_store_city "Test City" --allow-root
    docker-compose exec -T wordpress wp option update woocommerce_default_country "US:CA" --allow-root
    docker-compose exec -T wordpress wp option update woocommerce_store_postcode "12345" --allow-root
    docker-compose exec -T wordpress wp option update woocommerce_currency "USD" --allow-root
    docker-compose exec -T wordpress wp option update woocommerce_product_type "both" --allow-root
    docker-compose exec -T wordpress wp option update woocommerce_onboarding_opt_in "no" --allow-root
    print_success "WooCommerce configured"
}

# Install and activate theme
install_theme() {
    print_header "Installing and Activating Storefront Theme"

    local theme_version="${STOREFRONT_VERSION:-4.5.5}"

    print_info "Installing Storefront theme ${theme_version}..."
    docker-compose exec -T wordpress wp theme install "storefront" --version="${theme_version}" --activate --allow-root
    print_success "Storefront theme installed and activated"
}

# Setup sample data
setup_sample_data() {
    print_header "Setting Up Sample Data"

    print_info "Creating sample products and customers..."
    docker-compose exec -T wordpress bash /var/www/scripts/setup-sample-data.sh
    print_success "Sample data created successfully"
}

# Create VS Code configuration
create_vscode_config() {
    print_header "Creating VS Code Configuration"

    local vscode_dir="${SCRIPT_DIR}/.vscode"
    mkdir -p "${vscode_dir}"

    # Create launch.json for Xdebug
    cat > "${vscode_dir}/launch.json" <<EOF
{
    "version": "0.2.0",
    "configurations": [
        {
            "name": "Listen for Xdebug",
            "type": "php",
            "request": "launch",
            "port": 9003,
            "pathMappings": {
                "/var/www/html": "\${workspaceFolder}/wordpress"
            },
            "log": true
        }
    ]
}
EOF

    # Create settings.json
    cat > "${vscode_dir}/settings.json" <<EOF
{
    "php.validate.executablePath": "/usr/local/bin/php",
    "phpunit.phpunit": "vendor/bin/phpunit",
    "phpunit.args": [
        "-c",
        "phpunit.xml"
    ]
}
EOF

    print_success "VS Code configuration created"
    print_info "Launch.json and settings.json created in .vscode/"
}

# Print final instructions
print_final_instructions() {
    print_header "Setup Complete!"

    local site_url="${WP_SITE_URL:-http://localhost:8000}"
    local admin_user="${WP_ADMIN_USER:-admin}"
    local admin_password="${WP_ADMIN_PASSWORD:-admin123}"

    echo ""
    print_success "Your WordPress + WooCommerce development environment is ready!"
    echo ""
    print_info "Access your site:"
    echo "  Frontend: ${site_url}"
    echo "  Admin: ${site_url}/wp-admin"
    echo "  PHPMyAdmin: http://localhost:8080"
    echo ""
    print_info "Login credentials:"
    echo "  Username: ${admin_user}"
    echo "  Password: ${admin_password}"
    echo ""
    print_info "Environment:"
    echo "  PHP Version: ${PHP_VERSION:-8.1}"
    echo "  WordPress: ${WORDPRESS_VERSION:-6.4}"
    echo "  WooCommerce: ${WOOCOMMERCE_VERSION:-8.5.2}"
    echo ""
    print_info "Useful commands:"
    echo "  Stop containers:    docker-compose down"
    echo "  View logs:          docker-compose logs -f wordpress"
    echo "  Run WP-CLI:         docker-compose exec wordpress wp <command>"
    echo "  Access shell:       docker-compose exec wordpress bash"
    echo ""
    print_info "WordPress directory: ./wordpress/"
    print_info "Add plugins to: ./wordpress/wp-content/plugins/"
    print_info "Sample customers: john.doe@example.com / jane.smith@example.com (password: customer123)"
    echo ""
    print_info "Testing: Each plugin should have its own PHPUnit tests"
    echo ""
    print_warning "To start debugging with Xdebug:"
    echo "  1. Install 'PHP Debug' extension in VS Code"
    echo "  2. Press F5 to start listening for Xdebug"
    echo "  3. Add breakpoints in your code"
    echo "  4. Load your WordPress site in browser with ?XDEBUG_TRIGGER=1"
    echo ""
}

# Main execution
main() {
    print_header "WordPress + WooCommerce Plugin Development Environment Setup"
    print_info "This script will set up a complete development environment"
    echo ""

    check_prerequisites
    setup_env
    load_env
    start_containers
    wait_for_services
    install_wordpress
    install_plugins
    install_theme
    setup_sample_data
    create_vscode_config
    print_final_instructions

    print_success "All done! Happy coding!"
}

# Run main function
main "$@"
