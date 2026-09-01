/// # AppRegistry
///
/// The catalogue of business applications hosted by the platform.
///
/// ## Adding an application (the whole procedure)
///
/// 1. Drop the application's code under `lib/modules/<name>/`, exposing one
///    `Widget build<Name>Module(BuildContext, PlatformSession)` function.
/// 2. Register its dependencies in `injection_container.dart`.
/// 3. Append one [AppModule] entry below with the `app_id` the backend already
///    uses for that application.
///
/// That is all. The login probes it, the dashboard renders a card for it, the
/// grid re-flows, the route is created — no widget, no layout and no state
/// management is touched. See the commented examples at the end of the list for
/// Disconnect/Reconnect, Complaints, Maintenance, GIS and Inventory.
library;

import 'package:flutter/material.dart';

import '../../modules/inspection/inspection_module.dart';
import '../../modules/meter_reading/meter_reading_module.dart';
import '../../modules/smart_meters/smart_meters_module.dart';
import '../domain/entities/app_module.dart';

class AppRegistry {
  AppRegistry._();

  /// Route prefix under which every module is mounted, e.g. `/app/inspection`.
  static const String routePrefix = '/app';

  /// Every application known to this build, in the order they appear on the
  /// dashboard.
  static const List<AppModule> modules = [
    // ─── Field inspection (legacy app_id 20) ─────────────────────────────────
    AppModule(
      id: 'inspection',
      serverAppId: 20,
      loginDataType: 14,
      title: 'التفتيش الميداني',
      description: 'استعلام وتنفيذ بلاغات التفتيش',
      icon: Icons.engineering_rounded,
      accent: 'blue',
      route: '$routePrefix/inspection',
      builder: buildInspectionModule,
    ),

    // ─── Meter reading / coordinate capture (legacy app_id 49) ───────────────
    AppModule(
      id: 'meter_reading',
      serverAppId: 49,
      loginDataType: 1,
      title: 'قراءة العدادات',
      description: 'رصد إحداثيات العدادات والأصول',
      icon: Icons.speed_rounded,
      accent: 'teal',
      route: '$routePrefix/meter-reading',
      builder: buildMeterReadingModule,
    ),

    // ─── Smart meters (Irbid Electricity) ────────────────────────────────────
    AppModule(
      id: 'smart_meters',
      serverAppId: 7,
      loginDataType: 4,
      title: 'إدارة العدادات الذكية',
      description: 'نظام إدارة ومراقبة العدادات الذكية',
      icon: Icons.auto_graph_rounded,
      accent: 'deepPurple',
      route: '$routePrefix/smart-meters',
      builder: buildSmartMetersModule,
    ),



    // ─────────────────────────────────────────────────────────────────────────
    // Future applications — uncomment when the module and its backend
    // permission row exist. Nothing else in the code base changes.
    //
    // AppModule(
    //   id: 'disconnect_reconnect',
    //   serverAppId: 0,           // ← app_id from the permissions table
    //   loginDataType: 14,
    //   title: 'الفصل والوصل',
    //   description: 'أوامر فصل ووصل التيار ومتابعة تنفيذها',
    //   icon: Icons.electrical_services_rounded,
    //   accent: 'amber',
    //   route: '$routePrefix/disconnect-reconnect',
    //   builder: buildDisconnectReconnectModule,
    // ),
    // AppModule(
    //   id: 'complaints',
    //   serverAppId: 0,
    //   loginDataType: 14,
    //   title: 'الشكاوى',
    //   description: 'استلام شكاوى المشتركين ومتابعة معالجتها',
    //   icon: Icons.support_agent_rounded,
    //   accent: 'violet',
    //   route: '$routePrefix/complaints',
    //   builder: buildComplaintsModule,
    // ),
    // AppModule(
    //   id: 'maintenance',
    //   serverAppId: 0,
    //   loginDataType: 14,
    //   title: 'الصيانة',
    //   description: 'أوامر الصيانة الوقائية والطارئة للشبكة',
    //   icon: Icons.build_rounded,
    //   accent: 'rose',
    //   route: '$routePrefix/maintenance',
    //   builder: buildMaintenanceModule,
    // ),
    // AppModule(
    //   id: 'gis',
    //   serverAppId: 0,
    //   loginDataType: 14,
    //   title: 'نظم المعلومات الجغرافية',
    //   description: 'خرائط الشبكة والأصول الميدانية',
    //   icon: Icons.map_rounded,
    //   accent: 'green',
    //   route: '$routePrefix/gis',
    //   builder: buildGisModule,
    // ),
    // AppModule(
    //   id: 'inventory',
    //   serverAppId: 0,
    //   loginDataType: 14,
    //   title: 'المستودعات',
    //   description: 'حركة المواد وأرصدة المستودعات',
    //   icon: Icons.inventory_2_rounded,
    //   accent: 'cyan',
    //   route: '$routePrefix/inventory',
    //   builder: buildInventoryModule,
    // ),
  ];

  /// Applications that participate in the login probe and can be rendered.
  static List<AppModule> get enabledModules =>
      modules.where((module) => module.enabled).toList(growable: false);

  /// Looks up a module by [id], or `null` when it is not registered.
  static AppModule? byId(String id) =>
      modules.where((module) => module.id == id).firstOrNull;

  /// ## authorisedFor
  ///
  /// **Description**: Resolves the granted ids of a session into module
  /// descriptors, in registry order, dropping ids that no longer exist in this
  /// build (an app removed from the catalogue must not break a cached session).
  ///
  /// **Returns**: the modules the dashboard should render.
  static List<AppModule> authorisedFor(Iterable<String> grantedIds) {
    final granted = grantedIds.toSet();
    return modules
        .where((module) => module.enabled && granted.contains(module.id))
        .toList(growable: false);
  }
}
