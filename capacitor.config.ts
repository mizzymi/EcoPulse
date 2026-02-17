import type { CapacitorConfig } from '@capacitor/cli';

const config: CapacitorConfig = {
  appId: 'com.reimii.ecopulse',
  appName: 'EcoPulse',
  webDir: 'dist/ecopulse/browser',
  server: { androidScheme: 'https' }
};

export default config;
