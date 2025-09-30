import logging
def setup_logging(debug=False, base_dir="."):
    logging.basicConfig(
        filename=str(Path(base_dir)/"orq.log"),
        level=logging.DEBUG if debug else logging.INFO,
        format="%(asctime)s %(levelname)s %(name)s: %(message)s"
    )