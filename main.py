from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field

app = FastAPI(title="Pasarela de Pagos Bizum-Sim")

# Definimos cómo debe ser un pago de Bizum
class PagoBizum(BaseModel):
    telefono: str = Field(..., pattern=r"^\+?[1-9]\d{1,14}$", example="600123456")
    importe: float = Field(..., gt=0, le=500) # Máximo 500€ por Bizum
    concepto: str = Field(default="Pago App", max_length=35)

@app.get("/")
def index():
    return {"mensaje": "Servidor de Pagos Privado - UPV Cloud"}

@app.post("/pagar")
async def crear_pago(pago: PagoBizum):
    # Aquí es donde en el futuro conectarías con la API del banco
    # Por ahora, simulamos una respuesta exitosa
    return {
        "id_transaccion": "BZ-789456123",
        "estado": "ACEPTADO",
        "detalle": f"Bizum enviado a {pago.telefono} por {pago.importe}€",
        "concepto": pago.concepto
    }
