import logging
import platform
import psutil
import socket

def run(config: dict = {}):
    logging.info("System Information:")
    logging.info(f"OS: {platform.system()} {platform.release()}")
    logging.info(f"CPU: {platform.processor()}")
    logging.info(f"RAM: {psutil.virtual_memory().total / (1024 * 1024 * 1024):.2f} GB")
    
    if config.get("include_disk_info", True):
        logging.info(f"Disk: {psutil.disk_usage('/').total / (1024 * 1024 * 1024):.2f} GB")
    
    if config.get("include_network_info", True):
        network_info = psutil.net_if_addrs()
        for interface, addresses in network_info.items():
            for addr in addresses:
                if addr.family == socket.AF_INET:
                    logging.info(f"Network Interface: {interface}, IP: {addr.address}")