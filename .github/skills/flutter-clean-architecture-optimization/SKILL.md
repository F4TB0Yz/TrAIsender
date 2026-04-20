---
name: flutter-clean-architecture-optimization
description: 'Implementa y revisa buenas practicas de codigo en Flutter con Arquitectura Limpia y optimizacion de rendimiento. Usar para refactorizar features, prevenir deuda tecnica, mejorar testabilidad, reducir jank, y bajar uso de memoria/CPU en apps Flutter.'
argument-hint: 'Feature, modulo o pantalla a mejorar (ej. auth/login, home feed, checkout)'
user-invocable: true
---

# Flutter Clean Architecture + Optimization

Skill para disenar, refactorizar y validar codigo Flutter con foco en:
- Arquitectura Limpia (Domain, Application, Infrastructure, Presentation)
- Calidad de codigo (legibilidad, cohesion, testabilidad)
- Performance real en runtime (frames, rebuilds, memoria, I/O)

## Cuando usar
- Al crear una feature nueva y quieres base solida.
- Al refactorizar una feature con acoplamiento alto.
- Al investigar pantallas lentas, stutter o battery drain.
- Al preparar una release y cerrar deuda tecnica critica.

## Resultado esperado
- Limites de capas claros y dependencias correctas.
- Casos de uso centrados en dominio, sin logica de negocio en UI.
- Estado predecible y facil de testear.
- Menos rebuilds innecesarios, menor trabajo en hilo principal, I/O controlado.

## Flujo de trabajo

1. Delimitar alcance y metricas
- Identificar la feature/pantalla exacta y sus limites.
- Definir objetivos medibles antes de cambiar codigo.
- Baseline recomendado:
  - Tiempo de arranque (cold start)
  - FPS y dropped frames en interacciones clave
  - Rebuild frequency en widgets criticos
  - Uso de memoria y garbage collection spikes

2. Mapear arquitectura actual
- Listar modulos implicados: UI, estado, casos de uso, repositorios, data sources.
- Detectar violaciones de capa:
  - Presentation importando infraestructura directamente
  - Domain dependiendo de Flutter/Dart IO concreto
  - Reglas de negocio en widgets o controllers de UI

3. Aplicar reglas de Arquitectura Limpia
- Domain:
  - Entidades inmutables y orientadas a reglas de negocio.
  - Casos de uso pequenos y con una intencion clara.
  - Sin dependencias de framework.
- Application (si existe separada):
  - Orquestacion de casos de uso.
  - Traduccion de eventos de UI a acciones de dominio.
- Infrastructure:
  - Implementaciones de repositorios, APIs, DB, filesystem.
  - Mappers DTO <-> entidades.
  - Manejo de errores de transporte con conversion a fallos de dominio.
- Presentation:
  - Widgets puros y estado observable.
  - No se pueden devolver widgets dentro de funciones.
  - Sin reglas de negocio complejas.

4. Decisiones clave (branching)
- Si la feature es simple y estable:
  - Preferir minima abstraccion (evitar sobreingenieria).
- Si hay multiples fuentes de datos, reglas cambiantes, o alta complejidad:
  - Formalizar interfaces de repositorio y casos de uso dedicados.
- Si el estado es efimero de UI:
  - Mantener local (controller/viewmodel scoped).
- Si el estado afecta varias pantallas o flujos largos:
  - Elevar a capa de aplicacion con ciclo de vida claro.

5. Optimizacion de Flutter (orden recomendado)
- Medir primero en modo profile.
- Reducir trabajo por frame:
  - Evitar computo pesado en build.
  - Mover trabajo costoso a isolate/compute cuando aplique.
- Reducir rebuilds:
  - Partir widgets grandes en subwidgets pequenos.
  - Usar selectores granulares y keys correctas.
  - Marcar const donde sea posible.
- Render y listas:
  - Preferir constructores lazy (ListView.builder, SliverList).
  - Evitar layouts intrinsecos caros en listas largas.
- Imagenes y assets:
  - Ajustar tamanos de decode a resolucion objetivo.
  - Cachear con limites razonables segun dispositivo.
- I/O y red:
  - Debounce/throttle en eventos de alta frecuencia.
  - Batch de operaciones cuando sea viable.

6. Calidad y pruebas
- Longitud archivo: 
  - Idealmente < 300 lineas, max 500 con justificacion.
- Unit tests:
  - Casos de uso de dominio.
  - Mappers y reglas de transformacion.
- Widget tests:
  - Estados criticos y rendering condicional.
- Integration tests (flujos principales):
  - Happy path y errores relevantes.
- Regresion de performance:
  - Repetir baseline y comparar contra objetivos.

7. Checklist de finalizacion
- No hay imports que rompan la direccion de dependencias.
- El dominio no conoce framework UI ni detalles de transporte.
- Errores tecnicos no se filtran sin traducir a capa superior.
- Cobertura de pruebas en rutas criticas del cambio.
- Metricas de performance iguales o mejores que baseline.
- Sin warnings nuevos de analisis estatico relevantes.

## Criterios de calidad
- Claridad: cada archivo tiene una responsabilidad principal.
- Cohesion: codigo relacionado permanece junto.
- Acoplamiento: dependencias minimas y explicitas.
- Testabilidad: reglas de negocio verificables sin UI.
- Rendimiento: mejoras verificadas con medicion, no suposiciones.

## Prompt de activacion sugerido
- "/flutter-clean-architecture-optimization optimiza la pantalla de historial y separa reglas de negocio en casos de uso"
- "/flutter-clean-architecture-optimization revisa la feature de grabacion para reducir rebuilds y aislar infraestructura"
- "/flutter-clean-architecture-optimization refactoriza auth con arquitectura limpia y agrega plan de pruebas"
