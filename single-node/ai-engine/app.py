import time
import requests
import urllib3
import numpy as np
from sentence_transformers import SentenceTransformer
from sklearn.metrics.pairwise import cosine_similarity

urllib3.disable_warnings()

WAZUH_URL    = "https://wazuh.manager:55000"
WAZUH_USER   = "wazuh-wui"
WAZUH_PASS   = "MyS3cr37P450r.*-"
INDEXER_URL  = "https://wazuh.indexer:9200"
INDEXER_USER = "admin"
INDEXER_PASS = "SecretPassword"
TOKEN        = None
TOKEN_EXPIRY = 0

# ======================
# THREAT KNOWLEDGE BASE
# teach the model what threats look like
# ======================
THREAT_SIGNATURES = {
    "FILE_DELETED": [
        "file deleted removed unlinked",
        "ossec file integrity monitoring deleted",
        "file was deleted from monitored directory",
        "syscheck file deleted",
    ],
    "PRIVILEGE_ESCALATION": [
        "sudo privilege escalation root access granted",
        "user changed to root via sudo",
        "su root privilege escalation attempt",
        "sudoers unauthorized privilege elevation",
    ],
    "BRUTE_FORCE_SSH": [
        "multiple failed ssh authentication attempts",
        "ssh brute force login failed invalid user",
        "repeated authentication failure ssh",
        "sshd invalid user login attempt failed",
    ],
    "ROOTKIT": [
        "rootkit detected hidden process",
        "rootcheck trojans hidden files detected",
        "suspicious hidden file process rootkit",
    ],
    "FILE_MODIFIED": [
        "file integrity monitoring checksum changed",
        "syscheck monitored file modified changed",
        "file attributes changed unexpectedly",
    ],
    "NEW_USER_CREATED": [
        "new user account created useradd",
        "user added to system account created",
    ],
    "PORT_SCAN": [
        "port scan detected multiple connection attempts",
        "nmap scan detected network reconnaissance",
    ],
    "MALWARE": [
        "malware detected virus trojan suspicious executable",
        "malicious file detected quarantined",
    ]
}

def build_threat_db(model):
    """Encode all threat signatures into embeddings"""
    print("[*] Building threat knowledge base...")
    db = {}
    for threat_type, phrases in THREAT_SIGNATURES.items():
        embeddings = model.encode(phrases)
        db[threat_type] = embeddings
    print(f"[+] Loaded {len(db)} threat categories")
    return db

def classify_threat(text, embedding, threat_db, threshold=0.45):
    """Match alert against known threat signatures"""
    best_match  = None
    best_score  = 0.0
    for threat_type, threat_embeddings in threat_db.items():
        sims  = cosine_similarity([embedding], threat_embeddings)[0]
        score = float(np.max(sims))
        if score > best_score:
            best_score = score
            best_match = threat_type
    if best_score >= threshold:
        return best_match, best_score
    return "UNKNOWN", best_score

# ======================
# AUTH
# ======================
def get_token():
    global TOKEN, TOKEN_EXPIRY
    print("[*] Fetching new Wazuh token...")
    r = requests.post(
        f"{WAZUH_URL}/security/user/authenticate",
        auth=(WAZUH_USER, WAZUH_PASS),
        verify=False, timeout=10
    )
    r.raise_for_status()
    TOKEN        = r.json()["data"]["token"]
    TOKEN_EXPIRY = time.time() + 800
    print("[+] Token obtained OK")

def ensure_token():
    if TOKEN is None or time.time() > TOKEN_EXPIRY:
        get_token()
    return {"Authorization": f"Bearer {TOKEN}"}

# ======================
# LOAD MODEL + BUILD THREAT DB
# ======================
print("[*] Loading SBERT model...")
model = SentenceTransformer('all-MiniLM-L6-v2')
print("[+] Model loaded OK")
threat_db = build_threat_db(model)

# ======================
# MEMORY (noise filtering)
# ======================
memory_embeddings = []
memory_texts      = []

# ======================
# FETCH ALERTS FROM OPENSEARCH
# ======================
def fetch_alerts(limit=20):
    query = {
        "size": limit,
        "sort": [{"timestamp": {"order": "desc"}}],
        "query": {"match_all": {}}
    }
    r = requests.post(
        f"{INDEXER_URL}/wazuh-alerts-*/_search",
        auth=(INDEXER_USER, INDEXER_PASS),
        json=query,
        verify=False,
        timeout=10
    )
    r.raise_for_status()
    hits = r.json().get("hits", {}).get("hits", [])
    return [h["_source"] for h in hits]

# ======================
# NOISE FILTER
# ======================
def is_noise(embedding, threshold=0.92):
    global memory_embeddings
    if memory_embeddings:
        sims    = cosine_similarity([embedding], memory_embeddings)[0]
        max_sim = float(np.max(sims))
        if max_sim > threshold:
            return True, max_sim
    memory_embeddings.append(embedding)
    memory_texts.append("")
    if len(memory_embeddings) > 500:
        memory_embeddings.pop(0)
        memory_texts.pop(0)
    return False, 0.0

# ======================
# SEVERITY MAPPING
# ======================
THREAT_SEVERITY = {
    "FILE_DELETED":          "HIGH",
    "PRIVILEGE_ESCALATION":  "CRITICAL",
    "BRUTE_FORCE_SSH":       "HIGH",
    "ROOTKIT":               "CRITICAL",
    "FILE_MODIFIED":         "MEDIUM",
    "NEW_USER_CREATED":      "MEDIUM",
    "PORT_SCAN":             "MEDIUM",
    "MALWARE":               "CRITICAL",
    "UNKNOWN":               "LOW",
}

# ======================
# MAIN LOOP
# ======================
def run():
    print("\n=== SBERT WAZUH AI ENGINE STARTED ===")
    ensure_token()
    seen_ids = set()

    while True:
        try:
            alerts = fetch_alerts(limit=20)

            if not alerts:
                print("[~] No alerts in OpenSearch yet")

            for alert in alerts:
                alert_id = alert.get("id") or alert.get("_id")
                if alert_id and alert_id in seen_ids:
                    continue
                if alert_id:
                    seen_ids.add(alert_id)

                rule  = alert.get("rule", {})
                agent = alert.get("agent", {})

                # build rich text for embedding
                text = (
                    f"{rule.get('description', '')} "
                    f"level {rule.get('level', '')} "
                    f"agent {agent.get('name', '')} "
                    f"groups {' '.join(rule.get('groups', []))}"
                )

                embedding = model.encode([text])[0]

                # noise check first
                noisy, noise_score = is_noise(embedding)
                if noisy:
                    print(f"\n[NOISE] Skipping duplicate (sim={noise_score:.2f}): {text[:60]}...")
                    continue

                # classify threat
                threat_type, confidence = classify_threat(text, embedding, threat_db)
                severity = THREAT_SEVERITY.get(threat_type, "LOW")

                print("\n" + "="*50)
                print(f"  ALERT ID   : {alert_id}")
                print(f"  RULE       : {rule.get('description', 'N/A')}")
                print(f"  LEVEL      : {rule.get('level', 'N/A')}")
                print(f"  AGENT      : {agent.get('name', 'N/A')}")
                print(f"  THREAT     : {threat_type}")
                print(f"  CONFIDENCE : {confidence:.0%}")
                print(f"  SEVERITY   : {severity}")
                print("="*50)

        except requests.exceptions.ConnectionError as e:
            print(f"[ERROR] Cannot reach indexer: {e}")
        except requests.exceptions.HTTPError as e:
            print(f"[ERROR] HTTP {e.response.status_code}: {e}")
        except Exception as e:
            print(f"[ERROR] {type(e).__name__}: {e}")

        time.sleep(5)

if __name__ == "__main__":
    run()
