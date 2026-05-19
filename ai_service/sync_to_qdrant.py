"""
sync_to_qdrant.py — Firestore → CLIP → Qdrant Synchronization Script

Reads all products from the Firebase Firestore 'products' collection,
generates CLIP vector embeddings for each product image, and upserts
them into a Qdrant collection.

Prerequisites:
  1. Place your Firebase Admin SDK key at: ai_service/serviceAccountKey.json
  2. Fill in ai_service/.env with QDRANT_URL and QDRANT_API_KEY
  3. pip install -r requirements.txt firebase-admin python-dotenv requests
"""

import os
import io
import time
import requests

from dotenv import load_dotenv
from PIL import Image
from sentence_transformers import SentenceTransformer
from qdrant_client import QdrantClient
from qdrant_client.models import VectorParams, Distance, PointStruct

import firebase_admin
from firebase_admin import credentials, firestore

# ── Configuration ──
load_dotenv()

QDRANT_URL = os.getenv("QDRANT_URL")
QDRANT_API_KEY = os.getenv("QDRANT_API_KEY")
COLLECTION_NAME = "products"
VECTOR_SIZE = 512  # CLIP ViT-B-32 output dimension
BATCH_SIZE = 50    # Number of products to process per Firestore batch

SERVICE_ACCOUNT_PATH = os.path.join(os.path.dirname(__file__), "serviceAccountKey.json")


def init_firebase():
    """Initialize Firebase Admin SDK."""
    if not os.path.exists(SERVICE_ACCOUNT_PATH):
        raise FileNotFoundError(
            f"Firebase service account key not found at: {SERVICE_ACCOUNT_PATH}\n"
            "Please download it from Firebase Console → Project Settings → Service Accounts."
        )
    cred = credentials.Certificate(SERVICE_ACCOUNT_PATH)
    firebase_admin.initialize_app(cred)
    print("✅ Firebase Admin initialized.")
    return firestore.client()


def init_qdrant():
    """Initialize Qdrant client and ensure the collection exists."""
    client = QdrantClient(url=QDRANT_URL, api_key=QDRANT_API_KEY)

    # Check if collection exists, create if not
    existing = [c.name for c in client.get_collections().collections]

    if COLLECTION_NAME not in existing:
        client.create_collection(
            collection_name=COLLECTION_NAME,
            vectors_config=VectorParams(
                size=VECTOR_SIZE,
                distance=Distance.COSINE,
            ),
        )
        print(f"✅ Created Qdrant collection: '{COLLECTION_NAME}' ({VECTOR_SIZE}d, cosine)")
    else:
        print(f"✅ Qdrant collection '{COLLECTION_NAME}' already exists.")

    return client


def get_image_from_url(url: str) -> Image.Image | None:
    """Download an image from a URL and return a PIL Image."""
    try:
        response = requests.get(url, timeout=15)
        response.raise_for_status()
        return Image.open(io.BytesIO(response.content)).convert("RGB")
    except Exception as e:
        print(f"  ⚠️ Failed to download image: {e}")
        return None


def extract_image_url(product: dict) -> str | None:
    """Extract the best available image URL from a product document."""
    # Direct 'image' field
    if product.get("image"):
        return product["image"]

    # First item from 'images' array (skip videos)
    images = product.get("images", [])
    for img in images:
        if isinstance(img, str) and not img.endswith((".mp4", ".mov", ".avi")):
            return img

    return None


def sync():
    """Main sync pipeline: Firestore → CLIP → Qdrant."""
    print("=" * 60)
    print("  Zink Visual Search — Firestore → Qdrant Sync")
    print("=" * 60)

    # 1. Initialize services
    db = init_firebase()
    qdrant = init_qdrant()

    print("Loading CLIP model...")
    model = SentenceTransformer('sentence-transformers/clip-ViT-B-32')
    print("✅ CLIP model loaded.\n")

    # 2. Fetch all products from Firestore (paginated)
    products_ref = db.collection("products")
    all_docs = []

    print("Fetching products from Firestore...")
    query = products_ref.limit(BATCH_SIZE)
    last_doc = None
    batch_num = 0

    while True:
        batch_num += 1
        if last_doc:
            query = products_ref.start_after(last_doc).limit(BATCH_SIZE)

        docs = list(query.stream())
        if not docs:
            break

        all_docs.extend(docs)
        last_doc = docs[-1]
        print(f"  Batch {batch_num}: fetched {len(docs)} products (total: {len(all_docs)})")

    print(f"✅ Total products fetched: {len(all_docs)}\n")

    if not all_docs:
        print("No products found in Firestore. Nothing to sync.")
        return

    # 3. Process each product: download image → embed → prepare point
    points = []
    skipped = 0
    start_time = time.time()

    for i, doc in enumerate(all_docs):
        product = doc.to_dict()
        product_id = doc.id
        product_name = product.get("name", "Unknown")

        image_url = extract_image_url(product)
        if not image_url:
            print(f"  [{i+1}/{len(all_docs)}] ⏭️ {product_name} — no image, skipping")
            skipped += 1
            continue

        pil_image = get_image_from_url(image_url)
        if pil_image is None:
            skipped += 1
            continue

        # Generate embedding
        vector = model.encode(pil_image).tolist()

        # Build Qdrant point
        point = PointStruct(
            id=i,  # Sequential integer ID for Qdrant
            vector=vector,
            payload={
                "product_id": product_id,
                "name": product_name,
                "category": product.get("category", ""),
                "price": product.get("price", product.get("basePrice", 0)),
                "image_url": image_url,
            },
        )
        points.append(point)
        print(f"  [{i+1}/{len(all_docs)}] ✅ {product_name}")

    elapsed = round(time.time() - start_time, 1)
    print(f"\n✅ Embedding complete: {len(points)} vectors in {elapsed}s (skipped: {skipped})\n")

    # 4. Upsert to Qdrant in batches
    if not points:
        print("No vectors to upsert.")
        return

    print(f"Upserting {len(points)} vectors to Qdrant...")
    for batch_start in range(0, len(points), BATCH_SIZE):
        batch = points[batch_start:batch_start + BATCH_SIZE]
        qdrant.upsert(collection_name=COLLECTION_NAME, points=batch)
        print(f"  Batch {batch_start // BATCH_SIZE + 1}: upserted {len(batch)} points")

    print(f"\n{'=' * 60}")
    print(f"  ✅ SYNC COMPLETE")
    print(f"  Products indexed: {len(points)}")
    print(f"  Collection: {COLLECTION_NAME}")
    print(f"  Vector dimension: {VECTOR_SIZE}")
    print(f"{'=' * 60}")


if __name__ == "__main__":
    sync()
