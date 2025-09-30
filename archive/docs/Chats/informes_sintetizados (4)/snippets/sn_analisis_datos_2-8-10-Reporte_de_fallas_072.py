MANIFEST_REQ_KEYS = {"ps1","md","txt","json","csv","html","chart","zip","inventory","hashes","report","manifest"}
def validate_manifest(manifest: dict):
    missing = MANIFEST_REQ_KEYS - set(manifest.keys())
    if missing:
        raise ValueError(f"Manifest incompleto, faltan: {', '.join(sorted(missing))}")