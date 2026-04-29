from flask import Flask, jsonify

app = Flask(__name__)


@app.get("/health")
def health() -> tuple[dict, int]:
    return {"status": "ok"}, 200


@app.get("/")
def root() -> tuple[dict, int]:
    return jsonify({"app": "miniapp", "message": "Contoso LATAM platform is running"}), 200


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
