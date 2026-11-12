# Contrato Oficial de la API REST - GAVAC

## Estado
**Implementado y Verificado** (FastAPI + PostgreSQL + Flutter).

---

## Convenciones y Estándares
- **Prefijo base**: `/api/v1`
- **Formato de datos**: JSON (`Content-Type: application/json`)
- **Autenticación**: Bearer Token JWT en cabecera `Authorization: Bearer <token>`
- **Formato de fechas**: `YYYY-MM-DD` (ISO 8601)
- **Aislamiento Multi-inquilino**: La información de cada finca está aislada por el `farm_id` / `finca_id` asociado al usuario autenticado.
- **Manejo de Red**:
  - Web: `http://localhost:8001`
  - Emulador Android: `http://10.0.2.2:8001`
  - Producción (Railway): `https://proyectogestionganadera-production.up.railway.app`

---

## Endpoint / Resumen de Rutas

### 1. Autenticación y Usuarios (`/api/v1/auth`)

#### `POST /api/v1/auth/register`
* **Descripción**: Registra un nuevo usuario en la plataforma.
* **Cuerpo de Solicitud**:
  ```json
  {
    "nombre": "Juan Pérez",
    "email": "juan@finca.com",
    "password": "Password123!"
  }
  ```
* **Respuesta Exitosa (201 Created)**:
  ```json
  {
    "access_token": "eyJhbGciOi...",
    "token_type": "bearer"
  }
  ```

#### `POST /api/v1/auth/login`
* **Descripción**: Inicia sesión y devuelve un token JWT con vigencia de 60 minutos.
* **Cuerpo de Solicitud**:
  ```json
  {
    "email": "juan@finca.com",
    "password": "Password123!",
    "captcha_token": "opcional"
  }
  ```
* **Respuesta Exitosa (200 OK)**: Token JWT de acceso.

#### `GET /api/v1/auth/me`
* **Descripción**: Obtiene la información del usuario en sesión.
* **Respuesta Exitosa (200 OK)**:
  ```json
  {
    "id": 1,
    "email": "juan@finca.com",
    "full_name": "Juan Pérez",
    "role": "MAYORDOMO",
    "is_active": true,
    "created_at": "2026-03-31T00:00:00"
  }
  ```

---

### 2. Fincas (`/api/v1/farms`)

#### `GET /api/v1/farms`
* **Descripción**: Lista las fincas asociadas al usuario autenticado.

#### `POST /api/v1/farms`
* **Descripción**: Crea una nueva finca.
* **Cuerpo de Solicitud**:
  ```json
  {
    "nombre": "Finca La Esperanza",
    "ubicacion": "Antioquia, Colombia"
  }
  ```
* **Respuesta Exitosa (201 Created)**: Objeto `FarmRead` creado (`id`, `name`, `location`, `owner_id`, `created_at`).

#### `GET /api/v1/farms/{farm_id}/summary`
* **Descripción**: Devuelve un resumen estadístico de inventario ganadero y eventos sanitarios.
* **Respuesta Exitosa (200 OK)**:
  ```json
  {
    "farm_id": 1,
    "total_animales": 25,
    "por_estado": {
      "ACTIVO": 20,
      "VENDIDO": 5
    },
    "total_eventos": 12
  }
  ```

---

### 3. Animales (`/api/v1/animals`)

#### `GET /api/v1/animals`
* **Descripción**: Lista los animales pertenecientes a la finca del usuario autorizada (Soporta paginación con `skip` y `limit`).

#### `POST /api/v1/animals`
* **Descripción**: Registra un nuevo animal en la finca.
* **Cuerpo de Solicitud**:
  ```json
  {
    "farm_id": 1,
    "tag_id": "CO-101",
    "name": "Mariposa",
    "gender": "HEMBRA",
    "birth_date": "2023-05-10",
    "breed": "Holstein",
    "color": "Blanco y Negro",
    "current_weight": 450.0,
    "status": "ACTIVO"
  }
  ```
* **Valores Permitidos**:
  - `gender`: `"MACHO"` | `"HEMBRA"`
  - `status`: `"ACTIVO"` | `"VENDIDO"` | `"MUERTO"` | `"TRASLADADO"`
* **Respuesta Exitosa (201 Created)**: Objeto `AnimalRead`.

#### `PATCH /api/v1/animals/{animal_id}`
* **Descripción**: Actualiza campos específicos de un animal (nombre, color, peso actual o estado).

#### `DELETE /api/v1/animals/{animal_id}`
* **Descripción**: Elimina un animal de la finca (204 No Content).

---

### 4. Eventos Sanitarios y Pesajes (`/api/v1/animals/{animal_id}/events`)

#### `GET /api/v1/animals/{animal_id}/events`
* **Descripción**: Consulta el historial de eventos sanitarios y pesajes de un animal.

#### `POST /api/v1/animals/{animal_id}/events`
* **Descripción**: Registra un evento sanitario o pesaje.
* **Cuerpo de Solicitud**:
  ```json
  {
    "event_type": "VACUNACION",
    "event_date": "2026-03-31",
    "weight": 455.0,
    "description": "Vacuna Fiebre Aftosa Dosis 1",
    "withdrawal_days": 0
  }
  ```
* **Valores Permitidos para `event_type`**:
  - `"VACUNACION"`, `"DESPARASITACION"`, `"PESAJE"`, `"TRATAMIENTO"`
* **Respuesta Exitosa (201 Created)**: Objeto `EventRead`.

---

### 5. Producción (`/api/v1/production`)

#### `GET /api/v1/production`
* **Descripción**: Lista las mediciones de producción de los animales de la finca del usuario autenticado, de la más reciente a la más antigua.

#### `POST /api/v1/production`
* **Descripción**: Registra litros de leche, peso o ambas mediciones en una sola operación. Cada medición se asocia a un animal autorizado y se guarda en la base de datos.
* **Cuerpo de Solicitud**:
  ```json
  {
    "animal_id": 1,
    "milk_liters": 18.5,
    "weight_kg": 420,
    "recorded_at": "2026-11-10T12:00:00Z"
  }
  ```
  `milk_liters` y `weight_kg` son opcionales, pero se debe enviar al menos uno. `recorded_at` es opcional; por defecto se usa la fecha y hora UTC actuales.
* **Respuesta Exitosa (201 Created)**: Lista de mediciones creadas. Los litros se guardan como `MILK` en `L`; el peso como `WEIGHT` en `kg`.

#### `DELETE /api/v1/production/{record_id}`
* **Descripción**: Elimina una medición de producción de la finca autorizada (204 No Content).

---

### 6. Inventario (`/api/v1/inventory`)

#### `GET /api/v1/inventory`
* **Descripción**: Lista los insumos activos de la finca autenticada e incluye el saldo actual calculado a partir de sus movimientos.

#### `POST /api/v1/inventory`
* **Descripción**: Registra un insumo y su saldo inicial en una transacción.
* **Cuerpo de Solicitud**:
  ```json
  {
    "name": "Sal mineral",
    "category": "GENERAL",
    "unit": "unidades",
    "quantity": 12,
    "minimum_quantity": 0
  }
  ```
  `category`, `unit` y `minimum_quantity` tienen valores predeterminados si se omiten.
* **Respuesta Exitosa (201 Created)**: Objeto con los datos del insumo y `quantity` correspondiente al saldo actual.

#### `DELETE /api/v1/inventory/{item_id}`
* **Descripción**: Retira el insumo del inventario activo sin borrar su historial de movimientos (204 No Content).
