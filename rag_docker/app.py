"""
RAG API - Retrieval-Augmented Generation Service
344Mehmet LLM Ordusu için Docker tabanlı RAG sistemi
"""

import os
import httpx
from fastapi import FastAPI, HTTPException, UploadFile, File
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Optional
from qdrant_client import QdrantClient
from qdrant_client.models import Distance, VectorParams, PointStruct
from sentence_transformers import SentenceTransformer
import uuid

# Environment variables
OLLAMA_HOST = os.getenv("OLLAMA_HOST", "http://localhost:11434")
QDRANT_HOST = os.getenv("QDRANT_HOST", "localhost")
QDRANT_PORT = int(os.getenv("QDRANT_PORT", "6333"))
EMBEDDING_MODEL = os.getenv("EMBEDDING_MODEL", "all-MiniLM-L6-v2")
LLM_MODEL = os.getenv("LLM_MODEL", "phi3:mini")
COLLECTION_NAME = "documents"

# Initialize FastAPI
app = FastAPI(
    title="RAG API",
    description="344Mehmet LLM Ordusu RAG Servisi",
    version="1.0.0"
)

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Initialize clients
qdrant = None
embedder = None

@app.on_event("startup")
async def startup():
    global qdrant, embedder
    
    # Connect to Qdrant
    qdrant = QdrantClient(host=QDRANT_HOST, port=QDRANT_PORT)
    
    # Load embedding model
    embedder = SentenceTransformer(EMBEDDING_MODEL)
    
    # Create collection if not exists
    collections = qdrant.get_collections().collections
    if COLLECTION_NAME not in [c.name for c in collections]:
        qdrant.create_collection(
            collection_name=COLLECTION_NAME,
            vectors_config=VectorParams(
                size=embedder.get_sentence_embedding_dimension(),
                distance=Distance.COSINE
            )
        )
    print(f"✅ RAG API başlatıldı - Qdrant: {QDRANT_HOST}:{QDRANT_PORT}")

# Models
class IngestRequest(BaseModel):
    text: str
    metadata: Optional[dict] = {}

class IngestBatchRequest(BaseModel):
    documents: List[IngestRequest]

class QueryRequest(BaseModel):
    query: str
    top_k: int = 3
    use_llm: bool = True

class QueryResponse(BaseModel):
    query: str
    contexts: List[dict]
    answer: Optional[str] = None

# Endpoints
@app.get("/health")
async def health():
    return {"status": "healthy", "model": LLM_MODEL}

@app.get("/collections")
async def get_collections():
    """Tüm koleksiyonları listele"""
    collections = qdrant.get_collections().collections
    return {"collections": [c.name for c in collections]}

@app.post("/ingest")
async def ingest_document(request: IngestRequest):
    """Tek bir dokümanı vektör veritabanına ekle"""
    try:
        # Generate embedding
        embedding = embedder.encode(request.text).tolist()
        
        # Create point
        point_id = str(uuid.uuid4())
        qdrant.upsert(
            collection_name=COLLECTION_NAME,
            points=[
                PointStruct(
                    id=point_id,
                    vector=embedding,
                    payload={"text": request.text, **request.metadata}
                )
            ]
        )
        
        return {"success": True, "id": point_id, "message": "Doküman eklendi"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/ingest/batch")
async def ingest_batch(request: IngestBatchRequest):
    """Birden fazla dokümanı toplu ekle"""
    try:
        points = []
        for doc in request.documents:
            embedding = embedder.encode(doc.text).tolist()
            point_id = str(uuid.uuid4())
            points.append(
                PointStruct(
                    id=point_id,
                    vector=embedding,
                    payload={"text": doc.text, **doc.metadata}
                )
            )
        
        qdrant.upsert(collection_name=COLLECTION_NAME, points=points)
        return {"success": True, "count": len(points), "message": f"{len(points)} doküman eklendi"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/query", response_model=QueryResponse)
async def query_documents(request: QueryRequest):
    """RAG sorgusu yap"""
    try:
        # Generate query embedding
        query_embedding = embedder.encode(request.query).tolist()
        
        # Search in Qdrant
        results = qdrant.search(
            collection_name=COLLECTION_NAME,
            query_vector=query_embedding,
            limit=request.top_k
        )
        
        # Extract contexts
        contexts = [
            {
                "text": hit.payload.get("text", ""),
                "score": hit.score,
                "metadata": {k: v for k, v in hit.payload.items() if k != "text"}
            }
            for hit in results
        ]
        
        answer = None
        if request.use_llm and contexts:
            # Build context string
            context_str = "\n\n".join([f"[{i+1}] {c['text']}" for i, c in enumerate(contexts)])
            
            # Call Ollama for generation
            prompt = f"""Aşağıdaki bağlam bilgilerini kullanarak soruyu cevapla.

BAĞLAM:
{context_str}

SORU: {request.query}

CEVAP:"""
            
            async with httpx.AsyncClient(timeout=60.0) as client:
                response = await client.post(
                    f"{OLLAMA_HOST}/api/generate",
                    json={
                        "model": LLM_MODEL,
                        "prompt": prompt,
                        "stream": False
                    }
                )
                if response.status_code == 200:
                    answer = response.json().get("response", "")
        
        return QueryResponse(
            query=request.query,
            contexts=contexts,
            answer=answer
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.delete("/collection/{name}")
async def delete_collection(name: str):
    """Koleksiyonu sil"""
    try:
        qdrant.delete_collection(collection_name=name)
        return {"success": True, "message": f"'{name}' koleksiyonu silindi"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/stats")
async def get_stats():
    """Koleksiyon istatistiklerini getir"""
    try:
        info = qdrant.get_collection(COLLECTION_NAME)
        return {
            "collection": COLLECTION_NAME,
            "vectors_count": info.vectors_count,
            "points_count": info.points_count,
            "status": info.status
        }
    except Exception as e:
        return {"error": str(e)}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
