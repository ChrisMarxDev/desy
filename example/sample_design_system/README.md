# Sample Design System

This is a runnable Flutter application and the reference consumer for
`desy_bench`. Its registry, themes, and production widgets all live under
`lib/src/`; Desy Bench only renders them.

Run it from this directory:

```sh
flutter run
```

To launch the browser version in Chrome, run:

```sh
task web
```

To create a deployable production build, run `task web:build`. From the
repository root, the same commands are available as `task sample:web` and
`task sample:web:build`.
