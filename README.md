QueueGo

Sistema de coordinación y gestión de domicilios por roles.

QueueGo busca digitalizar la coordinación de restaurantes, clientes, repartidores y central de operaciones, reduciendo la dependencia de comunicación manual y proporcionando trazabilidad sobre pedidos y entregas.

Tecnologías

 Flutter / Dart
 Supabase Auth
 Supabase PostgreSQL
 Supabase RLS
 Supabase Realtime
 Riverpod
 Geolocator
 Flutter Web

Roles

 Cliente
 Restaurante
 Repartidor
 Central

Funcionalidades actuales

 Inicio de sesión con Supabase Auth.
 Creación automática del perfil mediante trigger.
 Identificación del rol del usuario.
 Dashboards independientes por rol.
 Consulta de restaurantes desde Supabase.
 Diseño responsive inicial.

Funcionalidades en desarrollo

 Catálogo de productos.
 Carrito.
 Creación y seguimiento de pedidos.
 Gestión de pedidos del restaurante.
 Asignación de entregas.
 GPS del repartidor.
 Seguimiento en tiempo real.
 Mapa.
 Reportes e indicadores.
 Tema visual definitivo.

 Arquitectura


screens -> repositories (interfaces) -> services (implementaciones)



Los modelos se mantienen separados de la lógica de acceso a datos.

Configuración

Crear un archivo `.env` en la raíz:

SUPABASE_URL=tu_url
SUPABASE_PUBLISHABLE_KEY=tu_publishable_key

No publicar el `.env` real en GitHub.

El repositorio debe incluir un `.env.example` sin valores sensibles.

Ejecución


flutter pub get
flutter run -d chrome


Para validar el proyecto:

flutter analyze

Supabase

El proyecto utiliza las tablas:


profiles
restaurants
products
orders
order_items
deliveries


RLS debe mantenerse habilitado y las políticas deben limitar el acceso según el rol y/o usuario correspondiente.

SOLID aplicado

**SRP:** separación entre modelos, repositorios, servicios, pantallas y dashboards.
**OCP:** roles y módulos separados para facilitar extensión.
**DIP:** la UI trabaja contra `AuthRepository` y `RestaurantRepository`.
**ISP:** interfaces pequeñas y específicas.
**LSP:** no se fuerza una jerarquía de herencia donde no existe una necesidad real.

Segunda entrega

La segunda entrega realiza una revisión crítica de la implementación inicial y registra los cambios en `docs/control_cambios.md`.

Cambios principales:

1. Separación de responsabilidades.
2. Sustitución de autenticación local de demostración por Supabase Auth.
3. Modelado de roles mediante `UserRole`.
4. Separación de dashboards.
5. Abstracción del acceso a datos mediante repositorios.
6. Implementación concreta de servicios Supabase.

Documentación

docs/
├── informe_solid_antipatrones.md
├── control_cambios.md
├── arquitectura.md
├── uml_clases_actualizado.puml
├── uml_clases_actualizado.png
└── uml_casos_uso.puml


Declaración de uso de IA

Durante el desarrollo se utilizamos inteligencia artificial como apoyo técnico para analizar código, identificar oportunidades de refactorización, proponer estructuras, resolver errores y apoyar la documentación.

Las decisiones finales de diseño, integración, pruebas y adaptación del código son responsabilidad del equipo. El equipo debe comprender y poder sustentar cada cambio realizado.
