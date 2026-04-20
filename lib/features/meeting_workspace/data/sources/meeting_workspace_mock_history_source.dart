import 'package:traisender/features/meeting_workspace/domain/entities/meeting_workspace_models.dart';

class MeetingWorkspaceMockHistorySource {
  static const List<MeetingHistoryItem> history = [
    MeetingHistoryItem(
      id: 1,
      title: 'Entrevista Equipo Tech',
      date: 'Hoy, 10:30 AM',
      length: '45 min',
      transcript:
          'Hola a todos. Repasemos los candidatos. Carlos parecio muy solido en React, pero le falto un poco de conocimiento en bases de datos. Maria, por otro lado, resolvio el problema de algoritmos en 5 minutos. Creo que deberiamos hacerle una oferta a Maria para el puesto Senior. Que opinan? Si, estoy de acuerdo. Carlos podria aplicar para el rol junior si abrimos la vacante la proxima semana.',
    ),
    MeetingHistoryItem(
      id: 2,
      title: 'Lluvia de ideas UX',
      date: 'Ayer, 16:00 PM',
      length: '1h 12m',
      transcript:
          'El problema principal es que los usuarios no encuentran el boton de exportar. Propongo moverlo a la barra superior derecha. Tambien necesitamos cambiar la paleta de colores porque el contraste actual falla en los tests de accesibilidad. Juan, puedes encargarte de los mockups para el viernes? Claro, yo lo reviso.',
    ),
    MeetingHistoryItem(
      id: 3,
      title: 'Revision de metricas',
      date: '15 Oct, 09:00 AM',
      length: '30 min',
      transcript:
          'Las ventas cayeron un 5% este trimestre. La tasa de retencion se mantiene estable en 85%. Necesitamos lanzar la campana de marketing antes del dia 20 para recuperar los numeros de ventas.',
    ),
  ];
}
