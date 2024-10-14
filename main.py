import yaml
import subprocess
import logging
import argparse
from typing import Dict, Any

# Configure logging
logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s"
)


def load_config() -> Dict[str, Any]:
    """
    Load the configuration from a YAML file.

    Returns:
        dict: A dictionary containing the configuration settings.
    """
    with open("config.yaml", "r") as file:
        return yaml.safe_load(file)


def execute_scan(mode: Dict[str, Any]) -> None:
    """
    Execute a security scan based on the provided mode.

    Args:
        mode (dict): A dictionary containing the scan mode and associated tools.
    """
    logging.info(f"Executing {mode['name']} scan...")
    for tool in mode["tools"]:
        try:
            subprocess.run(f"{tool} --scan", shell=True, check=True)
            logging.info(f"{tool} executed successfully.")
        except subprocess.CalledProcessError as e:
            logging.error(f"Failed to execute {tool}: {e}")


def main():
    config = load_config()
    parser = argparse.ArgumentParser(description="StateScrape Security Tool")
    parser.add_argument(
        "--mode",
        choices=[mode["name"] for mode in config["scan_modes"]],
        required=True,
        help="Select the scan mode",
    )
    args = parser.parse_args()

    selected_mode = next(
        (mode for mode in config["scan_modes"] if mode["name"] == args.mode), None
    )
    if selected_mode:
        execute_scan(selected_mode)
    else:
        logging.error("Invalid scan mode selected.")


if __name__ == "__main__":
    main()
