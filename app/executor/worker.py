import os
import time
import logging

logging.basicConfig(level=logging.INFO)
log = logging.getLogger("executor")

def main():
    log.info("Executor starting")
    log.info("Version: %s", os.getenv("APP_VERSION"))
    log.info("Git SHA: %s", os.getenv("APP_GIT_SHA"))

    # Placeholder idle loop
    while True:
        time.sleep(30)

if __name__ == "__main__":
    main()
