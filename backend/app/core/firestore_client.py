# app/core/firestore_client.py
import os, json
from typing import Optional
from google.cloud import firestore
from google.oauth2 import service_account
from google.auth.exceptions import DefaultCredentialsError

def get_firestore_client() -> Optional[firestore.Client]:
    # If running against emulator
    if os.getenv("FIRESTORE_EMULATOR_HOST"):
        return firestore.Client(project=os.getenv("GOOGLE_CLOUD_PROJECT"))

    # Use inline JSON if provided
    key_json = os.getenv("GCP_SA_KEY_JSON")
    if key_json:
        info = json.loads(key_json)
        creds = service_account.Credentials.from_service_account_info(info)
        project = os.getenv("GOOGLE_CLOUD_PROJECT") or info.get("project_id")
        return firestore.Client(project=project, credentials=creds)

    # Fallback to ADC (GOOGLE_APPLICATION_CREDENTIALS or gcloud)
    try:
        return firestore.Client(project=os.getenv("GOOGLE_CLOUD_PROJECT") or None)
    except DefaultCredentialsError:
        return None
