{{flutter_js}}
{{flutter_build_config}}

_flutter.loader.load({
  onEntrypointLoaded: async function(engineInitializer) {
    if (window._gmapsPromise) {
      try {
        await window._gmapsPromise;
      } catch (e) {
        console.error('Error waiting for Google Maps SDK:', e);
      }
    }
    const appRunner = await engineInitializer.initializeEngine();
    await appRunner.runApp();
  }
});

