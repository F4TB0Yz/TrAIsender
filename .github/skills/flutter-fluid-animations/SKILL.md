---
name: flutter-fluid-animations
description: 'Crea, revisa y optimiza animaciones fluidas en Flutter. Use when: hay jank, animaciones trabadas, transiciones bruscas, stutter en listas, o necesidad de mejorar UX motion con mejores practicas de rendimiento.'
argument-hint: 'Pantalla o flujo a animar (ej. onboarding, lista de historial, modal de feedback)'
user-invocable: true
---

# Flutter Fluid Animations

Skill para disenar, implementar y validar animaciones fluidas en Flutter sin degradar rendimiento.

## Cuando usar
- Al crear nuevas transiciones y microinteracciones.
- Al corregir animaciones con jank o frames perdidos.
- Al estandarizar motion tokens (duracion, curva, ritmo) en una app.
- Al auditar una pantalla pesada con animaciones simultaneas.

## Resultado esperado
- Animaciones suaves y consistentes con objetivo de 60fps (o 120fps en dispositivos compatibles).
- Curvas y timing coherentes entre componentes.
- Rebuilds y trabajo por frame minimizados.
- Motion accesible y desactivable cuando corresponda.

## Flujo de trabajo

1. Definir objetivo visual y tecnico
- Identificar que comunica la animacion: jerarquia, continuidad, feedback o estado.
- Definir metricas objetivo antes de codificar:
  - Duracion por tipo (microinteraccion, cambio de estado, transicion de pantalla)
  - Presupuesto de frame (evitar tareas costosas en 16.67ms)
  - Maximo de dropped frames aceptable en flujo critico

2. Elegir estrategia de animacion
- Usar implicit animations cuando:
  - El cambio es simple (opacidad, escala, padding, color).
  - No se necesita control fino de timeline.
- Usar explicit animations cuando:
  - Se requiere secuenciacion, control de estado, o sincronizar varios efectos.
  - Se necesita orchestration con AnimationController.
- Usar Hero/Shared transitions cuando:
  - La continuidad entre pantallas mejora comprension espacial.

3. Disenar motion tokens reutilizables
- Centralizar constantes de motion:
  - Duraciones (fast, normal, slow)
  - Curvas (emphasis-in, emphasis-out, standard)
- Evitar numeros magicos repetidos por widget.
- Mantener semantica: nombre del token debe explicar intencion.

4. Implementar cuidando rendimiento
- Reducir trabajo en build:
  - No ejecutar logica costosa por frame.
  - Precalcular valores cuando sea posible.
- Limitar area de repintado:
  - Encapsular con RepaintBoundary en zonas de animacion compleja.
  - Evitar invalidar arboles grandes por cambios pequenos.
- Separar estado animado del resto de UI:
  - Dividir widgets para evitar rebuild global.
  - Usar AnimatedBuilder/ValueListenableBuilder para granularidad.

5. Validar en profile mode
- Medir con Flutter DevTools:
  - Frame rendering chart
  - GPU/UI thread timeline
  - Rebuild profiler
- Buscar picos en UI thread o raster thread coincidiendo con animaciones.
- Si hay jank, priorizar por impacto visible.

6. Resolver cuellos de botella (branching)
- Si el cuello esta en layout/build:
  - Simplificar jerarquia, dividir widgets, eliminar trabajo redundante.
- Si el cuello esta en paint/raster:
  - Reducir blur/shadows caros, clipping excesivo, y overdraw.
- Si el cuello esta en I/O concurrente:
  - Desacoplar tareas async de la ventana de animacion.
- Si hay muchas animaciones paralelas:
  - Escalonar inicio (stagger) o reducir amplitud/frecuencia.

7. Accesibilidad y resiliencia
- Respetar preferencias de movimiento reducido cuando aplique.
- Evitar animaciones que oculten informacion esencial.
- Asegurar estados finales correctos en cancelaciones/interrupciones.

8. Pruebas y cierre
- Widget tests para:
  - Estado inicial, intermedio y final.
  - Transiciones disparadas por eventos clave.
- Pruebas manuales en dispositivo real:
  - Gama media/baja y alta tasa de refresco.
- Comparar metricas finales contra baseline.

## Checklist de calidad
- Hay baseline previo y medicion posterior.
- No hay trabajo pesado dentro de builders por frame.
- Tokens de motion centralizados y reutilizables.
- Rebuild scope controlado (sin rebuild masivo innecesario).
- Animaciones coherentes, legibles y con proposito UX.
- Flujo usable aun con movimiento reducido.

## Patrones recomendados
- Entrada/salida de componentes: Fade + slight translate.
- Cambios de estado: AnimatedSwitcher con transiciones discretas.
- Listas: animar solo elementos nuevos/afectados.
- Secuencias complejas: stagger con Interval en un solo controller.

## Antipatrones a evitar
- Encadenar multiples AnimatedContainer sin control de coste.
- Animar demasiadas propiedades simultaneas en widgets profundos.
- Curvas extremas que generan sensacion brusca o artificial.
- Usar animacion para enmascarar latencia de logica no optimizada.

## Prompts de ejemplo
- "/flutter-fluid-animations optimiza la transicion de la pantalla principal para eliminar jank"
- "/flutter-fluid-animations disena motion tokens y aplica mejores practicas en feedback window"
- "/flutter-fluid-animations revisa animaciones de lista y propone cambios medibles con DevTools"
