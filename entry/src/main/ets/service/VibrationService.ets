import vibrator from '@ohos.vibrator';

/**
 * Vibration service - triggers vibration based on action type
 */
export class VibrationService {
  /**
   * Vibrate based on action type
   * - Recommend action: short vibration (300ms)
   * - Probe action: long vibration (800ms)
   */
  static vibrateByActionType(actionType: string): void {
    const duration = actionType === 'recommend' ? 300 : 800;

    try {
      vibrator.startVibration({
        type: 'time',
        duration: duration
      }, {
        usage: 'notification'
      });

      console.log(`VibrationService: Vibrated ${duration}ms for action type: ${actionType}`);
    } catch (error) {
      console.error(`VibrationService: Vibration error - ${JSON.stringify(error)}`);
    }
  }

  /**
   * Stop any ongoing vibration
   */
  static stopVibration(): void {
    try {
      vibrator.stopVibration();
      console.log('VibrationService: Vibration stopped');
    } catch (error) {
      console.error(`VibrationService: Stop error - ${JSON.stringify(error)}`);
    }
  }
}
