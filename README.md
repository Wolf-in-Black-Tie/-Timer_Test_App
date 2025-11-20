# -Timer_Test_App
This is a test application where I will build an application from Codex and run through Github. The application is really simple  its just a timer that runs for each specific Task.

## Codemagic CI

The repository includes a `codemagic.yaml` configuration for building the iOS app on Codemagic without code signing. The workflow:

- Resolves Swift Package Manager dependencies for the `TaskTimers` Xcode project and scheme.
- Builds the simulator binary for an iPhone 16 Pro target.
- Archives a Release build for generic iOS devices with code signing disabled.
- Exports an unsigned `.ipa` to `build/output/` using `exportOptions.plist`.

To trigger a build, connect the repo to Codemagic, select the **iOS Build (TaskTimers)** workflow, and start the build. Downloadable artifacts will be available from `build/output/`.
