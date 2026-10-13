# IDECO Unified Enterprise Platform — منصة التطبيقات الموحدة

One Flutter application that hosts every field application of the electricity
company behind **a single login**, **one shared service endpoint** and **one
database**. Today it ships two applications; adding the next one is a single
registry entry.

| | |
|---|---|
| Flutter | 3.38+ / Dart 3.10+ |
| Design | Material 3, light theme, corporate blue `#00529C` |
| Language | Arabic, RTL throughout |
| Architecture | Clean Architecture (domain / data / presentation), Cubit, `get_it` |
| Backend | **Unchanged.** Same WCF/SOAP endpoint, same operations, same RSA key |

---

## 1. Navigation flow

```
Splash  ──►  Login  ──►  authenticate + resolve permissions  ──►  Home dashboard
                                                                      │
                                                        only authorised apps
                                                                      │
                                                                      ▼
                                                              selected application
```

Implemented declaratively by `PlatformGate`: it maps the authentication state to
a screen, so a logout anywhere in any module returns to the login screen, and a
cached session lands straight on the dashboard.

## 2. How permissions work without touching the backend

The legacy login query already carries the application filter:

```
DataType:<n>,Where: and A.USER_NAME='<user>'
  and A.USR_DFN_PASSWORD='<pass>' and b.app_id = <serverAppId>
```

`b.app_id` joins the company's own application-permission table, so **the server
decides**: rows returned means the employee is entitled to that application, an
empty result means they are not.

At login the platform fires one such query **per registered application, in
parallel**, on the shared endpoint:

| Application | `app_id` | `DataType` | Row element |
|---|---|---|---|
| Field inspection | 20 | 14 | `<Table>` |
| Meter reading | 49 | 1 | `<tblusers>` |

* every query is byte-for-byte what the corresponding standalone app already
  sends — the backend cannot tell the difference;
* the set of non-empty answers becomes the authorised application list;
* the employee profile is the **union** of the returned rows, because each
  `app_id` exposes different columns (name and department come from 20, workshop
  name from 49) — which is what fills the dashboard employee card;
* if one probe fails on the network while another succeeds, the employee still
  gets the applications that answered.

Offline (a real situation for field crews): credentials are matched against the
last successful login in the keychain and the cached entitlements are replayed,
with an "offline session" chip on the dashboard.

## 3. Project layout

```
lib/
├── core/                        shared by every application
│   ├── constants/               endpoint, SOAP operations, RSA key, brand strings
│   ├── network/                 SoapClient (one API client), NetworkInfo
│   ├── utils/rsa_helper.dart    RSA/PKCS1 payload encryption
│   ├── errors/                  typed Failures
│   ├── theme/                   AppColors · AppDimens · AppTheme (Material 3)
│   ├── layout/responsive.dart   breakpoints, tile metrics, ContentBounds
│   └── widgets/                 dialogs, entrance animation
│
├── platform/                    the shell: SSO + dashboard
│   ├── domain/entities/         Employee · AppModule · PlatformSession
│   ├── domain/usecases/         SignIn · SignOut · RestoreSession
│   ├── data/                    login probes, keychain session, repository
│   ├── registry/app_registry.dart   ← the application catalogue
│   └── presentation/            splash · login · dashboard · notifications
│
├── modules/                     the business applications
│   ├── inspection/              adapter over lib/features/** (app_id 20)
│   └── meter_reading/           ported Coordinates app (app_id 49)
│
├── features/                    inspection feature code (inquiry, submission, …)
├── injection_container.dart     wiring, one block per module
└── main.dart                    theme + localisation + gate only
```

## 4. Adding an application

Three steps, none of which touch a widget:

1. **Drop the code** under `lib/modules/<name>/` and expose one entry point:

   ```dart
   Widget buildComplaintsModule(BuildContext context, PlatformSession session) =>
       ComplaintsHomePage(api: sl<ComplaintsApi>(), session: session);
   ```

2. **Register its dependencies** in `injection_container.dart` (new block at the
   bottom; reuse `sl<SoapClient>()`).

3. **Append one entry** to `AppRegistry.modules` with the `app_id` the backend
   already uses:

   ```dart
   AppModule(
     id: 'complaints',
     serverAppId: 57,          // from the permissions table
     loginDataType: 14,
     title: 'الشكاوى',
     description: 'استلام شكاوى المشتركين ومتابعة معالجتها',
     icon: Icons.support_agent_rounded,
     accent: 'violet',         // key of AppColors.moduleAccents
     route: '${AppRegistry.routePrefix}/complaints',
     builder: buildComplaintsModule,
   ),
   ```

The login now probes it, the dashboard renders its card, the grid re-flows, and
employees without the permission never see it. `enabled: false` ships a module
that stays hidden until the backend is ready. Commented-out examples for
Disconnect/Reconnect, Complaints, Maintenance, GIS and Inventory are in the
registry.

## 5. Dashboard behaviour

* Company logo, greeting, notification button, logout — in the brand header.
* Employee card: name, employee number, department, workshop / office.
* Applications: a responsive grid whose column count comes from a maximum tile
  width, with a fixed tile height, so two applications and twenty look equally
  deliberate on a phone, a tablet or a desktop window.
* **One** authorised application renders as a single wide hero card.
* **No** authorised application renders an explicit "no access" screen, not an
  empty grid.
* Cards use a colourful gradient icon plate, rounded corners, ambient shadow,
  ink ripple, a press scale-down and a staggered fade-in entrance.

## 6. Tests

```bash
flutter analyze                            # 0 errors
flutter test                               # 40 unit + widget + golden tests
flutter test --update-goldens test/golden  # refresh the visual baselines
flutter build apk --debug                  # verifies the merged native config
```

* `test/platform/employee_model_test.dart` — both response shapes, empty result,
  profile merge.
* `test/platform/platform_auth_repository_test.dart` — permission resolution,
  partial failures, offline replay, logout.
* `test/platform/app_registry_test.dart` — catalogue invariants.
* `test/platform/{login,home_dashboard}_page_test.dart` — one login screen, one
  card per entitlement, single-app hero, no-access screen, responsive grid.
* `test/golden/` — rendered baselines with the bundled Arabic font. Goldens are
  machine-specific; re-run with `--update-goldens` on a different OS.

## 7. Deployment notes

* **Google Maps key** — the meter-reading module carries the keys from the
  standalone app (`AndroidManifest.xml`, `ios/Runner/AppDelegate.swift`). Google
  restricts keys by package name / bundle id + signing SHA-1, so add this app's
  identifiers to the key restrictions or the map renders blank.
* **Android identifiers** are unchanged (`com.example.revamp_eletric`) so
  existing installs upgrade in place; change `applicationId` and `namespace`
  together if a new identity is wanted.
* `INTERNET` permission is now declared explicitly — release builds do not
  inherit it from the debug manifest.
* **Notifications** are a placeholder screen: the service exposes no
  notification operation yet. Wire `NotificationsPage` and
  `DashboardHeader.notificationCount` when it does.
* **Biometric login** existed in the standalone meter-reading app and is not in
  this build. Re-enabling it needs `local_auth`, `MainActivity` extending
  `FlutterFragmentActivity`, and a Face ID usage string — none of which can be
  verified without an Android/iOS toolchain on the build machine.
