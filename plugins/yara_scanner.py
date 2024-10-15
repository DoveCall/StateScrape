import logging
import yara

def run(config: dict = {}):
    rules_path = config.get("rules_path", "/path/to/yara/rules")
    logging.info(f"Scanning with YARA rules from {rules_path}")
    rules = yara.compile(filepath=rules_path)
    matches = rules.match("/path/to/scan")
    for match in matches:
        logging.info(f"YARA match: {match}")

