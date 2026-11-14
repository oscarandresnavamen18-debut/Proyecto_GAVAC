# Contrato Oficial de la API REST - GAVAC

## Estado
**Implementado y Verificado** (FastAPI + PostgreSQL + Flutter).

---

## Convenciones y Estándares
- **Prefijo base**: `/api/v1`
- **Formato de datos**: JSON (`Content-Type: application/json`)
- **Autenticación**: Bearer Token JWT en cabecera `Authorization: Bearer <token>`
- **Formato de fechas**: `YYYY-MM-DD` (ISO 8601)
- **Aislamiento Multi-inquilino**: La información de cada finca está aislada por el `farm_id` / `finca_id` asociado al usuario autenticado (su **finca activa**).
- **Manejo de Red**:
  - Web: `http://localhost:8001`
  - Emulador Android: `http://10.0.2.2:8001`
  - Producción (Railway): `https://proyectogavac-production.up.railway.app`

---

## Roles y permisos

| Rol (`role`) | Nombre en la app | Cómo se crea |
|---|---|---|
| `ADMIN` | Administrador | Registro público (`POST /auth/register`) |
| `VETERINARIO` | Veterinario | El administrador, con `POST /users` |
| `MAYORDOMO` | Trabajador de campo | El administrador, con `POST /users` |

- **Módulos con permiso**: `registro`, `sanidad`, `reproduccion`, `produccion`, `insumos`, `reportes`.
- El administrador tiene todos los módulos y es el único que accede a la administración (fincas y usuarios).
- Si el administrador no configura permisos (`module_permissions = null`), se aplican los del rol:
  - Veterinario: `registro`, `sanidad`, `reproduccion`, `reportes`.
  - Trabajador de campo: `registro`, `produccion`, `insumos`.
- Un endpoint de un módulo no permitido responde **403** (`"No tienes permiso para el módulo de ..."`).
- Las cuentas desactivadas responden **403** al iniciar sesión y con un token vigente.

---

## Endpoint / Resumen de Rutas

### 1. Autenticación (`/api/v1/auth`)

#### `POST /api/v1/auth/register`
* **Descripción**: Registra al **administrador** de la finca.
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
    "token_type": "bearer",
    "role": "ADMIN"
  }
  ```

#### `POST /api/v1/auth/login`
* **Descripción**: Inicia sesión y devuelve un token JWT con vigencia de 60 minutos.
* **Cuerpo de Solicitud**:
  ```json
  {
    "email": "juan@finca.com",
    "password": "Password123!",
    "role": "ADMIN",
    "captcha_token": "opcional"
  }
  ```
  `role` es el tipo de usuario elegido en el login (`ADMIN`, `VETERINARIO` o `MAYORDOMO`). Es opcional por compatibilidad; si se envía y no coincide con la cuenta, responde **403**. La contraseña se valida primero (**401** si es incorrecta).
* **Respuesta Exitosa (200 OK)**: `access_token`, `token_type` y `role`.

#### `GET /api/v1/auth/me`
* **Descripción**: Obtiene la información del usuario en sesión, con su finca activa y sus módulos permitidos.
* **Respuesta Exitosa (200 OK)**:
  ```json
  {
    "id": 1,
    "email": "juan@finca.com",
    "full_name": "Juan Pérez",
    "role": "ADMIN",
    "is_active": true,
    "created_at": "2026-03-31T00:00:00",
    "farm_id": 1,
    "permissions": ["registro", "sanidad", "reproduccion", "produccion", "insumos", "reportes"]
  }
  ```

---

### 2. Usuarios (`/api/v1/users`) — solo administrador

#### `GET /api/v1/users`
* **Descripción**: Lista los veterinarios y trabajadores asignados a las fincas del administrador (formato de `GET /auth/me`).

#### `POST /api/v1/users`
* **Descripción**: Crea un veterinario o trabajador de campo en una finca del administrador.
* **Cuerpo de Solicitud**:
  ```json
  {
    "nombre": "Dra. Gómez",
    "email": "gomez@finca.com",
    "password": "Clave12345",
    "role": "VETERINARIO",
    "farm_id": 1,
    "permisos": ["registro", "sanidad"]
  }
  ```
  `role` solo admite `VETERINARIO` o `MAYORDOMO`. `permisos` es opcional (si se omite, aplican los del rol).
* **Errores**: 404 si la finca no es del administrador; 409 si el correo ya existe.

#### `PATCH /api/v1/users/{user_id}`
* **Descripción**: Actualiza `nombre`, `role`, `farm_id`, `permisos`, `is_active` o `password`. Cambiar la contraseña cierra las sesiones abiertas del usuario.

---

### 3. Fincas (`/api/v1/farms`)

#### `GET /api/v1/farms`
* **Descripción**: El administrador recibe todas sus fincas; los demás usuarios, la finca asignada.

#### `POST /api/v1/farms` — solo administrador
* **Descripción**: Crea una finca. La primera queda como finca activa.
* **Cuerpo de Solicitud**:
  ```json
  {
    "nombre": "Finca La Esperanza",
    "ubicacion": "Antioquia, Colombia"
  }
  ```
* **Respuesta Exitosa (201 Created)**: Objeto `FarmRead` (`id`, `name`, `location`, `owner_id`, `created_at`).

#### `PATCH /api/v1/farms/{farm_id}` — solo administrador
* **Descripción**: Actualiza `nombre` y `ubicacion` de una finca propia.

#### `POST /api/v1/farms/{farm_id}/activate` — solo administrador
* **Descripción**: Cambia la finca activa del administrador (la que usan el dashboard y los módulos).

#### `GET /api/v1/farms/{farm_id}/summary`
* **Descripción**: Resumen de animales activos por estado y total de eventos.
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

### Resumen del inicio (`GET /api/v1/dashboard`)
* **Descripción**: Indicadores de la finca activa para la página de inicio. Solo devuelve totales, por eso lo puede consultar cualquier usuario de la finca sin importar sus permisos por módulo. Si el usuario no tiene finca, todos los valores van en cero.
* **Respuesta (200 OK)**:
  ```json
  {
    "farm_id": 1,
    "farm_name": "La Esperanza",
    "total_animales": 3,
    "hembras": 2,
    "machos": 1,
    "peso_promedio_kg": 500.0,
    "animales_en_tratamiento": 1,
    "vacunas_por_vencer": 1,
    "vacunas_vencidas": 0,
    "vacas_gestantes": 1,
    "partos_proximos": 1,
    "leche_litros_30_dias": 40.0,
    "leche_promedio_ordeno": 20.0,
    "insumos_bajo_minimo": 1,
    "alertas": 2
  }
  ```
  - Las vacunas cuentan solo por su última aplicación (una vacuna renovada no genera alerta).
  - `vacas_gestantes`: hembras cuyo último evento reproductivo es una preñez; `partos_proximos`: de ellas, las que tienen parto estimado en los próximos 30 días.
  - Promedios de leche sobre los últimos 30 días. `alertas` = vacunas vencidas + por vencer + insumos bajo el mínimo.
  - Los animales eliminados no cuentan.

---

### 4. Animales (`/api/v1/animals`) — módulo `registro`

#### `GET /api/v1/animals`
* **Descripción**: Lista los animales de la finca (paginación con `skip` y `limit`). Disponible para cualquier usuario de la finca, porque los demás módulos lo necesitan.
* **`estado`**: `activos` (por defecto) = solo los que siguen en la finca; `todos` = incluye vendidos y muertos.
* Cada animal trae `status` (`ACTIVO`, `VENDIDO`, `MUERTO`) y `lote_id` (su potrero; `null` = sin potrero).

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
    "lote_id": 3
  }
  ```
* **Valores Permitidos**:
  - `gender`: `"MACHO"` | `"HEMBRA"`
  - `lote_id` es opcional: el potrero inicial. Queda registrado como primer movimiento.
  - El animal siempre se crea `ACTIVO`.
* **Respuesta Exitosa (201 Created)**: Objeto `AnimalRead`.

#### `PATCH /api/v1/animals/{animal_id}`
* **Descripción**: Actualiza `tag_id`, `breed`, `gender`, `birth_date`, `name`, `color` o `current_weight`. Responde 409 si la chapeta ya existe. El estado no se edita aquí: cambia al registrar una salida (sección 6). El potrero cambia con un movimiento.

#### `DELETE /api/v1/animals/{animal_id}`
* **Descripción**: Borrado lógico (204 No Content): el animal deja de listarse, pero se conserva su historial sanitario, reproductivo y de producción.

---

### Potreros (`/api/v1/lots`) y salidas (`/api/v1/exits`) — módulo `registro`

#### `GET /api/v1/lots` · `POST /api/v1/lots` · `PATCH /api/v1/lots/{lot_id}`
* Potreros de la finca activa con `animal_count` (animales activos que están hoy en él). `?incluir_inactivos=true` incluye los desactivados.
* Crear: `{"nombre": "Potrero Norte", "descripcion": "Pasto estrella", "area_hectareas": 4.5}` (409 si el nombre ya existe).
* Editar: `nombre`, `descripcion`, `area_hectareas`, `is_active`. Un potrero con animales no se puede desactivar (409).

#### `POST /api/v1/lots/move`
* Mueve uno o varios animales activos: `{"animal_ids": [1, 2], "lote_destino_id": 3, "fecha": "2026-11-14", "notas": "Rotación de pastos"}`. `lote_destino_id: null` = dejarlos sin potrero.
* La fecha no puede ser futura ni anterior al último movimiento del animal (422). Los que ya están en el destino no generan movimiento.
* Respuesta (201): los movimientos creados.

#### `GET /api/v1/lots/movements`
* Historial del más reciente al más antiguo, con `from_lot_name`, `to_lot_name`, `moved_at`, `notes` y `created_by_name`. Filtros opcionales `animal_id` y `lot_id`.

#### `POST /api/v1/exits`
* Registra la venta o la muerte: `{"animal_id": 1, "tipo": "VENTA", "fecha": "2026-11-14", "precio": 3500000, "comprador": "Subasta del Meta", "notas": "..."}`, o `{"animal_id": 1, "tipo": "MUERTE", "causa": "Picadura de serpiente"}` (la causa es obligatoria).
* El animal pasa a `VENDIDO` o `MUERTO`, sale de su potrero y del inventario activo, y conserva su historial. Ya no recibe registros de sanidad, reproducción, producción ni movimientos (422). Un animal con salida no acepta otra (409).

#### `GET /api/v1/exits` · `DELETE /api/v1/exits/{exit_id}`
* Lista las salidas (filtro `tipo`). Anular una salida registrada por error devuelve el animal a `ACTIVO` y a su potrero, si sigue activo.

---

### 5. Eventos Sanitarios y Pesajes (`/api/v1/animals/{animal_id}/events`) — módulo `sanidad`

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

### 6. Sanidad (`/api/v1/health-records`) — módulo `sanidad`

#### `GET /api/v1/health-records`
* **Descripción**: Vacunas y tratamientos de la finca, del más reciente al más antiguo.

#### `POST /api/v1/health-records`
* **Cuerpo de Solicitud**:
  ```json
  {
    "animal_id": 1,
    "record_type": "VACUNA",
    "diagnosis": "Aftosa",
    "treatment": null,
    "dose": "2 ml",
    "veterinarian": "Dra. Gómez",
    "recorded_at": "2026-11-14",
    "next_check_at": "2027-05-14",
    "notes": "Ciclo semestral"
  }
  ```
  - `record_type`: `"VACUNA"` | `"TRATAMIENTO"`. `diagnosis` es el nombre de la vacuna o el diagnóstico; `treatment`, el medicamento.
  - `next_check_at` es la próxima dosis (vacunas) o el fin del seguimiento (tratamientos); no puede ser anterior a `recorded_at`.
  - Si se omite `veterinarian`, se guarda el nombre de quien registra.
* **Respuesta (201 Created)**: el registro con `animal_tag`, `animal_name` y `status`: `VIGENTE`, `PROXIMO_A_VENCER` (15 días o menos), `VENCIDO`, `EN_TRATAMIENTO` o `FINALIZADO`.

#### `DELETE /api/v1/health-records/{record_id}`
* **Descripción**: Elimina un registro sanitario (204 No Content).

---

### 7. Reproducción (`/api/v1/breeding-records`) — módulo `reproduccion`

#### `GET /api/v1/breeding-records`
* **Descripción**: Eventos reproductivos de la finca, del más reciente al más antiguo.

#### `POST /api/v1/breeding-records`
* **Cuerpo de Solicitud**:
  ```json
  {
    "animal_id": 1,
    "record_type": "PRENEZ",
    "recorded_at": "2026-09-01",
    "expected_at": null,
    "notes": "Toro 102"
  }
  ```
  - `record_type`: `"CELO"` | `"INSEMINACION"` | `"PRENEZ"` | `"PARTO"`.
  - Solo para hembras (422 en machos) y sin fechas futuras.
  - En `PRENEZ`, si se omite `expected_at` se calcula el parto a 283 días.
* **Respuesta (201 Created)**: el registro con `animal_tag`, `expected_at` y `status` descriptivo (por ejemplo, `"Gestante, parto en 209 días"`).

#### `DELETE /api/v1/breeding-records/{record_id}`
* **Descripción**: Elimina un evento reproductivo (204 No Content).

---

### 8. Producción (`/api/v1/production`) — módulo `produccion`

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

### 9. Inventario (`/api/v1/inventory`) — módulo `insumos`

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

---

### 10. Reportes (`/api/v1/reports`) — módulo `reportes`

#### `GET /api/v1/reports/{reporte}?formato=pdf|xlsx`
* **Descripción**: Descarga un archivo (no JSON) con los datos de la finca activa.
* **`reporte`**:
  - `animales`, `potreros`, `salidas`, `sanidad`, `reproduccion`, `produccion`, `insumos`: todas las columnas del módulo e indicadores de resumen. Además del permiso `reportes`, requiere el permiso del módulo.
  - `general`: resumen de la finca. El PDF trae una portada con los indicadores y una sección por módulo; el Excel, una hoja `Resumen` y una hoja por módulo. Solo incluye los módulos que el usuario tiene habilitados.
* **Respuesta (200 OK)**: `application/pdf` o `application/vnd.openxmlformats-officedocument.spreadsheetml.sheet`, con `Content-Disposition: attachment; filename="gavac_<reporte>_<fecha>.<formato>"`.
