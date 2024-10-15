import logging

def run(config: dict = {}):
    message = config.get("message", "Hello World from the plugin system!")
    logging.info(message)
