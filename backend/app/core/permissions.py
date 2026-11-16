
"""Permisos por módulo de GAVAC.

El administrador tiene acceso total. Para veterinarios y trabajadores de campo
(rol MAYORDOMO), el administrador elige los módulos habilitados. Si nunca los ha
configurado (columna en NULL), se aplican los permisos por defecto del rol.
"""

from app.models import User, UserRole

MODULES: tuple[str, ...] = (
    "registro",
    "sanidad",
    "reproduccion",
    "produccion",
    "insumos",
    "reportes",
)

DEFAULT_PERMISSIONS: dict[UserRole, tuple[str, ...]] = {
    UserRole.ADMIN: MODULES,
    UserRole.VETERINARIO: ("registro", "sanidad", "reproduccion", "reportes"),
    UserRole.MAYORDOMO: ("registro", "produccion", "insumos"),
}


def effective_permissions(user: User) -> list[str]:
    if user.role == UserRole.ADMIN:
        return list(MODULES)

    default_permissions = DEFAULT_PERMISSIONS.get(user.role, ())

    if user.module_permissions is None:
        return list(default_permissions)

    if not isinstance(user.module_permissions, (list, tuple, set)):
        return list(default_permissions)

    return [
        module
        for module in MODULES
        if module in user.module_permissions
    ]


def has_module(user: User, module: str) -> bool:
    if module not in MODULES:
        return False

    return module in effective_permissions(user)
