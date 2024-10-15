import yaml
import argparse
import logging
from typing import Dict, Any
import importlib
import os
import subprocess
import colorlog

# Configure colorful logging
log_colors = {
    'DEBUG': 'cyan',
    'INFO': 'green',
    'WARNING': 'yellow',
    'ERROR': 'red',
    'CRITICAL': 'bold_red',
}

formatter = colorlog.ColoredFormatter(
    "%(log_color)s%(asctime)s - %(levelname)s - %(message)s",
    datefmt='%Y-%m-%d %H:%M:%S',
    log_colors=log_colors
)

handler = logging.StreamHandler()
handler.setFormatter(formatter)

logging.basicConfig(
    level=logging.DEBUG,  # Set to DEBUG to capture all log levels
    handlers=[handler]
)


def load_config() -> Dict[str, Any]:
    """
    Load the configuration from a YAML file.

    Returns:
        dict: A dictionary containing the configuration settings.
    """
    logging.debug("Loading configuration from config.yaml...")
    try:
        with open("config.yaml", "r") as file:
            config = yaml.safe_load(file)
            logging.info("Configuration loaded successfully.")
            return config
    except Exception as e:
        logging.critical(f"Failed to load configuration: {e}")
        raise


def load_plugins(plugin_dir: str) -> Dict[str, Any]:
    """
    Load plugins from the specified directory.

    Args:
        plugin_dir (str): The directory containing the plugins.

    Returns:
        dict: A dictionary of loaded plugins.
    """
    logging.debug(f"Loading plugins from {plugin_dir}...")
    plugins = {}
    try:
        for filename in os.listdir(plugin_dir):
            if filename.endswith(".py") and not filename.startswith("__"):
                module_name = filename[:-3]
                module = importlib.import_module(f"plugins.{module_name}")
                if hasattr(module, "run"):
                    plugins[module_name] = module.run
                    logging.info(f"Loaded plugin: {module_name}")
        logging.info("All plugins loaded successfully.")
    except Exception as e:
        logging.error(f"Failed to load plugins: {e}")
    return plugins


def execute_scan(mode: Dict[str, Any], plugins: Dict[str, Any], config: Dict[str, Any]) -> None:
    """
    Execute a security scan based on the provided mode and plugins.

    Args:
        mode (dict): A dictionary containing the scan mode and associated tools.
        plugins (dict): A dictionary of loaded plugins.
        config (dict): The configuration dictionary.
    """
    logging.info(f"Executing {mode['name']} scan...")
    for tool in mode["tools"]:
        if tool in plugins:
            try:
                tool_config = config.get("plugin_config", {}).get(tool, {})
                plugins[tool](tool_config)
                logging.info(f"{tool} executed successfully.")
            except subprocess.CalledProcessError as e:
                logging.error(f"Failed to execute {tool}: {e}")
            except Exception as e:
                logging.error(f"Failed to execute {tool} plugin: {e}")
        else:
            logging.warning(f"No specific command defined for {tool}. Skipping.")


def health_check():
    try:
        # Check configuration
        config = load_config()
        assert config is not None, "Configuration is missing"
        
        # Check plugins
        plugins = load_plugins("plugins")
        assert plugins, "No plugins loaded"
        
        logging.info("Health check passed.")
    except AssertionError as e:
        logging.error(f"Health check failed: {e}")
        raise


def main():
    parser = argparse.ArgumentParser(description="StateScrape Security Tool")
    parser.add_argument("--debug", action="store_true", help="Enable debug mode")
    args = parser.parse_args()

    if args.debug:
        logging.getLogger().setLevel(logging.DEBUG)
        logging.debug("Debug mode enabled")

    health_check()
    # Continue with normal execution


if __name__ == "__main__":
    main()
