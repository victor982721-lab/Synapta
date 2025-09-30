def utc_stamp(override:str|None=None) -> str:
    return override or datetime.utcnow().strftime("%Y-%m-%dT%H-%M-%SZ")