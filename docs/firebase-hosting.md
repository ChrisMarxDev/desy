# Firebase Hosting deployment

The Harbor Operations sample is hosted at
[desy-bench.web.app](https://desy-bench.web.app) in the Firebase project
`desy-bench` (project number `304128145969`). The hosted artifact is the release
build from `example/sample_design_system`.

## Automatic production deployment

`.github/workflows/deploy-sample.yml` builds and deploys every push to `main`.
It can also be started manually from GitHub Actions. The workflow writes
`build-metadata.json` beside the web build with the commit, UTC deployment time,
and workflow run URL.

GitHub authenticates through Google Workload Identity Federation. The provider
accepts only repository ID `1325293647` owned by GitHub account ID `18598726`,
then impersonates the dedicated
`github-firebase-hosting@desy-bench.iam.gserviceaccount.com` service account.
No long-lived Firebase token or service-account key is stored in GitHub.

The workflow uses a production concurrency group without cancellation. A
failed build or deployment therefore cannot replace the active release.

## Local deployment

Authenticate the Firebase CLI, then run from the repository root:

```sh
task deploy:sample
```

For a build-only verification, use `task sample:web:build`.

## Caching and routing

Firebase rewrites unknown routes to `index.html` so Flutter web routes can load
directly. The app shell and service worker are not cached; static visual and
font assets use a one-day browser cache.

## Rollback

Open Firebase Console → Hosting → release history, find the last known-good
release, and choose **Rollback**. Firebase keeps the currently active release
when a new workflow run fails, so rollback is needed only after a successful
but faulty deployment.
