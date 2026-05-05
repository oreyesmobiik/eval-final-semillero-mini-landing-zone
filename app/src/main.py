import os

from flask import Flask, jsonify

app = Flask(__name__)


@app.get("/health")
def health() -> tuple[dict, int]:
    return {"status": "ok"}, 200


@app.get("/")
def root() -> tuple[dict, int]:
    return jsonify({"app": "miniapp", "message": "Contoso LATAM platform is running"}), 200


@app.get("/config")
def config() -> tuple[dict, int]:
    secret_file = os.getenv("SECRET_FILE_PATH", "/mnt/secrets-store/miniapp-config")
    try:
        with open(secret_file, "r", encoding="utf-8") as f:
            secret_value = f.read().strip()
        return jsonify({"secret_loaded": True, "secret_length": len(secret_value)}), 200
    except OSError:
        return jsonify({"secret_loaded": False, "secret_length": 0}), 200


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
