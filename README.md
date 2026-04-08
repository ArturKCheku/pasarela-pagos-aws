PASARELA DE PAGOS HIBRIDA (AWS + FastAPI)

Este proyecto implementa una infraestructura de red segura en Amazon Web Services (AWS) gestionada mediante Terraform, diseñada específicamente para alojar una API de pagos (Simulación de Bizum) 
en un entorno aislado y protegido.

ARQUITECTURA DE RED

La infraestructura se basa en una arquitectura de VPC (Virtual Private Cloud) con las siguientes capas:

  - Subred Pública: Aloja un servidor VPN (WireGuard) que actúa como puente seguro.

  - Subred Privada: Aloja el Backend de Pagos (FastAPI), totalmente aislado de internet.

  - Conectividad: * Internet Gateway: Para la salida a internet de la zona pública.

      - NAT Gateway: Permite que la instancia privada descargue actualizaciones sin ser accesible desde el exterior.

      - Seguridad: Grupos de seguridad (Firewalls) configurados con el principio de mínimo privilegio.

TECNOLOGIAS USADAS

  - Infraestructura: Terraform (IaC)

  - Cloud: AWS (EC2, VPC, NAT Gateway, EIP)

  - Seguridad: WireGuard VPN

  - Backend: FastAPI (Python 3.10+)

  - Validación de Datos: Pydantic
    
CONFIGURACION Y DESPLIEGUE

1. Despliegue de Infraestructura

Desde la carpeta raíz, inicializa y aplica los planos de Terraform:
Bash

    terraform init
    terraform plan
    terraform apply

Nota: Asegúrate de tener tus credenciales de AWS configuradas y la llave pública SSH en ~/.ssh/clave_vpn_upv.pub.

2. Acceso vía VPN
   
Configura tu cliente WireGuard local usando la IP pública generada por el output de Terraform para establecer el túnel cifrado hacia la red 10.0.0.0/16.

3. Ejecución de la API

Una vez dentro de la instancia privada (10.0.2.209):
Bash

    cd api-bizum-pagos
    source venv/bin/activate
    uvicorn main:app --host 0.0.0.0 --port 8000

API DE PAGOS (SIMULACION)

La API cuenta con documentación automática generada por Swagger. Una vez conectado a la VPN, puedes acceder en: http://10.0.2.209:8000/docs.
Endpoint Principal: POST /pagar

Cuerpo de la petición (JSON):
JSON
{
  "telefono": "600123456",
  "importe": 20.50,
  "concepto": "Cena de anoche"
}

PROXIMAS MEJORAS

  - Implementar persistencia de datos con PostgreSQL.

  - Integración real con Webhooks de pasarelas de pago (Redsys).

  - Implementar autenticación mediante JWT (JSON Web Tokens).

Autor: ArturKCheku

Proyecto: Prácticas de Infraestructura Cloud y Seguridad.
