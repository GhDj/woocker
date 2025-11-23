# Woocker Quick Start

## Multi-Instance Support

Woocker now supports running multiple isolated WordPress instances simultaneously.

### 1. Create an Instance

Use the `woocker` CLI to create a new instance. You can specify PHP, WordPress, and WooCommerce versions.

```bash
./woocker create my-store --php 8.1 --wp 6.4 --woo 8.5.2
```

This will:
- Create a new directory in `instances/my-store`
- Assign unique ports (HTTP, HTTPS, PMA)
- Configure the environment

### 2. Start an Instance

```bash
./woocker start my-store
```

### 3. Initialize an Instance

Run the initialization script to install WordPress, WooCommerce, and sample data:

```bash
./woocker init my-store
```

### 4. List Instances

See all created instances and their assigned ports:

```bash
./woocker list
```

### 5. Remove an Instance

To delete an instance and all its data:

```bash
./woocker remove my-store
```

### 4. Shared Plugins

Place your custom plugins in the `plugins/` directory. They will be available in **all** instances under `wp-content/plugins/shared-plugins/`.

### 5. Stop an Instance

```bash
./woocker stop my-store
```

## Legacy Setup

The `setup.sh` script is deprecated. Please use `woocker create` instead.
