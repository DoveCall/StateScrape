import logging
import requests

def run(config: dict = {}):
    try:
        threat_intel_url = config.get("threat_intel_url", "https://threatintel.example.com/api")
        response = requests.get(threat_intel_url)
        response.raise_for_status()
        data = response.json()
        logging.info("Threat intelligence data fetched successfully.")
        
        for threat in data.get("threats", []):
            logging.info(f"Threat detected: {threat}")
    except requests.exceptions.RequestException as e:
        logging.error(f"Failed to fetch threat intelligence data: {e}")
