import logging
import socket

def run(config: dict = {}):
    target = config.get("target", "localhost")
    ports = config.get("ports", [80, 443, 22, 21])
    
    logging.info(f"Scanning ports on {target}:")
    for port in ports:
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.settimeout(1)
        result = sock.connect_ex((target, port))
        if result == 0:
            logging.info(f"Port {port}: Open")
        else:
            logging.info(f"Port {port}: Closed")
        sock.close()
