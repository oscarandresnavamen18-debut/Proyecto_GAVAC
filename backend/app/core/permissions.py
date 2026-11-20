
"""Permisos por módulo de GAVAC."""

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
    UserRole.VETERINARIO: ("registro", "sanidad", "reproduccion"),
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

    valid_permissions = set(user.module_permissions)

    return [
        module
        for module in MODULES
        if module in valid_permissions
    ]


def has_module(user: User, module: str) -> bool:
    if module not in MODULES:
        return False

    return module in effective_permissions(user)
