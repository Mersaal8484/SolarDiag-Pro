# Release builds

Android debug builds use the SDK debug key. Android release builds are never
signed with that key and fail closed until the owner provides a private
keystore outside source control.

Create `android/key.properties` locally:

```properties
storeFile=C:/absolute/private/path/solardiag-release.jks
storePassword=<private value>
keyAlias=<private alias>
keyPassword=<private value>
```

`key.properties`, `*.jks`, and `*.keystore` are ignored by Git. Never copy a
keystore or its passwords into the repository, CI logs, screenshots, issues,
or reports. CI must provision these four properties from its secret manager.

The owner performs the release build and signing verification. Round 7 did not
run Gradle, Flutter, an APK build, or signature inspection.
